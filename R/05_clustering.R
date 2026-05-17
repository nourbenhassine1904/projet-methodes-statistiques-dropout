# ============================================================
# 05_clustering.R
# Objectif : clustering principal sur FAMD principale reduite
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

set.seed(123)

chemin_famd_principale <- file.path(
  "outputs",
  "models",
  "04_resultat_famd_principale_reduite.rds"
)

if (!file.exists(chemin_famd_principale)) {
  stop("FAMD principale reduite absente. Executer R/04_famd.R avant R/05_clustering.R.")
}

chemin_donnees <- file.path("data", "processed", "dropout_clean.rds")
if (!file.exists(chemin_donnees)) {
  source(file.path("R", "02_preparation_donnees.R"))
}

res_famd <- readRDS(chemin_famd_principale)
donnees <- readRDS(chemin_donnees)

if (is.null(res_famd$ind$coord)) {
  stop("L'objet FAMD principale reduite ne contient pas de coordonnees individuelles.")
}

coord_famd <- as.data.frame(res_famd$ind$coord)

if (nrow(coord_famd) != nrow(donnees)) {
  stop("Le nombre d'individus FAMD ne correspond pas aux donnees nettoyees.")
}

if (anyNA(coord_famd)) {
  stop("Les coordonnees FAMD principales contiennent des valeurs manquantes.")
}

variables_actives <- readr::read_csv(
  file.path("outputs", "tables", "04_principale_variables_actives.csv"),
  show_col_types = FALSE
) |>
  dplyr::pull(.data$variable)

if ("target" %in% variables_actives) {
  stop("Controle clustering : target ne doit pas etre active dans la FAMD source.")
}

variables_derivees_actives <- intersect(c("dropout_binary", "success_binary"), variables_actives)
if (length(variables_derivees_actives) > 0) {
  stop("Controle clustering : dropout_binary/success_binary ne doivent pas etre actives.")
}

if (any(grepl("2nd_sem", variables_actives))) {
  stop("Controle clustering : une variable du semestre 2 est active dans la FAMD principale reduite.")
}

if (length(intersect(c("unemployment_rate", "inflation_rate", "gdp"), variables_actives)) > 0) {
  stop("Controle clustering : une variable economique est active dans la FAMD principale reduite.")
}

# Les clusters sont construits uniquement sur les coordonnees FAMD.
nb_axes_disponibles <- ncol(coord_famd)
nb_axes_candidats <- intersect(c(2, 3, 4, 5, 6, 8, 10), seq_len(nb_axes_disponibles))
k_candidats <- 2:10

if (length(nb_axes_candidats) == 0) {
  stop("Aucun nombre d'axes candidat disponible pour le clustering.")
}

calculer_solution <- function(nb_axes, k, seed = 123, nstart = 50) {
  set.seed(seed)
  coord <- as.matrix(coord_famd[, seq_len(nb_axes), drop = FALSE])
  km <- stats::kmeans(coord, centers = k, nstart = nstart, iter.max = 1000)
  sil <- cluster::silhouette(km$cluster, stats::dist(coord))
  tailles <- as.integer(table(km$cluster))

  tibble::tibble(
    inertie_intra_totale = km$tot.withinss,
    silhouette_moyenne = mean(sil[, "sil_width"]),
    taille_min_cluster = min(tailles),
    taille_max_cluster = max(tailles),
    ratio_taille_max_min = max(tailles) / min(tailles),
    interpretabilite_auto = dplyr::case_when(
      min(tailles) < max(30, ceiling(0.03 * nrow(coord_famd))) ~ "fragile_taille_minimale",
      max(tailles) / min(tailles) > 15 ~ "fragile_desequilibre",
      k > 7 ~ "complexe_nombre_clusters",
      TRUE ~ "interpretable"
    ),
    score_interpretabilite = dplyr::case_when(
      interpretabilite_auto == "interpretable" ~ 3,
      interpretabilite_auto == "complexe_nombre_clusters" ~ 2,
      TRUE ~ 1
    ),
    objet = list(list(kmeans = km, silhouette = sil, coord = coord))
  )
}

grille_validation <- tidyr::crossing(nb_axes = nb_axes_candidats, k = k_candidats) |>
  dplyr::mutate(resultat = purrr::map2(.data$nb_axes, .data$k, calculer_solution)) |>
  tidyr::unnest(.data$resultat)

