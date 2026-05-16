# Audit d'état du projet

Projet : **Analyse multivariée des profils d'étudiants en enseignement supérieur : facteurs socio-économiques, parcours académique et réussite à l'aide de la FAMD et du clustering**

Date de l'audit : 15/05/2026

## Synthèse exécutive

Le projet est dans un état avancé sur la partie statistique : les scripts R sont structurés, les données brutes et préparées existent, les outputs principaux sont générés, le rapport HTML est présent, l'interprétation méthodologique est déjà rédigée, et une interface React/Vite moderne existe dans `webapp/`.

Les principaux points à corriger avant un rendu final concernent surtout la préparation GitHub, la soutenance et quelques finitions de robustesse :

- `.gitignore` est vide alors que des fichiers temporaires et volumineux existent.
- `webapp/node_modules/`, `webapp/dist/`, `.RData`, `.Rhistory`, `.RDataTmp`, `.RDataTmp1` et `Rplots.pdf` sont présents localement et ne doivent pas être poussés tels quels.
- `slides/plan_soutenance.md` existe mais il est vide.
- Le README ne documente pas encore l'application React/Vite.
- Le rapport est complet, mais certains éléments de rendu/encodage et quelques formulations doivent être relus avant dépôt.

État global estimé : **82 / 100**.

## 1. Architecture du projet

### Dossiers attendus

| Élément | État | Commentaire |
|---|---:|---|
| `data/` | Présent | Organisation propre avec sous-dossiers. |
| `data/raw/` | Présent | Contient le CSV brut `dropout_academic_success.csv`. |
| `data/processed/` | Présent | Contient `dropout_clean.rds`. |
| `R/` | Présent | Contient les scripts 00 à 07 attendus. |
| `outputs/` | Présent | Structure complète avec tables, figures et modèles. |
| `outputs/tables/` | Présent | Nombreuses sorties CSV générées. |
| `outputs/figures/` | Présent | Figures descriptives, FAMD, clustering et logistique. |
| `outputs/models/` | Présent | Objets RDS FAMD, k-means, CAH et logistique. |
| `rapport/` | Présent | Contient Rmd, HTML et interprétation Markdown. |
| `webapp/` | Présent | Application React/Vite complète. |
| `interface/` | Présent | Interface Shiny existante conservée. |
| `slides/` | Présent | Dossier présent, mais contenu vide. |

### Organisation GitHub

L'organisation générale est propre pour un projet académique GitHub : séparation claire entre scripts, données, sorties, rapport, interface et supports de présentation.

Points fragiles pour GitHub :

- Aucun dossier `.git/` n'a été détecté à la racine pendant l'audit.
- `.gitignore` existe mais il est vide.
- Des fichiers temporaires R et Node sont présents à la racine ou dans `webapp/`.
- `node_modules/` est présent et ne doit pas être versionné.
- `webapp/dist/` est présent ; il peut être ignoré si le dépôt doit contenir seulement le code source, ou conservé uniquement si un déploiement statique est prévu.

Conclusion : **architecture fonctionnelle et lisible, mais préparation GitHub insuffisante en l'état**.

## 2. Scripts R

### `R/00_packages_config.R`

Rôle :

- Configure le dépôt CRAN.
- Installe les packages manquants.
- Charge les bibliothèques nécessaires : `tidyverse`, `janitor`, `skimr`, `naniar`, `FactoMineR`, `factoextra`, `cluster`, `corrplot`, `broom`, `nnet`, `knitr`, `kableExtra`, `shiny`, `bslib`, `DT`, `rmarkdown`.

État probable : **complet**.

Sorties générées :

- Pas de sortie statistique directe.
- Prépare l'environnement d'exécution.

Risques :

- Installation automatique de packages dans un script peut surprendre sur certaines machines.
- La dépendance à des binaires Windows est pratique localement, mais moins portable hors Windows.

Améliorations possibles :

- Ajouter une note README sur la version de R conseillée.
- Éventuellement fournir un fichier `renv.lock` si le projet doit être parfaitement reproductible.

### `R/01_import_audit.R`

