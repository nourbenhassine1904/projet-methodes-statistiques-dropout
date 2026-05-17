---
marp: true
title: "Soutenance - Analyse multivariee des profils d'etudiants"
paginate: true
theme: default
---

# Analyse multivariee des profils d'etudiants

**Dataset : Predict Students' Dropout and Academic Success**

**Problematique**  
Comment identifier des profils d'etudiants a partir de variables administratives, socio-economiques et academiques, et comment ces profils se differencient-ils selon `Dropout`, `Enrolled` ou `Graduate` ?

**Equipe**  
Nour BEN HASSINE, Nouha BEN KHELIL, Hadir FELLI, Nouha BRIKI

**Figure recommandee** : `outputs/figures/03_a_distribution_target.png`

**Message oral** : "Notre objectif est de construire une typologie interpretable, pas seulement de predire un statut."

**Justification statistique** : analyse exploratoire multivariee sur donnees mixtes.

---

# 2. Contexte et objectif du projet

- Dataset UCI sur la reussite et le decrochage dans l'enseignement superieur.
- Donnees mixtes : variables quantitatives, qualitatives et binaires.
- Objectif principal : comprendre la structure des profils etudiants.
- Methodes : analyse descriptive, FAMD, clustering, regression logistique complementaire.

**Pipeline**  
Dataset -> Preparation -> FAMD principale reduite -> Clustering k-means -> Regression logistique -> Recommandations

**Message oral** : "Nous avons separe l'analyse exploratoire non supervisee de la modelisation complementaire supervisee."

**Justification statistique** : la FAMD traite les variables mixtes avant le clustering.

---

# 3. Dataset et variable Target

- 4 424 etudiants.
- Variable cible `target` a 3 modalites : `Dropout`, `Enrolled`, `Graduate`.
- `target` sert a caracteriser les profils apres calcul.
- Elle n'est jamais active dans la FAMD ni dans le clustering.

**Distribution**

| Target | Effectif | Pourcentage |
|---|---:|---:|
| Dropout | 1 421 | 32,12 % |
| Enrolled | 794 | 17,95 % |
| Graduate | 2 209 | 49,93 % |

**Figure recommandee** : `outputs/figures/03_a_distribution_target.png`

**Message oral** : "Target est notre repere d'interpretation, mais pas une variable qui fabrique les axes ou les clusters."

---

# 4. Preparation et typologie des variables

- Les variables qualitatives codees par des entiers sont converties en facteurs.
- Les variables creees `dropout_binary` et `success_binary` sont exclues des analyses non supervisees.
- Les zeros academiques sont verifies et conserves comme informations possibles.
- Les valeurs atypiques ne sont pas supprimees automatiquement.

**Tables recommandees**

- `outputs/tables/04_principale_variables_actives.csv`
- `outputs/tables/04_principale_variables_supplementaires.csv`
- `outputs/tables/08_typologie_variables.csv`
- `outputs/tables/08_audit_famd_principale_reduite.csv`

**Message oral** : "Le type informatique ne suffit pas : une variable integer peut etre une categorie."

**Justification statistique** : preparation adaptee au type statistique reel des variables.

---

# 5. Pourquoi la FAMD ?

- ACP seule : adaptee surtout aux variables quantitatives.
- ACM seule : adaptee surtout aux variables qualitatives.
- FAMD : combine les deux dans un meme espace factoriel.
- FAMD principale reduite : 11 variables actives defendables.
- `target` reste illustrative uniquement.

**Variables actives**

- Quantitatives : notes, age, evaluations, unites validees du semestre 1.
- Qualitatives : regime jour/soir, debiteur, frais a jour, genre, boursier.

**Message oral** : "La FAMD est coherente avec la nature mixte du dataset et avec le cours."

**Justification statistique** : evite de traiter des codes qualitatifs comme des mesures continues.

---

# 6. Resultats FAMD principale reduite

- Dim.1 : principalement liee au niveau academique.
- Dim.2 : lecture complementaire du parcours et du contexte socio-administratif.
- Inertie Dim.1 : 21,81 %.
- Inertie Dim.2 : 15,95 %.
- Inertie cumulee Dim.1 + Dim.2 : 37,76 %.

**Figures recommandees**

- `outputs/figures/04_principale_screeplot.png`
- `outputs/figures/04_principale_variables_top.png`
- `outputs/figures/04_principale_individus_target.png`
- `outputs/figures/04_principale_barycentres_target.png`

**Message oral** : "Le chevauchement dans le plan 1-2 est normal : deux axes ne resument pas toute l'information."

**Justification statistique** : les axes factoriels servent de base numerique au clustering.

---

# 7. Pourquoi clustering sur coordonnees FAMD ?

- Les donnees brutes melangent echelles numeriques et categories.
- Les coordonnees FAMD donnent un espace numerique homogene.
- Le clustering est donc applique aux individus projetes dans cet espace.
- `target` n'intervient pas dans la construction des clusters.

**Figure recommandee** : `outputs/figures/05_principale_clusters_famd.png`

