#!/usr/bin/env bash
set -Eeuo pipefail

AWS_PROFILE="${AWS_PROFILE:-admin}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
BASE_DIR="${PWD}"

DRY_RUN=false
AGGRESSIVE=false
AUTO_APPROVE=false

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="cleanup-${TIMESTAMP}.log"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log()  { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[ERR ]${NC} $*" | tee -a "$LOG_FILE"; }
step() { echo -e "${BLUE}[STEP]${NC} $*" | tee -a "$LOG_FILE"; }

usage() {
  cat <<EOF
Usage: $0 [options] [base_dir]

Options:
  --dry-run       Simule les actions sans rien supprimer
  --aggressive    Supprime aussi les restes AWS fréquents (NAT, EIP, ECR, logs)
  --yes           Ne demande pas de confirmation
  --profile NAME  Profil AWS CLI (défaut: admin)
  --region NAME   Région AWS (défaut: eu-west-3)
  -h, --help      Affiche cette aide

Exemples:
  $0 --dry-run
  $0 --aggressive --yes /root/CloudComputingAWS
  $0 --profile training --region eu-west-3
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Commande manquante: $1"; exit 1; }
}

run_cmd() {
  if $DRY_RUN; then
    echo "[DRY-RUN] $*" | tee -a "$LOG_FILE"
  else
    eval "$@" 2>&1 | tee -a "$LOG_FILE"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --aggressive) AGGRESSIVE=true; shift ;;
    --yes) AUTO_APPROVE=true; shift ;;
    --profile) AWS_PROFILE="$2"; shift 2 ;;
    --region) AWS_REGION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) BASE_DIR="$1"; shift ;;
  esac
done

require_cmd terraform
require_cmd aws
require_cmd jq

step "Configuration"
echo "Base dir    : $BASE_DIR" | tee -a "$LOG_FILE"
echo "AWS profile : $AWS_PROFILE" | tee -a "$LOG_FILE"
echo "AWS region  : $AWS_REGION" | tee -a "$LOG_FILE"
echo "Dry run     : $DRY_RUN" | tee -a "$LOG_FILE"
echo "Aggressive  : $AGGRESSIVE" | tee -a "$LOG_FILE"
echo "Log file    : $LOG_FILE" | tee -a "$LOG_FILE"

if ! $AUTO_APPROVE; then
  echo
  read -r -p "Confirmer le nettoyage complet ? (yes/no) : " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { warn "Annulé."; exit 0; }
fi

mapfile -d '' tf_dirs < <(
  find "$BASE_DIR" -maxdepth 3 -type f \( -name "*.tf" -o -name "*.tf.json" \) -printf '%h\0' | sort -zu
)