Rôle :

- Importe le CSV brut depuis `data/raw/dropout_academic_success.csv`.
- Réalise un audit initial : dimensions, noms de colonnes, valeurs manquantes, distribution de `Target`, résumé `skimr`.
- Exporte les premières tables dans `outputs/tables/`.

État probable : **complet**.

Sorties générées :

- `01_dimensions.csv`
- `01_noms_colonnes.csv`
- `01_valeurs_manquantes.csv`
- `01_distribution_target.csv`
- `01_skim.csv`

Risques :

- Le script suppose que le séparateur CSV est `;`, ce qui est correct pour le fichier UCI utilisé.
- Pas de contrôle explicite de l'encodage du CSV brut.

Améliorations possibles :

- Ajouter un contrôle sur les colonnes attendues.
- Ajouter un message clair si la distribution de `Target` diffère des valeurs attendues.

### `R/02_preparation_donnees.R`

Rôle :

- Nettoie les noms de colonnes avec `janitor::clean_names()`.
- Convertit les variables qualitatives codées numériquement en facteurs.
- Ajoute des labels lisibles pour certaines variables binaires.
- Crée `dropout_binary` et `success_binary`.
- Exporte le dataset préparé et le dictionnaire de variables.

État probable : **complet et central pour le projet**.

Sorties générées :

- `data/processed/dropout_clean.rds`
- `02_types_variables.csv`
- `02_dictionnaire_variables.csv`

Risques :

- Certaines variables à forte cardinalité sont conservées comme facteurs mais ensuite non utilisées dans la FAMD principale ; c'est justifié mais doit être expliqué.
- Le nom original `nacionality` est conservé selon le dataset ; cela peut surprendre mais reste cohérent.

Améliorations possibles :

- Ajouter un test de cohérence sur le nombre final de lignes.
- Ajouter un bloc court listant les variables exclues de la FAMD mais disponibles pour analyses secondaires.

### `R/03_analyse_descriptive.R`

Rôle :

- Produit les tableaux et figures descriptives.
- Analyse `Target`, variables socio-démographiques, socio-économiques, académiques, économiques et corrélations numériques.

État probable : **complet**.

Sorties générées :

- Tables `03_a_*`, `03_b_*`, `03_c_*`, `03_d_*`, `03_e_*`, matrice de corrélation.
- Figures `03_a_*`, `03_b_*`, `03_c_*`, `03_d_*`, `03_e_*`, `03_matrice_*`.

Risques :

- Les graphiques sont surtout descriptifs ; ils ne testent pas formellement les différences entre groupes.
- Les variables économiques sont moins centrales dans l'interprétation actuelle.

Améliorations possibles :

- Ajouter une table synthétique "messages descriptifs clés".
- Ajouter des tests non paramétriques ou ANOVA en annexe uniquement si le professeur attend des tests, sans surcharger la soutenance.

### `R/04_famd.R`

Rôle :

- Sélectionne les variables actives interprétables.
- Utilise `target` comme variable supplémentaire.
- Réalise la FAMD avec `FactoMineR::FAMD`.
- Exporte valeurs propres, coordonnées, contributions et figures.

État probable : **solide**.

Sorties générées :

- `04_resultat_famd.rds`
- `04_famd_variables_actives.csv`
- `04_famd_valeurs_propres.csv`
- `04_famd_coordonnees_individus.csv`
- `04_famd_coordonnees_variables.csv`
- `04_famd_contributions_axes_1_2.csv`
- Figures FAMD correspondantes.

Risques :

- Le choix des variables actives est raisonné mais doit être défendu.
- Les deux premiers axes expliquent une inertie modérée : Dim.1 = 13,55 %, Dim.2 = 6,68 %, cumul = 20,23 %.

Améliorations possibles :

- Ajouter dans le rapport une justification encore plus explicite du non-usage des variables à très forte cardinalité.
- Ajouter une table synthétique des contributions principales de Dim.2, car elle est importante pour l'axe socio-administratif.

### `R/05_clustering.R`

Rôle :

