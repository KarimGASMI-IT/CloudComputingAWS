# TP 13 — Infrastructure as Code CloudFormation : socle réseau reproductible

## Objectif

Ce TP a pour objectif de déployer un socle réseau AWS entièrement reproductible à l’aide de CloudFormation et de maîtriser le cycle complet d’Infrastructure as Code :

* création de stack,
* mise à jour via change set,
* exploitation des outputs,
* suppression complète des ressources.

---

## Contexte

L’Infrastructure as Code (IaC) permet de :

* standardiser les déploiements,
* réduire les erreurs humaines,
* assurer la traçabilité des changements,
* faciliter les rollback.

CloudFormation est un service AWS permettant de décrire et déployer des infrastructures sous forme de templates déclaratifs.

---

## Architecture déployée

Le template déploie un socle réseau simple et reproductible :

* 1 VPC
* 2 subnets publics (multi-AZ)
* 1 Internet Gateway (IGW)
* 1 route table publique
* 1 route vers Internet (0.0.0.0/0)
* associations entre subnets et route table

---

## Fichiers du TP

* `template.yaml` : définition complète de l’infrastructure
* `template.yaml` : définition du changement de l’infrastructure
* `parameters-dev.json` : paramètres du projet (CIDR, AZ, nom)

---

## Déploiement

```bash
aws cloudformation create-stack \
  --stack-name tp13-vpc \
  --template-body file://template.yaml \
  --parameters file://parameters-dev.json \
  --profile admin \
  --region eu-west-3
```

---

## Vérification de la création

### État de la stack

```bash
aws cloudformation describe-stacks \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3
```

### Événements CloudFormation

```bash
aws cloudformation describe-stack-events \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3
```

---

## Outputs

Le template expose plusieurs outputs :

* VpcId
* VpcCidr
* InternetGatewayId
* PublicSubnet1Id
* PublicSubnet2Id
* PublicRouteTableId

### Récupération des outputs

```bash
aws cloudformation describe-stacks \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3 \
  --query "Stacks[0].Outputs"
```

### Exemple d’utilisation

```bash
VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3 \
  --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" \
  --output text)

aws ec2 describe-subnets \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --profile admin \
  --region eu-west-3
```

---

## Mise à jour via Change Set

Une modification mineure (ex : ajout d’un tag `Owner=Karim`) est effectuée dans le template.

### Création du change set

```bash
aws cloudformation create-change-set \
  --stack-name tp13-vpc \
  --change-set-name tp13-update-tags \
  --template-body file://template.yaml \
  --parameters file://parameters-dev.json \
  --change-set-type UPDATE \
  --profile admin \
  --region eu-west-3
```

### Vérification

```bash
aws cloudformation describe-change-set \
  --stack-name tp13-vpc \
  --change-set-name tp13-update-tags \
  --profile admin \
  --region eu-west-3
```

### Exécution

```bash
aws cloudformation execute-change-set \
  --stack-name tp13-vpc \
  --change-set-name tp13-update-tags \
  --profile admin \
  --region eu-west-3
```

### Vérification des événements

```bash
aws cloudformation describe-stack-events \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3
```

---

## Contrôles sécurité

* Aucun secret dans le template
* Tags appliqués sur toutes les ressources principales
* Infrastructure entièrement traçable
* Déploiement reproductible

---

## Tests de validation

### Création de la stack

* Stack en état `CREATE_COMPLETE`
* Ressources visibles dans AWS
* Outputs cohérents

---

### Mise à jour via change set

* Change set généré correctement
* Modification contrôlée
* Événements visibles dans CloudFormation

---

### Suppression complète

```bash
aws cloudformation delete-stack \
  --stack-name tp13-vpc \
  --profile admin \
  --region eu-west-3
```

---

## Vérification post-delete

### Vérifier l’absence du VPC

```bash
aws ec2 describe-vpcs \
  --filters Name=tag:Project,Values=tp13-karim \
  --profile admin \
  --region eu-west-3
```

### Vérifier l’absence des subnets

```bash
aws ec2 describe-subnets \
  --filters Name=tag:Project,Values=tp13-karim \
  --profile admin \
  --region eu-west-3
```

### Vérifier l’absence des route tables

```bash
aws ec2 describe-route-tables \
  --filters Name=tag:Project,Values=tp13-karim \
  --profile admin \
  --region eu-west-3
```

### Vérifier l’absence des Internet Gateways

```bash
aws ec2 describe-internet-gateways \
  --filters Name=tag:Project,Values=tp13-karim \
  --profile admin \
  --region eu-west-3
```

---

## Résultats obtenus

* Déploiement reproductible via CloudFormation
* Infrastructure réseau fonctionnelle
* Outputs exploitables en CLI
* Mise à jour contrôlée via change set
* Suppression complète validée
* Aucun résidu après destruction

---

## Bonnes pratiques appliquées

* Infrastructure as Code versionnée
* Paramétrisation du template
* Tags systématiques
* Séparation template / paramètres
* Validation des changements avant déploiement

---

## Conclusion

Ce TP démontre la mise en œuvre d’un socle réseau AWS entièrement automatisé avec CloudFormation.

Il valide :

* la reproductibilité de l’infrastructure,
* la maîtrise du cycle de vie (create / update / delete),
* la capacité à auditer et contrôler les changements.

---