objets_solutions <- grille_validation |>
  dplyr::select(.data$nb_axes, .data$k, .data$objet)

grille_validation_export <- grille_validation |>
  dplyr::select(-.data$objet) |>
  dplyr::arrange(.data$nb_axes, .data$k)

readr::write_csv(
  grille_validation_export,
  file.path("outputs", "tables", "05_grille_validation_k_axes_principale.csv")
)

taille_min_acceptable <- max(30, ceiling(0.03 * nrow(coord_famd)))

candidats_recommandables <- grille_validation_export |>
  dplyr::filter(
    .data$taille_min_cluster >= taille_min_acceptable,
    .data$ratio_taille_max_min <= 15
  )

if (nrow(candidats_recommandables) == 0) {
  candidats_recommandables <- grille_validation_export
}

solution_recommandee <- candidats_recommandables |>
  dplyr::arrange(
    dplyr::desc(.data$score_interpretabilite),
    dplyr::desc(.data$silhouette_moyenne),
    .data$ratio_taille_max_min,
    .data$k,
    .data$nb_axes
  ) |>
  dplyr::slice(1)

nb_axes_retenus <- solution_recommandee$nb_axes[[1]]
k_retenu <- solution_recommandee$k[[1]]

objet_retenu <- objets_solutions |>
  dplyr::filter(.data$nb_axes == nb_axes_retenus, .data$k == k_retenu) |>
  dplyr::pull(.data$objet) |>
  purrr::pluck(1)

res_kmeans <- objet_retenu$kmeans
silhouette_solution <- objet_retenu$silhouette
coord_retenues <- as.data.frame(objet_retenu$coord)
names(coord_retenues) <- paste0("Dim.", seq_len(ncol(coord_retenues)))

saveRDS(res_kmeans, file.path("outputs", "models", "05_kmeans_principale.rds"))

recommandation_solution <- solution_recommandee |>
  dplyr::mutate(
    solution_recommandee = paste0("nb_axes = ", nb_axes_retenus, ", k = ", k_retenu),
    critere = "grille axes-k, silhouette moyenne, taille des clusters et interpretabilite automatique",
    conclusion = dplyr::case_when(
      silhouette_moyenne >= 0.50 ~ "stable",
      silhouette_moyenne >= 0.25 ~ "moderee",
      TRUE ~ "fragile"
    ),
    commentaire = paste0(
      "Solution recommandee apres recalcul sur la FAMD principale reduite : ",
      solution_recommandee,
      ". Target est utilisee uniquement apres clustering."
    )
  ) |>
  dplyr::select(
    .data$solution_recommandee,
    .data$nb_axes,
    .data$k,
    .data$silhouette_moyenne,
    .data$inertie_intra_totale,
    .data$taille_min_cluster,
    .data$taille_max_cluster,
    .data$ratio_taille_max_min,
    .data$interpretabilite_auto,
    .data$critere,
    .data$conclusion,
    .data$commentaire
  )

readr::write_csv(
  recommandation_solution,
  file.path("outputs", "tables", "05_recommandation_solution_clustering_principale.csv")
)

clusters_individus <- tibble::tibble(
  id_individu = seq_len(nrow(coord_retenues)),
  cluster_kmeans = factor(res_kmeans$cluster, levels = sort(unique(res_kmeans$cluster))),
  target = donnees$target
) |>
  dplyr::bind_cols(coord_retenues)

readr::write_csv(
  clusters_individus,
  file.path("outputs", "tables", "05_clusters_individus_principale.csv")
)

donnees_clusters <- donnees |>
  dplyr::mutate(
    id_individu = dplyr::row_number(),
    cluster_kmeans = factor(res_kmeans$cluster, levels = sort(unique(res_kmeans$cluster)))
  )

croisement_cluster_target <- donnees_clusters |>
  dplyr::count(.data$cluster_kmeans, .data$target, name = "effectif") |>
  dplyr::group_by(.data$cluster_kmeans) |>
  dplyr::mutate(
    total_cluster = sum(.data$effectif),
    proportion = .data$effectif / .data$total_cluster,
    pourcentage = round(100 * .data$proportion, 2)
  ) |>
  dplyr::ungroup()