- Réalise le clustering sur les coordonnées FAMD.
- Utilise les 5 premiers axes FAMD lorsque disponibles.
- Compare `k = 2` à `k = 6` avec coude et silhouette.
- Retient techniquement `k = 6`.
- Produit k-means, CAH, profils de clusters, croisement cluster/Target.

État probable : **complet, mais à justifier avec prudence**.

Sorties générées :

- `05_kmeans.rds`
- `05_cah.rds`
- `05_kmeans_methode_coude.csv`
- `05_kmeans_silhouette.csv`
- `05_k_recommande.csv`
- `05_clusters_individus.csv`
- `05_profils_clusters_kmeans.csv`
- `05_profils_clusters_interpretes.csv`
- `05_repartition_binaires_clusters.csv`
- `05_croisement_cluster_target.csv`
- Figures coude, silhouette, clusters, composition, dendrogramme.

Risques :

- La silhouette maximale est faible/modérée : 0,2611 pour `k = 6`.
- Les silhouettes de `k = 5` et `k = 6` sont proches : 0,2585 contre 0,2611.
- Le choix `k = 6` doit être présenté comme exploratoire et interprétable, pas comme une vérité définitive.

Améliorations possibles :

- Ajouter une petite table de justification combinant silhouette, coude, taille des clusters et interprétabilité.
- Ajouter une visualisation des profils par indicateurs académiques moyens.

### `R/06_modelisation_complementaire.R`

Rôle :

- Construit une cible binaire `Dropout` vs `Non_Dropout`.
- Ajuste une régression logistique binaire.
- Exporte odds ratios, matrice de confusion, métriques et histogramme des probabilités.

État probable : **complet et correctement positionné comme complémentaire**.

Sorties générées :

- `06_modele_logistique_dropout.rds`
- `06_logit_odds_ratios.csv`
- `06_interpretation_odds_ratios.csv`
- `06_matrice_confusion.csv`
- `06_metriques_logit.csv`
- `06_metriques_detaillees_logit.csv`
- `06_probabilites_dropout.png`

Risques :

- Pas de validation croisée.
- Modèle simple avec split train/test aléatoire 80/20 ; les métriques peuvent dépendre du split.
- Certaines variables peuvent être corrélées entre elles, notamment les variables académiques semestrielles.

Améliorations possibles :

- Ajouter une phrase sur l'absence de causalité et la nature conditionnelle des odds ratios.
- Ajouter une validation croisée en bonus, si le temps le permet.

### `R/07_export_resultats.R`

Rôle :

- Vérifie la présence des sorties principales.
- Crée un inventaire des outputs.

État probable : **complet**.

Sorties générées :

- `07_inventaire_outputs.csv`
- `07_verification_sorties.csv`

Risques :

- Vérification minimale : elle confirme l'existence de fichiers, pas leur contenu.

Améliorations possibles :

- Ajouter un contrôle de non-vacuité des fichiers.
- Ajouter des contrôles sur quelques valeurs clés attendues : `n = 4424`, `k = 6`, métriques logistiques non manquantes.

## 3. Données et préparation

### Données disponibles

| Élément | État | Détail |
|---|---:|---|
| Dataset brut | Présent | `data/raw/dropout_academic_success.csv` |
| Dataset nettoyé | Présent | `data/processed/dropout_clean.rds` |
| Dimensions brutes | Présentes | 4424 lignes, 37 colonnes |
| Dictionnaire | Présent | `02_dictionnaire_variables.csv` |
| Types de variables | Présents | `02_types_variables.csv` |
| Valeurs manquantes | Contrôlées | 0 valeur manquante détectée dans l'audit initial |

### Variables créées

Les variables suivantes existent dans `02_types_variables.csv` :

- `target` : facteur à 3 modalités.
- `dropout_binary` : facteur à 2 modalités.
- `success_binary` : facteur à 2 modalités.

La préparation est suffisante pour le projet :

- Les variables qualitatives codées numériquement ont été converties en facteurs.
- Les variables binaires importantes ont des labels lisibles.
- La variable `Target` est ordonnée de manière stable.
- Le dictionnaire facilite le rapport et la soutenance.

