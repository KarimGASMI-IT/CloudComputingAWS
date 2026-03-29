# Cleanup Script — AWS Terraform

## Objectif

Ce script permet de **supprimer automatiquement toutes les ressources AWS créées avec Terraform** dans les dossiers du projet (`TP-*`).

Il est particulièrement utile pour :

* éviter toute **dérive de coûts (FinOps)**
* nettoyer l’environnement après les TPs
* préparer un rendu propre

---

## Fonctionnement

Le script :

1. Parcourt tous les dossiers contenant du Terraform (`*.tf`)
2. Exécute automatiquement :

   ```bash
   terraform destroy
   ```
3. Gère les cas bloquants :

   * bucket S3 non vide → vidage automatique
4. Relance la suppression si nécessaire
5. Effectue une **vérification finale AWS**

---

## Prérequis

* Terraform installé
* AWS CLI configuré (`aws configure`)
* Profil AWS valide (par défaut : `admin`)
* Outil `jq` installé

Installation de `jq` :

```bash
sudo apt-get update && sudo apt-get install -y jq
```

---

## Utilisation

### 1. Donner les droits

```bash
chmod +x cleanup-all.sh
```

---

### 2. Exécuter

```bash
./cleanup-all.sh
```

Ou sur un dossier spécifique :

```bash
./cleanup-all.sh /root/CloudComputingAWS
```

---

## ⚠️ Confirmation

Le script demande une validation :

```text
Confirmer la suppression ? (yes/no)
```

⚠️ Cette action est **irréversible**

---

## Vérifications automatiques

À la fin, le script vérifie :

* ECS clusters et services
* Load Balancers (ALB)
* Target Groups
* Instances EC2
* NAT Gateway
* Elastic IP
* Buckets S3
* Repositories ECR
* CloudWatch Logs

---

## Bonnes pratiques

* Toujours exécuter ce script après un TP
* Vérifier Cost Explorer après nettoyage
* Ne jamais exécuter en production

---

## Nettoyage manuel (si nécessaire)

Certains éléments peuvent nécessiter une suppression manuelle :

* snapshots RDS
* AMI / snapshots EBS
* buckets S3 externes
* logs CloudWatch spécifiques

---

## Conclusion

Ce script permet de :

* automatiser le nettoyage complet des ressources AWS
* éviter les coûts inutiles
* appliquer une démarche FinOps efficace

---
