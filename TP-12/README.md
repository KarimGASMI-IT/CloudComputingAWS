# TP 12 — KMS, Secrets Manager, chiffrement et sécurité runtime

## Objectif

Ce TP a pour objectif de mettre en place des mécanismes de sécurité avancés sur AWS :

* chiffrement des données avec une clé KMS dédiée,
* gestion sécurisée des secrets avec AWS Secrets Manager,
* consommation des secrets au runtime par une application (Lambda),
* restriction des accès via des politiques IAM minimales,
* introduction à la détection de menaces avec GuardDuty.

---

## Contexte

La fuite de secrets constitue un incident critique dans un système cloud.
Les bonnes pratiques imposent :

* un stockage centralisé des secrets,
* un accès contrôlé et audité,
* l’absence totale de secrets en clair dans le code.

---

## Architecture

Les composants déployés sont les suivants :

* **AWS KMS** : clé dédiée avec rotation activée
* **Amazon S3** : bucket chiffré avec KMS
* **Secrets Manager** : stockage du secret applicatif
* **AWS Lambda** : lecture du secret au runtime
* **IAM** : accès strictement limité
* **GuardDuty** : (tentative d’activation)

---

## Ressources déployées

* KMS Key + alias
* S3 bucket chiffré (SSE-KMS)
* Secret Manager (secret JSON)
* Lambda reader (runtime secret)
* IAM role minimal
* CloudWatch logs

---

## Déploiement

```bash
terraform init
terraform plan
terraform apply
```

---

## Chiffrement avec KMS

### Création de la clé

* clé dédiée au projet
* rotation activée (`enable_key_rotation = true`)

### Vérification

```bash
aws kms list-keys \
  --profile admin \
  --region eu-west-3
```

---

## 🪣 Chiffrement S3

Le bucket est configuré avec chiffrement KMS :

```bash
aws s3api get-bucket-encryption \
  --bucket <bucket-name> \
  --profile admin \
  --region eu-west-3
```

### Résultat attendu

* `SSEAlgorithm = aws:kms`
* clé KMS utilisée

---

## Secrets Manager

### Création du secret

Le secret contient :

```json
{
  "username": "admin",
  "password": "SuperSecret123!",
  "token": "tp12-token"
}
```

### Vérification

```bash
aws secretsmanager list-secrets \
  --profile admin \
  --region eu-west-3
```

```bash
aws secretsmanager get-secret-value \
  --secret-id <secret-name> \
  --profile admin \
  --region eu-west-3
```

---

## Lecture du secret au runtime (Lambda)

La Lambda récupère dynamiquement le secret via AWS SDK.

### Test

```bash
aws lambda invoke \
  --function-name <lambda-name> \
  response.json \
  --profile admin \
  --region eu-west-3
```

```bash
cat response.json
```

---

## Logs CloudWatch

```bash
aws logs tail /aws/lambda/<lambda-name> \
  --since 10m \
  --profile admin \
  --region eu-west-3
```

### Preuve attendue

* le secret est utilisé
* mais **jamais affiché en clair**

---

## Sécurité IAM

Les permissions sont strictement limitées :

### Autorisé

* `secretsmanager:GetSecretValue` sur UN secret
* `kms:Decrypt` sur UNE clé

### Refusé

* accès global aux secrets
* accès non autorisé via autre identité

---

## Tests de validation

### Test 1 — Fonctionnement runtime

* Lambda récupère le secret dynamiquement
* aucune donnée sensible en dur dans le code

---

### Test 2 — Accès refusé

```bash
aws secretsmanager get-secret-value \
  --secret-id <secret-name> \
  --profile training \
  --region eu-west-3
```

Résultat attendu :
→ **AccessDeniedException**

---

### Test 3 — Chiffrement actif

* KMS actif
* S3 chiffré
* Secret chiffré

---

## GuardDuty

### Tentative d’activation

L’activation via Terraform a échoué avec :

```
SubscriptionRequiredException
```

### Interprétation

Cela signifie que le service n’est pas disponible dans cet environnement de laboratoire.

---

### Catégories de findings GuardDuty

* **UnauthorizedAccess** : accès suspect
* **Recon** : scan réseau
* **CryptoCurrency** : minage
* **Trojan** : malware
* **Backdoor** : accès distant
* **Behavior** : comportement anormal

---

## Résultats obtenus

* chiffrement KMS fonctionnel
* S3 sécurisé
* secrets centralisés
* accès contrôlé via IAM
* récupération runtime validée
* accès non autorisé refusé
* logs exploitables

---

## Nettoyage

Optionnel :

```bash
terraform destroy
```

Attention :

* KMS nécessite un délai de suppression
* Secrets Manager peut avoir une période de récupération

---

## Bonnes pratiques appliquées

* aucun secret en clair
* chiffrement systématique
* IAM minimal
* séparation infra / secret
* auditabilité complète

---

## Conclusion

Ce TP démontre la mise en place d’un socle de sécurité solide :

* protection des données au repos,
* gestion sécurisée des secrets,
* accès runtime contrôlé,
* réduction de la surface d’attaque.

Ces pratiques sont essentielles pour tout environnement cloud en production.

---
