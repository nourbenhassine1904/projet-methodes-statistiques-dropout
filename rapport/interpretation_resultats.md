# Interprétation des résultats

Ce document présente une interprétation synthétique des résultats générés dans `outputs/tables`. L’objectif est de proposer une lecture académique, claire et défendable des analyses descriptives, de la FAMD et du clustering, sans ajouter de résultats non présents dans les fichiers CSV.

## 1. Résultats de l’analyse descriptive

Le jeu de données contient trois statuts finaux dans la variable `Target`. D’après `03_a_distribution_target.csv`, la répartition est la suivante :

| Statut | Effectif | Pourcentage |
|---|---:|---:|
| Dropout | 1421 | 32,12 % |
| Enrolled | 794 | 17,95 % |
| Graduate | 2209 | 49,93 % |

La modalité la plus fréquente est donc `Graduate`, qui représente presque la moitié des observations. La modalité `Dropout` concerne environ un tiers des étudiants, ce qui confirme l’intérêt d’étudier les facteurs associés au décrochage.

Les variables académiques présentent des différences nettes selon `Target`. Les étudiants `Graduate` ont en moyenne une note d’admission plus élevée (**128,79**) que les étudiants `Dropout` (**124,96**) et `Enrolled` (**125,53**). L’écart est surtout visible sur les performances semestrielles.

Pour les unités approuvées au 1er semestre, la moyenne est de **2,55** pour `Dropout`, **4,32** pour `Enrolled` et **6,23** pour `Graduate`. Au 2e semestre, la moyenne est de **1,94** pour `Dropout`, **4,06** pour `Enrolled` et **6,18** pour `Graduate`.

Les notes moyennes suivent la même logique. Au 1er semestre, la moyenne est de **7,26** pour `Dropout`, **11,13** pour `Enrolled` et **12,64** pour `Graduate`. Au 2e semestre, elle est de **5,90** pour `Dropout`, **11,12** pour `Enrolled` et **12,70** pour `Graduate`.

Ces résultats descriptifs montrent que les variables académiques des deux semestres sont fortement différenciées selon le statut final. Elles constituent donc un bloc central pour l’analyse multivariée et pour l’interprétation des profils.

## 2. Interprétation de la FAMD

### 2.1 Inertie

La FAMD a été réalisée sur une sélection de variables actives interprétables, avec `target` utilisée comme variable supplémentaire. Certaines variables à très forte cardinalité ont été écartées de la FAMD principale afin de conserver une lecture plus lisible des axes et des contributions. Les valeurs propres issues de `04_famd_valeurs_propres.csv` indiquent que :

| Axe | Inertie expliquée | Inertie cumulée |
|---|---:|---:|
| Dim.1 | 13,55 % | 13,55 % |
| Dim.2 | 6,68 % | 20,23 % |
| Dim.3 | 4,37 % | 24,60 % |
| Dim.4 | 4,26 % | 28,86 % |
| Dim.5 | 3,67 % | 32,53 % |

Les deux premiers axes expliquent ensemble **20,23 %** de l’inertie totale. Cette part reste modérée, ce qui est fréquent dans des données mixtes comportant de nombreuses variables. Les deux premiers axes ne résument donc pas toute l’information, mais ils donnent une lecture synthétique des principales oppositions entre profils.

### 2.2 Axe 1 : dimension académique

La Dimension 1 est principalement construite par les variables académiques. Les plus fortes contributions à l’axe 1 sont :

| Variable | Contribution Dim.1 |
|---|---:|
| `curricular_units_1st_sem_approved` | 15,55 |
| `curricular_units_2nd_sem_approved` | 14,66 |
| `curricular_units_2nd_sem_enrolled` | 12,62 |
| `curricular_units_1st_sem_enrolled` | 12,51 |
| `curricular_units_2nd_sem_grade` | 10,69 |
| `curricular_units_1st_sem_grade` | 10,69 |
| `curricular_units_2nd_sem_evaluations` | 9,83 |
| `curricular_units_1st_sem_evaluations` | 9,24 |