Point à surveiller :

- Le dataset brut a 37 colonnes, mais le dataset préparé contient 39 variables après ajout de `dropout_binary` et `success_binary`. Il faut bien distinguer ces deux nombres dans le rapport et l'interface.

## 4. Outputs générés

### Sorties indispensables

Indispensables pour le rendu :

- `01_dimensions.csv`
- `01_valeurs_manquantes.csv`
- `02_dictionnaire_variables.csv`
- `03_a_distribution_target.csv`
- Figures académiques `03_d_*`
- `04_famd_valeurs_propres.csv`
- `04_famd_contributions_axes_1_2.csv`
- `04_famd_variables_actives.csv`
- Figures `04_famd_*`
- `05_k_recommande.csv`
- `05_kmeans_silhouette.csv`
- `05_profils_clusters_interpretes.csv`
- `05_croisement_cluster_target.csv`
- Figures `05_*`
- `06_metriques_detaillees_logit.csv`
- `06_matrice_confusion.csv`
- `06_logit_odds_ratios.csv`
- `06_interpretation_odds_ratios.csv`

### Sorties secondaires mais utiles

- `01_skim.csv`
- `03_b_socio_demographique_target.csv`
- `03_c_socio_economique_target.csv`
- `03_e_resume_contexte_economique_par_target.csv`
- `03_matrice_correlation.csv`
- `04_famd_coordonnees_individus.csv`
- `04_famd_coordonnees_variables.csv`
- `05_clusters_individus.csv`
- `05_repartition_binaires_clusters.csv`
- `05_dendrogramme_cah.png`
- `07_inventaire_outputs.csv`
- `07_verification_sorties.csv`

### Sorties éventuellement manquantes

Rien d'indispensable ne semble manquer. Pour enrichir le rendu, on pourrait ajouter :

- une table synthétique "messages clés" par étape ;
- une figure radar ou barplot comparant les profils de clusters ;
- une table propre des variables les plus associées au risque logistique avec une interprétation en français ;
- une version PDF du rapport, si demandée par l'enseignant.

## 5. Analyse descriptive

État : **bonne base, suffisamment riche pour soutenir la suite**.

Présent :

- Distribution de `Target`.
- Analyse des variables académiques.
- Analyse socio-démographique.
- Analyse socio-économique.
- Analyse du contexte économique.
- Matrice de corrélation des variables numériques.
- Tableaux et figures cohérents.

Forces :

- Les variables académiques sont clairement identifiées comme centrales.
- Les sorties sont suffisamment nombreuses pour alimenter rapport, Shiny et React.
- L'analyse prépare bien la transition vers la FAMD.

À renforcer :

- Ajouter une synthèse en une phrase par figure dans le rapport ou les slides.
- Éviter de surcharger la soutenance avec toutes les figures ; sélectionner les plus parlantes.
- Ajouter un encadré "pourquoi la descriptive ne suffit pas", déjà présent dans l'interface React mais à valoriser dans les slides.

## 6. FAMD

État : **solide et cohérent avec la matière**.

Présent :

- Justification de la FAMD pour données mixtes.
- Sélection de variables actives.
- `target` utilisée comme variable illustrative/supplémentaire.
- Valeurs propres.
- Contributions des axes 1 et 2.
- Coordonnées individus et variables.
- Figures FAMD.
- Interprétation Dim.1 et Dim.2.

Résultats clés :

- Dim.1 : 13,55 % d'inertie.
- Dim.2 : 6,68 % d'inertie.
- Cumul Dim.1 + Dim.2 : 20,23 %.
- Cumul des 5 premiers axes : 32,53 %.
- Dim.1 principalement académique : unités approuvées, inscrites, évaluations et notes.
- Dim.2 davantage socio-administrative : âge, qualification précédente, déplacement, frais, bourse, régime.

Appréciation :

- La partie est défendable devant le professeur.
- La prudence sur l'inertie modérée est déjà présente.
- Le fait que `target` soit illustrative est correctement expliqué.

Améliorations possibles :

