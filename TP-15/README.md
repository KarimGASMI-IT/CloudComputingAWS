# TP-15 — FinOps & Résilience

## Budgets, Tags, Continuité de service et PRA

---

## Objectif

Ce TP a pour objectif de mettre en place une gouvernance minimale des coûts (**FinOps**) et de démontrer la **résilience d’une architecture AWS**.

Les objectifs principaux sont :

* Mettre en place un **budget AWS avec alertes**
* Appliquer une stratégie de **tagging cohérente**
* Identifier des **sources potentielles de coûts**
* Simuler un **incident applicatif**
* Tester la **continuité de service**
* Réaliser une **restauration de données**
* Formaliser un **runbook PRA**

---

## Architecture utilisée

Ce TP s’appuie sur l’architecture du **TP-14** :

* **Application Load Balancer (ALB)** public
* **ECS Fargate** en subnets privés
* **Target Group** avec health checks
* **S3 versionné** pour la restauration
* **CloudWatch** pour l’observabilité

---

## Déploiement Terraform

### 1. Initialisation

```bash
terraform init
```

### 2. Plan

```bash
terraform plan
```

### 3. Application

```bash
terraform apply
```

---

## Budget AWS

Un budget mensuel est configuré avec :

* un seuil d’alerte à **80%**
* un seuil critique à **100%**

### Vérification

Dans AWS Console :

```
Billing → Budgets
```

---

## Gouvernance des tags

Tags appliqués automatiquement :

```hcl
Project     = TP-Cloud
Owner       = Karim
Environment = training
TP          = 15
ManagedBy   = Terraform
CostCenter  = Education
```

### Vérification CLI

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=TP-Cloud \
  --region eu-west-3 \
  --profile admin
```

---

## Analyse FinOps

### Principaux postes de coûts identifiés

| Ressource   | Risque         | Optimisation                 |
| ----------- | -------------- | ---------------------------- |
| ALB         | coût continu   | suppression hors usage       |
| ECS Fargate | compute actif  | réduire tâches / autoscaling |
| S3 / Logs   | stockage       | lifecycle policy             |
| NAT Gateway | trafic sortant | endpoints privés             |

---

## Test de continuité de service

### 1. Vérification initiale

```bash
curl http://$(terraform output -raw alb_dns_name)
curl http://$(terraform output -raw alb_dns_name)/health
```

---

### 2. Simulation d’incident

```bash
aws ecs list-tasks \
  --cluster tp14-karim-cluster \
  --service-name tp14-karim-service \
  --profile admin \
  --region eu-west-3
```

```bash
aws ecs stop-task \
  --cluster tp14-karim-cluster \
  --task <TASK_ARN> \
  --reason "TP15 incident simulation" \
  --profile admin \
  --region eu-west-3
```

---

### 3. Validation

* Une nouvelle task est recréée automatiquement
* Le service reste accessible
* Le Target Group reste healthy

---

## Observabilité

Dashboard CloudWatch :

```
CloudWatch → Dashboards → tp15-karim-dashboard
```

Métriques suivies :

* RequestCount (ALB)
* HealthyHostCount
* RunningTaskCount (ECS)

---

## Test de restauration S3

### 1. Lire le fichier

```bash
aws s3 cp s3://$(terraform output -raw pra_bucket_name)/restore-demo/app.txt -
```

---

### 2. Modifier

```bash
echo "version-2" > app-v2.txt

aws s3 cp app-v2.txt s3://$(terraform output -raw pra_bucket_name)/restore-demo/app.txt \
  --profile admin \
  --region eu-west-3
```

---

### 3. Lister les versions

```bash
aws s3api list-object-versions \
  --bucket $(terraform output -raw pra_bucket_name) \
  --prefix restore-demo/app.txt \
  --profile admin \
  --region eu-west-3
```

---

### 4. Restaurer

```bash
aws s3api copy-object \
  --bucket $(terraform output -raw pra_bucket_name) \
  --copy-source $(terraform output -raw pra_bucket_name)/restore-demo/app.txt?versionId=<VERSION_ID> \
  --key restore-demo/app.txt \
  --profile admin \
  --region eu-west-3
```

---

## Runbook PRA (Résumé)

### RTO

5 à 10 minutes

### RPO

≈ 0 minute (S3 versioning)

### Incident

Arrêt d’une task ECS

### Continuité

* ECS recrée automatiquement la task
* ALB redirige vers les instances saines

### Restauration

* récupération d’une version précédente S3

---

## Validation du TP

✔ Budget actif avec alertes
✔ Tags appliqués et cohérents
✔ Incident simulé avec continuité de service
✔ Restauration S3 réussie
✔ Runbook PRA documenté

---

## Nettoyage (Teardown)

```bash
terraform destroy
```

Supprimer également :

* objets S3 inutiles
* logs CloudWatch excessifs

---

## Conclusion

Ce TP démontre que :

* la gouvernance FinOps peut être mise en place simplement avec budgets et tags
* la résilience applicative repose sur l’automatisation (ECS + ALB)
* la restauration des données est assurée via S3 versioning

L’architecture est capable de **résister à un incident simple et de se rétablir automatiquement**, constituant une base solide pour un PRA en environnement cloud.

---
