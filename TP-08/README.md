# TP-08 — DynamoDB : Modélisation par requêtes, GSI, TTL et Streams

## Objectif

Ce TP vise à concevoir une table DynamoDB optimisée pour les requêtes, en évitant l’utilisation de `Scan`, puis à mettre en place :

* une clé primaire adaptée (PK / SK)
* un index secondaire global (GSI)
* une politique TTL
* les Streams DynamoDB

---

## 1. Modélisation orientée requêtes

### Requêtes cibles

* Lire les commandes d’un utilisateur
* Lire les commandes par statut
* Lire les commandes par date

---

### Design des clés

Table : `tp8-orders`

* **PK** : `USER#<user_id>`
* **SK** : `ORDER#<date_iso>#<order_id>`

Exemple :

```
PK = USER#U001
SK = ORDER#2026-03-21T10:00:00Z#O106
```

---

### Justification

Ce design permet :

* accès rapide par utilisateur (`Query`)
* tri naturel par date via la SK
* filtrage par plage de dates sans Scan

---

## 2. GSI (Global Secondary Index)

Index : `GSI1`

* **GSI1PK** : `STATUS#<status>`
* **GSI1SK** : `<date>#USER#<user_id>#ORDER#<order_id>`

---

### Objectif

Permettre la requête :

Lire les commandes par statut **sans Scan**

---

## 3. Déploiement Terraform

### Commandes

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## 4. Vérifications

### Table DynamoDB

```bash
aws dynamodb describe-table \
  --table-name tp8-orders \
  --profile admin \
  --region eu-west-3
```

---

### TTL

```bash
aws dynamodb describe-time-to-live \
  --table-name tp8-orders \
  --profile admin \
  --region eu-west-3
```

Résultat attendu :

```json
"TimeToLiveStatus": "ENABLED"
```

---

### Streams

```bash
aws dynamodb describe-table \
  --table-name tp8-orders \
  --query 'Table.{StreamEnabled:StreamSpecification.StreamEnabled,StreamViewType:StreamSpecification.StreamViewType,LatestStreamArn:LatestStreamArn}' \
  --output table \
  --profile admin \
  --region eu-west-3
```

Résultat attendu :

* StreamEnabled = True
* StreamViewType = NEW_AND_OLD_IMAGES

---

## 5. Insertion des données

```bash
for f in items/*.json; do
  echo "Insertion de $f"
  aws dynamodb put-item \
    --table-name tp8-orders \
    --item file://$f \
    --profile admin \
    --region eu-west-3
done
```

---

## 6. Tests des requêtes

### 6.1 Lecture par utilisateur

```bash
aws dynamodb query \
  --table-name tp8-orders \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk":{"S":"USER#U001"}}' \
  --profile admin \
  --region eu-west-3
```

Résultat attendu :

* retourne les commandes de U001
* pas de Scan utilisé

---

### 6.2 Lecture par statut (via GSI)

```bash
aws dynamodb query \
  --table-name tp8-orders \
  --index-name GSI1 \
  --key-condition-expression "GSI1PK = :status" \
  --expression-attribute-values '{":status":{"S":"STATUS#PENDING"}}' \
  --profile admin \
  --region eu-west-3
```

Résultat attendu :

* retourne les commandes PENDING
* utilise le GSI

---

### 6.3 Lecture par date

```bash
aws dynamodb query \
  --table-name tp8-orders \
  --key-condition-expression "PK = :pk AND SK BETWEEN :from AND :to" \
  --expression-attribute-values '{
    ":pk":   {"S":"USER#U001"},
    ":from": {"S":"ORDER#2026-03-20T00:00:00Z#"},
    ":to":   {"S":"ORDER#2026-03-23T23:59:59Z#ZZZZ"}
  }' \
  --profile admin \
  --region eu-west-3
```

Résultat attendu :

* filtre sur une plage de dates
* toujours sans Scan

---

## 7. TTL

* attribut : `expires_at`
* format : timestamp Unix

permet la suppression automatique des items

suppression **asynchrone** (pas immédiate)

---

## 8. Streams

* activé en `NEW_AND_OLD_IMAGES`
* permet de capturer :

  * INSERT
  * MODIFY
  * REMOVE (TTL inclus)

utile pour intégration avec AWS Lambda

---

## 9. Bonnes pratiques respectées

* ❌ aucun Scan utilisé
* ✅ modélisation orientée requêtes
* ✅ GSI utilisé pour accès alternatif
* ✅ TTL activé
* ✅ Streams activés
* ✅ cohérence éventuelle comprise (GSI)

---

## 10. Conclusion

La modélisation DynamoDB repose sur les patterns d’accès et non sur un modèle relationnel.

Ce TP démontre :

* optimisation des performances avec `Query`
* utilisation efficace des GSI
* automatisation via TTL
* préparation à une architecture événementielle avec Streams