Cet axe peut donc être interprété comme un **axe académique**. Il synthétise surtout le niveau d’engagement et de performance dans le cursus : unités inscrites, unités évaluées, unités approuvées et notes obtenues aux deux semestres.

Cette interprétation est cohérente avec l’analyse descriptive : le statut `Graduate` est associé en moyenne à davantage d’unités approuvées et à de meilleures notes que le statut `Dropout`.

### 2.3 Axe 2 : dimension socio-administrative

La Dimension 2 est davantage associée à des variables de profil et de contexte administratif. Les principales contributions à l’axe 2 sont :

| Variable | Contribution Dim.2 |
|---|---:|
| `age_at_enrollment` | 18,52 |
| `previous_qualification` | 11,31 |
| `displaced` | 7,85 |
| `tuition_fees_up_to_date` | 6,38 |
| `curricular_units_1st_sem_evaluations` | 6,24 |
| `daytime_evening_attendance` | 5,93 |
| `scholarship_holder` | 5,30 |
| `curricular_units_2nd_sem_without_evaluations` | 4,87 |
| `curricular_units_1st_sem_without_evaluations` | 4,77 |
| `debtor` | 3,42 |

La Dimension 2 peut être interprétée comme un **axe socio-administratif**. Elle est fortement liée à l’âge à l’inscription, à la qualification précédente, au fait d’être déplacé, à la situation des frais de scolarité, au régime jour/soir et au statut de boursier.

Certaines variables académiques contribuent également à cet axe, notamment les évaluations et les unités sans évaluation. Cela indique que la Dimension 2 ne doit pas être lue comme strictement sociale ou administrative : elle combine des éléments de contexte étudiant avec des éléments liés à la participation au parcours.

### 2.4 Lien avec Target

Dans la FAMD, `target` est utilisée comme variable supplémentaire. Elle ne sert donc pas à construire les axes, mais elle permet de lire a posteriori comment les statuts `Dropout`, `Enrolled` et `Graduate` se positionnent par rapport aux dimensions factorielles.

Le lien principal avec `Target` apparaît à travers l’axe académique. Les résultats descriptifs montrent que le statut `Graduate` est associé à des moyennes plus élevées en unités approuvées et en notes semestrielles, tandis que le statut `Dropout` est associé aux valeurs moyennes les plus faibles sur ces variables. Comme ces variables contribuent fortement à la Dimension 1, il est défendable d’interpréter cet axe comme central pour distinguer les profils de réussite et de décrochage.

La Dimension 2 enrichit cette lecture en ajoutant des informations socio-administratives. Elle peut aider à qualifier les profils au-delà des seules performances académiques.

## 3. Choix du nombre de clusters

Le clustering k-means a été réalisé sur les coordonnées issues de la FAMD. Le fichier `05_kmeans_silhouette.csv` compare les silhouettes moyennes pour plusieurs valeurs de `k` :

| k | Silhouette moyenne |
|---:|---:|
| 2 | 0,2567 |
| 3 | 0,2481 |
| 4 | 0,2449 |
| 5 | 0,2585 |
| 6 | 0,2611 |

Le fichier `05_k_recommande.csv` indique que le nombre de clusters recommandé techniquement est **k = 6**, selon le critère de la **silhouette moyenne maximale**. La silhouette la plus élevée est obtenue pour `k = 6`, avec une valeur de **0,2611**.

Cette recommandation doit cependant être interprétée avec prudence. La silhouette maximale de **0,2611** reste modérée ; le choix de **k = 6** est donc retenu non seulement pour ce critère technique, mais aussi pour l’interprétabilité des profils obtenus. Le choix final doit aussi tenir compte de la lisibilité des profils, de leur taille et de leur intérêt pour l’analyse du décrochage.

## 4. Description des 6 profils

### 4.1 Cluster 1 : Profil fragile à risque académique

