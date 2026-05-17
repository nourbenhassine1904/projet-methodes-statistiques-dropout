# Script oral de soutenance - 15 minutes

## Intention generale

Le discours doit rester simple : on part d'un dataset mixte, on applique une FAMD adaptee, on segmente les etudiants sur les coordonnees FAMD, puis on complete par une regression logistique. Le message central est que les performances academiques sont tres informatives pour distinguer les parcours, avec une lecture exploratoire prudente.

## Slide 1 - Titre, equipe, problematique

Bonjour, nous presentons notre projet sur le dataset **Predict Students' Dropout and Academic Success**.  
La question principale est la suivante : comment analyser les profils d'etudiants pour mieux comprendre les situations associees au decrochage, a l'inscription continue et a la reussite ?

Notre objectif n'est pas de donner une explication causale, mais de construire une lecture statistique claire : structure des donnees, profils d'etudiants et modelisation complementaire.

## Slide 2 - Contexte et objectif du projet

Le projet combine trois niveaux d'analyse.

D'abord, une preparation des donnees pour distinguer les variables quantitatives et qualitatives. Ensuite, une FAMD pour reduire l'information multivariee. Enfin, un clustering pour obtenir des profils d'etudiants, complete par une regression logistique pour analyser Dropout contre Non_Dropout.

Le fil conducteur est donc : comprendre, segmenter, puis comparer.

## Slide 3 - Dataset et variable Target

Le dataset contient **4424 etudiants** et **37 variables initiales**. La variable cible `target` possede trois modalites : **Dropout**, **Enrolled** et **Graduate**.

Dans notre strategie, `target` n'est jamais active dans la FAMD ni dans le clustering. Elle sert uniquement apres coup, pour caracteriser les groupes obtenus.

C'est important : les clusters ne sont pas construits a partir du statut final, ce qui evite une lecture circulaire.

## Slide 4 - Preparation des donnees et typologie

Une difficulte du dataset est que certaines variables sont codees par des nombres entiers, mais sont statistiquement qualitatives. Par exemple, un code de cours ou un genre n'est pas une quantite mesurable, meme si le fichier le stocke sous forme numerique.

Nous avons donc distingue le type informatique du type statistique. Les variables qualitatives codees numeriquement ont ete converties en facteurs lorsque c'etait necessaire.

Les zeros academiques ont aussi ete verifies. Ils ne sont pas automatiquement des erreurs : ils peuvent indiquer une absence de validation ou une performance tres faible, donc une information academique forte.

## Slide 5 - Pourquoi FAMD et pourquoi target illustrative

Nous utilisons la FAMD parce que les donnees sont mixtes : certaines variables sont quantitatives, d'autres qualitatives. Une ACP seule traiterait mal les variables qualitatives, tandis qu'une ACM seule transformerait toutes les variables en categories et perdrait une partie de l'information quantitative.

La FAMD permet de travailler dans un cadre commun. La FAMD principale reduite utilise **11 variables actives** : des variables administratives, individuelles et academiques du premier semestre.

`target` reste illustrative. Le semestre 2 et les variables economiques sont supplementaires, car ils servent a enrichir l'interpretation sans piloter la construction principale.

## Slide 6 - Resultats FAMD

La FAMD produit des axes factoriels. Dans notre interpretation, **Dim.1** est surtout liee au niveau academique, notamment les evaluations, les unites validees et les notes du premier semestre.

**Dim.2** apporte une information complementaire, davantage liee a des dimensions socio-administratives ou individuelles selon les contributions finales.

La projection en deux dimensions ne resume pas toute l'information. Il est donc normal de voir un chevauchement entre les modalites de `target`. Ce chevauchement n'annule pas l'interet de la FAMD : il rappelle simplement que les trajectoires etudiantes sont multifactorielles.

## Slide 7 - Clustering sur coordonnees FAMD

Le clustering n'est pas applique directement sur les donnees brutes. Il est applique sur les coordonnees individuelles issues de la FAMD.

Ce choix est important car les coordonnees FAMD forment un espace numerique homogene, plus adapte a des variables mixtes que les colonnes d'origine.

Le clustering k-means cherche ensuite a regrouper les etudiants proches dans cet espace factoriel. `target` n'intervient pas dans cette construction : elle sert uniquement a lire les clusters apres leur formation.

## Slide 8 - Validation du clustering

Apres recalcul sur la FAMD principale reduite, la solution principale retenue est **2 axes FAMD** et **k = 2**.

La silhouette moyenne est d'environ **0.508**, ce qui indique une separation lisible, sans presenter les groupes comme parfaitement separes. La solution est aussi stable dans les relances du k-means.

Ce choix correspond a un compromis statistique et interpretatif : `k = 2` donne une typologie claire, robuste et defendable pour une soutenance.

## Slide 9 - Profils obtenus

Le **cluster 1** regroupe environ **929 etudiants**. Il correspond au profil a risque eleve : environ **81.5 %** de Dropout et seulement environ **8.9 %** de Graduate. Les indicateurs academiques y sont plus faibles.

Le **cluster 2** regroupe environ **3495 etudiants**. Il correspond au profil majoritaire favorable : environ **60.8 %** de Graduate et environ **19.0 %** de Dropout.