- Ajouter une explication très pédagogique de "variable active" vs "variable illustrative" dans les slides.
- Expliquer pourquoi les variables à forte cardinalité ont été écartées.
- Ne pas affirmer que les axes expliquent tout : insister sur la lecture synthétique.

## 7. Clustering

État : **bon, avec prudence nécessaire sur la silhouette**.

Présent :

- Clustering sur coordonnées FAMD.
- K-means.
- CAH en complément.
- Méthode du coude.
- Silhouette.
- Choix technique `k = 6`.
- Profils de clusters.
- Profils interprétés.
- Composition des clusters par `Target`.

Résultats clés :

| Cluster | Profil | Effectif | Dropout | Graduate | Risque |
|---:|---|---:|---:|---:|---|
| 1 | Profil fragile à risque académique | 74 | 64,86 % | 17,57 % | Élevé |
| 2 | Profil performant à forte réussite | 619 | 18,26 % | 64,62 % | Faible |
| 3 | Profil stable majoritaire | 2158 | 14,97 % | 64,37 % | Faible |
| 4 | Profil critique de décrochage | 619 | 79,48 % | 11,31 % | Très élevé |
| 5 | Profil intermédiaire en transition | 585 | 36,58 % | 47,18 % | Modéré |
| 6 | Profil à risque élevé | 369 | 62,60 % | 16,53 % | Élevé |

Justification de `k = 6` :

- La silhouette maximale est atteinte pour `k = 6` : 0,2611.
- `k = 6` produit des profils interprétables.
- Le cluster 4 ressort clairement comme profil critique.

Fragilité :

- La silhouette est modérée.
- Les valeurs de silhouette pour `k = 5` et `k = 6` sont proches.
- La partition doit être présentée comme exploratoire.

Améliorations possibles :

- Ajouter une slide spécifique "Pourquoi k = 6 malgré une silhouette modérée ?".
- Montrer la composition par Target des clusters plutôt que toutes les tables.
- Ajouter une lecture décisionnelle des clusters : favorable, intermédiaire, à risque, critique.

## 8. Régression logistique complémentaire

État : **complément utile et bien positionné**.

Présent :

- Cible binaire `Dropout` vs `Non_Dropout`.
- Split train/test.
- Régression logistique binaire.
- Métriques détaillées.
- Matrice de confusion.
- Odds ratios.
- Interprétation prudente.

Métriques :

| Métrique | Valeur |
|---|---:|
| Accuracy | 85,76 % |
| Precision Dropout | 82,11 % |
| Recall Dropout | 71,13 % |
| F1 Dropout | 76,23 % |
| Specificity Non_Dropout | 92,68 % |

Matrice de confusion :

- Vrais négatifs : 557.
- Faux positifs : 44.
- Faux négatifs : 82.
- Vrais positifs : 202.

Interprétation :

- Le modèle est cohérent avec les résultats FAMD/clustering.
- Les variables académiques du deuxième semestre et certaines variables socio-administratives ressortent dans les odds ratios.
- Le modèle doit rester complémentaire : le coeur du projet est FAMD + clustering.

Risques :

- Pas de validation croisée.
- Les odds ratios peuvent être sensibles à la sélection des variables.
- La présence de variables du deuxième semestre améliore la performance mais rend la logique moins "prédiction précoce".

Améliorations possibles :

- Présenter clairement que les odds ratios sont des associations conditionnelles, pas des relations causales.
- Ajouter une phrase sur le seuil de prédiction fixé à 0,5.
- En bonus : comparer un modèle "précoce" avec variables disponibles dès l'inscription ou le S1.

## 9. Rapport

Fichiers analysés :

- `rapport/rapport_projet.Rmd`
- `rapport/rapport_projet.html`
- `rapport/interpretation_resultats.md`

### Contenu présent dans le rapport

| Partie attendue | État |
|---|---:|
| Introduction | Présente |
| Problématique | Présente |
| Objectifs | Présents |
| Dataset | Présent |
| Préparation | Présente |
| Analyse descriptive | Présente |
| FAMD | Présente |
| Clustering | Présent |
| Régression logistique complémentaire | Présente |
| Recommandations | Présentes |
| Limites | Présentes |
| Conclusion | Présente |