readr::write_csv(
  croisement_cluster_target,
  file.path("outputs", "tables", "05_croisement_cluster_target_principale.csv")
)

proportion_vrai <- function(x) {
  if (is.logical(x)) return(mean(x, na.rm = TRUE))
  if (is.numeric(x)) return(mean(x == 1, na.rm = TRUE))
  x_chr <- tolower(trimws(as.character(x)))
  mean(x_chr %in% c("1", "yes", "oui", "true", "vrai", "y"), na.rm = TRUE)
}

proportion_faux <- function(x) {
  if (is.logical(x)) return(mean(!x, na.rm = TRUE))
  if (is.numeric(x)) return(mean(x == 0, na.rm = TRUE))
  x_chr <- tolower(trimws(as.character(x)))
  mean(x_chr %in% c("0", "no", "non", "false", "faux", "n"), na.rm = TRUE)
}

profils_clusters <- donnees_clusters |>
  dplyr::group_by(.data$cluster_kmeans) |>
  dplyr::summarise(
    effectif = dplyr::n(),
    proportion_dropout = mean(.data$target == "Dropout", na.rm = TRUE),
    proportion_enrolled = mean(.data$target == "Enrolled", na.rm = TRUE),
    proportion_graduate = mean(.data$target == "Graduate", na.rm = TRUE),
    moyenne_age = mean(.data$age_at_enrollment, na.rm = TRUE),
    moyenne_previous_qualification_grade = mean(.data$previous_qualification_grade, na.rm = TRUE),
    moyenne_admission_grade = mean(.data$admission_grade, na.rm = TRUE),
    moyenne_1st_sem_evaluations = mean(.data$curricular_units_1st_sem_evaluations, na.rm = TRUE),
    moyenne_1st_sem_approved = mean(.data$curricular_units_1st_sem_approved, na.rm = TRUE),
    moyenne_1st_sem_grade = mean(.data$curricular_units_1st_sem_grade, na.rm = TRUE),
    moyenne_2nd_sem_approved = mean(.data$curricular_units_2nd_sem_approved, na.rm = TRUE),
    moyenne_2nd_sem_grade = mean(.data$curricular_units_2nd_sem_grade, na.rm = TRUE),
    proportion_debtor = proportion_vrai(.data$debtor),
    proportion_tuition_not_up_to_date = proportion_faux(.data$tuition_fees_up_to_date),
    proportion_scholarship_holder = proportion_vrai(.data$scholarship_holder),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    profil_auto = dplyr::case_when(
      proportion_dropout == max(proportion_dropout) ~ "profil_a_risque_eleve",
      effectif == max(effectif) & proportion_graduate >= proportion_dropout ~ "profil_majoritaire_favorable",
      moyenne_age == max(moyenne_age) & proportion_graduate >= proportion_dropout ~ "profil_adulte_atypique_plutot_favorable",
      proportion_graduate >= proportion_dropout ~ "profil_plutot_favorable",
      TRUE ~ "profil_mixte_a_interpreter"
    ),
    interpretation_synthetique = paste0(
      "Dropout: ", scales::percent(proportion_dropout, accuracy = 0.1),
      "; Graduate: ", scales::percent(proportion_graduate, accuracy = 0.1),
      "; profil automatique: ", profil_auto,
      "."
    )
  )

readr::write_csv(
  profils_clusters,
  file.path("outputs", "tables", "05_profils_clusters_principale.csv")
)

silhouette_individus <- tibble::as_tibble(as.data.frame(silhouette_solution)) |>
  dplyr::transmute(
    cluster = factor(.data$cluster, levels = sort(unique(.data$cluster))),
    silhouette = .data$sil_width
  )

silhouette_par_cluster <- silhouette_individus |>
  dplyr::group_by(.data$cluster) |>
  dplyr::summarise(
    effectif = dplyr::n(),
    silhouette_moyenne = mean(.data$silhouette),
    silhouette_min = min(.data$silhouette),
    silhouette_q1 = unname(stats::quantile(.data$silhouette, 0.25)),
    silhouette_mediane = stats::median(.data$silhouette),
    silhouette_q3 = unname(stats::quantile(.data$silhouette, 0.75)),
    silhouette_max = max(.data$silhouette),
    niveau = dplyr::case_when(
      silhouette_moyenne >= 0.50 ~ "stable",
      silhouette_moyenne >= 0.25 ~ "moderee",
      TRUE ~ "fragile"
    ),
    .groups = "drop"
  )