**Message oral** : "On ne regroupe pas directement les lignes brutes ; on regroupe les individus dans l'espace FAMD."

**Justification statistique** : distance plus coherente pour des donnees mixtes.

---

# 8. Validation du clustering principal

- Solution principale : `nb_axes = 2`, `k = 2`.
- Silhouette moyenne : 0,508.
- Taille minimale : 929 etudiants.
- Taille maximale : 3 495 etudiants.
- Stabilite : ARI moyen = 1,00 sur 30 repetitions.

**Figures recommandees**

- `outputs/figures/05_principale_methode_coude.png`
- `outputs/figures/05_principale_silhouette_moyenne.png`
- `outputs/figures/05_principale_dendrogramme_cah.png`

**Message oral** : "k = 2 est retenu apres recalcul sur la FAMD principale reduite ; c'est une solution stable et lisible."

**Justification statistique** : grille axes-k, silhouette, tailles de clusters et stabilite.

---

# 9. Profils obtenus : Cluster 1 vs Cluster 2

| Profil | Effectif | Dropout | Graduate | Lecture |
|---|---:|---:|---:|---|
| Cluster 1 | 929 | 81,5 % | 8,9 % | Profil a risque eleve |
| Cluster 2 | 3 495 | 19,0 % | 60,8 % | Profil majoritaire favorable |

- Cluster 1 : indicateurs academiques faibles, profil prioritaire a surveiller.
- Cluster 2 : indicateurs academiques meilleurs, profil plus favorable.
- `target` est utilisee apres clustering pour caracteriser les groupes.

**Figures recommandees**

- `outputs/figures/05_principale_composition_clusters_target.png`
- `outputs/figures/05_principale_profils_academiques_clusters.png`

**Message oral** : "La typologie finale oppose un groupe a risque eleve et un groupe majoritaire favorable."

---

# 10. Regression logistique complementaire

- Cible binaire : `Dropout` vs `Non_Dropout`.
- Modele precoce : variables d'entree + semestre 1.
- Modele complet : variables d'entree + semestre 1 + semestre 2.
- Le modele complet est plus performant mais disponible plus tard.

| Modele | Accuracy | Recall Dropout | F1 Dropout | AUC |
|---|---:|---:|---:|---:|
| Precoce | 0,849 | 0,716 | 0,753 | 0,884 |
| Complet | 0,865 | 0,747 | 0,780 | 0,909 |

**Figures recommandees**

- `outputs/figures/06_roc_logit_precoce.png`
- `outputs/figures/06_roc_logit_complet.png`

**Message oral** : "La regression est complementaire : elle mesure des associations avec Dropout vs Non_Dropout."

---

# 11. Recommandations operationnelles

- Mettre en place un suivi academique precoce apres le premier semestre.
- Prioriser les etudiants du cluster 1.
- Surveiller les signaux administratifs et financiers : debiteur, frais a jour.
- Utiliser le modele precoce comme logique d'alerte possible.
- Lire les resultats avec prudence avant toute generalisation.

**Figure recommandee** : `outputs/figures/05_principale_profils_academiques_clusters.png`

**Message oral** : "Les recommandations sont des pistes d'aide a la decision, pas des decisions automatiques."

**Justification statistique** : combinaison entre typologie exploratoire et modele complementaire.

---

# 12. Limites methodologiques

- Analyse exploratoire, non supervisee pour la FAMD et le clustering.
- Projection 2D partielle : Dim.1 + Dim.2 = 37,76 % d'inertie.
- k = 2 est robuste et lisible, mais moins detaille qu'une typologie plus fine.
- Les donnees viennent d'une cohorte specifique.
- Une validation externe sur d'autres cohortes serait necessaire.

**Message oral** : "Nous assumons une lecture prudente : le projet met en evidence des structures et des associations."

**Justification statistique** : absence de validation externe et nature exploratoire du clustering.

---

# 13. Conclusion

- Le projet combine analyse descriptive, FAMD, clustering et regression logistique.
- La FAMD principale reduite fournit un espace adapte aux donnees mixtes.
- Le clustering principal identifie deux profils interpretable.
- La regression logistique confirme l'interet informatif des variables academiques.
- Les resultats soutiennent une logique d'alerte et d'accompagnement.

**Message oral** : "La contribution principale est une typologie defendable, claire et utile pour comprendre les parcours etudiants."

**Phrase finale** :  
"Notre analyse suggere que les performances academiques precoces structurent fortement les profils, et que le cluster 1 merite une attention prioritaire."

---

# 14. Questions possibles de soutenance

- Pourquoi FAMD et pas ACP ?
- Pourquoi `target` illustrative ?
- Pourquoi semestre 2 supplementaire ?
- Pourquoi clustering sur coordonnees FAMD ?
- Pourquoi `k = 2` ?
- Que signifie silhouette = 0,508 ?
- Les resultats sont-ils causaux ?
- Difference entre modele precoce et modele complet ?

**Table recommandee** : `outputs/tables/08_questions_soutenance_reponses.csv`

**Message oral** : "Nous pouvons defendre chaque choix par la coherence entre type de donnees, methode et objectif exploratoire."

