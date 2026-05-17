# Analyse multivariee des profils d'etudiants

Mini-projet de **Methodes statistiques et etude de donnees en R**.

Sujet : analyse multivariee des profils d'etudiants en enseignement superieur, avec prise en compte du parcours academique, de variables administratives et du statut final, a l'aide d'une **FAMD principale reduite**, d'un **clustering non supervise** et d'une **regression logistique complementaire**.

## Dataset

Dataset utilise : **Predict Students' Dropout and Academic Success**, UCI Repository.

Fichier local :

```text
data/raw/dropout_academic_success.csv
```

La variable cible est `target`, avec les modalites :

- `Dropout`
- `Enrolled`
- `Graduate`

Dans le pipeline final, `target` est utilisee uniquement comme variable illustrative pour interpreter les plans factoriels et les clusters. Elle ne construit pas les axes de la FAMD et n'intervient pas dans la formation des groupes.

## Methodologie finale

Le coeur du projet repose sur une **FAMD principale reduite**. Ce choix est retenu plutot qu'une ACP parce que les donnees combinent des variables quantitatives et qualitatives codees.

La FAMD principale utilise **11 variables actives** :

- variables quantitatives : `previous_qualification_grade`, `admission_grade`, `age_at_enrollment`, `curricular_units_1st_sem_evaluations`, `curricular_units_1st_sem_approved`, `curricular_units_1st_sem_grade` ;
- variables qualitatives : `daytime_evening_attendance`, `debtor`, `tuition_fees_up_to_date`, `gender`, `scholarship_holder`.

Les variables du semestre 2 et les variables economiques sont conservees comme variables supplementaires. Elles aident a lire les resultats, mais ne participent pas a la construction des axes.

Le clustering principal est realise sur les coordonnees individuelles de la FAMD principale reduite. La solution finale retenue est :

- `nb_axes = 2` ;
- `k = 2` ;
- silhouette moyenne proche de **0.508** ;
- stabilite elevee, avec ARI moyen egal a **1.00** dans les repetitions disponibles.

Les deux profils finaux sont :

- **Cluster 1** : 929 etudiants, profil a risque eleve, avec environ **81.5 % Dropout** et **8.9 % Graduate** ;
- **Cluster 2** : 3495 etudiants, profil majoritaire favorable, avec environ **19.0 % Dropout** et **60.8 % Graduate**.

Les solutions avec `k = 3` ou `k = 6` peuvent apparaitre comme comparaisons exploratoires dans certains tableaux ou commentaires, mais elles ne constituent pas la solution principale du projet.

La regression logistique est une analyse complementaire. Elle compare :

- un modele precoce : accuracy **0.849**, recall dropout **0.716**, AUC **0.884** ;
- un modele complet : accuracy **0.865**, recall dropout **0.747**, AUC **0.909**.

Ces resultats sont interpretes comme des associations statistiques descriptives et conditionnelles, sans conclusion causale.

## Fichiers principaux a consulter

```text
rapport/rapport_projet.Rmd              rapport source
rapport/rapport_projet.html             rapport HTML rendu
rapport/interpretation_resultats.md     synthese interpretative finale
webapp/                                 tableau de bord web statique
interface/                              interface Shiny locale
```

Ces fichiers presentent la version finale du pipeline : FAMD principale reduite, clustering principal `nb_axes = 2, k = 2`, `target` illustrative et regression logistique complementaire.

## Structure du projet

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
  04_famd.R                    FAMD principale reduite
  05_clustering.R              clustering sur coordonnees FAMD
  06_modelisation_complementaire.R
                               regression logistique complementaire
  07_export_resultats.R        verification des sorties
  08_audit_technique.R         controles techniques

rapport/
  rapport_projet.Rmd           rapport source
  rapport_projet.html          rapport HTML
  interpretation_resultats.md  interpretation finale

interface/
  app.R                        interface Shiny locale

webapp/
  src/                         interface web statique
  public/project-assets/       figures et tableaux utilises par la webapp
```

## Comment executer le projet

Depuis la racine du projet, les etapes finales peuvent etre relancees avec :

```bash
Rscript R/04_famd.R
Rscript R/05_clustering.R
Rscript R/06_modelisation_complementaire.R
Rscript R/08_audit_technique.R
Rscript -e 'rmarkdown::render("rapport/rapport_projet.Rmd")'
```

Pour une execution complete depuis les donnees brutes, executer d'abord les scripts de configuration, d'import, de preparation et d'analyse descriptive :

```bash
Rscript R/00_packages_config.R
Rscript R/01_import_audit.R
Rscript R/02_preparation_donnees.R
Rscript R/03_analyse_descriptive.R
```

## Comment lancer l'interface Shiny

Depuis la racine du projet, executer :

```r
source("R/00_packages_config.R")
shiny::runApp("interface")
```

## Remarque

Le rapport et les interfaces utilisent les sorties deja produites dans `outputs/`. Les interpretations finales doivent etre lues comme une analyse exploratoire et descriptive, sans validation externe sur une autre cohorte.
