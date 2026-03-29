#!/usr/bin/env bash
set -Eeuo pipefail

AWS_PROFILE="${AWS_PROFILE:-admin}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
BASE_DIR="${1:-$PWD}"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR ]${NC} $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Commande manquante: $1"; exit 1; }
}

require_cmd terraform
require_cmd aws

echo "Base dir     : $BASE_DIR"
echo "AWS profile  : $AWS_PROFILE"
echo "AWS region   : $AWS_REGION"
echo
read -r -p "Confirmer la suppression de toutes les ressources Terraform trouvées sous '$BASE_DIR' ? (yes/no) : " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { warn "Annulé."; exit 0; }

tf_dirs=()

while IFS= read -r -d '' dir; do
  tf_dirs+=("$dir")
done < <(find "$BASE_DIR" -maxdepth 2 -type f \( -name "*.tf" -o -name "*.tf.json" \) -printf '%h\0' | sort -zu)

if [[ ${#tf_dirs[@]} -eq 0 ]]; then
  warn "Aucun dossier Terraform trouvé."
else
  log "Dossiers Terraform détectés :"
  for d in "${tf_dirs[@]}"; do
    echo " - $d"
  done
fi

empty_bucket_completely() {
  local bucket="$1"

  warn "Vidage complet du bucket S3: $bucket"

  aws s3 rm "s3://$bucket" --recursive \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" || true

  aws s3api delete-objects \
    --bucket "$bucket" \
    --delete "$(aws s3api list-object-versions \
      --bucket "$bucket" \
      --output json \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      | jq '{Objects: ((.Versions // []) + (.DeleteMarkers // []) | map({Key: .Key, VersionId: .VersionId}))}')" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" >/dev/null 2>&1 || true

  while true; do
    local remaining
    remaining="$(aws s3api list-object-versions \
      --bucket "$bucket" \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --query 'length(Versions[]) + length(DeleteMarkers[])' \
      --output text 2>/dev/null || echo 0)"

    [[ "$remaining" == "None" ]] && remaining=0
    [[ "$remaining" =~ ^[0-9]+$ ]] || remaining=0

    if [[ "$remaining" -eq 0 ]]; then
      break
    fi

    warn "Il reste $remaining versions/delete markers dans $bucket, nouvelle tentative..."
    aws s3api delete-objects \
      --bucket "$bucket" \
      --delete "$(aws s3api list-object-versions \
        --bucket "$bucket" \
        --output json \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        | jq '{Objects: ((.Versions // []) + (.DeleteMarkers // []) | map({Key: .Key, VersionId: .VersionId}))}')" \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" >/dev/null 2>&1 || true
  done
}

destroy_tf_dir() {
  local dir="$1"
  log "Traitement de $dir"

  pushd "$dir" >/dev/null

  export AWS_PROFILE AWS_REGION

  local bucket=""
  if terraform output -raw pra_bucket_name >/dev/null 2>&1; then
    bucket="$(terraform output -raw pra_bucket_name 2>/dev/null || true)"
  fi

  if [[ ! -d .terraform ]]; then
    log "terraform init dans $dir"
    terraform init -input=false -no-color >/dev/null
  fi

  log "terraform destroy dans $dir"
  if terraform destroy -auto-approve -input=false -no-color; then
    log "Destroy OK pour $dir"
    popd >/dev/null
    return
  fi

  warn "Destroy échoué dans $dir"

  if [[ -n "$bucket" ]]; then
    warn "Tentative de nettoyage du bucket de sortie: $bucket"
    empty_bucket_completely "$bucket"
    log "Nouvelle tentative terraform destroy dans $dir"
    terraform destroy -auto-approve -input=false -no-color || err "Destroy toujours en échec dans $dir"
  else
    warn "Aucun output pra_bucket_name trouvé dans $dir"
  fi

  popd >/dev/null
}

for dir in "${tf_dirs[@]}"; do
  destroy_tf_dir "$dir"
done

echo
log "Vérifications AWS finales"

echo
echo "=== ECS clusters ==="
aws ecs list-clusters \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --output table || true

echo
echo "=== ECS services (clusters tp14/tp15 si présents) ==="
for cluster in tp14-karim-cluster tp15-karim-cluster; do
  aws ecs list-services \
    --cluster "$cluster" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --output table 2>/dev/null || true
done

echo
echo "=== Load Balancers ==="
aws elbv2 describe-load-balancers \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
  --output table || true

echo
echo "=== Target Groups ==="
aws elbv2 describe-target-groups \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'TargetGroups[].{Name:TargetGroupName,Arn:TargetGroupArn}' \
  --output table || true

echo
echo "=== EC2 instances ==="
aws ec2 describe-instances \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table || true

echo
echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'NatGateways[].{Id:NatGatewayId,State:State,Subnet:SubnetId}' \
  --output table || true

echo
echo "=== Elastic IPs ==="
aws ec2 describe-addresses \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp,Assoc:AssociationId}' \
  --output table || true

echo
echo "=== Buckets S3 ==="
aws s3 ls || true

echo
echo "=== Repositories ECR ==="
aws ecr describe-repositories \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'repositories[].repositoryName' \
  --output table 2>/dev/null || true

echo
echo "=== Log groups CloudWatch ==="
aws logs describe-log-groups \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'logGroups[].logGroupName' \
  --output table || true

echo
log "Nettoyage terminé."
warn "Si tu vois encore des NAT Gateway, EIP, buckets S3 non voulus, snapshots RDS ou log groups, supprime-les manuellement."
