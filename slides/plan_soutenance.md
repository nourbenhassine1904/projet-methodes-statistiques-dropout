# Plan de soutenance - Projet Dropout Academic Success

## Objectif du support

Soutenance de 15 minutes sur une analyse statistique du dataset **Predict Students' Dropout and Academic Success**.

Fil conducteur :

1. Comprendre le dataset et la variable `target`.
2. Justifier la FAMD principale reduite sur donnees mixtes.
3. Segmenter les etudiants par clustering sur coordonnees FAMD.
4. Completer l'analyse par deux regressions logistiques.
5. Proposer une lecture operationnelle prudente.

Methodologie finale a respecter :

- FAMD principale reduite avec 11 variables actives.
- `target` illustrative uniquement.
- Semestre 2 et variables economiques supplementaires.
- Clustering principal sur coordonnees FAMD.
- Solution principale : `nb_axes = 2`, `k = 2`.
- Silhouette moyenne environ `0.508`.
- Cluster 1 : profil a risque eleve, environ `81.5 %` Dropout.
- Cluster 2 : profil majoritaire favorable, environ `60.8 %` Graduate.
- Regression logistique complementaire : modele precoce vs modele complet.

## Deroule conseille sur 15 minutes

| Slide | Theme | Duree cible | Objectif oral |
|---:|---|---:|---|
| 1 | Titre, equipe, problematique | 0:45 | Installer le sujet et la question centrale. |
| 2 | Contexte et objectif | 1:00 | Expliquer le besoin d'analyse statistique. |
| 3 | Dataset et Target | 1:00 | Presenter les 4424 etudiants et les 3 modalites. |
| 4 | Preparation et typologie | 1:15 | Montrer que les types statistiques ont ete controles. |
| 5 | Pourquoi FAMD | 1:15 | Justifier FAMD, target illustrative et exclusions. |
| 6 | Resultats FAMD | 1:30 | Interpreter Dim.1, Dim.2 et le chevauchement. |
| 7 | Clustering sur FAMD | 1:00 | Relier reduction de dimension et segmentation. |
| 8 | Validation clustering | 1:15 | Defendre `k = 2`, silhouette et stabilite. |
| 9 | Profils obtenus | 1:30 | Comparer clairement les deux clusters. |
| 10 | Regression logistique | 1:30 | Comparer modele precoce et modele complet. |
| 11 | Recommandations | 1:00 | Traduire les resultats en pistes d'action. |
| 12 | Limites | 0:45 | Montrer la prudence methodologique. |
| 13 | Conclusion | 0:45 | Fermer avec les messages cles. |
| 14 | Questions | apres expose | Anticiper les questions de soutenance. |

## Repartition de parole pour 4 membres

| Membre | Slides | Duree | Perimetre |
|---|---:|---:|---|
| Membre 1 | 1 a 4 | environ 4 min | Introduction, dataset, target, preparation, typologie des variables. |
| Membre 2 | 5 a 6 | environ 3 min | Justification de la FAMD, variables actives/supplementaires, lecture des axes. |
| Membre 3 | 7 a 9 | environ 4 min | Clustering sur coordonnees FAMD, validation, interpretation des deux profils. |
| Membre 4 | 10 a 13 | environ 4 min | Regression logistique, recommandations, limites et conclusion. |

Conseil de transition :

- Membre 1 vers 2 : "Comme les variables sont mixtes, il faut maintenant une methode factorielle adaptee."
- Membre 2 vers 3 : "Les coordonnees FAMD donnent ensuite l'espace utilise pour segmenter les etudiants."
- Membre 3 vers 4 : "Apres cette lecture exploratoire, on complete par une modelisation supervisee du decrochage."

## Figures recommandees

| Theme | Figure |
|---|---|
| Target | `outputs/figures/03_a_distribution_target.png` |
| FAMD - inertie | `outputs/figures/04_principale_screeplot.png` |
| FAMD - variables | `outputs/figures/04_principale_variables_top.png` |
| FAMD - individus | `outputs/figures/04_principale_individus_target.png` |
| FAMD - barycentres | `outputs/figures/04_principale_barycentres_target.png` |
| Clustering - projection | `outputs/figures/05_principale_clusters_famd.png` |
| Clustering - target | `outputs/figures/05_principale_composition_clusters_target.png` |
| Clustering - coude | `outputs/figures/05_principale_methode_coude.png` |
| Clustering - silhouette | `outputs/figures/05_principale_silhouette_moyenne.png` |
| Clustering - profils | `outputs/figures/05_principale_profils_academiques_clusters.png` |
| Logit precoce | `outputs/figures/06_roc_logit_precoce.png` |
| Logit complet | `outputs/figures/06_roc_logit_complet.png` |

## Messages cles a faire passer

- La FAMD est adaptee car le dataset contient des variables quantitatives et qualitatives.
- `target` sert a interpreter les resultats apres coup, pas a construire les axes ou les clusters.
- Le clustering principal est realise sur les coordonnees FAMD, pas sur les donnees brutes.
- La solution retenue est `k = 2` sur `2` axes FAMD, avec silhouette moyenne proche de `0.508`.
- Les deux groupes distinguent un profil a risque eleve et un profil majoritaire favorable.
- La regression logistique est complementaire : elle mesure des associations avec Dropout vs Non_Dropout.
- L'ensemble reste une interpretation statistique exploratoire a lire avec prudence.

## Points de vigilance

- Ne pas presenter `k = 3` ou `k = 6` comme solution principale.
- Ne pas dire que les resultats demontrent une relation causale.
- Ne pas dire que la FAMD ou le clustering remplacent la regression logistique.
- Ne pas dire que le modele complet est "meilleur" sans rappeler qu'il utilise des informations plus tardives.
- Rester clair sur la difference entre variables actives, supplementaires et illustratives.

## Preparation technique

Avant la soutenance :

1. Verifier que les figures sont visibles dans le support final.
2. Garder une version PDF ou HTML hors ligne.
3. Preparer une phrase courte pour chaque question probable.
4. Chronometrer une repetition complete en 15 minutes.
5. Eviter de lire les slides : utiliser les points comme appui.
