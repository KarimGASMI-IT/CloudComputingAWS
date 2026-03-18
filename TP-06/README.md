# TP6 AWS - S3 sécurité, versioning, lifecycle et politique TLS avec Terraform

Ce projet Terraform déploie un bucket S3 conforme aux exigences du TP6 :

- blocage public complet
- versioning activé
- chiffrement par défaut activé
- règle lifecycle avec transition et expiration
- bucket policy refusant tout accès sans TLS

## Fichiers du projet

- `main.tf` : ressources Terraform S3
- `variables.tf` : variables du projet
- `terraform.tfvars` : valeurs d'exemple
- `outputs.tf` : sorties utiles

## Pré-requis

- AWS CLI configurée
- profil AWS nommé `training`
- Terraform installé
- droits suffisants sur S3
- nom de bucket unique mondialement

## 1. Adapter le nom du bucket

Dans `terraform.tfvars`, change la valeur de `bucket_name` si nécessaire :

```hcl
bucket_name = "training-karim-tp6-s3-terraform"
```

Si le nom existe déjà dans AWS, Terraform retournera une erreur. Il faut alors choisir un autre nom unique.

## 2. Initialiser le projet

```bash
terraform init
```

## 3. Vérifier la syntaxe

```bash
terraform validate
```

## 4. Prévisualiser le déploiement

```bash
terraform plan
```

## 5. Déployer

```bash
terraform apply
```

Répondre `yes` quand Terraform demande confirmation.

## 6. Vérifications attendues après déploiement

### Vérifier le versioning

```bash
aws s3api get-bucket-versioning   --bucket training-karim-tp6-s3-terraform   --profile training
```

Résultat attendu :

```json
{
  "Status": "Enabled"
}
```

### Vérifier le chiffrement

```bash
aws s3api get-bucket-encryption   --bucket training-karim-tp6-s3-terraform   --profile training
```

Résultat attendu : `SSEAlgorithm` doit être `AES256`.

### Vérifier le blocage public

```bash
aws s3api get-public-access-block   --bucket training-karim-tp6-s3-terraform   --profile training
```

Résultat attendu :

```json
{
  "PublicAccessBlockConfiguration": {
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }
}
```

### Vérifier la policy TLS

```bash
aws s3api get-bucket-policy   --bucket training-karim-tp6-s3-terraform   --profile training
```

Résultat attendu : la policy contient une condition :

```json
"aws:SecureTransport": "false"
```

et un effet `Deny`.

### Vérifier la lifecycle rule

```bash
aws s3api get-bucket-lifecycle-configuration   --bucket training-karim-tp6-s3-terraform   --profile training
```

Résultat attendu :

- transition des objets courants vers `STANDARD_IA` après 30 jours
- expiration des objets courants après 365 jours
- gestion des versions non courantes

## 7. Tests demandés dans le TP

### Test 1 - Upload d'un objet puis modification

Créer un fichier de test :

```bash
echo "Version 1" > test.txt
aws s3 cp test.txt s3://training-karim-tp6-s3-terraform/test.txt --profile training
```

Modifier le fichier puis réuploader :

```bash
echo "Version 2" > test.txt
aws s3 cp test.txt s3://training-karim-tp6-s3-terraform/test.txt --profile training
```

### Test 2 - Vérifier la présence de deux versions

```bash
aws s3api list-object-versions   --bucket training-karim-tp6-s3-terraform   --prefix test.txt   --profile training
```

Résultat attendu :

- deux `VersionId`
- la dernière version correspond à `Version 2`
- l'ancienne version correspond à `Version 1`

### Test 3 - Restaurer une version précédente

1. Repérer le `VersionId` de la première version dans la sortie de `list-object-versions`
2. Lancer la restauration logique en recopiant l'ancienne version sur la clé actuelle

```bash
aws s3api copy-object   --copy-source training-karim-tp6-s3-terraform/test.txt?versionId=<VERSION_ID_V1>   --bucket training-karim-tp6-s3-terraform   --key test.txt   --profile training
```

### Test 4 - Valider l'intégrité de la restauration

Télécharger l'objet courant :

```bash
aws s3 cp s3://training-karim-tp6-s3-terraform/test.txt restored.txt --profile training
cat restored.txt
```

Résultat attendu :

```text
Version 1
```

## 8. Preuves à fournir dans le compte-rendu

### Captures console AWS

- `Permissions` → Block public access
- `Properties` → Bucket Versioning
- `Properties` → Default encryption
- `Management` → Lifecycle rules

### Sorties CLI à joindre

- `get-bucket-versioning`
- `get-public-access-block`
- `get-bucket-encryption`
- `get-bucket-policy`
- `get-bucket-lifecycle-configuration`
- `list-object-versions`
- restauration avec `copy-object`
- vérification finale avec `cat restored.txt`

## 9. Nettoyage éventuel

### Détruire l'infrastructure Terraform

Attention : un bucket non vide ne peut pas être détruit directement.

Supprimer d'abord les objets et versions de test, puis lancer :

```bash
terraform destroy
```

## 10. Remarques sécurité

- Le bucket n'est pas public
- Les accès non chiffrés en HTTP sont refusés
- Le versioning protège contre l'écrasement accidentel
- Le lifecycle optimise les coûts et gère la rétention
- Le chiffrement par défaut sécurise les objets stockés

