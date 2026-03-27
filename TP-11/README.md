# TP 11 — Observabilité CloudWatch, CloudTrail, Flow Logs et alarmes

## Objectif

Mettre en place une supervision minimale exploitable et une traçabilité des actions sur AWS :

* visualisation centralisée des métriques (CloudWatch Dashboard),
* mise en place d’alarmes actionnables,
* activation et exploitation de CloudTrail,
* vérification et analyse des VPC Flow Logs,
* rédaction d’un mini-runbook d’exploitation.

---

## Contexte

Sans métriques, logs et traçabilité, l’exploitation d’un environnement cloud devient lente et peu fiable.

Ce TP vise à introduire une couche d’observabilité permettant :

* d’identifier rapidement les incidents,
* de comprendre leur origine,
* de faciliter les actions correctives.

---

## Architecture supervisée

Ce TP s’appuie sur le pipeline serverless du TP10 :

Client → API Gateway → Lambda Producer → SQS → Lambda Consumer → DynamoDB

---

## Ressources déployées

* **CloudWatch Dashboard**
* **Alarmes CloudWatch**

  * erreurs API Gateway (5xx)
  * erreurs Lambda Consumer
  * DLQ non vide
* **SNS Topic** pour notifications
* **CloudTrail**

  * management events activés
  * stockage S3 + logs CloudWatch
* **VPC Flow Logs**

  * vérification d’un périmètre critique existant

---

## Déploiement

```bash
terraform init
terraform plan
terraform apply
```

Vérifier que les variables suivantes sont correctement renseignées :

* `api_gateway_id`
* `critical_vpc_id`
* `alarm_email`

---

## Dashboard CloudWatch

Le dashboard permet de visualiser :

* erreurs API Gateway (4xx / 5xx),
* latence API,
* invocations et erreurs Lambda,
* durée d’exécution,
* throttling,
* profondeur de la DLQ.

### Vérification

```bash
aws cloudwatch list-dashboards \
  --profile admin \
  --region eu-west-3
```

---

## Alarmes mises en place

### 1. API Gateway 5xx

Déclenchement si erreurs serveur détectées.

### 2. Lambda Consumer Errors

Déclenchement si au moins une erreur d’exécution.

### 3. DLQ non vide

Déclenchement si un message est présent en DLQ.

### Vérification

```bash
aws cloudwatch describe-alarms \
  --profile admin \
  --region eu-west-3
```

---

## Tests de validation

### Déclenchement d’une alarme (DLQ)

Injection d’un message en erreur via le TP10 :

```bash
API_URL=$(cd ~/TP-10 && terraform output -raw api_url)

curl -X POST "${API_URL}/items" \
  -H "Content-Type: application/json" \
  -d '{
    "id":"item-err-011",
    "name":"test-dlq",
    "status":"NEW",
    "force_error":true
  }'
```

### Vérification DLQ

```bash
DLQ_URL=$(cd ~/TP-10 && terraform output -raw dlq_url)

aws sqs receive-message \
  --queue-url "$DLQ_URL" \
  --max-number-of-messages 5 \
  --attribute-names All \
  --message-attribute-names All \
  --profile admin \
  --region eu-west-3
```

### Vérification alarme

```bash
aws cloudwatch describe-alarms \
  --profile admin \
  --region eu-west-3
```

---

## CloudTrail — traçabilité

### Recherche d’un événement IAM

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateRole \
  --max-results 5 \
  --profile admin \
  --region eu-west-3
```

### Informations observées

* identité (user / role),
* action réalisée,
* ressource ciblée,
* source AWS,
* timestamp.

---

## Flow Logs — analyse réseau

### Vérification des Flow Logs existants

```bash
aws ec2 describe-flow-logs \
  --profile admin \
  --region eu-west-3
```

Un Flow Log actif a été identifié :

* **ResourceId** : subnet critique
* **LogGroupName** : `tp3-flowlogs`
* **Status** : ACTIVE
* **TrafficType** : ALL

### Lecture des logs

```bash
aws logs tail "tp3-flowlogs" \
  --since 10m \
  --profile admin \
  --region eu-west-3
```

### Interprétation

Un Flow Log contient :

* `srcaddr` : IP source
* `dstaddr` : IP destination
* `srcport` : port source
* `dstport` : port destination
* `protocol` : TCP (6) / UDP (17)
* `action` : ACCEPT ou REJECT

### Exemple d’analyse

Un flux vers le port `443` avec `action=ACCEPT` correspond à une communication HTTPS autorisée.

---

## Mini-runbook d’alerte

### Alerte API 5xx

**Triage**

* vérifier le dashboard CloudWatch
* consulter logs API Gateway et Lambda Producer

**Actions**

* vérifier intégration API
* corriger code ou IAM
* redéployer si nécessaire

---

### Alerte Lambda Consumer Errors

**Triage**

* analyser logs Lambda Consumer
* identifier message SQS en cause

**Actions**

* corriger le traitement
* vérifier retry et DLQ

---

### Alerte DLQ non vide

**Triage**

* lire message en DLQ
* analyser cause de l’échec

**Actions**

* corriger la cause
* décider d’un rejeu ou purge

---

## Résultats obtenus

* Dashboard CloudWatch opérationnel
* Alarmes fonctionnelles et non bruitées
* Déclenchement contrôlé validé (DLQ)
* CloudTrail actif et exploitable
* Flow Logs disponibles et interprétables

L’ensemble démontre une supervision minimale efficace et exploitable.

---

## Nettoyage

Les dashboards et alarmes sont conservés pour exploitation future.

---

## Bonnes pratiques appliquées

* Observabilité centralisée
* Alarmes actionnables (pas de bruit)
* Traçabilité complète des actions
* Analyse réseau disponible
* Séparation monitoring / applicatif

---

## Conclusion

Ce TP met en place les bases indispensables d’un système observable sur AWS :

* détection rapide des incidents,
* diagnostic facilité,
* compréhension des flux,
* amélioration de la résilience globale.

---
