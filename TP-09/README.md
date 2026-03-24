# TP-09 — Lambda trigger S3, rôles minimaux, logs et gestion d’erreurs

## Objectif

Ce TP a pour objectif de mettre en place une architecture serverless sur AWS permettant de :

* Traiter un événement S3
* Valider un objet (type + taille)
* Produire une sortie dans un autre préfixe
* Implémenter un rôle IAM minimal
* Assurer une observabilité via CloudWatch Logs
* Gérer explicitement les erreurs

---

## Architecture mise en place

* **Bucket S3** : `training-karim-tp6-s3-terraform` (créé au TP-06)
* **Préfixe d’entrée** : `input/`
* **Préfixe de sortie** : `output/`
* **Lambda** : `tp9-s3-validator`
* **Logs** : `/aws/lambda/tp9-s3-validator`

Flux :

S3 (input/) → Event → Lambda → Validation → output/ + Logs

---

## Sécurité (IAM minimal)

Le rôle IAM associé à la Lambda respecte le principe du moindre privilège :

* Lecture uniquement sur :

  * `s3://training-karim-tp6-s3-terraform/input/*`
* Écriture uniquement sur :

  * `s3://training-karim-tp6-s3-terraform/output/*`
* ListBucket limité aux préfixes `input/` et `output/`
* Accès aux logs CloudWatch uniquement

Aucune permission large de type `s3:*`

---

## Configuration Lambda

* Runtime : `python3.11`
* Handler : `lambda_function.lambda_handler`
* Timeout : 10 secondes
* Mémoire : 128 Mo

Variables d’environnement :

* `MAX_SIZE_BYTES`
* `ALLOWED_EXTENSIONS`
* `INPUT_PREFIX`
* `OUTPUT_PREFIX`

---

## Vérifications

### Vérifier la Lambda

```bash
aws lambda get-function \
 --function-name tp9-s3-validator \
 --profile admin \
 --region eu-west-3 \
 --no-cli-pager
```

```bash
aws lambda get-function-configuration \
 --function-name tp9-s3-validator \
 --profile admin \
 --region eu-west-3 \
 --query '{FunctionName:FunctionName,Runtime:Runtime,Handler:Handler,Timeout:Timeout,MemorySize:MemorySize,Role:Role}' \
 --output table \
 --no-cli-pager
```

---

### Vérifier le rôle IAM

```bash
aws iam get-role-policy \
 --role-name tp9-s3-validator-role \
 --policy-name tp9-s3-validator-inline-policy \
 --profile admin \
 --no-cli-pager
```

---

### Vérifier le trigger S3

```bash
aws s3api get-bucket-notification-configuration \
 --bucket training-karim-tp6-s3-terraform \
 --profile admin \
 --region eu-west-3 \
 --no-cli-pager
```

---

### Vérifier CloudWatch Logs

```bash
aws logs describe-log-groups \
 --log-group-name-prefix /aws/lambda/tp9-s3-validator \
 --profile admin \
 --region eu-west-3 \
 --no-cli-pager
```

---

## Tests

### Cas nominal

Upload d’un fichier valide :

```bash
aws s3 cp tests/valid.txt s3://training-karim-tp6-s3-terraform/input/valid.txt \
 --profile admin \
 --region eu-west-3
```

Vérifier la sortie :

```bash
aws s3 ls s3://training-karim-tp6-s3-terraform/output/ \
 --profile admin \
 --region eu-west-3
```

Lire le résumé :

```bash
aws s3 cp s3://training-karim-tp6-s3-terraform/output/valid.txt.summary.json - \
 --profile admin \
 --region eu-west-3
```

Résultat attendu :

* Fichier généré dans `output/`
* `status = ACCEPTED`

---

### Cas erreur

Upload d’un fichier interdit :

```bash
aws s3 cp tests/invalid.exe s3://training-karim-tp6-s3-terraform/input/invalid.exe \
 --profile admin \
 --region eu-west-3
```

Vérifier :

```bash
aws s3 ls s3://training-karim-tp6-s3-terraform/output/ \
 --profile admin \
 --region eu-west-3
```

Résultat attendu :

* Aucun fichier de sortie créé
* Rejet loggé

---

## Logs CloudWatch

Afficher les logs :

```bash
aws logs tail /aws/lambda/tp9-s3-validator \
 --since 10m \
 --profile admin \
 --region eu-west-3 \
 --no-cli-pager
```

Suivi en temps réel :

```bash
aws logs tail /aws/lambda/tp9-s3-validator \
 --since 10m \
 --follow \
 --profile admin \
 --region eu-west-3
```

---

## Format des logs

Logs JSON structurés :

Exemple succès :

```json
{
  "request_id": "...",
  "status": "ACCEPTED",
  "bucket": "training-karim-tp6-s3-terraform",
  "key": "input/valid.txt"
}
```

Exemple erreur :

```json
{
  "request_id": "...",
  "status": "REJECTED",
  "key": "input/invalid.exe",
  "reason": "INVALID_EXTENSION"
}
```

---

## Incident rencontré

Lors des tests, un problème de connectivité réseau a été rencontré :

* Erreur : `Temporary failure in name resolution`
* Cause : DNS non fonctionnel sur la VM
* Impact : impossibilité d’accéder aux endpoints AWS (S3, logs)

Ce problème est **indépendant de l’infrastructure AWS**.

---

## Validation du TP

✔ Upload valide déclenche la Lambda
✔ Output généré dans `output/`
✔ Upload invalide rejeté
✔ Aucun fichier non conforme produit
✔ Logs contenant `request_id` et `status`
✔ Rôle IAM minimal respecté

---

## Nettoyage

```bash
aws s3 rm s3://training-karim-tp6-s3-terraform/input/valid.txt --profile admin --region eu-west-3
aws s3 rm s3://training-karim-tp6-s3-terraform/input/invalid.exe --profile admin --region eu-west-3
aws s3 rm s3://training-karim-tp6-s3-terraform/output/valid.txt.summary.json --profile admin --region eu-west-3
```

```bash
terraform destroy
```

---

## Conclusion

Ce TP démontre l’importance :

* du design serverless basé sur les événements
* de la gestion stricte des permissions IAM
* de la validation des données en entrée
* de la gestion des erreurs
* de l’observabilité via logs structurés