readr::write_csv(
  silhouette_par_cluster,
  file.path("outputs", "tables", "05_silhouette_par_cluster_principale.csv")
)

# ------------------------------------------------------------
# Stabilite du k-means final
# ------------------------------------------------------------

adjusted_rand_index <- function(x, y) {
  tab <- table(x, y)
  comb2 <- function(z) z * (z - 1) / 2
  somme_cellules <- sum(comb2(tab))
  somme_lignes <- sum(comb2(rowSums(tab)))
  somme_colonnes <- sum(comb2(colSums(tab)))
  total <- comb2(sum(tab))
  attendu <- somme_lignes * somme_colonnes / total
  maximum <- (somme_lignes + somme_colonnes) / 2
  if (isTRUE(all.equal(maximum, attendu))) return(NA_real_)
  (somme_cellules - attendu) / (maximum - attendu)
}

seeds_stabilite <- 101:130
clusters_stabilite <- purrr::map(seeds_stabilite, function(seed) {
  set.seed(seed)
  stats::kmeans(
    as.matrix(coord_retenues),
    centers = k_retenu,
    nstart = 50,
    iter.max = 1000
  )$cluster
})

ari_vs_reference <- purrr::map_dbl(
  clusters_stabilite,
  ~ adjusted_rand_index(res_kmeans$cluster, .x)
)

stabilite_clustering <- tibble::tibble(
  nb_axes = nb_axes_retenus,
  k = k_retenu,
  nb_repetitions = length(seeds_stabilite),
  ari_moyen_vs_reference = mean(ari_vs_reference, na.rm = TRUE),
  ari_min_vs_reference = min(ari_vs_reference, na.rm = TRUE),
  ari_mediane_vs_reference = stats::median(ari_vs_reference, na.rm = TRUE),
  conclusion_stabilite = dplyr::case_when(
    ari_moyen_vs_reference >= 0.90 ~ "stable",
    ari_moyen_vs_reference >= 0.75 ~ "moderee",
    TRUE ~ "fragile"
  )
)

readr::write_csv(
  stabilite_clustering,
  file.path("outputs", "tables", "05_stabilite_clustering_principale.csv")
)

# ------------------------------------------------------------
# Tests statistiques de differenciation des clusters
# ------------------------------------------------------------

variables_quanti_tests <- c(
  "previous_qualification_grade",
  "admission_grade",
  "age_at_enrollment",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade"
) |>
  intersect(names(donnees_clusters))

extraire_stat <- function(test, champ) {
  if (is.list(test) && champ %in% names(test)) {
    as.numeric(test[[champ]][1])
  } else {
    NA_real_
  }
}

tests_quanti <- purrr::map_dfr(variables_quanti_tests, function(variable_test) {
  objet_test <- tryCatch(
    stats::kruskal.test(
      x = donnees_clusters[[variable_test]],
      g = donnees_clusters$cluster_kmeans
    ),
    error = function(e) NULL
  )
  moyennes <- donnees_clusters |>
    dplyr::group_by(.data$cluster_kmeans) |>
    dplyr::summarise(moyenne = mean(.data[[variable_test]], na.rm = TRUE), .groups = "drop")

  tibble::tibble(
    variable = variable_test,
    test = "Kruskal-Wallis",
    statistique = extraire_stat(objet_test, "statistic"),
    ddl = extraire_stat(objet_test, "parameter"),
    p_value = extraire_stat(objet_test, "p.value"),
    cluster_moyenne_min = as.character(moyennes$cluster_kmeans[which.min(moyennes$moyenne)]),
    cluster_moyenne_max = as.character(moyennes$cluster_kmeans[which.max(moyennes$moyenne)]),
    interpretation = dplyr::if_else(
      !is.na(extraire_stat(objet_test, "p.value")) && extraire_stat(objet_test, "p.value") < 0.05,
      "distribution differente selon les clusters",
      "difference non nette au seuil 5%"
    )
  )
})

