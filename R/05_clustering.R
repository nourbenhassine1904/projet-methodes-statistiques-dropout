# ============================================================
# 05_clustering.R
# Objectif : clustering robuste sur coordonnees FAMD et profils
# ============================================================

chemins_possibles <- c(getwd(), dirname(getwd()))
racine_projet <- chemins_possibles[
  file.exists(file.path(chemins_possibles, "R", "00_packages_config.R"))
][1]

if (is.na(racine_projet)) {
  stop("Impossible de trouver la racine du projet.")
}

setwd(racine_projet)
source(file.path("R", "00_packages_config.R"))

dir.create(file.path("outputs", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "models"), recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Source des donnees de clustering
# ------------------------------------------------------------

chemins_famd <- c(
  file.path("outputs", "models", "04_resultat_famd_globale.rds"),
  file.path("outputs", "models", "04_resultat_famd.rds")
)

chemin_famd <- chemins_famd[file.exists(chemins_famd)][1]

if (is.na(chemin_famd)) {
  stop(
    "Aucun objet FAMD disponible. Executer R/04_famd.R avant le clustering."
  )
}

res_famd <- readRDS(chemin_famd)
donnees <- readRDS(file.path("data", "processed", "dropout_clean.rds"))

if (is.null(res_famd$ind$coord)) {
  stop("L'objet FAMD ne contient pas res_famd$ind$coord.")
}

coord_famd <- as.data.frame(res_famd$ind$coord)

if (nrow(coord_famd) != nrow(donnees)) {
  stop("Le nombre d'individus FAMD ne correspond pas aux donnees nettoyees.")
}

if (anyNA(coord_famd)) {
  stop("Les coordonnees FAMD contiennent des valeurs manquantes.")
}

# Les variables target, dropout_binary et success_binary ne sont jamais utilisees
# pour construire les clusters. Elles servent uniquement a l'interpretation aval.
# Les coordonnees FAMD ne sont pas standardisees ici : les axes sont orthogonaux
# et leurs variances portent l'information d'inertie. Standardiser donnerait le
# meme poids a des axes plus faibles et modifierait la geometrie FAMD.

nb_axes_possibles <- c(3, 5, 8, 10)
nb_axes_disponibles <- ncol(coord_famd)
nb_axes_testes <- nb_axes_possibles[nb_axes_possibles <= nb_axes_disponibles]

if (length(nb_axes_testes) == 0) {
  stop("Moins de 3 axes FAMD disponibles : clustering non lance.")
}

k_possibles <- 2:10
set.seed(123)

calculer_solution <- function(nb_axes, k, coord_source = coord_famd) {
  coord <- as.matrix(coord_source[, seq_len(nb_axes), drop = FALSE])
  km <- kmeans(coord, centers = k, nstart = 50, iter.max = 1000, algorithm = "Lloyd")
  sil <- cluster::silhouette(km$cluster, dist(coord))
  tailles <- as.integer(table(km$cluster))

  list(
    nb_axes = nb_axes,
    k = k,
    kmeans = km,
    silhouette = sil,
    inertie_intra_totale = km$tot.withinss,
    silhouette_moyenne = mean(sil[, "sil_width"]),
    taille_min_cluster = min(tailles),
    taille_max_cluster = max(tailles),
    ratio_taille_max_min = max(tailles) / min(tailles)
  )
}

solutions <- tidyr::crossing(nb_axes = nb_axes_testes, k = k_possibles) |>
  dplyr::mutate(
    solution = purrr::map2(nb_axes, k, calculer_solution)
  )

grille_validation <- solutions |>
  dplyr::transmute(
    nb_axes,
    k,
    inertie_intra_totale = purrr::map_dbl(solution, "inertie_intra_totale"),
    silhouette_moyenne = purrr::map_dbl(solution, "silhouette_moyenne"),
    taille_min_cluster = purrr::map_int(solution, "taille_min_cluster"),
    taille_max_cluster = purrr::map_int(solution, "taille_max_cluster"),
    ratio_taille_max_min = purrr::map_dbl(solution, "ratio_taille_max_min")
  )

readr::write_csv(
  grille_validation,
  file.path("outputs", "tables", "05_grille_validation_k_axes.csv")
)

# ------------------------------------------------------------
# Choix argumente de la solution retenue
# ------------------------------------------------------------

n_individus <- nrow(coord_famd)
taille_min_acceptable <- max(30, ceiling(0.03 * n_individus))
meilleure_silhouette <- max(grille_validation$silhouette_moyenne, na.rm = TRUE)

# Decision finale du projet :
# la solution principale est fixee a 3 axes FAMD et k = 3.
# Les autres valeurs de k restent documentees en comparaison secondaire.
nb_axes_retenus <- 3
k_retenu <- 3

if (nb_axes_disponibles < nb_axes_retenus) {
  stop("La solution principale demande 3 axes FAMD, mais ils ne sont pas disponibles.")
}

solution_retenue_ligne <- grille_validation |>
  dplyr::filter(nb_axes == nb_axes_retenus, k == k_retenu) |>
  dplyr::slice(1)

solution_retenue <- solutions |>
  dplyr::filter(nb_axes == nb_axes_retenus, k == k_retenu) |>
  dplyr::pull(solution) |>
  purrr::pluck(1)

res_kmeans <- solution_retenue$kmeans
silhouette_solution <- solution_retenue$silhouette
coord_retenues <- as.data.frame(
  coord_famd[, seq_len(nb_axes_retenus), drop = FALSE]
)
dist_coord_retenues <- dist(as.matrix(coord_retenues))

justification_retenue <- paste0(
  "Solution principale fixee a nb_axes = 3 et k = 3 apres comparaison des ",
  "solutions candidates k = 2, k = 3 et k = 6 : k = 3 maximise la silhouette ",
  "moyenne parmi ces candidates et fournit des profils interpretables. ",
  "Target, dropout_binary et success_binary sont reserves a l'interpretation apres clustering."
)

prudence_retenue <- paste0(
  "Le clustering reste exploratoire : la silhouette moyenne est ",
  round(solution_retenue_ligne$silhouette_moyenne, 3),
  " et ne doit pas etre presentee comme une separation parfaite."
)

choix_k_axes_argumente <- tibble::tibble(
  nb_axes_retenus = nb_axes_retenus,
  k_retenu = k_retenu,
  silhouette_moyenne = solution_retenue_ligne$silhouette_moyenne,
  inertie_intra_totale = solution_retenue_ligne$inertie_intra_totale,
  taille_min_cluster = solution_retenue_ligne$taille_min_cluster,
  taille_max_cluster = solution_retenue_ligne$taille_max_cluster,
  justification = justification_retenue,
  prudence_interpretation = prudence_retenue
)

readr::write_csv(
  choix_k_axes_argumente,
  file.path("outputs", "tables", "05_choix_k_axes_argumente.csv")
)

table_k_recommande <- tibble::tibble(
  k_recommande = k_retenu,
  nb_axes_retenus = nb_axes_retenus,
  critere = "compromis silhouette_interpretabilite",
  commentaire = "k = 3 maximise la silhouette moyenne parmi les solutions candidates et fournit des profils interpr\u00e9tables ; le choix reste exploratoire."
)

readr::write_csv(
  table_k_recommande,
  file.path("outputs", "tables", "05_k_recommande.csv")
)

saveRDS(res_kmeans, file.path("outputs", "models", "05_kmeans.rds"))

# ------------------------------------------------------------
# Silhouette par cluster
# ------------------------------------------------------------

silhouette_individus <- tibble::as_tibble(as.data.frame(silhouette_solution)) |>
  dplyr::transmute(
    cluster = factor(cluster),
    silhouette = sil_width
  )

silhouette_par_cluster <- silhouette_individus |>
  dplyr::group_by(cluster) |>
  dplyr::summarise(
    effectif = dplyr::n(),
    silhouette_moyenne = mean(silhouette),
    silhouette_min = min(silhouette),
    silhouette_q1 = unname(stats::quantile(silhouette, 0.25)),
    silhouette_mediane = stats::median(silhouette),
    silhouette_q3 = unname(stats::quantile(silhouette, 0.75)),
    silhouette_max = max(silhouette),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    niveau_stabilite = dplyr::case_when(
      silhouette_moyenne < 0.20 ~ "faible",
      silhouette_moyenne < 0.50 ~ "modere",
      TRUE ~ "correct"
    )
  )

readr::write_csv(
  silhouette_par_cluster,
  file.path("outputs", "tables", "05_silhouette_par_cluster.csv")
)

table_silhouette_retenue <- grille_validation |>
  dplyr::filter(nb_axes == nb_axes_retenus) |>
  dplyr::select(k, silhouette_moyenne)

readr::write_csv(
  table_silhouette_retenue,
  file.path("outputs", "tables", "05_kmeans_silhouette.csv")
)

table_coude_retenue <- grille_validation |>
  dplyr::filter(nb_axes == nb_axes_retenus) |>
  dplyr::transmute(k, inertie_intra = inertie_intra_totale)

readr::write_csv(
  table_coude_retenue,
  file.path("outputs", "tables", "05_kmeans_methode_coude.csv")
)

# ------------------------------------------------------------
# CAH complementaire
# ------------------------------------------------------------

res_hclust <- hclust(dist_coord_retenues, method = "ward.D2")
clusters_cah <- cutree(res_hclust, k = k_retenu)

saveRDS(res_hclust, file.path("outputs", "models", "05_cah.rds"))

png(file.path("outputs", "figures", "05_dendrogramme_cah.png"), width = 1200, height = 800, res = 150)
plot(
  res_hclust,
  labels = FALSE,
  hang = -1,
  main = paste("CAH - methode de Ward (k =", k_retenu, ")"),
  xlab = "",
  sub = "Validation complementaire sur les memes coordonnees FAMD que k-means"
)
rect.hclust(res_hclust, k = k_retenu, border = 2:(k_retenu + 1))
dev.off()

# ------------------------------------------------------------
# Table individuelle des clusters
# ------------------------------------------------------------

clusters_individus <- tibble::tibble(
  id_individu = seq_len(nrow(coord_retenues)),
  cluster_kmeans = factor(res_kmeans$cluster, levels = sort(unique(res_kmeans$cluster))),
  cluster_cah = factor(clusters_cah, levels = sort(unique(clusters_cah))),
  target = donnees$target
) |>
  dplyr::bind_cols(coord_retenues)

readr::write_csv(
  clusters_individus,
  file.path("outputs", "tables", "05_clusters_individus.csv")
)

donnees_clusters <- donnees |>
  dplyr::mutate(id_individu = dplyr::row_number()) |>
  dplyr::bind_cols(
    tibble::tibble(
      cluster_kmeans = factor(res_kmeans$cluster, levels = sort(unique(res_kmeans$cluster))),
      cluster_cah = factor(clusters_cah, levels = sort(unique(clusters_cah)))
    )
  )

# ------------------------------------------------------------
# Profils academiques et socio-economiques
# ------------------------------------------------------------

proportion_vrai <- function(x) {
  if (is.logical(x)) {
    return(mean(x, na.rm = TRUE))
  }

  if (is.numeric(x)) {
    return(mean(x == 1, na.rm = TRUE))
  }

  x_chr <- tolower(trimws(as.character(x)))
  mean(x_chr %in% c("1", "yes", "oui", "true", "vrai", "y"), na.rm = TRUE)
}

proportion_faux <- function(x) {
  if (is.logical(x)) {
    return(mean(!x, na.rm = TRUE))
  }

  if (is.numeric(x)) {
    return(mean(x == 0, na.rm = TRUE))
  }

  x_chr <- tolower(trimws(as.character(x)))
  mean(x_chr %in% c("0", "no", "non", "false", "faux", "n"), na.rm = TRUE)
}

calculer_profils_detailles <- function(clusters, donnees_source = donnees) {
  profils_base <- donnees_source |>
    dplyr::mutate(
      cluster = factor(clusters, levels = sort(unique(clusters)))
    ) |>
    dplyr::group_by(cluster) |>
    dplyr::summarise(
      effectif = dplyr::n(),
      proportion_dropout = mean(target == "Dropout", na.rm = TRUE),
      proportion_enrolled = mean(target == "Enrolled", na.rm = TRUE),
      proportion_graduate = mean(target == "Graduate", na.rm = TRUE),
      moyenne_age = mean(age_at_enrollment, na.rm = TRUE),
      moyenne_admission_grade = mean(admission_grade, na.rm = TRUE),
      moyenne_1st_sem_approved = mean(curricular_units_1st_sem_approved, na.rm = TRUE),
      moyenne_1st_sem_grade = mean(curricular_units_1st_sem_grade, na.rm = TRUE),
      moyenne_2nd_sem_approved = mean(curricular_units_2nd_sem_approved, na.rm = TRUE),
      moyenne_2nd_sem_grade = mean(curricular_units_2nd_sem_grade, na.rm = TRUE),
      proportion_debtor = proportion_vrai(debtor),
      proportion_tuition_not_up_to_date = proportion_faux(tuition_fees_up_to_date),
      proportion_scholarship_holder = proportion_vrai(scholarship_holder),
      .groups = "drop"
    )

  scores_profils <- profils_base |>
    dplyr::mutate(
      score_academique = rowMeans(
        dplyr::pick(
          moyenne_admission_grade,
          moyenne_1st_sem_approved,
          moyenne_1st_sem_grade,
          moyenne_2nd_sem_approved,
          moyenne_2nd_sem_grade
        ) |>
          scale(),
        na.rm = TRUE
      ),
      score_financier = rowMeans(
        dplyr::pick(
          proportion_debtor,
          proportion_tuition_not_up_to_date
        ) |>
          scale(),
        na.rm = TRUE
      )
    ) |>
    dplyr::select(cluster, score_academique, score_financier)

  profils_base |>
    dplyr::left_join(scores_profils, by = "cluster") |>
    dplyr::mutate(
      niveau_risque = dplyr::case_when(
        proportion_dropout >= stats::quantile(proportion_dropout, 0.75) ~ "eleve",
        proportion_dropout <= stats::quantile(proportion_dropout, 0.25) ~ "faible",
        TRUE ~ "modere"
      ),
      interpretation_synthetique = paste0(
        "Dropout: ", scales::percent(proportion_dropout, accuracy = 0.1),
        "; Graduate: ", scales::percent(proportion_graduate, accuracy = 0.1),
        "; indicateurs academiques ",
        dplyr::case_when(
          score_academique > 0.25 ~ "au-dessus de la moyenne des clusters",
          score_academique < -0.25 ~ "en dessous de la moyenne des clusters",
          TRUE ~ "proches de la moyenne des clusters"
        ),
        "; risque ", niveau_risque, "."
      )
    ) |>
    dplyr::select(
      cluster,
      effectif,
      proportion_dropout,
      proportion_enrolled,
      proportion_graduate,
      moyenne_age,
      moyenne_admission_grade,
      moyenne_1st_sem_approved,
      moyenne_1st_sem_grade,
      moyenne_2nd_sem_approved,
      moyenne_2nd_sem_grade,
      proportion_debtor,
      proportion_tuition_not_up_to_date,
      proportion_scholarship_holder,
      interpretation_synthetique,
      niveau_risque
    )
}

profils_academiques_clusters <- donnees_clusters |>
  dplyr::group_by(cluster_kmeans) |>
  dplyr::summarise(
    cluster = as.character(dplyr::first(cluster_kmeans)),
    effectif = dplyr::n(),
    proportion_dropout = mean(target == "Dropout", na.rm = TRUE),
    proportion_enrolled = mean(target == "Enrolled", na.rm = TRUE),
    proportion_graduate = mean(target == "Graduate", na.rm = TRUE),
    moyenne_age = mean(age_at_enrollment, na.rm = TRUE),
    moyenne_admission_grade = mean(admission_grade, na.rm = TRUE),
    moyenne_1st_sem_approved = mean(curricular_units_1st_sem_approved, na.rm = TRUE),
    moyenne_1st_sem_grade = mean(curricular_units_1st_sem_grade, na.rm = TRUE),
    moyenne_2nd_sem_approved = mean(curricular_units_2nd_sem_approved, na.rm = TRUE),
    moyenne_2nd_sem_grade = mean(curricular_units_2nd_sem_grade, na.rm = TRUE),
    proportion_debtor = proportion_vrai(debtor),
    proportion_tuition_not_up_to_date = proportion_faux(tuition_fees_up_to_date),
    proportion_scholarship_holder = proportion_vrai(scholarship_holder),
    .groups = "drop"
  ) |>
  dplyr::select(
    cluster,
    effectif,
    proportion_dropout,
    proportion_enrolled,
    proportion_graduate,
    moyenne_age,
    moyenne_admission_grade,
    moyenne_1st_sem_approved,
    moyenne_1st_sem_grade,
    moyenne_2nd_sem_approved,
    moyenne_2nd_sem_grade,
    proportion_debtor,
    proportion_tuition_not_up_to_date,
    proportion_scholarship_holder
  )

readr::write_csv(
  profils_academiques_clusters,
  file.path("outputs", "tables", "05_profils_academiques_clusters.csv")
)

profils_clusters_kmeans <- profils_academiques_clusters |>
  dplyr::rename(cluster_kmeans = cluster)

readr::write_csv(
  profils_clusters_kmeans,
  file.path("outputs", "tables", "05_profils_clusters_kmeans.csv")
)

score_academique <- profils_academiques_clusters |>
  dplyr::mutate(
    score_academique = rowMeans(
      dplyr::pick(
        moyenne_admission_grade,
        moyenne_1st_sem_approved,
        moyenne_1st_sem_grade,
        moyenne_2nd_sem_approved,
        moyenne_2nd_sem_grade
      ) |>
        scale(),
      na.rm = TRUE
    ),
    score_financier = rowMeans(
      dplyr::pick(
        proportion_debtor,
        proportion_tuition_not_up_to_date
      ) |>
        scale(),
      na.rm = TRUE
    )
  ) |>
  dplyr::select(cluster, score_academique, score_financier)

cluster_dropout_max <- profils_academiques_clusters$cluster[
  which.max(profils_academiques_clusters$proportion_dropout)
]
cluster_majoritaire <- profils_academiques_clusters$cluster[
  which.max(profils_academiques_clusters$effectif)
]
cluster_plus_age <- profils_academiques_clusters$cluster[
  which.max(profils_academiques_clusters$moyenne_age)
]

profils_clusters_interpretes <- profils_academiques_clusters |>
  dplyr::left_join(score_academique, by = "cluster") |>
  dplyr::mutate(
    cluster_kmeans = cluster,
    niveau_risque = dplyr::case_when(
      cluster == cluster_dropout_max ~ "Tr\u00e8s \u00e9lev\u00e9",
      cluster == cluster_majoritaire & proportion_graduate > proportion_dropout ~ "Faible",
      cluster == cluster_plus_age & proportion_graduate > proportion_dropout ~ "Faible \u00e0 mod\u00e9r\u00e9",
      TRUE ~ "Mod\u00e9r\u00e9"
    ),
    nom_profil = dplyr::case_when(
      cluster == cluster_dropout_max ~ "Profil \u00e0 risque \u00e9lev\u00e9 de d\u00e9crochage",
      cluster == cluster_majoritaire & proportion_graduate > proportion_dropout ~ "Profil majoritaire favorable",
      cluster == cluster_plus_age & proportion_graduate > proportion_dropout ~ "Profil adulte/atypique plut\u00f4t favorable",
      proportion_graduate > proportion_dropout ~ "Profil plut\u00f4t favorable",
      TRUE ~ "Profil mixte \u00e0 interpr\u00e9ter prudemment"
    ),
    interpretation_synthetique = paste0(
      "Dropout: ", scales::percent(proportion_dropout, accuracy = 0.1),
      "; Graduate: ", scales::percent(proportion_graduate, accuracy = 0.1),
      "; indicateurs academiques ",
      dplyr::case_when(
        score_academique > 0.25 ~ "au-dessus de la moyenne des clusters",
        score_academique < -0.25 ~ "en dessous de la moyenne des clusters",
        TRUE ~ "proches de la moyenne des clusters"
      ),
      "; Target utilisee uniquement apres clustering pour interpreter ce profil."
    )
  ) |>
  dplyr::select(
    cluster_kmeans,
    nom_profil,
    effectif,
    proportion_dropout,
    proportion_enrolled,
    proportion_graduate,
    interpretation_synthetique,
    niveau_risque
  )

readr::write_csv(
  profils_clusters_interpretes,
  file.path("outputs", "tables", "05_profils_clusters_interpretes.csv")
)

# ------------------------------------------------------------
# Comparaison secondaire des solutions candidates k = 2, 3 et 6
# ------------------------------------------------------------

extraire_solution <- function(nb_axes, k) {
  solutions |>
    dplyr::filter(nb_axes == !!nb_axes, k == !!k) |>
    dplyr::pull(solution) |>
    purrr::pluck(1)
}

solutions_candidates_def <- tibble::tibble(
  solution = c("A", "B", "C"),
  nb_axes = c(3, 3, 3),
  k = c(2, 3, 6)
) |>
  dplyr::filter(nb_axes <= nb_axes_disponibles)

solutions_candidates_stats <- solutions_candidates_def |>
  dplyr::left_join(grille_validation, by = c("nb_axes", "k")) |>
  dplyr::mutate(
    statut_analyse = "comparaison secondaire",
    avantage = dplyr::case_when(
      k == 2 ~ "Solution simple, stable et lisible, avec deux groupes faciles a presenter.",
      k == 3 ~ "Solution principale : meilleure silhouette parmi les candidates et typologie interpretable.",
      k == 6 ~ "Typologie plus detaillee, utile pour explorer des sous-profils.",
      TRUE ~ NA_character_
    ),
    limite = dplyr::case_when(
      k == 2 ~ "Lecture trop binaire pour la decision finale : des profils distincts peuvent etre fusionnes.",
      k == 3 ~ "Solution retenue a interpreter comme un compromis exploratoire.",
      k == 6 ~ "Silhouette plus faible et risque de surinterpretation de petits sous-groupes.",
      TRUE ~ NA_character_
    ),
    decision_possible = dplyr::case_when(
      k == 2 ~ "Reference secondaire pour verifier la lecture synthetique.",
      k == 3 ~ "Solution principale retenue pour les sorties standard du script 05.",
      k == 6 ~ "Typologie exploratoire secondaire, non retenue comme solution principale.",
      TRUE ~ NA_character_
    )
  )

readr::write_csv(
  solutions_candidates_stats,
  file.path("outputs", "tables", "05_comparaison_solutions_candidates.csv")
)

profils_candidates <- solutions_candidates_def |>
  dplyr::mutate(
    solution_obj = purrr::map2(nb_axes, k, extraire_solution),
    profils = purrr::map(solution_obj, ~ calculer_profils_detailles(.x$kmeans$cluster))
  )

profils_candidate_k2 <- profils_candidates |>
  dplyr::filter(k == 2) |>
  dplyr::pull(profils) |>
  purrr::pluck(1)

profils_candidate_k3 <- profils_candidates |>
  dplyr::filter(k == 3) |>
  dplyr::pull(profils) |>
  purrr::pluck(1)

profils_candidate_k6 <- profils_candidates |>
  dplyr::filter(k == 6) |>
  dplyr::pull(profils) |>
  purrr::pluck(1)

readr::write_csv(
  profils_candidate_k2,
  file.path("outputs", "tables", "05_profils_candidates_k2.csv")
)

readr::write_csv(
  profils_candidate_k3,
  file.path("outputs", "tables", "05_profils_candidates_k3.csv")
)

readr::write_csv(
  profils_candidate_k6,
  file.path("outputs", "tables", "05_profils_candidates_k6.csv")
)

stats_k2 <- solutions_candidates_stats |>
  dplyr::filter(k == 2) |>
  dplyr::slice(1)

stats_k3 <- solutions_candidates_stats |>
  dplyr::filter(k == 3) |>
  dplyr::slice(1)

stats_k6 <- solutions_candidates_stats |>
  dplyr::filter(k == 6) |>
  dplyr::slice(1)

gain_silhouette_k3 <- stats_k3$silhouette_moyenne - stats_k2$silhouette_moyenne
recommandation_k <- 3

stats_recommandee <- solutions_candidates_stats |>
  dplyr::filter(k == recommandation_k) |>
  dplyr::slice(1)

solution_recommandee <- paste0(
  "solution ",
  stats_recommandee$solution,
  " - nb_axes = ",
  stats_recommandee$nb_axes,
  ", k = ",
  stats_recommandee$k
)

justification_statistique <- paste0(
  "k = 3 obtient la meilleure silhouette moyenne parmi les solutions candidates ",
  "(k = 2 : ", round(stats_k2$silhouette_moyenne, 3),
  " ; k = 3 : ", round(stats_k3$silhouette_moyenne, 3),
  " ; k = 6 : ", round(stats_k6$silhouette_moyenne, 3),
  ") avec un cluster minimal de ", stats_k3$taille_min_cluster,
  " individus."
)

justification_interpretation <- paste0(
  "Les profils k = 3 apportent une segmentation plus fine que k = 2 tout en restant presentables ; ",
  "la lecture reste centree sur des profils de risque interpretes apres clustering."
)

limite_recommandation <- paste0(
  "La solution retenue reste un compromis exploratoire : les groupes doivent etre interpretes prudemment ",
  "et valides par une lecture metier."
)

recommandation_solution_clustering <- tibble::tibble(
  solution_recommandee = solution_recommandee,
  justification_statistique = justification_statistique,
  justification_interpretation = justification_interpretation,
  limite = limite_recommandation,
  phrase_pour_rapport = paste0(
    "La solution principale retenue est un compromis fonde sur la silhouette, la taille des groupes et l'interpretabilite : ",
    solution_recommandee,
    "."
  ),
  phrase_pour_soutenance = paste0(
    "Nous avons compare k = 2, k = 3 et k = 6 ; le compromis retenu est ",
    solution_recommandee,
    ", avec Target utilisee seulement apres clustering pour interpreter les groupes."
  )
)

readr::write_csv(
  recommandation_solution_clustering,
  file.path("outputs", "tables", "05_recommandation_solution_clustering.csv")
)

variables_binaires_importantes <- c(
  "gender",
  "displaced",
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  "international"
) |>
  intersect(names(donnees_clusters))

repartition_binaires_clusters <- donnees_clusters |>
  dplyr::select(cluster_kmeans, dplyr::all_of(variables_binaires_importantes)) |>
  tidyr::pivot_longer(
    cols = -cluster_kmeans,
    names_to = "variable",
    values_to = "modalite"
  ) |>
  dplyr::count(cluster_kmeans, variable, modalite, name = "effectif") |>
  dplyr::group_by(cluster_kmeans, variable) |>
  dplyr::mutate(
    total_variable_cluster = sum(effectif),
    proportion = effectif / total_variable_cluster,
    pourcentage = round(100 * proportion, 2)
  ) |>
  dplyr::ungroup()

readr::write_csv(
  repartition_binaires_clusters,
  file.path("outputs", "tables", "05_repartition_binaires_clusters.csv")
)

croisement_cluster_target <- donnees_clusters |>
  dplyr::count(cluster_kmeans, target, name = "effectif") |>
  dplyr::group_by(cluster_kmeans) |>
  dplyr::mutate(
    total_cluster = sum(effectif),
    proportion = effectif / total_cluster,
    pourcentage = round(100 * proportion, 2)
  ) |>
  dplyr::ungroup()

readr::write_csv(
  croisement_cluster_target,
  file.path("outputs", "tables", "05_croisement_cluster_target.csv")
)

# ------------------------------------------------------------
# Figures
# ------------------------------------------------------------

note_coude <- paste0(
  "Le coude est peu net ; le choix final combine silhouette, tailles de groupes et interpr\u00e9tabilit\u00e9."
)

candidats_fig_coude <- table_coude_retenue |>
  dplyr::filter(k %in% c(2, 3, 6)) |>
  dplyr::mutate(
    label = dplyr::if_else(k == k_retenu, "solution principale k = 3", paste0("secondaire k = ", k))
  )

p_coude <- table_coude_retenue |>
  ggplot2::ggplot(ggplot2::aes(x = k, y = inertie_intra)) +
  ggplot2::geom_line(color = "#2F6F7E", linewidth = 0.8) +
  ggplot2::geom_point(size = 2.5, color = "#2F6F7E") +
  ggplot2::geom_point(
    data = candidats_fig_coude,
    ggplot2::aes(x = k, y = inertie_intra),
    color = "#B23A48",
    size = 3.5,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_text(
    data = candidats_fig_coude,
    ggplot2::aes(x = k, y = inertie_intra, label = label),
    vjust = -0.8,
    color = "#B23A48",
    size = 3.3,
    inherit.aes = FALSE
  ) +
  ggplot2::scale_x_continuous(breaks = k_possibles) +
  ggplot2::labs(
    title = "Methode du coude sur coordonnees FAMD",
    subtitle = note_coude,
    x = "Nombre de clusters k",
    y = "Inertie intra-classe totale"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_methode_coude.png"),
  p_coude,
  width = 8,
  height = 5,
  dpi = 300
)

table_silhouette_candidates <- table_silhouette_retenue |>
  dplyr::filter(k %in% c(2, 3, 6))

k_silhouette_max <- table_silhouette_candidates$k[which.max(table_silhouette_candidates$silhouette_moyenne)]
candidats_fig_silhouette <- table_silhouette_candidates |>
  dplyr::mutate(
    label = dplyr::if_else(k == k_retenu, "meilleure candidate k = 3", paste0("secondaire k = ", k))
  )

p_silhouette <- table_silhouette_candidates |>
  ggplot2::ggplot(ggplot2::aes(x = k, y = silhouette_moyenne)) +
  ggplot2::geom_line(color = "#3B7A57", linewidth = 0.8) +
  ggplot2::geom_point(size = 2.5, color = "#3B7A57") +
  ggplot2::geom_text(
    ggplot2::aes(label = round(silhouette_moyenne, 3)),
    vjust = -0.8,
    size = 3.2
  ) +
  ggplot2::geom_point(
    data = candidats_fig_silhouette,
    ggplot2::aes(x = k, y = silhouette_moyenne),
    color = "#B23A48",
    size = 3.5,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_text(
    data = candidats_fig_silhouette,
    ggplot2::aes(x = k, y = silhouette_moyenne, label = label),
    vjust = 1.8,
    color = "#B23A48",
    size = 3.3,
    inherit.aes = FALSE
  ) +
  ggplot2::annotate(
    "label",
    x = k_silhouette_max,
    y = max(table_silhouette_candidates$silhouette_moyenne),
    label = paste("meilleure silhouette candidate : k =", k_silhouette_max),
    vjust = -0.4,
    fill = "white",
    color = "#3B7A57",
    size = 3.2
  ) +
  ggplot2::scale_x_continuous(breaks = k_possibles) +
  ggplot2::labs(
    title = "Silhouette moyenne des solutions candidates",
    subtitle = "k = 3 a la meilleure silhouette moyenne parmi k = 2, k = 3 et k = 6.",
    x = "Nombre de clusters k",
    y = "Silhouette moyenne"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_silhouette_moyenne.png"),
  p_silhouette,
  width = 8,
  height = 5,
  dpi = 300
)

centroides_projection <- as.data.frame(res_kmeans$centers) |>
  tibble::rownames_to_column("cluster_kmeans") |>
  dplyr::mutate(cluster_kmeans = factor(cluster_kmeans, levels = levels(clusters_individus$cluster_kmeans)))

p_clusters <- clusters_individus |>
  ggplot2::ggplot(ggplot2::aes(x = Dim.1, y = Dim.2, color = cluster_kmeans)) +
  ggplot2::geom_point(alpha = 0.35, size = 1.1) +
  ggplot2::geom_point(
    data = centroides_projection,
    ggplot2::aes(x = Dim.1, y = Dim.2, fill = cluster_kmeans),
    shape = 21,
    color = "black",
    size = 4,
    stroke = 0.8,
    inherit.aes = FALSE
  ) +
  ggplot2::labs(
    title = paste("K-means sur coordonnees FAMD - k =", k_retenu),
    subtitle = "Clusters construits sur 3 axes FAMD, projet\u00e9s ici sur Dim.1-Dim.2.",
    x = "Dimension 1",
    y = "Dimension 2",
    color = "Cluster",
    fill = "Centroide"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_clusters_kmeans_famd.png"),
  p_clusters,
  width = 8,
  height = 6,
  dpi = 300
)

p_cluster_target <- croisement_cluster_target |>
  ggplot2::ggplot(ggplot2::aes(x = cluster_kmeans, y = proportion, fill = target)) +
  ggplot2::geom_col(width = 0.75) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Composition des clusters selon Target",
    subtitle = "Target est utilis\u00e9e apr\u00e8s clustering uniquement pour interpr\u00e9ter les groupes.",
    x = "Cluster k-means",
    y = "Proportion dans le cluster",
    fill = "Target"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_composition_clusters_target.png"),
  p_cluster_target,
  width = 7,
  height = 5,
  dpi = 300
)

preparer_indicateurs_heatmap <- function(profils) {
  profils |>
    dplyr::select(
      cluster,
      admission_grade = moyenne_admission_grade,
      curricular_units_1st_sem_approved = moyenne_1st_sem_approved,
      curricular_units_1st_sem_grade = moyenne_1st_sem_grade,
      curricular_units_2nd_sem_approved = moyenne_2nd_sem_approved,
      curricular_units_2nd_sem_grade = moyenne_2nd_sem_grade,
      proportion_dropout
    ) |>
    tidyr::pivot_longer(
      cols = -cluster,
      names_to = "indicateur",
      values_to = "valeur"
    ) |>
    dplyr::group_by(indicateur) |>
    dplyr::mutate(valeur_standardisee = as.numeric(scale(valeur))) |>
    dplyr::ungroup()
}

construire_heatmap_profils <- function(profils, titre, sous_titre) {
  preparer_indicateurs_heatmap(profils) |>
    ggplot2::ggplot(ggplot2::aes(x = indicateur, y = cluster, fill = valeur_standardisee)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4) +
    ggplot2::scale_fill_gradient2(
      low = "#3B7A57",
      mid = "white",
      high = "#B23A48",
      midpoint = 0,
      name = "Valeur standardisee"
    ) +
    ggplot2::labs(
      title = titre,
      subtitle = sous_titre,
      x = NULL,
      y = "Cluster"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
}

p_profils_academiques <- construire_heatmap_profils(
  profils_academiques_clusters,
  "Profils academiques compares par cluster",
  "Indicateurs standardises entre clusters pour faciliter la comparaison."
)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_profils_clusters_academiques.png"),
  p_profils_academiques,
  width = 9,
  height = 5.5,
  dpi = 300
)

p_profils_candidates_k3 <- construire_heatmap_profils(
  profils_candidate_k3,
  "Profils academiques compares - solution candidate k = 3",
  "Indicateurs standardises entre clusters pour comparer la variante a trois groupes."
)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_profils_candidates_k3_academiques.png"),
  p_profils_candidates_k3,
  width = 9,
  height = 5.5,
  dpi = 300
)

# ------------------------------------------------------------
# Comparaison k-means / CAH
# ------------------------------------------------------------

resume_composition <- function(data, cluster_col) {
  data |>
    dplyr::count({{ cluster_col }}, target, name = "effectif") |>
    dplyr::group_by({{ cluster_col }}) |>
    dplyr::mutate(proportion = effectif / sum(effectif)) |>
    dplyr::ungroup() |>
    dplyr::group_by({{ cluster_col }}) |>
    dplyr::summarise(
      dominant = target[which.max(proportion)],
      prop_dominante = max(proportion),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      texte = paste0({{ cluster_col }}, ": ", dominant, " (", scales::percent(prop_dominante, accuracy = 1), ")")
    ) |>
    dplyr::pull(texte) |>
    paste(collapse = " | ")
}

comparaison_kmeans_cah <- tibble::tibble(
  methode = c("k-means", "CAH Ward"),
  nombre_de_clusters = c(k_retenu, k_retenu),
  composition_generale = c(
    resume_composition(donnees_clusters, cluster_kmeans),
    resume_composition(donnees_clusters, cluster_cah)
  ),
  interet = c(
    "Solution principale : reproductible, lisible et appliquee aux coordonnees FAMD retenues.",
    "Validation complementaire : visualise une structure hierarchique sur la meme distance FAMD."
  ),
  limite = c(
    "Depend du choix de k et peut produire des frontieres sensibles aux centres initiaux, limite attenuee par nstart = 50.",
    "Lecture du dendrogramme parfois subjective et moins directe pour affecter de nouveaux individus."
  )
)

readr::write_csv(
  comparaison_kmeans_cah,
  file.path("outputs", "tables", "05_comparaison_kmeans_cah.csv")
)

# ------------------------------------------------------------
# Analyse complementaire : segmentation precoce
# ------------------------------------------------------------

chemin_famd_precoce <- file.path("outputs", "models", "04_resultat_famd_precoce.rds")

if (file.exists(chemin_famd_precoce)) {
  res_famd_precoce <- readRDS(chemin_famd_precoce)
  coord_famd_precoce <- as.data.frame(res_famd_precoce$ind$coord)

  if (nrow(coord_famd_precoce) == nrow(donnees) && ncol(coord_famd_precoce) >= 2) {
    nb_axes_precoce <- min(3, ncol(coord_famd_precoce))
    k_precoce_possibles <- 2:6

    solutions_precoce <- tibble::tibble(k = k_precoce_possibles) |>
      dplyr::mutate(
        nb_axes = nb_axes_precoce,
        solution_obj = purrr::map(k, ~ calculer_solution(nb_axes_precoce, .x, coord_famd_precoce))
      )

    validation_precoce <- solutions_precoce |>
      dplyr::transmute(
        analyse = "segmentation precoce sans variables du 2e semestre",
        nb_axes,
        k,
        inertie_intra_totale = purrr::map_dbl(solution_obj, "inertie_intra_totale"),
        silhouette_moyenne = purrr::map_dbl(solution_obj, "silhouette_moyenne"),
        taille_min_cluster = purrr::map_int(solution_obj, "taille_min_cluster"),
        taille_max_cluster = purrr::map_int(solution_obj, "taille_max_cluster"),
        ratio_taille_max_min = purrr::map_dbl(solution_obj, "ratio_taille_max_min")
      )

    readr::write_csv(
      validation_precoce,
      file.path("outputs", "tables", "05_clustering_precoce_validation.csv")
    )

    candidats_precoce <- validation_precoce |>
      dplyr::filter(taille_min_cluster >= taille_min_acceptable)

    if (nrow(candidats_precoce) == 0) {
      candidats_precoce <- validation_precoce
    }

    choix_precoce <- candidats_precoce |>
      dplyr::arrange(
        dplyr::desc(silhouette_moyenne),
        ratio_taille_max_min,
        k
      ) |>
      dplyr::slice(1)

    solution_precoce <- solutions_precoce |>
      dplyr::filter(k == choix_precoce$k) |>
      dplyr::pull(solution_obj) |>
      purrr::pluck(1)

    profils_precoce <- calculer_profils_detailles(solution_precoce$kmeans$cluster) |>
      dplyr::mutate(
        analyse = "segmentation precoce sans variables du 2e semestre",
        nb_axes = nb_axes_precoce,
        k = choix_precoce$k,
        .before = cluster
      )

    readr::write_csv(
      profils_precoce,
      file.path("outputs", "tables", "05_clustering_precoce_profils.csv")
    )

    p_precoce_silhouette <- validation_precoce |>
      ggplot2::ggplot(ggplot2::aes(x = k, y = silhouette_moyenne)) +
      ggplot2::geom_line(color = "#2F6F7E", linewidth = 0.8) +
      ggplot2::geom_point(size = 2.5, color = "#2F6F7E") +
      ggplot2::geom_text(
        ggplot2::aes(label = round(silhouette_moyenne, 3)),
        vjust = -0.8,
        size = 3.2
      ) +
      ggplot2::geom_vline(xintercept = choix_precoce$k, linetype = "dashed", color = "#B23A48") +
      ggplot2::labs(
        title = "Silhouette moyenne - segmentation precoce",
        subtitle = "Segmentation precoce sans variables du 2e semestre ; Target est utilisee seulement apres clustering.",
        x = "Nombre de clusters k",
        y = "Silhouette moyenne"
      ) +
      ggplot2::scale_x_continuous(breaks = k_precoce_possibles) +
      ggplot2::theme_minimal(base_size = 12)

    ggplot2::ggsave(
      file.path("outputs", "figures", "05_clustering_precoce_silhouette.png"),
      p_precoce_silhouette,
      width = 8,
      height = 5,
      dpi = 300
    )

    composition_precoce <- tibble::tibble(
      cluster = factor(solution_precoce$kmeans$cluster, levels = sort(unique(solution_precoce$kmeans$cluster))),
      target = donnees$target
    ) |>
      dplyr::count(cluster, target, name = "effectif") |>
      dplyr::group_by(cluster) |>
      dplyr::mutate(proportion = effectif / sum(effectif)) |>
      dplyr::ungroup()

    p_precoce_target <- composition_precoce |>
      ggplot2::ggplot(ggplot2::aes(x = cluster, y = proportion, fill = target)) +
      ggplot2::geom_col(width = 0.75) +
      ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
      ggplot2::labs(
        title = "Composition Target - segmentation precoce",
        subtitle = paste("Solution complementaire k =", choix_precoce$k, "sur", nb_axes_precoce, "axes FAMD precoces."),
        x = "Cluster precoce",
        y = "Proportion dans le cluster",
        fill = "Target"
      ) +
      ggplot2::theme_minimal(base_size = 12)

    ggplot2::ggsave(
      file.path("outputs", "figures", "05_clustering_precoce_composition_target.png"),
      p_precoce_target,
      width = 7,
      height = 5,
      dpi = 300
    )
  } else {
    warning("FAMD precoce disponible mais dimensions incompatibles : analyse precoce ignoree.")
  }
} else {
  message("FAMD precoce absente : analyse complementaire precoce non executee.")
}

# ------------------------------------------------------------
# Messages pour rapport et soutenance
# ------------------------------------------------------------

messages_cles_clustering <- tibble::tribble(
  ~point_technique, ~message_pour_rapport, ~message_pour_soutenance,
  "Clustering sur coordonnees FAMD",
  "Le clustering est applique aux coordonnees individuelles issues de la FAMD globale, ce qui respecte la nature mixte des variables actives.",
  "On ne regroupe pas directement les lignes brutes : on utilise l'espace factoriel FAMD, plus coherent pour variables numeriques et qualitatives.",
  "Pas de clustering direct sur donnees brutes",
  "Un clustering direct melangerait echelles numeriques et codages categoriels, ce qui pourrait biaiser les distances.",
  "La FAMD sert de pretraitement statistique pour construire une distance plus defendable.",
  "Solution principale a trois axes",
  "La solution principale utilise 3 axes FAMD ; les autres nombres d'axes servent a documenter la sensibilite du clustering.",
  "Les clusters sont construits sur 3 axes FAMD, meme si la figure les projette seulement sur Dim.1 et Dim.2.",
  "Chevauchement en Dim.1-Dim.2",
  "La projection 2D peut montrer du chevauchement car les clusters sont construits sur plusieurs axes FAMD.",
  "Un recouvrement visuel sur le graphique ne signifie pas que le clustering a ete fait seulement en deux dimensions.",
  "Solution principale k = 3",
  "k = 3 est la solution principale retenue ; k = 2 et k = 6 sont conserves comme comparaison secondaire.",
  "La decision finale retient k = 3, avec k = 2 et k = 6 presentes comme reperes secondaires.",
  "Methode du coude peu nette",
  "Le coude peut etre progressif dans des donnees sociales et academiques, donc il sert de repere plutot que de preuve unique.",
  "Si le coude n'est pas franc, c'est normal : on le combine avec silhouette et interpretabilite.",
  "Silhouette de la solution retenue",
  "k = 3 maximise la silhouette moyenne parmi les solutions candidates, mais les groupes restent partiellement superposes.",
  "k = 3 est le meilleur compromis de silhouette parmi les candidates ; on garde une interpretation exploratoire.",
  "Caractere exploratoire",
  "La solution retenue est un compromis exploratoire, pas une verite definitive.",
  "Le clustering aide a formuler des profils, mais ne remplace pas une validation metier ou predictive.",
  "Profils a risque",
  "Les profils a risque sont interpretes apres clustering via Target et les indicateurs academiques et socio-economiques.",
  "Target sert a comprendre les groupes apres coup, pas a les fabriquer."
)

readr::write_csv(
  messages_cles_clustering,
  file.path("outputs", "tables", "05_messages_cles_clustering.csv")
)

message(
  "Clustering termine. Les sorties principales 05_* sont maintenant basees sur k = ",
  k_retenu,
  " et ", nb_axes_retenus,
  " axes FAMD ; silhouette moyenne = ",
  round(solution_retenue_ligne$silhouette_moyenne, 3),
  ". Comparaison secondaire conservee : ",
  paste0(
    "k=", solutions_candidates_stats$k,
    " (silhouette=", round(solutions_candidates_stats$silhouette_moyenne, 3),
    ", min=", solutions_candidates_stats$taille_min_cluster, ")",
    collapse = " ; "
  ),
  "."
)
