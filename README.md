# Analyse multivariee des profils d'etudiants

Mini-projet de **Methodes statistiques et etude de donnees en R**.

Sujet : analyse multivariee des profils d'etudiants en enseignement superieur, avec prise en compte de facteurs socio-economiques, du parcours academique et de la reussite, a l'aide de la **FAMD** et du **clustering**.

## Dataset

Dataset utilise : **Predict Students' Dropout and Academic Success**, UCI Repository.

Fichier local :

```text
data/raw/dropout_academic_success.csv
```

La variable cible est `Target`, avec les modalites :

- `Dropout`
- `Enrolled`
- `Graduate`

## Methodes prevues

- audit initial du fichier CSV ;
- nettoyage des noms de colonnes avec `janitor` ;
- conversion des variables categorielles codees par des nombres en `factor` ;
- analyse descriptive avec tableaux et graphiques ;
- FAMD avec `FactoMineR`, en gardant `target` comme variable illustrative ;
- clustering sur les coordonnees FAMD : methode du coude, silhouette, CAH et k-means ;
- regression logistique binaire complementaire : `Dropout` vs `Non_Dropout`.

## Organisation

```text
data/
  raw/                         donnees brutes
  processed/                   donnees nettoyees au format RDS
outputs/
  figures/                     graphiques exportes
  tables/                      tableaux exportes
  models/                      objets R sauvegardes
R/
  00_packages_config.R         installation, chargement, configuration
  01_import_audit.R            import et audit initial
  02_preparation_donnees.R     nettoyage et typage
  03_analyse_descriptive.R     graphiques descriptifs
  04_famd.R                    FAMD
  05_clustering.R              clustering sur coordonnees FAMD
  06_modelisation_complementaire.R
                               regression logistique binaire
  07_export_resultats.R        verification des sorties
rapport/
  rapport_projet.Rmd           squelette du rapport final
```

## Execution conseillee dans RStudio

Ouvrir le dossier du projet, puis executer les scripts dans cet ordre :

```r
source("R/00_packages_config.R")
source("R/01_import_audit.R")
source("R/02_preparation_donnees.R")
source("R/03_analyse_descriptive.R")
source("R/04_famd.R")
source("R/05_clustering.R")
source("R/06_modelisation_complementaire.R")
source("R/07_export_resultats.R")
```

Le rapport final est dans :

```text
rapport/rapport_projet.Rmd
```

## Comment lancer l'interface Shiny

Depuis la racine du projet, executer :

```r
source("R/00_packages_config.R")
shiny::runApp("interface")
```

## Remarque importante

Les scripts ne contiennent pas d'interpretation inventee. Les commentaires et conclusions du rapport doivent etre completes apres execution du pipeline et lecture des sorties produites dans `outputs/`.
