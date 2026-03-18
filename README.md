# TP AWS - Infrastructure as Code

Travaux pratiques AWS réalisés avec Terraform.

Réalisé par Karim GASMI
M1 Systèmes, Réseaux & Cloud Computing - ESGI
Cloud Computing AWS - M. Bounif
---

## Structure

| Dossier | Description |
|--------|------------|
| `TP-06/` | S3 sécurité, versioning, lifecycle, politique transport TLS |
| `TP-07/` | Données RDS privé, SG restrictif, snapshot et restauration |
| `TP-08/` | DynamoDB - modélisation par requêtes, GSI, TTL, Streams |
| `TP-09/` | Lambda trigger S3, rôles minimaux, logs et gestion d'erreurs |
| `TP-10/` | API Gateway, SQS, DLQ pipeline asynchrone robuste |
| `TP-11/` | Observabilité CloudWatch, CloudTrail, Flow Logs, alarmes |
| `TP-12/` | KMS et Screts Manager chiffrements et secrets au runtime, triage GuardDuty |
| `TP-13/` | Infrastructure as Code CloudFormation socle réseau reproductible |
| `TP-14/` | Conteneurs managés ECR, ECS Fargate, ALB, logs CloudWatch |
| `TP-15/` | FinOps et résilience budgets, tags, test de continuité et runbook PRA |
---

## Pré-requis

- AWS CLI configuré avec profil
- Terraform >= 1.0

---

## Utilisation

```bash
cd TP-06/   # ou TP-07/ ou TP-08/ ou TP-09/ ou TP-xx/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