readr::write_csv(
  tests_quanti,
  file.path("outputs", "tables", "05_tests_quanti_par_cluster.csv")
)

variables_quali_tests <- c(
  "daytime_evening_attendance",
  "debtor",
  "tuition_fees_up_to_date",
  "gender",
  "scholarship_holder",
  "course",
  "previous_qualification",
  "displaced"
) |>
  intersect(names(donnees_clusters))

cramer_v <- function(tab) {
  chi <- tryCatch(suppressWarnings(stats::chisq.test(tab)), error = function(e) NULL)
  n <- sum(tab)
  denom <- n * (min(nrow(tab) - 1, ncol(tab) - 1))
  if (denom == 0) return(NA_real_)
  sqrt(extraire_stat(chi, "statistic") / denom)
}

tests_quali <- purrr::map_dfr(variables_quali_tests, function(variable_test) {
  tab <- table(donnees_clusters$cluster_kmeans, donnees_clusters[[variable_test]])
  objet_test <- tryCatch(suppressWarnings(stats::chisq.test(tab)), error = function(e) NULL)
  p_value <- extraire_stat(objet_test, "p.value")
  tibble::tibble(
    variable = variable_test,
    test = "Khi-deux",
    statistique = extraire_stat(objet_test, "statistic"),
    ddl = extraire_stat(objet_test, "parameter"),
    p_value = p_value,
    cramer_v = cramer_v(tab),
    interpretation = dplyr::if_else(
      !is.na(p_value) && p_value < 0.05,
      "repartition differente selon les clusters",
      "difference non nette au seuil 5%"
    )
  )
})

readr::write_csv(
  tests_quali,
  file.path("outputs", "tables", "05_tests_quali_par_cluster.csv")
)

tab_cluster_target <- table(donnees_clusters$cluster_kmeans, donnees_clusters$target)
test_cluster_target <- tryCatch(
  suppressWarnings(stats::chisq.test(tab_cluster_target)),
  error = function(e) NULL
)
p_value_cluster_target <- extraire_stat(test_cluster_target, "p.value")

test_cluster_target_table <- tibble::tibble(
  variable = "cluster_kmeans_x_target",
  test = "Khi-deux",
  statistique = extraire_stat(test_cluster_target, "statistic"),
  ddl = extraire_stat(test_cluster_target, "parameter"),
  p_value = p_value_cluster_target,
  cramer_v = cramer_v(tab_cluster_target),
  interpretation = dplyr::if_else(
    !is.na(p_value_cluster_target) && p_value_cluster_target < 0.05,
    "target est associee aux clusters apres construction non supervisee",
    "association cluster-target non nette au seuil 5%"
  )
)

readr::write_csv(
  test_cluster_target_table,
  file.path("outputs", "tables", "05_test_cluster_target.csv")
)

effets_variables_clusters <- dplyr::bind_rows(
  tests_quanti |>
    dplyr::transmute(variable, famille = "quantitative", p_value, effet = NA_real_, mesure_effet = "non_calcule"),
  tests_quali |>
    dplyr::transmute(variable, famille = "qualitative", p_value, effet = cramer_v, mesure_effet = "V de Cramer"),
  test_cluster_target_table |>
    dplyr::transmute(variable, famille = "target", p_value, effet = cramer_v, mesure_effet = "V de Cramer")
) |>
  dplyr::mutate(
    force_statistique = dplyr::case_when(
      is.na(p_value) ~ "non_disponible",
      p_value < 0.001 ~ "tres_marquee",
      p_value < 0.05 ~ "marquee",
      TRUE ~ "non_nette"
    )
  ) |>
  dplyr::arrange(.data$p_value)

readr::write_csv(
  effets_variables_clusters,
  file.path("outputs", "tables", "05_effets_variables_clusters.csv")
)

# ------------------------------------------------------------
# Figures principales
# ------------------------------------------------------------

validation_axes_retenus <- grille_validation_export |>
  dplyr::filter(.data$nb_axes == nb_axes_retenus)