Le cluster 1 regroupe **74 étudiants**. Il contient **64,86 %** de `Dropout`, **17,57 %** de `Enrolled` et **17,57 %** de `Graduate`.

Ses indicateurs académiques sont faibles : **3,42** unités approuvées au 1er semestre, **2,97** au 2e semestre, une note moyenne de **7,17** au 1er semestre et **5,22** au 2e semestre. La note d’admission moyenne est de **125,74**.

Ce cluster correspond à un profil fragile, avec un niveau de risque **élevé**.

### 4.2 Cluster 2 : Profil performant à forte réussite

Le cluster 2 regroupe **619 étudiants**. Il contient **18,26 %** de `Dropout`, **17,12 %** de `Enrolled` et **64,62 %** de `Graduate`.

Il présente une note d’admission moyenne de **145,75**, la plus élevée parmi les profils décrits. Les performances académiques sont également favorables : **5,47** unités approuvées au 1er semestre, **5,25** au 2e semestre, une note moyenne de **12,91** au 1er semestre et **12,55** au 2e semestre.

Ce cluster correspond à un profil performant, avec un niveau de risque **faible**.

### 4.3 Cluster 3 : Profil stable majoritaire

Le cluster 3 est le plus important, avec **2158 étudiants**. Il contient **14,97 %** de `Dropout`, **20,67 %** de `Enrolled` et **64,37 %** de `Graduate`.

Ses indicateurs académiques sont favorables : **5,44** unités approuvées au 1er semestre, **5,35** au 2e semestre, une note moyenne de **12,65** au 1er semestre et **12,51** au 2e semestre. La note d’admission moyenne est de **122,69**.

Ce cluster représente un profil stable et majoritaire, avec un niveau de risque **faible**.

### 4.4 Cluster 4 : Profil critique de décrochage

Le cluster 4 regroupe **619 étudiants**. Il présente la proportion la plus élevée de `Dropout`, avec **79,48 %**. Les proportions de `Enrolled` et `Graduate` sont respectivement **9,21 %** et **11,31 %**.

Les performances académiques moyennes sont très faibles : **0,23** unité approuvée au 1er semestre, **0,08** au 2e semestre, une note moyenne de **1,38** au 1er semestre et **0,62** au 2e semestre. La note d’admission moyenne est de **125,88**.

Ce cluster correspond à un profil critique de décrochage, avec un niveau de risque **très élevé**.

### 4.5 Cluster 5 : Profil intermédiaire en transition

Le cluster 5 regroupe **585 étudiants**. Il contient **36,58 %** de `Dropout`, **16,24 %** de `Enrolled` et **47,18 %** de `Graduate`.

Ses performances sont intermédiaires : **6,43** unités approuvées au 1er semestre, **5,69** au 2e semestre, une note moyenne de **11,54** au 1er semestre et **11,17** au 2e semestre. La note d’admission moyenne est de **124,66**.

Ce profil combine une proportion importante de diplômés et une proportion non négligeable de décrochage. Il peut être qualifié de profil intermédiaire, avec un niveau de risque **modéré**.

### 4.6 Cluster 6 : Profil à risque élevé

Le cluster 6 regroupe **369 étudiants**. Il contient **62,60 %** de `Dropout`, **20,87 %** de `Enrolled` et **16,53 %** de `Graduate`.

Ses indicateurs académiques sont inférieurs à ceux des profils favorables : **4,19** unités approuvées au 1er semestre, **3,38** au 2e semestre, une note moyenne de **9,90** au 1er semestre et **8,63** au 2e semestre. La note d’admission moyenne est de **126,33**.

Ce cluster correspond à un profil à risque élevé, moins extrême que le cluster 4 mais clairement associé au décrochage.

## 5. Analyse combinée FAMD + clustering + Target

L’analyse combinée montre que les profils d’étudiants sont fortement associés aux performances académiques. La Dimension 1 de la FAMD, dominée par les unités approuvées, les unités inscrites, les évaluations et les notes des deux semestres, est cohérente avec le fait que certains clusters soient davantage associés à la réussite ou au décrochage.