### Forces

- Structure très complète.
- Rapport connecté aux outputs générés par les scripts.
- Les limites sont présentes.
- La FAMD est bien expliquée.
- Le clustering est interprété avec prudence.
- La logistique est présentée comme complémentaire.

### Points à améliorer

- Relire l'encodage dans les outils de rendu : certains accents apparaissent mal dans la sortie console PowerShell, même si le rendu HTML peut être correct. Avant GitHub, vérifier l'affichage sur GitHub ou réenregistrer en UTF-8 si nécessaire.
- Le commentaire YAML "À remplacer par les vrais noms..." est encore présent alors que les noms semblent déjà renseignés. Il faut le supprimer avant rendu.
- Ajouter éventuellement une phrase de transition claire entre analyse descriptive et FAMD.
- Ajouter une phrase plus explicite sur les variables disponibles au moment de l'inscription vs les variables académiques après semestre.

### Formulations causales

Les formulations dangereuses semblent globalement évitées. Le rapport utilise surtout :

- "associé à" ;
- "suggère" ;
- "ne doivent pas être interprétés comme..." ;
- "exploratoire".

À surveiller :

- Les mots comme "explique" sont parfois utilisés au sens d'inertie FAMD ou de lecture structurante, ce qui est acceptable si le contexte est clair.
- Garder la distinction entre association statistique et causalité dans la soutenance orale.

## 10. Interface React

Fichiers analysés :

- `webapp/package.json`
- `webapp/src/App.jsx`
- `webapp/src/main.jsx`
- `webapp/src/styles.css`
- `webapp/src/data/projectData.js`
- `webapp/public/project-assets/figures/`
- `webapp/public/project-assets/tables/`

### État technique

Présent :

- Application React + Vite.
- Scripts `dev`, `build`, `preview`.
- `App.jsx` structuré en pages.
- `main.jsx` conforme : `createRoot(...).render(<App />)`.
- CSS responsive.
- Données centralisées dans `projectData.js`.
- Assets copiés dans `public/project-assets`.
- 28 figures dans `webapp/public/project-assets/figures`.
- 34 tables dans `webapp/public/project-assets/tables`.

État observé :

- `webapp/dist/` existe, ce qui indique qu'un build a été généré.
- `vite-dev.log` indique un serveur Vite lancé sur `http://127.0.0.1:5173/`.
- Lors de l'audit, aucun nouveau `npm run build` n'a été lancé afin de respecter la contrainte "ne pas modifier les fichiers du projet". À relancer juste avant rendu.

### Qualité de l'interface

Forces :

- Sidebar conservée et lisible.
- Pages principales présentes : Accueil, Dataset, Analyse descriptive, FAMD, Clustering, Régression logistique, Recommandations.
- Composants pédagogiques présents : cartes d'insight, méthode, métrique, figure, cluster, warning, message clé.
- Storytelling statistique par page.
- Figures PNG affichées depuis les outputs copiés.
- Design académique moderne.

Fragilités :

- L'interface contient des valeurs codées dans `projectData.js`, reprises des sorties. C'est acceptable, mais il faut maintenir la cohérence si les scripts R sont relancés.
- Les CSV copiés dans `webapp/public/project-assets/tables/` ne sont pas lus dynamiquement par React ; ils servent plutôt d'archives/assets.
- La présence de `node_modules/` et `dist/` dans le projet local pose un problème GitHub si `.gitignore` reste vide.

Améliorations possibles :

- Ajouter un bouton ou lien vers le rapport HTML.
- Ajouter une page "Méthodologie" ou un mode présentation plein écran.
- Ajouter une table filtrable pour les clusters ou les odds ratios.
- Ajouter des mini graphiques faits en React uniquement à partir des valeurs déjà présentes, sans recalcul statistique.
- Ajouter une section "À retenir pour la soutenance" sur chaque page.
- Ajouter une vérification visuelle mobile avant rendu.

## 11. README et GitHub

