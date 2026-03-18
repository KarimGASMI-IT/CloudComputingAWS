# TP AWS - Infrastructure as Code

Travaux pratiques AWS réalisés en Terraform.

---

## Structure

| Dossier | Description |
|--------|------------|
| `tp6/` | S3 sécurité, versioning, lifecycle, politique transport TLS |
| `tp7/` | Données RDS privé, SG restrictif, snapshot et restauration |
| `tp8/` | DynamoDB - modélisation par requêtes, GSI, TTL, Streams |
| `tp9/` | Lambda trigger S3, rôles minimaux, logs et gestion d'erreurs |
| `tp10/` | API Gateway, SQS, DLQ pipeline asynchrone robuste |
| `tp11/` | Observabilité CloudWatch, CloudTrail, Flow Logs, alarmes |
| `tp12/` | KMS et Screts Manager chiffrements et secrets au runtime, triage GuardDuty |
| `tp13/` | Infrastructure as Code CloudFormation socle réseau reproductible |
| `tp14/` | Conteneurs managés ECR, ECS Fargate, ALB, logs CloudWatch |
| `tp15/` | FinOps et résilience budgets, tags, test de continuité et runbook PRA |
---

## Pré-requis

- AWS CLI configuré avec profil
- Terraform >= 1.0

---

## Utilisation

```bash
cd tp-06/   # ou tp-07/ ou tp-08/ ou tp-09/ ou tp-xx/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