p_coude <- validation_axes_retenus |>
  ggplot2::ggplot(ggplot2::aes(x = .data$k, y = .data$inertie_intra_totale)) +
  ggplot2::geom_line(color = "#2F6F7E", linewidth = 0.8) +
  ggplot2::geom_point(size = 2.5, color = "#2F6F7E") +
  ggplot2::geom_vline(xintercept = k_retenu, linetype = "dashed", color = "#B23A48") +
  ggplot2::labs(
    title = "Methode du coude - FAMD principale reduite",
    subtitle = paste("Courbe affichee pour", nb_axes_retenus, "axes FAMD retenus."),
    x = "Nombre de clusters k",
    y = "Inertie intra-classe totale"
  ) +
  ggplot2::scale_x_continuous(breaks = k_candidats) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_principale_methode_coude.png"),
  p_coude,
  width = 8,
  height = 5,
  dpi = 300
)

p_silhouette <- validation_axes_retenus |>
  ggplot2::ggplot(ggplot2::aes(x = .data$k, y = .data$silhouette_moyenne)) +
  ggplot2::geom_line(color = "#3B7A57", linewidth = 0.8) +
  ggplot2::geom_point(size = 2.5, color = "#3B7A57") +
  ggplot2::geom_text(ggplot2::aes(label = round(.data$silhouette_moyenne, 3)), vjust = -0.8, size = 3.1) +
  ggplot2::geom_vline(xintercept = k_retenu, linetype = "dashed", color = "#B23A48") +
  ggplot2::labs(
    title = "Silhouette moyenne - FAMD principale reduite",
    subtitle = paste("Solution recommandee : k =", k_retenu, "sur", nb_axes_retenus, "axes."),
    x = "Nombre de clusters k",
    y = "Silhouette moyenne"
  ) +
  ggplot2::scale_x_continuous(breaks = k_candidats) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_principale_silhouette_moyenne.png"),
  p_silhouette,
  width = 8,
  height = 5,
  dpi = 300
)

centroides_projection <- as.data.frame(res_kmeans$centers) |>
  tibble::rownames_to_column("cluster_kmeans") |>
  dplyr::mutate(cluster_kmeans = factor(.data$cluster_kmeans, levels = levels(clusters_individus$cluster_kmeans)))

p_clusters <- clusters_individus |>
  ggplot2::ggplot(ggplot2::aes(x = .data[["Dim.1"]], y = .data[["Dim.2"]], color = .data$cluster_kmeans)) +
  ggplot2::geom_point(alpha = 0.35, size = 1.1) +
  ggplot2::geom_point(
    data = centroides_projection,
    ggplot2::aes(x = .data[["Dim.1"]], y = .data[["Dim.2"]], fill = .data$cluster_kmeans),
    shape = 21,
    color = "black",
    size = 4,
    stroke = 0.8,
    inherit.aes = FALSE
  ) +
  ggplot2::labs(
    title = paste("K-means sur FAMD principale reduite - k =", k_retenu),
    subtitle = paste("Clusters construits sur", nb_axes_retenus, "axes FAMD, projetes sur Dim.1-Dim.2."),
    x = "Dimension 1",
    y = "Dimension 2",
    color = "Cluster",
    fill = "Centroide"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_principale_clusters_famd.png"),
  p_clusters,
  width = 8,
  height = 6,
  dpi = 300
)

p_cluster_target <- croisement_cluster_target |>
  ggplot2::ggplot(ggplot2::aes(x = .data$cluster_kmeans, y = .data$proportion, fill = .data$target)) +
  ggplot2::geom_col(width = 0.75) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Composition des clusters selon Target - FAMD principale reduite",
    subtitle = "Target est utilisee uniquement apres clustering pour caracteriser les groupes.",
    x = "Cluster k-means",
    y = "Proportion dans le cluster",
    fill = "Target"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "05_principale_composition_clusters_target.png"),
  p_cluster_target,
  width = 7,
  height = 5,
  dpi = 300
)

preparer_heatmap <- function(profils) {
  profils |>
    dplyr::select(
      cluster = cluster_kmeans,
      admission_grade = moyenne_admission_grade,
      s1_evaluations = moyenne_1st_sem_evaluations,
      s1_approved = moyenne_1st_sem_approved,
      s1_grade = moyenne_1st_sem_grade,
      s2_approved = moyenne_2nd_sem_approved,
      s2_grade = moyenne_2nd_sem_grade,
      proportion_dropout = proportion_dropout
    ) |>
    tidyr::pivot_longer(cols = -.data$cluster, names_to = "indicateur", values_to = "valeur") |>
    dplyr::group_by(.data$indicateur) |>
    dplyr::mutate(valeur_standardisee = as.numeric(scale(.data$valeur))) |>
    dplyr::ungroup()
}

