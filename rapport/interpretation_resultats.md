# Interprétation des résultats

Ce document synthétise les résultats finaux disponibles dans `outputs/tables`. Il accompagne le rapport principal en donnant une lecture claire de la FAMD principale réduite, du clustering principal et de la régression logistique complémentaire.

## 1. Analyse descriptive

Le jeu de données contient trois statuts dans `target` : `Dropout`, `Enrolled` et `Graduate`. La distribution globale est la suivante :

| Statut | Effectif | Pourcentage |
|---|---:|---:|
| Dropout | 1421 | 32,12 % |
| Enrolled | 794 | 17,95 % |
| Graduate | 2209 | 49,93 % |

Les variables académiques différencient nettement ces statuts. Les étudiants `Graduate` présentent en moyenne davantage d'unités approuvées et de meilleures notes que les étudiants `Dropout`. Cette différence justifie l'importance des indicateurs académiques dans les analyses multivariées.

## 2. FAMD principale réduite

La FAMD principale est réalisée sur **11 variables actives**. Elle est préférable à une ACP, car le dataset combine des variables quantitatives et des variables qualitatives codées. La FAMD permet de construire un espace factoriel commun sans traiter les modalités qualitatives comme de simples valeurs numériques.

Variables actives quantitatives :

| Variable |
|---|
| `previous_qualification_grade` |
| `admission_grade` |
| `age_at_enrollment` |
| `curricular_units_1st_sem_evaluations` |
| `curricular_units_1st_sem_approved` |
| `curricular_units_1st_sem_grade` |

Variables actives qualitatives :

| Variable |
|---|
| `daytime_evening_attendance` |
| `debtor` |
| `tuition_fees_up_to_date` |
| `gender` |
| `scholarship_holder` |

`target` est uniquement illustrative. Les variables du semestre 2 et les variables économiques sont supplémentaires : elles aident à interpréter les résultats, mais ne construisent pas les axes.

Les valeurs propres de `04_principale_valeurs_propres.csv` indiquent que la Dimension 1 explique **21,81 %** de l'inertie, la Dimension 2 **15,95 %**, et les deux premières dimensions **37,76 %** au total. Les cinq premiers axes expliquent **71,98 %** de l'inertie cumulée.

La Dimension 1 est principalement académique. Elle est portée par `curricular_units_1st_sem_grade`, `curricular_units_1st_sem_approved`, `tuition_fees_up_to_date` et `curricular_units_1st_sem_evaluations`. La Dimension 2 complète cette lecture avec les évaluations du premier semestre, l'âge à l'inscription, la qualification précédente, la note d'admission et le régime jour/soir.

## 3. Clustering principal

Le clustering principal est réalisé sur les coordonnées de la FAMD principale réduite. Cette stratégie évite de calculer les distances directement sur les variables brutes et utilise un espace où les variables quantitatives et qualitatives ont déjà été équilibrées.

La solution principale retenue est :

| Paramètre | Valeur |
|---|---:|
| Nombre d'axes FAMD | 2 |
| Nombre de clusters | 2 |
| Silhouette moyenne | 0,508 |
| Taille du cluster 1 | 929 |
| Taille du cluster 2 | 3495 |
| Stabilité | stable |
| ARI moyen | 1,00 |

Cette solution est robuste et lisible. Elle ne doit pas être présentée comme une vérité définitive : elle constitue la solution principale du pipeline final, en raison de sa silhouette, de la taille des groupes, de sa stabilité et de son interprétabilité. Les solutions `k = 3` ou `k = 6` peuvent être mentionnées comme comparaisons exploratoires, mais elles ne sont pas la solution principale.

## 4. Interprétation des deux clusters

### Cluster 1 : profil à risque élevé

Le cluster 1 regroupe **929 étudiants**. Sa composition selon `target` est la suivante :

| Statut | Pourcentage |
|---|---:|
| Dropout | 81,5 % |
| Enrolled | 9,6 % |
| Graduate | 8,9 % |

Ce groupe présente des indicateurs académiques fragiles dès le premier semestre : peu d'unités approuvées et des notes faibles. Il présente aussi une proportion plus élevée de frais de scolarité non à jour et de débiteurs. Il correspond au profil prioritaire pour une lecture du risque.

### Cluster 2 : profil majoritaire favorable

Le cluster 2 regroupe **3495 étudiants**. Sa composition selon `target` est la suivante :

| Statut | Pourcentage |
|---|---:|
| Dropout | 19,0 % |
| Enrolled | 20,2 % |
| Graduate | 60,8 % |

Ce groupe présente des indicateurs académiques nettement plus favorables : davantage d'unités approuvées, de meilleures notes et une situation administrative plus stable en moyenne. Il constitue le profil majoritaire favorable.

## 5. Tests statistiques

Les tests de différences entre clusters montrent des écarts marqués. Pour les variables quantitatives, les tests de Kruskal-Wallis indiquent des distributions différentes selon les clusters, notamment pour :

| Variable | p-value |
|---|---:|
| `curricular_units_1st_sem_approved` | p < 0.001 |
| `curricular_units_1st_sem_grade` | p < 0.001 |
| `curricular_units_2nd_sem_approved` | p < 0.001 |
| `curricular_units_2nd_sem_grade` | p < 0.001 |
| `age_at_enrollment` | p < 0.001 |

Pour les variables qualitatives, les tests du khi-deux indiquent aussi des répartitions différentes, notamment pour `tuition_fees_up_to_date`, `debtor`, `gender` et `scholarship_holder`. L'association entre clusters et `target` est forte après construction des groupes, avec un V de Cramer de **0,549**.

Ces tests décrivent des différences statistiques entre groupes. Ils ne doivent pas être lus comme des mécanismes explicatifs directs.

## 6. Régression logistique complémentaire

La régression logistique est une analyse complémentaire. Elle ne remplace pas le cœur du projet, qui reste la FAMD et le clustering.

Deux modèles sont comparés :

| Modèle | Accuracy | Recall Dropout | AUC |
|---|---:|---:|---:|
| Précoce | 0,849 | 0,716 | 0,884 |
| Complet | 0,865 | 0,747 | 0,909 |

Le modèle précoce utilise les variables d'entrée et les informations du premier semestre. Il est donc plus utile pour un repérage anticipé. Le modèle complet ajoute les variables du deuxième semestre : il est plus performant, mais disponible plus tard dans le parcours.

Les coefficients et odds ratios doivent être interprétés comme des associations conditionnelles avec la probabilité de `Dropout`. Ils ne donnent pas une lecture explicative directe.

## 7. Limites

L'analyse reste exploratoire. Elle identifie des profils et des associations, mais elle ne valide pas de mécanisme explicatif.

La FAMD principale est volontairement réduite à 11 variables actives. Cette sélection améliore la lisibilité, mais laisse les variables du semestre 2 et les variables économiques en rôle supplémentaire.

La projection factorielle 1-2 est partielle : elle facilite la visualisation, mais ne résume pas toute l'information du dataset.

Le clustering à deux groupes est robuste et stable, mais il est moins détaillé qu'une segmentation plus fine. Les solutions `k = 3` et `k = 6` restent des lectures secondaires possibles.

Aucune validation externe sur une autre cohorte n'est disponible. Enfin, le modèle logistique complet est plus performant que le modèle précoce, mais il utilise des informations plus tardives.
