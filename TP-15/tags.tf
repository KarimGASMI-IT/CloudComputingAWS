resource "null_resource" "tag_existing_resources" {
  count = length(var.resource_arns_to_tag) > 0 ? 1 : 0

  triggers = {
    resource_arns = join(",", var.resource_arns_to_tag)
    tags_hash     = sha1(jsonencode(local.common_tags))
    aws_profile   = trimspace(var.aws_profile)
    aws_region    = trimspace(var.aws_region)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list ${join(" ", var.resource_arns_to_tag)} \
  --tags Project="${local.common_tags.Project}",Owner="${local.common_tags.Owner}",Environment="${local.common_tags.Environment}",TP="${local.common_tags.TP}",ManagedBy="${local.common_tags.ManagedBy}",CostCenter="${local.common_tags.CostCenter}" \
  --region ${trimspace(var.aws_region)} \
  --profile ${trimspace(var.aws_profile)}
EOT
  }
}