Les clusters 2 et 3 sont les profils les plus favorables à la réussite. Ils présentent respectivement **64,62 %** et **64,37 %** de `Graduate`, avec des notes semestrielles moyennes supérieures à 12. Ces résultats sont cohérents avec l’interprétation de la Dimension 1 comme axe académique.

À l’inverse, les clusters 4, 1 et 6 sont les profils les plus associés au risque de décrochage. Le cluster 4 est le plus critique, avec **79,48 %** de `Dropout` et des moyennes académiques très faibles. Les clusters 1 et 6 présentent également des proportions élevées de `Dropout`, respectivement **64,86 %** et **62,60 %**.

Le cluster 5 occupe une position intermédiaire. Il présente **47,18 %** de `Graduate`, mais aussi **36,58 %** de `Dropout`. Il ne relève donc ni d’un profil clairement favorable, ni d’un profil aussi critique que les clusters 4, 1 et 6.

La Dimension 2 apporte une lecture complémentaire. Elle met en évidence des variables socio-administratives telles que l’âge à l’inscription, la qualification précédente, le déplacement, les frais de scolarité, le régime jour/soir et le statut de boursier. Ces éléments peuvent aider à contextualiser les profils, même si la séparation principale entre réussite et décrochage reste très liée aux variables académiques.

## 6. Recommandations décisionnelles

Les recommandations suivantes doivent être comprises comme des pistes opérationnelles fondées sur les profils observés, et non comme des preuves causales.

1. Prioriser le suivi des clusters **4**, **1** et **6**, car ils présentent les proportions les plus élevées de `Dropout`.

2. Mettre en place un repérage précoce fondé sur les variables académiques des deux semestres : unités approuvées, unités évaluées et notes moyennes.

3. Accorder une attention particulière au cluster **4**, qui combine une proportion de `Dropout` de **79,48 %** avec des performances académiques très faibles.

4. Accompagner le cluster **5** comme profil intermédiaire : sa proportion de `Graduate` reste importante, mais son taux de `Dropout` de **36,58 %** justifie un suivi.

5. Utiliser les variables de la Dimension 2 pour affiner l’accompagnement : âge à l’inscription, qualification précédente, déplacement, situation des frais de scolarité, régime jour/soir et statut de boursier.

6. Étudier les clusters **2** et **3** comme profils de référence favorables à la réussite, afin d’identifier les caractéristiques communes aux trajectoires stables.

## 7. Limites de l’analyse

Cette analyse est descriptive et exploratoire. Elle permet d’identifier des structures et des profils, mais elle ne démontre pas de relations causales.

La première limite concerne l’inertie expliquée par la FAMD. Les deux premiers axes expliquent **20,23 %** de l’inertie totale. Ils sont utiles pour l’interprétation, mais ne résument pas toute l’information contenue dans les données.

La deuxième limite concerne le choix des variables actives. Certaines variables qualitatives très détaillées ont été limitées ou écartées afin de conserver une FAMD lisible. Ce choix améliore l’interprétation, mais peut réduire une partie de l’information disponible.

La troisième limite concerne le choix du nombre de clusters. Le critère de silhouette recommande **k = 6**, mais les valeurs de silhouette restent proches entre plusieurs valeurs de `k`, notamment `k = 5` avec **0,2585** et `k = 6` avec **0,2611**. Le choix de six clusters doit donc être justifié aussi par la lisibilité et l’intérêt des profils.

La quatrième limite concerne l’utilisation de `Target`. Dans la FAMD, `target` est une variable supplémentaire : elle ne construit pas les axes. Dans le clustering, elle sert à interpréter les groupes après leur formation. Les clusters ne doivent donc pas être confondus avec un modèle supervisé de prédiction.

Enfin, les recommandations proposées doivent être validées par une analyse complémentaire, par exemple une modélisation supervisée ou une validation sur d’autres cohortes.
