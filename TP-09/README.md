# TP-09 — Lambda trigger S3, rôle minimal, logs et gestion d'erreurs

## Objectif

Mettre en place une fonction Lambda déclenchée par un upload S3 sur le préfixe `input/`, capable de :
- valider le type de fichier
- valider la taille maximale
- produire une sortie dans `output/`
- journaliser l'exécution dans CloudWatch Logs avec un format stable
- gérer explicitement les erreurs

---

## Architecture

- **Bucket S3 existant** : bucket du TP-06
- **Préfixe d'entrée** : `input/`
- **Préfixe de sortie** : `output/`
- **Lambda** : `tp9-s3-validator`
- **Logs** : `/aws/lambda/tp9-s3-validator`

---

## Sécurité mise en place

Le rôle IAM de la Lambda est minimal :
- lecture S3 sur `input/*`
- écriture S3 sur `output/*`
- `ListBucket` limité aux préfixes `input/` et `output/`
- écriture dans CloudWatch Logs
- aucune permission `s3:*`

La Lambda est limitée à :
- **timeout** : 10 secondes
- **mémoire** : 128 Mo

---

## Fichiers du dossier

- `main.tf` : infrastructure Terraform
- `variables.tf` : variables
- `outputs.tf` : sorties utiles
- `terraform.tfvars` : valeurs à adapter
- `src/lambda_function.py` : code Lambda
- `tests/valid.txt` : fichier de test autorisé
- `tests/invalid.exe` : fichier de test interdit

---

## Déploiement

1. Remplacer `bucket_name` dans `terraform.tfvars` par le bucket du TP-06.
2. Déployer :

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## Vérifications

### Vérifier la Lambda
```bash
aws lambda get-function \
  --function-name tp9-s3-validator \
  --profile admin \
  --region eu-west-3 \
  --no-cli-pager
```

### Vérifier le rôle IAM inline
```bash
aws iam get-role-policy \
  --role-name tp9-s3-validator-role \
  --policy-name tp9-s3-validator-inline-policy \
  --profile admin \
  --no-cli-pager
```

### Vérifier la configuration de notification S3
```bash
aws s3api get-bucket-notification-configuration \
  --bucket REPLACE_WITH_TP6_BUCKET_NAME \
  --profile admin \
  --region eu-west-3 \
  --no-cli-pager
```

---

## Tests de validation

### Cas nominal
Upload d'un fichier autorisé :

```bash
aws s3 cp tests/valid.txt s3://REPLACE_WITH_TP6_BUCKET_NAME/input/valid.txt \
  --profile admin \
  --region eu-west-3
```

Vérifier la sortie :

```bash
aws s3 ls s3://REPLACE_WITH_TP6_BUCKET_NAME/output/ \
  --profile admin \
  --region eu-west-3
```

Lire le résumé produit :

```bash
aws s3 cp s3://REPLACE_WITH_TP6_BUCKET_NAME/output/valid.txt.summary.json - \
  --profile admin \
  --region eu-west-3
```

### Cas erreur
Upload d'un fichier interdit :

```bash
aws s3 cp tests/invalid.exe s3://REPLACE_WITH_TP6_BUCKET_NAME/input/invalid.exe \
  --profile admin \
  --region eu-west-3
```

Vérifier qu'aucune sortie non conforme n'a été produite :

```bash
aws s3 ls s3://REPLACE_WITH_TP6_BUCKET_NAME/output/ \
  --profile admin \
  --region eu-west-3
```

---

## Collecte des logs CloudWatch

Afficher les logs récents :

```bash
aws logs tail /aws/lambda/tp9-s3-validator \
  --since 10m \
  --profile admin \
  --region eu-west-3
```

Suivi temps réel :

```bash
aws logs tail /aws/lambda/tp9-s3-validator \
  --since 10m \
  --follow \
  --profile admin \
  --region eu-west-3
```

---

## Format de log attendu

Les logs sont en JSON sur une seule ligne avec un format stable contenant :
- `request_id`
- `status`
- `bucket`
- `key`

Exemple de succès :
```json
{"request_id":"...","status":"ACCEPTED","bucket":"...","key":"input/valid.txt","output_key":"output/valid.txt.summary.json","size":22,"content_type":"text/plain"}
```

Exemple d'erreur :
```json
{"request_id":"...","status":"REJECTED","bucket":"...","key":"input/invalid.exe","reason":"INVALID_EXTENSION","allowed_extensions":[".json",".png",".txt"],"size":18,"content_type":"application/x-msdos-program"}
```

---

## Résultat attendu

- un upload valide déclenche la Lambda
- la Lambda écrit un résumé JSON dans `output/`
- un upload invalide est rejeté
- le rejet est visible dans les logs
- les logs contiennent `request_id` et `status`

---

## Nettoyage

Supprimer les objets de test :

```bash
aws s3 rm s3://REPLACE_WITH_TP6_BUCKET_NAME/input/valid.txt \
  --profile admin \
  --region eu-west-3

aws s3 rm s3://REPLACE_WITH_TP6_BUCKET_NAME/input/invalid.exe \
  --profile admin \
  --region eu-west-3

aws s3 rm s3://REPLACE_WITH_TP6_BUCKET_NAME/output/valid.txt.summary.json \
  --profile admin \
  --region eu-west-3
```

Détruire l'infra si nécessaire :

```bash
terraform destroy
```