### README

État : **utile mais incomplet**.

Présent :

- Description du sujet.
- Description du dataset.
- Méthodes prévues.
- Organisation du projet.
- Ordre d'exécution des scripts R.
- Lancement de Shiny.

Manques :

- Pas d'instructions pour React/Vite.
- Pas d'instructions pour générer le rapport HTML.
- Pas de section "Résultats principaux".
- Pas de section "Équipe" structurée.
- Pas de mention des fichiers à ne pas versionner.
- Pas de prérequis système complets : R, RStudio, Node.js, npm.
- Pas de commande `cd webapp && npm install && npm run dev`.

### `.gitignore`

État : **à corriger absolument**.

Le fichier existe mais il est vide.

À ajouter avant push GitHub :

```gitignore
.Rproj.user/
.RData
.Rhistory
.RDataTmp
.RDataTmp1
Rplots.pdf

webapp/node_modules/
webapp/dist/
webapp/vite-dev.log
webapp/vite-dev.err.log

*.knit.md
*.utf8.md
```

À discuter :

- Garder ou ignorer `outputs/models/*.rds` selon la taille et les consignes.
- Garder ou ignorer `outputs/figures` et `outputs/tables`. Pour un rendu académique, il est souvent utile de les garder.
- Garder `webapp/package-lock.json`, recommandé pour reproductibilité npm.

## 12. Fichiers temporaires à supprimer ou ignorer

Fichiers/dossiers détectés :

| Fichier ou dossier | État | Recommandation |
|---|---:|---|
| `.RData` | Présent | Supprimer localement avant push et ajouter au `.gitignore`. |
| `.Rhistory` | Présent | Supprimer localement avant push et ajouter au `.gitignore`. |
| `.RDataTmp` | Présent | Supprimer localement avant push et ajouter au `.gitignore`. |
| `.RDataTmp1` | Présent | Supprimer localement avant push et ajouter au `.gitignore`. |
| `Rplots.pdf` | Présent | Supprimer localement avant push et ajouter au `.gitignore`. |
| `.Rproj.user/` | Présent | Ne pas versionner. |
| `rapport_projet.knit.md` | Non détecté | Rien à supprimer. |
| `webapp/node_modules/` | Présent | Ne jamais versionner. |
| `webapp/dist/` | Présent | Ignorer sauf stratégie de déploiement statique. |
| `webapp/vite-dev.log` | Présent | Ignorer. |
| `webapp/vite-dev.err.log` | Présent | Ignorer. |

## 13. Slides et soutenance

État du dossier `slides/` :

- `slides/plan_soutenance.md` existe.
- Le fichier est vide.
- Aucun deck PowerPoint/PDF n'a été détecté.

Il faut donc créer un support de soutenance.

### Plan recommandé de 12 slides

1. **Titre**
   - Sujet, membres, module, encadrant si applicable.

2. **Contexte et problématique**
   - Décrochage, réussite, trajectoires étudiantes.
   - Question : comment identifier des profils interprétables ?

3. **Dataset**
   - UCI Machine Learning Repository.
   - 4424 étudiants, 37 variables, 3 statuts.

4. **Préparation**
   - Nettoyage, typage, facteurs, variables binaires.
   - Absence de valeurs manquantes.

5. **Analyse descriptive**
   - Distribution Target.
   - Variables académiques : notes et unités approuvées.

6. **FAMD : méthode**
   - Pourquoi FAMD.
   - Variables actives.
   - Target illustrative.

7. **FAMD : résultats**
   - Dim.1 axe académique.
   - Dim.2 axe socio-administratif.
   - Inertie modérée à interpréter prudemment.

8. **Clustering**
   - k-means sur coordonnées FAMD.
   - Coude, silhouette, choix `k = 6`.

9. **Profils étudiants**
   - Clusters 2 et 3 favorables.
   - Cluster 5 intermédiaire.
   - Clusters 1, 4 et 6 à risque.
   - Cluster 4 critique.

10. **Régression logistique complémentaire**
    - Dropout vs Non_Dropout.
    - Accuracy, precision, recall, F1, specificity.
    - Odds ratios lus comme associations.

