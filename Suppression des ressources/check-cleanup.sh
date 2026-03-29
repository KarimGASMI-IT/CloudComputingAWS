#!/usr/bin/env bash
set -u

PROFILE="${AWS_PROFILE:-admin}"
REGION="${AWS_REGION:-eu-west-3}"

ok()  { echo "[OK]  $1"; }
ko()  { echo "[KO]  $1"; }
info(){ echo "[INFO] $1"; }

FAIL=0

check_empty_json_array() {
  local label="$1"
  local cmd="$2"
  local result

  result=$(eval "$cmd" 2>/dev/null)
  if [[ "$result" == "[]" || "$result" == "" || "$result" == "None" ]]; then
    ok "$label"
  else
    ko "$label"
    echo "       Restant: $result"
    FAIL=1
  fi
}

check_s3_tp_buckets() {
  local result
  result=$(aws s3 ls 2>/dev/null | awk '{print $3}' | grep -E '^(tp|TP)' || true)

  if [[ -z "$result" ]]; then
    ok "Buckets S3 TP supprimés"
  else
    ko "Buckets S3 TP supprimés"
    echo "$result" | sed 's/^/       Restant: /'
    FAIL=1
  fi
}

check_logs_tp() {
  local result
  result=$(aws logs describe-log-groups \
    --region "$REGION" \
    --profile "$PROFILE" \
    --query 'logGroups[].logGroupName' \
    --output text 2>/dev/null | tr '\t' '\n' | grep -E '(^/aws/lambda/tp|^tp|TP-)' || true)

  if [[ -z "$result" ]]; then
    ok "Log groups TP supprimés"
  else
    ko "Log groups TP supprimés"
    echo "$result" | sed 's/^/       Restant: /'
    FAIL=1
  fi
}

echo "======================================"
echo " Vérification du nettoyage AWS"
echo " PROFILE = $PROFILE"
echo " REGION  = $REGION"
echo "======================================"

check_empty_json_array \
  "Clusters ECS supprimés" \
  "aws ecs list-clusters --region \"$REGION\" --profile \"$PROFILE\" --query 'clusterArns' --output json"

check_empty_json_array \
  "Load Balancers supprimés" \
  "aws elbv2 describe-load-balancers --region \"$REGION\" --profile \"$PROFILE\" --query 'LoadBalancers[].LoadBalancerName' --output json"

check_empty_json_array \
  "Target Groups supprimés" \
  "aws elbv2 describe-target-groups --region \"$REGION\" --profile \"$PROFILE\" --query 'TargetGroups[].TargetGroupName' --output json"

check_empty_json_array \
  "Instances EC2 supprimées" \
  "aws ec2 describe-instances --region \"$REGION\" --profile \"$PROFILE\" --query 'Reservations[].Instances[?State.Name!=\`terminated\`].InstanceId' --output json"

check_empty_json_array \
  "NAT Gateway supprimées" \
  "aws ec2 describe-nat-gateways --region \"$REGION\" --profile \"$PROFILE\" --query 'NatGateways[?State!=\`deleted\`].NatGatewayId' --output json"

check_empty_json_array \
  "Elastic IP libérées" \
  "aws ec2 describe-addresses --region \"$REGION\" --profile \"$PROFILE\" --query 'Addresses[].AllocationId' --output json"

check_empty_json_array \
  "Repositories ECR supprimés" \
  "aws ecr describe-repositories --region \"$REGION\" --profile \"$PROFILE\" --query 'repositories[].repositoryName' --output json"

check_s3_tp_buckets
check_logs_tp

echo "======================================"
if [[ "$FAIL" -eq 0 ]]; then
  echo "✅ Nettoyage complet : aucune ressource TP détectée."
  exit 0
else
  echo "❌ Nettoyage incomplet : il reste des ressources."
  exit 1
fi
