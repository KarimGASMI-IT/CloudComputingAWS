# TP-14 — Conteneurs managés sur AWS avec Terraform

## Objectif

Ce TP a pour objectif de déployer une application conteneurisée sur AWS en utilisant :

* Amazon ECR (Elastic Container Registry)
* Amazon ECS avec Fargate (serverless)
* Application Load Balancer (ALB)
* Amazon CloudWatch Logs

Le tout est automatisé avec **Terraform**, sans gestion de serveurs.

---

## Architecture

L’architecture mise en place repose sur les principes suivants :

* Image Docker stockée dans **ECR**
* Service **ECS Fargate** exécuté dans des **subnets privés**
* Exposition via un **ALB public**
* Accès contrôlé via **Security Groups**
* Logs centralisés dans **CloudWatch**

```
Internet
   │
   ▼
[ ALB Public ]
   │
   ▼
[ ECS Fargate Tasks ]
   │
   ▼
[ Subnets privés ]
   │
   ▼
[ NAT Gateway → Internet ]
```

---

## Pré-requis

* AWS CLI configuré (`profile admin`)
* Terraform installé
* Docker installé
* VPC avec :

  * subnets publics (ALB)
  * subnets privés (ECS)
  * NAT Gateway

---

## Déploiement

### 1. Initialisation Terraform

```bash
terraform init
terraform plan
terraform apply
```

---

### 2. Build et push de l’image Docker

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile admin)
REGION=eu-west-3
REPO_NAME=tp14-karim-repo

aws ecr get-login-password --region $REGION --profile admin \
| docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

cd app
docker build -t ${REPO_NAME}:v1 .
docker tag ${REPO_NAME}:v1 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:v1
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:v1
```

---

### 3. Déploiement ECS

```bash
aws ecs update-service \
  --cluster tp14-karim-cluster \
  --service tp14-karim-service \
  --force-new-deployment \
  --profile admin \
  --region eu-west-3
```

---

## Accès à l’application

Récupérer l’URL de l’ALB :

```bash
terraform output -raw alb_dns_name
```

Tester :

```bash
curl http://<ALB>
curl http://<ALB>/health
```

### Résultat attendu

```json
{"message":"TP14 ECS Fargate OK","version":"v1"}
```

---

## Logs CloudWatch

Afficher les logs :

```bash
aws logs tail /ecs/tp14-karim \
  --since 10m \
  --follow \
  --profile admin \
  --region eu-west-3
```

---

## Sécurité

* Les tâches ECS sont déployées en **subnets privés**
* Aucun accès direct depuis Internet
* Accès uniquement via **ALB**
* Security Groups :

  * ALB : HTTP (80) ouvert
  * ECS : accès uniquement depuis le SG de l’ALB
* IAM :

  * rôle d’exécution ECS (`AmazonECSTaskExecutionRolePolicy`)
  * rôle applicatif minimal

---

## Mise à jour de version

### 1. Build et push v2

```bash
docker build -t ${REPO_NAME}:v2 .
docker tag ${REPO_NAME}:v2 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:v2
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:v2
```

### 2. Modifier Terraform

```hcl
image_tag = "v2"
```

### 3. Déployer

```bash
terraform apply
```

### Résultat

* Déploiement **sans interruption**
* Remplacement progressif des tâches (rolling update)

---

## Incident rencontré

Lors du déploiement initial, une erreur a été rencontrée :

```
CannotPullContainerError: image not found
```

### Cause

L’image Docker n’avait pas été poussée dans ECR avec le tag `v1`.

### Solution

* Build de l’image
* Push dans ECR
* Redéploiement ECS

---

## Teardown

```bash
terraform destroy
```

Vérifier la suppression :

```bash
aws ecs describe-services ...
aws elbv2 describe-load-balancers ...
aws ecr describe-repositories ...
```

---

## Validation du TP

* Service accessible via ALB
* Logs CloudWatch fonctionnels
* Tâches en subnets privés
* Sécurité réseau respectée
* Mise à jour version sans interruption

---

## Technologies utilisées

* Terraform
* AWS ECS Fargate
* AWS ECR
* AWS ALB
* AWS CloudWatch Logs
* Docker

---

## Auteur

Karim GASMI

M1 SRC - ESGI

TP Cloud Computing AWS