p_profils <- preparer_heatmap(profils_clusters) |>
  ggplot2::ggplot(ggplot2::aes(x = .data$indicateur, y = .data$cluster, fill = .data$valeur_standardisee)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.4) +
  ggplot2::scale_fill_gradient2(low = "#3B7A57", mid = "white", high = "#B23A48", midpoint = 0) +
  ggplot2::labs(
    title = "Profils academiques compares - clustering principal",
    subtitle = "Indicateurs standardises entre clusters pour faciliter la comparaison.",
    x = NULL,
    y = "Cluster",
    fill = "Valeur standardisee"
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))

ggplot2::ggsave(
  file.path("outputs", "figures", "05_principale_profils_academiques_clusters.png"),
  p_profils,
  width = 9,
  height = 5.5,
  dpi = 300
)

res_hclust <- stats::hclust(stats::dist(as.matrix(coord_retenues)), method = "ward.D2")
saveRDS(res_hclust, file.path("outputs", "models", "05_cah_principale.rds"))

png(file.path("outputs", "figures", "05_principale_dendrogramme_cah.png"), width = 1200, height = 800, res = 150)
plot(
  res_hclust,
  labels = FALSE,
  hang = -1,
  main = paste("CAH Ward - FAMD principale reduite (k =", k_retenu, ")"),
  xlab = "",
  sub = "Validation complementaire sur les memes coordonnees FAMD que k-means"
)
rect.hclust(res_hclust, k = k_retenu, border = 2:(k_retenu + 1))
dev.off()

# Exports de compatibilite utiles aux anciens rapports/interfaces.
readr::write_csv(
  tibble::tibble(
    k_recommande = k_retenu,
    nb_axes_retenus = nb_axes_retenus,
    critere = "recalcul_famd_principale_reduite",
    commentaire = paste0(
      "Solution recommandee apres grille axes-k : k = ",
      k_retenu,
      ", nb_axes = ",
      nb_axes_retenus,
      ", silhouette = ",
      round(solution_recommandee$silhouette_moyenne[[1]], 3),
      "."
    )
  ),
  file.path("outputs", "tables", "05_k_recommande.csv")
)
readr::write_csv(
  recommandation_solution |>
    dplyr::transmute(
      solution_recommandee,
      justification_statistique = critere,
      justification_interpretation = commentaire,
      limite = "Solution exploratoire a lire avec les tests de stabilite et les tests statistiques par cluster.",
      phrase_pour_rapport = commentaire,
      phrase_pour_soutenance = commentaire
    ),
  file.path("outputs", "tables", "05_recommandation_solution_clustering.csv")
)
readr::write_csv(clusters_individus, file.path("outputs", "tables", "05_clusters_individus.csv"))
readr::write_csv(croisement_cluster_target, file.path("outputs", "tables", "05_croisement_cluster_target.csv"))
readr::write_csv(profils_clusters, file.path("outputs", "tables", "05_profils_clusters_kmeans.csv"))
readr::write_csv(profils_clusters, file.path("outputs", "tables", "05_profils_clusters_interpretes.csv"))
readr::write_csv(silhouette_par_cluster, file.path("outputs", "tables", "05_silhouette_par_cluster.csv"))
readr::write_csv(
  validation_axes_retenus |> dplyr::select(.data$k, .data$silhouette_moyenne),
  file.path("outputs", "tables", "05_kmeans_silhouette.csv")
)
readr::write_csv(
  validation_axes_retenus |> dplyr::select(.data$k, inertie_intra = .data$inertie_intra_totale),
  file.path("outputs", "tables", "05_kmeans_methode_coude.csv")
)

message(
  "Clustering principal termine : nb_axes = ",
  nb_axes_retenus,
  ", k = ",
  k_retenu,
  ", silhouette moyenne = ",
  round(solution_recommandee$silhouette_moyenne[[1]], 3),
  ", stabilite = ",
  stabilite_clustering$conclusion_stabilite[[1]],
  "."
)