Cette segmentation met en evidence deux profils contrastes, mais elle reste exploratoire. Elle aide a decrire les parcours, pas a etablir une relation causale.

## Slide 10 - Regression logistique precoce vs complete

La regression logistique est une analyse complementaire. Elle transforme la cible en **Dropout** contre **Non_Dropout**.

Le modele precoce utilise les variables d'entree et le semestre 1. Il obtient environ **0.849** d'accuracy, **0.716** de recall Dropout, **0.753** de F1 Dropout et **0.884** d'AUC.

Le modele complet ajoute le semestre 2. Il monte a environ **0.865** d'accuracy, **0.747** de recall Dropout, **0.780** de F1 Dropout et **0.909** d'AUC.

Le modele complet est plus performant, mais il est plus tardif. Le modele precoce est donc plus utile dans une logique d'alerte.

## Slide 11 - Recommandations operationnelles

Les resultats suggerent de suivre tot les indicateurs academiques du premier semestre, en particulier les evaluations, les unites validees et les notes.

Le cluster 1 peut servir de signal de priorisation pour un accompagnement plus attentif. Cela peut inclure un suivi pedagogique, administratif ou financier selon les informations disponibles.

Ces recommandations doivent etre lues comme des pistes d'aide a la decision. Elles necessitent une validation sur d'autres cohortes avant une utilisation operationnelle forte.

## Slide 12 - Limites methodologiques

Il y a plusieurs limites. La FAMD simplifie l'information, donc les axes ne capturent pas toute la complexite du dataset.

Le clustering est non supervise : il identifie des groupes selon une structure statistique, mais il ne donne pas une explication causale.

La regression logistique mesure des associations avec le decrochage. Elle depend des variables disponibles, du seuil de prediction et du decoupage train/test.

## Slide 13 - Conclusion

Le projet combine analyse descriptive, FAMD, clustering et regression logistique.

La FAMD montre une structure multivariee fortement liee aux performances academiques. Le clustering sur coordonnees FAMD identifie deux profils interpretables : un profil a risque eleve et un profil majoritaire favorable.

La regression logistique confirme que les variables academiques sont tres informatives, avec un modele complet plus performant mais moins precoce. L'ensemble fournit une lecture claire et prudente des parcours etudiants.

## Slide 14 - Questions possibles

Pour les questions, l'idee est de revenir toujours aux choix methodologiques : donnees mixtes, target illustrative, semestre 2 supplementaire, clustering sur FAMD et lecture exploratoire.

La phrase a garder en tete est : "Nous avons separe la construction statistique des profils et leur interpretation avec la variable target."

# Questions et reponses probables

## Pourquoi FAMD et pas ACP ?

Parce que le dataset contient des variables quantitatives et qualitatives. L'ACP est adaptee aux variables quantitatives, mais elle ne traite pas correctement les modalites qualitatives codees par des entiers. La FAMD gere les deux types dans un cadre commun.

## Pourquoi target est illustrative ?

Parce que `target` correspond au statut final de l'etudiant. Si elle etait active, elle orienterait directement les axes ou les clusters. Ici, elle sert uniquement a interpreter les groupes obtenus apres construction.

## Pourquoi le semestre 2 est supplementaire ?

Le semestre 2 est plus tardif dans le parcours. Pour une analyse principale plus defendable et plus precoce, il est utilise comme information supplementaire, sans influencer la FAMD principale reduite.

## Pourquoi clustering sur coordonnees FAMD ?

Les coordonnees FAMD donnent un espace numerique homogene et synthetique. C'est plus coherent que de calculer des distances directement sur des variables brutes de natures et d'echelles differentes.

## Pourquoi k = 2 ?

Apres recalcul sur la FAMD principale reduite, `k = 2` sur 2 axes donne une silhouette moyenne proche de `0.508`, une solution stable et deux profils clairement interpretables. C'est la solution principale retenue.

## Que signifie une silhouette de 0.508 ?

La silhouette mesure si les individus sont plus proches de leur propre cluster que des autres clusters. Une valeur autour de `0.508` indique une separation correcte et lisible, sans signifier que les groupes sont totalement separes.

## Les resultats sont-ils causaux ?

Non. Les resultats mettent en evidence des associations et des structures statistiques. Ils doivent etre interpretes avec prudence et ne remplacent pas une etude causale dediee.

## Difference entre modele precoce et modele complet ?

Le modele precoce utilise les variables d'entree et le premier semestre : il est plus utile pour detecter plus tot des situations a surveiller. Le modele complet ajoute le semestre 2 : il est plus performant, mais disponible plus tard.

## Pourquoi les points se chevauchent dans la FAMD ?

La projection en deux dimensions ne resume qu'une partie de l'information totale. Le chevauchement est normal, surtout pour des trajectoires etudiantes qui dependent de plusieurs dimensions.

## Le cluster 1 est-il automatiquement une liste d'etudiants a sanctionner ?

Non. Le cluster 1 indique un profil statistiquement plus associe au decrochage. Il doit etre utilise comme signal de vigilance pour proposer un accompagnement, pas comme une decision automatique.
