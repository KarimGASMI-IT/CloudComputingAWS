# TP 10 — API Gateway, SQS, DLQ : Pipeline asynchrone robuste

## Objectif

Mettre en place un pipeline asynchrone robuste permettant :

* d’exposer une API HTTP,
* de valider strictement un payload,
* de publier un message dans une file SQS,
* de traiter ce message via une Lambda,
* de persister les données dans DynamoDB,
* et de démontrer la gestion d’erreur avec une Dead Letter Queue (DLQ).

---

## Architecture

### Flux nominal

Client → API Gateway → Lambda Producer → SQS → Lambda Consumer → DynamoDB

### Flux d’erreur

Lambda Consumer échoue → retries → message envoyé en DLQ

---

## Composants AWS

* **API Gateway HTTP**
* **Lambda Producer** (validation + envoi SQS)
* **SQS Main Queue**
* **SQS Dead Letter Queue (DLQ)**
* **Lambda Consumer** (traitement + DynamoDB)
* **DynamoDB** (table du TP8)

---

## Sécurité

* Validation stricte du payload en entrée
* Principe du moindre privilège (IAM)

  * Producer : `sqs:SendMessage`
  * Consumer : `sqs:ReceiveMessage`, `dynamodb:PutItem`
* DLQ configurée et testée

---

## Déploiement

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Récupération des outputs :

```bash
terraform output api_url
terraform output main_queue_url
terraform output dlq_url
terraform output producer_lambda
terraform output consumer_lambda
```

---

## Tests

### 1. Test nominal

```bash
API_URL=$(terraform output -raw api_url)

curl -X POST "${API_URL}/items" \
  -H "Content-Type: application/json" \
  -d '{
    "id":"item-001",
    "name":"clavier",
    "status":"NEW"
  }'
```

### Vérification DynamoDB

```bash
aws dynamodb scan \
  --table-name tp8-orders \
  --profile admin \
  --region eu-west-3
```

---

### 2. Test d’erreur (DLQ)

```bash
curl -X POST "${API_URL}/items" \
  -H "Content-Type: application/json" \
  -d '{
    "id":"item-err-001",
    "name":"item-ko",
    "status":"NEW",
    "force_error":true
  }'
```

---

## Vérifications

### 🔹 Logs Lambda

```bash
aws logs tail /aws/lambda/<consumer-fn> --since 10m --follow
```

---

### Configuration SQS + DLQ

```bash
aws sqs get-queue-attributes \
  --queue-url <main-queue-url> \
  --attribute-names RedrivePolicy
```

---

### Message en DLQ

```bash
aws sqs receive-message \
  --queue-url <dlq-url> \
  --max-number-of-messages 5 \
  --attribute-names All \
  --message-attribute-names All
```

---

## Résultats obtenus

### Cas nominal

* Requête acceptée par l’API
* Message envoyé dans SQS
* Traitement par Lambda Consumer
* Donnée persistée dans DynamoDB

### Cas d’erreur

* Message contenant `force_error=true`
* Échec volontaire de la Lambda Consumer
* Plusieurs tentatives de traitement (retry)
* Message redirigé automatiquement vers la DLQ

---

## Preuves techniques

* Redrive policy configurée avec `maxReceiveCount=3`
* Logs CloudWatch montrant les erreurs répétées
* Message visible dans la DLQ avec :

  * payload complet
  * `ApproximateReceiveCount`
  * `DeadLetterQueueSourceArn`

---

## Nettoyage (optionnel)

```bash
terraform destroy
```

---

## Bonnes pratiques appliquées

* Découplage via SQS
* Gestion d’erreur avec DLQ
* Validation stricte des entrées API
* Observabilité via CloudWatch
* IAM minimal

---

## Conclusion

Ce TP démontre la mise en place d’un pipeline asynchrone robuste sur AWS, capable de :

* traiter des flux de manière découplée,
* gérer les erreurs sans perte de données,
* assurer la traçabilité et la résilience du système.

---