11. **Interface React**
    - Dashboard de soutenance.
    - Pages, figures, messages clés.
    - Ne recalcule pas les analyses.

12. **Conclusion, limites, recommandations**
    - Suivi académique précoce.
    - Accompagnement financier.
    - Limites : exploratoire, pas de causalité, validation nécessaire.

## 14. Évaluation globale

| Critère | Note | Commentaire |
|---|---:|---|
| Cohérence avec la matière | 14 / 15 | FAMD + clustering au centre du projet. |
| Richesse statistique | 15 / 17 | Descriptive, FAMD, clustering, logistique complémentaire. |
| Qualité du code R | 14 / 15 | Pipeline clair et outputs reproductibles. |
| Qualité des interprétations | 13 / 15 | Bonne prudence statistique, à relire oralement. |
| Qualité du rapport | 13 / 15 | Complet, mais finitions/encodage à vérifier. |
| Qualité de l'interface | 12 / 13 | Dashboard moderne et pédagogique. |
| Préparation GitHub | 3 / 6 | `.gitignore` vide et fichiers temporaires présents. |
| Préparation soutenance | 1 / 4 | Slides non rédigées. |

Note globale estimée : **82 / 100**.

Interprétation :

- Le fond statistique est solide.
- Le rendu est déjà supérieur à un simple rapport R.
- Les derniers points perdus viennent surtout de la finition : GitHub, slides, nettoyage, README.

## 15. Plan d'action final

### Priorité 1 — indispensable avant rendu

- Remplir `.gitignore`.
- Supprimer localement ou exclure du versionnement : `.RData`, `.Rhistory`, `.RDataTmp`, `.RDataTmp1`, `Rplots.pdf`, `.Rproj.user/`, `webapp/node_modules/`, logs Vite.
- Relancer le pipeline R dans l'ordre une dernière fois si le temps le permet.
- Regénérer ou vérifier `rapport/rapport_projet.html`.
- Relancer `npm run build` dans `webapp/`.
- Vérifier l'affichage des accents dans le rapport HTML, GitHub et l'interface React.
- Compléter `README.md` avec React/Vite, génération du rapport et consignes d'exécution.
- Créer les slides de soutenance ou au minimum remplir `slides/plan_soutenance.md`.
- Supprimer le commentaire YAML "À remplacer par les vrais noms..." dans le rapport si les noms sont définitifs.

### Priorité 2 — amélioration importante

- Ajouter une section README "Résultats principaux" : Dim.1, Dim.2, k = 6, cluster 4, accuracy logistique.
- Ajouter une justification claire de `k = 6` dans les slides.
- Ajouter une slide sur les limites : inertie, silhouette, absence de causalité, validation externe.
- Ajouter au rapport une table synthétique des messages clés par étape.
- Ajouter une phrase sur le fait que le modèle logistique est complémentaire et non central.
- Vérifier que les figures les plus importantes sont bien lisibles dans le rapport HTML.
- Mettre en cohérence les noms exacts des membres dans README, rapport et slides.

### Priorité 3 — bonus pour impressionner

- Ajouter un bouton dans React vers `rapport_projet.html`.
- Ajouter une page React "Soutenance" avec les 5 messages essentiels.
- Créer une vraie présentation PowerPoint/PDF.
- Ajouter un diagramme du pipeline dans les slides.
- Ajouter une visualisation synthétique des profils de clusters.
- Ajouter une validation croisée simple pour la régression logistique, en annexe uniquement.
- Ajouter un `renv.lock` pour reproductibilité R.

## Conclusion de l'audit

Le projet est **statistiquement cohérent, avancé et présentable**. Les analyses principales sont terminées : import, préparation, descriptive, FAMD, clustering, logistique complémentaire, rapport et interface React.

Le risque principal n'est pas statistique, mais organisationnel : fichiers temporaires, `.gitignore` vide, README incomplet pour React, slides non préparées. En corrigeant ces points, le projet sera nettement plus propre pour le rendu final, la soutenance et une publication GitHub.