if [[ ${#tf_dirs[@]} -eq 0 ]]; then
  warn "Aucun dossier Terraform trouvé."
else
  step "Dossiers Terraform détectés"
  for d in "${tf_dirs[@]}"; do
    echo " - $d" | tee -a "$LOG_FILE"
  done
fi

empty_bucket_completely() {
  local bucket="$1"
  warn "Vidage complet du bucket: $bucket"

  run_cmd "aws s3 rm s3://$bucket --recursive --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\" || true"

  local payload
  payload="$(aws s3api list-object-versions \
    --bucket "$bucket" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --output json 2>/dev/null \
    | jq -c '{Objects: ((.Versions // []) + (.DeleteMarkers // []) | map({Key: .Key, VersionId: .VersionId}))}')" || payload='{"Objects":[]}'

  if [[ "$payload" != '{"Objects":[]}' ]]; then
    if $DRY_RUN; then
      echo "[DRY-RUN] aws s3api delete-objects --bucket \"$bucket\" --delete '$payload'" | tee -a "$LOG_FILE"
    else
      aws s3api delete-objects \
        --bucket "$bucket" \
        --delete "$payload" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" >>"$LOG_FILE" 2>&1 || true
    fi
  fi
}

destroy_tf_dir() {
  local dir="$1"
  local bucket=""

  step "Traitement Terraform: $dir"
  pushd "$dir" >/dev/null

  export AWS_PROFILE AWS_REGION

  if [[ ! -d .terraform ]]; then
    run_cmd "terraform init -input=false -no-color"
  fi

  if terraform output -raw pra_bucket_name >/dev/null 2>&1; then
    bucket="$(terraform output -raw pra_bucket_name 2>/dev/null || true)"
  fi

  if $DRY_RUN; then
    run_cmd "terraform destroy -auto-approve -input=false -no-color"
    popd >/dev/null
    return
  fi

  if terraform destroy -auto-approve -input=false -no-color 2>&1 | tee -a "$LOG_FILE"; then
    log "Destroy OK: $dir"
    popd >/dev/null
    return
  fi

  warn "Destroy en échec dans $dir"
  if [[ -n "$bucket" ]]; then
    empty_bucket_completely "$bucket"
    terraform destroy -auto-approve -input=false -no-color 2>&1 | tee -a "$LOG_FILE" || err "Destroy toujours en échec: $dir"
  fi

  popd >/dev/null
}

delete_nat_gateways() {
  step "Suppression NAT Gateways"
  mapfile -t nat_ids < <(
    aws ec2 describe-nat-gateways \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --query 'NatGateways[?State!=`deleted`].NatGatewayId' \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d'
  )
  for id in "${nat_ids[@]:-}"; do
    run_cmd "aws ec2 delete-nat-gateway --nat-gateway-id \"$id\" --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\""
  done
}

release_eips() {
  step "Libération Elastic IP"
  mapfile -t alloc_ids < <(
    aws ec2 describe-addresses \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --query 'Addresses[].AllocationId' \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d'
  )
  for id in "${alloc_ids[@]:-}"; do
    run_cmd "aws ec2 release-address --allocation-id \"$id\" --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\""
  done
}

delete_ecr_repos() {
  step "Suppression repositories ECR"
  mapfile -t repos < <(
    aws ecr describe-repositories \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --query 'repositories[].repositoryName' \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d'
  )
  for repo in "${repos[@]:-}"; do
    run_cmd "aws ecr delete-repository --repository-name \"$repo\" --force --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\""
  done
}

delete_log_groups() {
  step "Suppression log groups CloudWatch"
  mapfile -t groups < <(
    aws logs describe-log-groups \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --query 'logGroups[].logGroupName' \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d'
  )
  for group in "${groups[@]:-}"; do
    run_cmd "aws logs delete-log-group --log-group-name \"$group\" --profile \"$AWS_PROFILE\" --region \"$AWS_REGION\""
  done
}

delete_remaining_s3() {
  step "Suppression buckets S3 restants"
  mapfile -t buckets < <(aws s3 ls | awk '{print $3}')
  for bucket in "${buckets[@]:-}"; do
    warn "Nettoyage bucket restant: $bucket"
    empty_bucket_completely "$bucket"
    run_cmd "aws s3 rb s3://$bucket --force"
  done
}

final_checks() {
  step "Vérifications finales"

  echo -e "\n=== ECS clusters ===" | tee -a "$LOG_FILE"
  aws ecs list-clusters --profile "$AWS_PROFILE" --region "$AWS_REGION" --output table 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== Load Balancers ===" | tee -a "$LOG_FILE"
  aws elbv2 describe-load-balancers \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code}' \
    --output table 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== EC2 instances ===" | tee -a "$LOG_FILE"
  aws ec2 describe-instances \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' \
    --output table 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== NAT Gateways ===" | tee -a "$LOG_FILE"
  aws ec2 describe-nat-gateways \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'NatGateways[].{Id:NatGatewayId,State:State}' \
    --output table 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== Elastic IPs ===" | tee -a "$LOG_FILE"
  aws ec2 describe-addresses \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp}' \
    --output table 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== S3 buckets ===" | tee -a "$LOG_FILE"
  aws s3 ls 2>&1 | tee -a "$LOG_FILE" || true

  echo -e "\n=== ECR repositories ===" | tee -a "$LOG_FILE"
  aws ecr describe-repositories \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'repositories[].repositoryName' \
    --output table 2>&1 | tee -a "$LOG_FILE" || true
}

for dir in "${tf_dirs[@]:-}"; do
  destroy_tf_dir "$dir"
done

if $AGGRESSIVE; then
  delete_nat_gateways
  release_eips
  delete_ecr_repos
  delete_log_groups
  delete_remaining_s3
fi

final_checks

log "Nettoyage terminé."
warn "Consulte le log: $LOG_FILE"
