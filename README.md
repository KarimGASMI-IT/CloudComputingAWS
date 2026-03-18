# TP AWS - Infrastructure as Code

Travaux pratiques AWS réalisés en Terraform.

---

## Structure

| Dossier | Description |
|--------|------------|
| `tp6/` | S3 sécurité - versioning, TLS, chiffrement, lifecycle |
| `tp7/` | RDS privée - SG restrictif, chiffrement, snapshot et restauration |
| `tp8/` | DynamoDB - modélisation par requêtes, GSI, TTL, Streams |

---

## Pré-requis

- AWS CLI configuré avec profil
- Terraform >= 1.0

---

## Utilisation

```bash
cd tp-06/   # ou tp-07/ ou tp-08/ ou tp-09/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
