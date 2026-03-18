# TP7 AWS - RDS privé, SG restrictif, snapshot et restauration avec Terraform

Ce projet Terraform déploie une base **RDS PostgreSQL privée** conforme au TP7 :

- DB subnet group sur subnets privés multi-AZ
- security group DB restrictif autorisant uniquement le SG app
- RDS non publique
- chiffrement au repos activé
- sauvegardes automatiques activées
- procédure de test de connexion, snapshot et restauration

## Fichiers du projet

- `main.tf` : ressources Terraform RDS
- `variables.tf` : variables du projet
- `terraform.tfvars` : valeurs d'exemple à adapter
- `outputs.tf` : sorties utiles

## Pré-requis

- VPC TP3 déjà créé
- 2 subnets privés dans des AZ différentes
- instance applicative privée déjà existante
- security group de l'instance app déjà existant
- AWS CLI configurée
- profil AWS `admin` fonctionnel
- Terraform installé

## 1. Adapter `terraform.tfvars`

Renseigner les ressources déjà créées dans les TP précédents :

```hcl
vpc_id                = "vpc-xxxxxxxxxxxxxxxxx"
private_subnet_ids    = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
app_security_group_id = "sg-xxxxxxxxxxxxxxxxx"
```

Définir aussi les paramètres de base de données :

```hcl
db_instance_identifier = "tp7-postgres-private"
db_name                = "tp7db"
db_username            = "tp7admin"
db_password            = "ChangeMe1234!"
```

## 2. Déployer

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Répondre `yes` à la confirmation.

## 3. Vérifications attendues après déploiement

Définir des variables shell :

```bash
export AWS_PROFILE="admin"
export DB_ID="tp7-postgres-private"
```

### Vérifier l'instance RDS

```bash
aws rds describe-db-instances   --db-instance-identifier $DB_ID   --profile $AWS_PROFILE
```

Points attendus :
- `PubliclyAccessible` = `false`
- `StorageEncrypted` = `true`
- `BackupRetentionPeriod` > `0`
- `Engine` = `postgres`

### Vérifier le DB subnet group

```bash
aws rds describe-db-subnet-groups   --db-subnet-group-name tp7-karim-db-subnet-group   --profile $AWS_PROFILE
```

Points attendus :
- présence des deux subnets privés
- coverage multi-AZ

### Vérifier le SG DB

```bash
aws ec2 describe-security-groups   --group-ids <DB_SECURITY_GROUP_ID>   --profile $AWS_PROFILE
```

Points attendus :
- entrée TCP 5432
- source = security group applicatif
- aucun `0.0.0.0/0` en entrée

## 4. Test de connexion depuis l'instance app

Se connecter à l'instance privée via SSM puis installer le client PostgreSQL.

### Amazon Linux

```bash
sudo dnf install postgresql15 -y
```

ou selon l'image :

```bash
sudo yum install postgresql -y
```

### Se connecter à la base

Récupérer l'endpoint :

```bash
aws rds describe-db-instances   --db-instance-identifier $DB_ID   --query 'DBInstances[0].Endpoint.Address'   --output text   --profile $AWS_PROFILE
```

Puis depuis l'instance app :

```bash
psql "host=<RDS_ENDPOINT> port=5432 dbname=tp7db user=tp7admin password=ChangeMe1234!"
```

## 5. Requêtes SQL de preuve

Dans `psql` :

```sql
CREATE TABLE preuve_tp7 (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO preuve_tp7 (nom) VALUES ('test-1');
INSERT INTO preuve_tp7 (nom) VALUES ('test-2');

SELECT * FROM preuve_tp7;
SELECT current_database();
SELECT now();
```

Résultats attendus :
- table créée
- deux lignes visibles
- base `tp7db`
- horodatage affiché

## 6. Test d'échec depuis un réseau non autorisé

Méthodes de preuve possibles :
- montrer que le SG DB autorise uniquement le SG app sur 5432
- montrer que `PubliclyAccessible` est à `false`
- tenter une connexion depuis une machine non autorisée si disponible

Commande utile :

```bash
aws ec2 describe-security-groups   --group-ids <DB_SECURITY_GROUP_ID>   --query 'SecurityGroups[0].IpPermissions'   --profile $AWS_PROFILE
```

## 7. Créer un snapshot manuel

Créer un identifiant horodaté :

```bash
SNAP_ID="tp7-postgres-private-snap-$(date +%Y%m%d%H%M%S)"
echo $SNAP_ID
```

Créer le snapshot :

```bash
aws rds create-db-snapshot   --db-instance-identifier $DB_ID   --db-snapshot-identifier $SNAP_ID   --profile $AWS_PROFILE
```

Vérifier :

```bash
aws rds describe-db-snapshots   --db-snapshot-identifier $SNAP_ID   --profile $AWS_PROFILE
```

Points attendus :
- snapshot visible
- identifiant horodaté
- statut `creating` puis `available`

## 8. Procédure de restauration

Restaurer vers une nouvelle instance :

```bash
RESTORE_ID="tp7-postgres-restore"
aws rds restore-db-instance-from-db-snapshot   --db-instance-identifier $RESTORE_ID   --db-snapshot-identifier $SNAP_ID   --db-subnet-group-name tp7-karim-db-subnet-group   --vpc-security-group-ids <DB_SECURITY_GROUP_ID>   --db-instance-class db.t3.micro   --no-publicly-accessible   --profile $AWS_PROFILE
```

Vérifier l'état :

```bash
aws rds describe-db-instances   --db-instance-identifier $RESTORE_ID   --profile $AWS_PROFILE
```

Quand l'instance est `available`, récupérer l'endpoint restauré puis tester la connexion avec `psql` et exécuter :

```sql
SELECT * FROM preuve_tp7;
```

Résultat attendu :
- les données restaurées sont présentes

## 9. Preuves à fournir dans le compte-rendu

### Captures console AWS

- page RDS instance
- `Publicly accessible = No`
- `Storage encrypted = Yes`
- `Backup retention period`
- DB subnet group
- rules du SG DB
- snapshot manuel

### Sorties CLI à joindre

- `describe-db-instances`
- `describe-db-subnet-groups`
- `describe-security-groups`
- commandes `psql` et résultats
- `create-db-snapshot`
- `describe-db-snapshots`
- procédure de restauration

## 10. Nettoyage

Supprimer la base si elle n'est pas réutilisée :

```bash
terraform destroy
```

Supprimer aussi, si demandé :
- snapshot manuel
- instance restaurée
- security groups orphelins

### Supprimer un snapshot manuel

```bash
aws rds delete-db-snapshot   --db-snapshot-identifier $SNAP_ID   --profile $AWS_PROFILE
```

### Supprimer l'instance restaurée

```bash
aws rds delete-db-instance   --db-instance-identifier $RESTORE_ID   --skip-final-snapshot   --profile $AWS_PROFILE
```

## 11. Remarques sécurité

- la base n'est pas exposée publiquement
- seul le SG app peut joindre la base
- le chiffrement au repos protège les données stockées
- les sauvegardes automatiques assurent une reprise
- le snapshot manuel permet une restauration ponctuelle documentée
