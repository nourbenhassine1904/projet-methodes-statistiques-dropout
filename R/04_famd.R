# ============================================================
# 04_famd.R
# Objectif : FAMD globale et FAMD precoce defendables
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

dir.create(file.path("outputs", "models"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)

chemin_rds <- file.path("data", "processed", "dropout_clean.rds")

if (!file.exists(chemin_rds)) {
  source(file.path("R", "02_preparation_donnees.R"))
}

donnees <- readRDS(chemin_rds)

if (!"target" %in% names(donnees)) {
  stop("La variable target est absente des donnees preparees.")
}

# ------------------------------------------------------------
# Definition des variables actives
# ------------------------------------------------------------

variables_actives_globale <- c(
  "gender",
  "age_at_enrollment",
  "displaced",
  "educational_special_needs",
  "international",
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  "daytime_evening_attendance",
  "previous_qualification",
  "previous_qualification_grade",
  "admission_grade",
  "curricular_units_1st_sem_enrolled",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_1st_sem_without_evaluations",
  "curricular_units_2nd_sem_enrolled",
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade",
  "curricular_units_2nd_sem_without_evaluations"
)

variables_actives_precoce <- c(
  "gender",
  "age_at_enrollment",
  "displaced",
  "educational_special_needs",
  "international",
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  "daytime_evening_attendance",
  "previous_qualification",
  "previous_qualification_grade",
  "admission_grade",
  "curricular_units_1st_sem_enrolled",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_1st_sem_without_evaluations"
)

variables_qualitatives_famd <- c(
  "gender",
  "displaced",
  "educational_special_needs",
  "international",
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  "daytime_evening_attendance",
  "previous_qualification",
  "target"
)

variables_interdites_actives <- c("target", "dropout_binary", "success_binary")

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

classe_variable <- function(x) {
  paste(class(x), collapse = " / ")
}

verifier_variables_actives <- function(variables, nom_analyse) {
  variables_interdites <- intersect(variables, variables_interdites_actives)

  if (length(variables_interdites) > 0) {
    stop(
      "Variables interdites dans la FAMD ",
      nom_analyse,
      " : ",
      paste(variables_interdites, collapse = ", ")
    )
  }

  variables_presentes <- intersect(variables, names(donnees))
  variables_absentes <- setdiff(variables, variables_presentes)

  if (length(variables_absentes) > 0) {
    warning(
      "Variables absentes pour la FAMD ",
      nom_analyse,
      " : ",
      paste(variables_absentes, collapse = ", ")
    )
  }

  variables_presentes
}

preparer_donnees_famd <- function(variables_actives) {
  donnees_famd <- donnees |>
    dplyr::select(dplyr::all_of(variables_actives), "target")

  variables_facteurs <- intersect(variables_qualitatives_famd, names(donnees_famd))

  donnees_famd |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(variables_facteurs), as.factor),
      dplyr::across(where(is.character), as.factor)
    )
}

selection_variables_famd <- function(donnees_famd, variables_actives) {
  tibble::tibble(
    variable = variables_actives,
    classe = purrr::map_chr(donnees[variables_actives], classe_variable),
    classe_famd = purrr::map_chr(donnees_famd[variables_actives], classe_variable),
    nb_modalites = purrr::map_int(donnees[variables_actives], ~ dplyr::n_distinct(.x, na.rm = TRUE)),
    type_famd = purrr::map_chr(
      donnees_famd[variables_actives],
      ~ if (inherits(.x, "factor")) "qualitative" else "quantitative"
    ),
    role_famd = "active"
  )
}

extraire_infos_variables <- function(res_famd) {
  infos_variables <- factoextra::get_famd_var(res_famd)

  coord_variables <- if (!is.null(infos_variables$coord)) {
    infos_variables$coord
  } else if (!is.null(res_famd$var$coord)) {
    res_famd$var$coord
  } else {
    matrix(nrow = 0, ncol = 0)
  }

  contrib_variables <- if (!is.null(infos_variables$contrib)) {
    infos_variables$contrib
  } else if (!is.null(res_famd$var$contrib)) {
    res_famd$var$contrib
  } else {
    matrix(nrow = 0, ncol = 0)
  }

  list(
    coord = coord_variables |>
      as.data.frame() |>
      tibble::rownames_to_column("variable"),
    contrib = contrib_variables |>
      as.data.frame() |>
      tibble::rownames_to_column("variable")
  )
}

contributions_axes_1_2 <- function(contrib_variables) {
  contrib_axes <- contrib_variables |>
    dplyr::select("variable", dplyr::any_of(c("Dim.1", "Dim.2")))

  if ("Dim.1" %in% names(contrib_axes)) {
    contrib_axes <- contrib_axes |>
      dplyr::arrange(dplyr::desc(.data[["Dim.1"]]))
  }

  contrib_axes
}

cumul_inertie <- function(eig_famd, n_axes) {
  eig_famd |>
    dplyr::slice_head(n = min(n_axes, nrow(eig_famd))) |>
    dplyr::summarise(cumul = sum(.data$variance.percent, na.rm = TRUE)) |>
    dplyr::pull(.data$cumul)
}

valeur_inertie <- function(eig_famd, axe, colonne) {
  valeur <- eig_famd |>
    dplyr::filter(.data$axe == .env$axe) |>
    dplyr::pull({{ colonne }})

  if (length(valeur) == 0) {
    NA_real_
  } else {
    valeur[[1]]
  }
}

top_contributions <- function(contrib_axes, axe, n = 5) {
  if (!axe %in% names(contrib_axes)) {
    return("contributions non disponibles")
  }

  variables <- contrib_axes |>
    dplyr::filter(!is.na(.data[[axe]])) |>
    dplyr::arrange(dplyr::desc(.data[[axe]])) |>
    dplyr::slice_head(n = n) |>
    dplyr::pull(.data$variable)

  if (length(variables) == 0) {
    "contributions non disponibles"
  } else {
    paste(variables, collapse = ", ")
  }
}

libelle_axe <- function(eig_famd, dim_nom, libelle_court) {
  inertie <- valeur_inertie(eig_famd, dim_nom, variance.percent)

  if (is.na(inertie)) {
    libelle_court
  } else {
    paste0(libelle_court, " (", round(inertie, 1), "%)")
  }
}

theme_famd <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

creer_figure_individus <- function(coord_ind, eig_famd, titre) {
  ggplot2::ggplot(
    coord_ind,
    ggplot2::aes(x = .data[["Dim.1"]], y = .data[["Dim.2"]], color = .data$target)
  ) +
    ggplot2::geom_point(size = 0.75, alpha = 0.35) +
    ggplot2::labs(
      title = paste0(titre, " - projection des individus Dim.1-Dim.2"),
      subtitle = "Les groupes peuvent se chevaucher car cette projection 2D ne resume pas toute l'information.",
      x = libelle_axe(eig_famd, "Dim.1", "Dim.1"),
      y = libelle_axe(eig_famd, "Dim.2", "Dim.2"),
      color = "Target"
    ) +
    theme_famd()
}

creer_figure_variables_top <- function(contrib_axes, titre) {
  if (!all(c("Dim.1", "Dim.2") %in% names(contrib_axes))) {
    return(NULL)
  }

  contrib_long <- contrib_axes |>
    tidyr::pivot_longer(
      cols = c("Dim.1", "Dim.2"),
      names_to = "axe",
      values_to = "contribution"
    ) |>
    dplyr::filter(!is.na(.data$contribution)) |>
    dplyr::group_by(.data$axe) |>
    dplyr::slice_max(.data$contribution, n = 12, with_ties = FALSE) |>
    dplyr::ungroup()

  ggplot2::ggplot(
    contrib_long,
    ggplot2::aes(
      x = stats::reorder(.data$variable, .data$contribution),
      y = .data$contribution,
      fill = .data$axe
    )
  ) +
    ggplot2::geom_col(alpha = 0.85) +
    ggplot2::coord_flip() +
    ggplot2::facet_wrap(ggplot2::vars(.data$axe), scales = "free_y") +
    ggplot2::labs(
      title = paste0(titre, " - variables les plus contributives"),
      subtitle = "Affichage limite aux principales contributions des axes 1 et 2 pour eviter le chevauchement.",
      x = "Variable",
      y = "Contribution",
      fill = "Axe"
    ) +
    theme_famd()
}

creer_figure_barycentres <- function(coord_ind, eig_famd, titre) {
  barycentres <- coord_ind |>
    dplyr::group_by(.data$target) |>
    dplyr::summarise(
      Dim.1 = mean(.data[["Dim.1"]], na.rm = TRUE),
      Dim.2 = mean(.data[["Dim.2"]], na.rm = TRUE),
      effectif = dplyr::n(),
      .groups = "drop"
    )

  ggplot2::ggplot() +
    ggplot2::geom_point(
      data = coord_ind,
      ggplot2::aes(x = .data[["Dim.1"]], y = .data[["Dim.2"]], color = .data$target),
      size = 0.65,
      alpha = 0.12
    ) +
    ggplot2::geom_point(
      data = barycentres,
      ggplot2::aes(x = .data[["Dim.1"]], y = .data[["Dim.2"]], color = .data$target),
      size = 4
    ) +
    ggplot2::geom_label(
      data = barycentres,
      ggplot2::aes(
        x = .data[["Dim.1"]],
        y = .data[["Dim.2"]],
        label = paste0(.data$target, " (n=", .data$effectif, ")"),
        color = .data$target
      ),
      fill = "white",
      linewidth = 0.2,
      show.legend = FALSE,
      nudge_y = 0.25
    ) +
    ggplot2::labs(
      title = paste0(titre, " - barycentres par Target"),
      subtitle = "Les barycentres resument une tendance globale; ils n'indiquent pas une separation parfaite.",
      x = libelle_axe(eig_famd, "Dim.1", "Dim.1"),
      y = libelle_axe(eig_famd, "Dim.2", "Dim.2"),
      color = "Target"
    ) +
    theme_famd()
}

executer_famd <- function(nom_analyse, titre_analyse, variables_recommandees, usage_recommande) {
  message("Debut de la FAMD ", nom_analyse, ".")

  variables_actives <- verifier_variables_actives(variables_recommandees, nom_analyse)
  donnees_famd <- preparer_donnees_famd(variables_actives)
  indice_target <- which(names(donnees_famd) == "target")

  selection_famd <- selection_variables_famd(donnees_famd, variables_actives)

  if (any(selection_famd$type_famd == "qualitative" & selection_famd$classe_famd != "factor")) {
    stop("Certaines variables qualitatives ne sont pas factor apres preparation.")
  }

  set.seed(123)
  res_famd <- FactoMineR::FAMD(
    donnees_famd,
    ncp = 10,
    graph = FALSE,
    sup.var = indice_target
  )

  prefixe <- paste0("04_", nom_analyse, "_famd")

  saveRDS(
    res_famd,
    file.path("outputs", "models", paste0("04_resultat_famd_", nom_analyse, ".rds"))
  )

  readr::write_csv(
    selection_famd,
    file.path("outputs", "tables", paste0(prefixe, "_variables_actives.csv"))
  )

  eig_famd <- factoextra::get_eigenvalue(res_famd) |>
    as.data.frame() |>
    tibble::rownames_to_column("axe")

  readr::write_csv(
    eig_famd,
    file.path("outputs", "tables", paste0(prefixe, "_valeurs_propres.csv"))
  )

  coord_ind <- as.data.frame(res_famd$ind$coord) |>
    tibble::rownames_to_column("id_individu") |>
    dplyr::bind_cols(tibble::tibble(target = donnees$target))

  readr::write_csv(
    coord_ind,
    file.path("outputs", "tables", paste0(prefixe, "_coordonnees_individus.csv"))
  )

  infos_variables <- extraire_infos_variables(res_famd)
  contrib_axes <- contributions_axes_1_2(infos_variables$contrib)

  readr::write_csv(
    contrib_axes,
    file.path("outputs", "tables", paste0(prefixe, "_contributions_axes_1_2.csv"))
  )

  p_scree <- factoextra::fviz_screeplot(res_famd, addlabels = TRUE) +
    ggplot2::labs(title = paste0(titre_analyse, " - eboulis des valeurs propres")) +
    theme_famd()

  ggplot2::ggsave(
    file.path("outputs", "figures", paste0(prefixe, "_screeplot.png")),
    p_scree,
    width = 7,
    height = 5,
    dpi = 300
  )

  p_ind <- creer_figure_individus(coord_ind, eig_famd, titre_analyse)

  ggplot2::ggsave(
    file.path("outputs", "figures", paste0(prefixe, "_individus_target.png")),
    p_ind,
    width = 8,
    height = 6,
    dpi = 300
  )

  p_variables <- creer_figure_variables_top(contrib_axes, titre_analyse)

  if (!is.null(p_variables)) {
    ggplot2::ggsave(
      file.path("outputs", "figures", paste0(prefixe, "_variables_top.png")),
      p_variables,
      width = 9,
      height = 6,
      dpi = 300
    )
  }

  p_barycentres <- creer_figure_barycentres(coord_ind, eig_famd, titre_analyse)

  ggplot2::ggsave(
    file.path("outputs", "figures", paste0(prefixe, "_barycentres_target.png")),
    p_barycentres,
    width = 8,
    height = 6,
    dpi = 300
  )

  resume <- tibble::tibble(
    analyse = nom_analyse,
    nb_variables_actives = length(variables_actives),
    inertie_dim1 = valeur_inertie(eig_famd, "Dim.1", variance.percent),
    inertie_dim2 = valeur_inertie(eig_famd, "Dim.2", variance.percent),
    inertie_cumulee_dim1_dim2 = valeur_inertie(eig_famd, "Dim.2", cumulative.variance.percent),
    inertie_cumulee_5_axes = cumul_inertie(eig_famd, 5),
    interpretation_dim1 = paste("Variables les plus contributives :", top_contributions(contrib_axes, "Dim.1")),
    interpretation_dim2 = paste("Variables les plus contributives :", top_contributions(contrib_axes, "Dim.2")),
    usage_recommande = usage_recommande
  )

  message("FAMD ", nom_analyse, " terminee.")

  list(
    res_famd = res_famd,
    selection = selection_famd,
    eig = eig_famd,
    coord_ind = coord_ind,
    coord_var = infos_variables$coord,
    contrib_axes = contrib_axes,
    figure_scree = p_scree,
    figure_ind = p_ind,
    figure_variables = p_variables,
    figure_barycentres = p_barycentres,
    resume = resume
  )
}

# ------------------------------------------------------------
# Estimation des deux analyses
# ------------------------------------------------------------

resultat_globale <- executer_famd(
  nom_analyse = "globale",
  titre_analyse = "FAMD globale",
  variables_recommandees = variables_actives_globale,
  usage_recommande = "Analyse principale des profils etudiants avec informations individuelles, administratives et academiques des deux semestres."
)

resultat_precoce <- executer_famd(
  nom_analyse = "precoce",
  titre_analyse = "FAMD precoce",
  variables_recommandees = variables_actives_precoce,
  usage_recommande = "Analyse des profils avec les informations disponibles plus tot dans le parcours, sans variables du second semestre."
)

# ------------------------------------------------------------
# Table comparative globale / precoce
# ------------------------------------------------------------

comparaison_famd <- dplyr::bind_rows(
  resultat_globale$resume,
  resultat_precoce$resume
)

readr::write_csv(
  comparaison_famd,
  file.path("outputs", "tables", "04_comparaison_famd_globale_precoce.csv")
)

# ------------------------------------------------------------
# Exports de compatibilite : les anciens fichiers = FAMD globale
# ------------------------------------------------------------

saveRDS(resultat_globale$res_famd, file.path("outputs", "models", "04_resultat_famd.rds"))

readr::write_csv(
  resultat_globale$selection,
  file.path("outputs", "tables", "04_famd_variables_actives.csv")
)

readr::write_csv(
  resultat_globale$eig,
  file.path("outputs", "tables", "04_famd_valeurs_propres.csv")
)

readr::write_csv(
  resultat_globale$contrib_axes,
  file.path("outputs", "tables", "04_famd_contributions_axes_1_2.csv")
)

readr::write_csv(
  resultat_globale$coord_ind,
  file.path("outputs", "tables", "04_famd_coordonnees_individus.csv")
)

readr::write_csv(
  resultat_globale$coord_var,
  file.path("outputs", "tables", "04_famd_coordonnees_variables.csv")
)

ggplot2::ggsave(
  file.path("outputs", "figures", "04_famd_screeplot.png"),
  resultat_globale$figure_scree,
  width = 7,
  height = 5,
  dpi = 300
)

ggplot2::ggsave(
  file.path("outputs", "figures", "04_famd_individus_target.png"),
  resultat_globale$figure_ind,
  width = 8,
  height = 6,
  dpi = 300
)

if (!is.null(resultat_globale$figure_variables)) {
  ggplot2::ggsave(
    file.path("outputs", "figures", "04_famd_variables.png"),
    resultat_globale$figure_variables,
    width = 9,
    height = 6,
    dpi = 300
  )

  ggplot2::ggsave(
    file.path("outputs", "figures", "04_famd_contributions_axes_1_2.png"),
    resultat_globale$figure_variables,
    width = 9,
    height = 6,
    dpi = 300
  )
}

# ------------------------------------------------------------
# FAMD principale reduite : version technique defendable
# ------------------------------------------------------------

message("Debut de la FAMD principale reduite.")

variables_quanti_principale <- c(
  "previous_qualification_grade",
  "admission_grade",
  "age_at_enrollment",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade"
)

variables_quali_principale <- c(
  "daytime_evening_attendance",
  "debtor",
  "tuition_fees_up_to_date",
  "gender",
  "scholarship_holder"
)

variables_actives_principale <- c(
  variables_quanti_principale,
  variables_quali_principale
)

variables_supplementaires_principale <- c(
  "target",
  "course",
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade",
  "unemployment_rate",
  "inflation_rate",
  "gdp",
  "application_mode",
  "application_order",
  "previous_qualification",
  "mothers_qualification",
  "fathers_qualification",
  "displaced"
)

variables_exclues_principale <- c(
  "marital_status",
  "nacionality",
  "mothers_occupation",
  "fathers_occupation",
  "educational_special_needs",
  "international",
  "curricular_units_1st_sem_without_evaluations",
  "curricular_units_2nd_sem_without_evaluations",
  "dropout_binary",
  "success_binary"
)

variables_semestre_2 <- grep("2nd_sem", names(donnees), value = TRUE)
variables_economiques <- c("unemployment_rate", "inflation_rate", "gdp")

variables_manquantes_principale <- setdiff(
  c(variables_actives_principale, variables_supplementaires_principale),
  names(donnees)
)

if (length(variables_manquantes_principale) > 0) {
  stop(
    "Variables manquantes pour la FAMD principale reduite : ",
    paste(variables_manquantes_principale, collapse = ", ")
  )
}

if ("target" %in% variables_actives_principale) {
  stop("Controle FAMD principale reduite : target ne doit jamais etre active.")
}

variables_derivees_actives <- intersect(c("dropout_binary", "success_binary"), variables_actives_principale)
if (length(variables_derivees_actives) > 0) {
  stop(
    "Controle FAMD principale reduite : variables derivees de target actives : ",
    paste(variables_derivees_actives, collapse = ", ")
  )
}

variables_s2_actives <- intersect(variables_semestre_2, variables_actives_principale)
if (length(variables_s2_actives) > 0) {
  stop(
    "Controle FAMD principale reduite : variables du semestre 2 actives : ",
    paste(variables_s2_actives, collapse = ", ")
  )
}

variables_eco_actives <- intersect(variables_economiques, variables_actives_principale)
if (length(variables_eco_actives) > 0) {
  stop(
    "Controle FAMD principale reduite : variables economiques actives : ",
    paste(variables_eco_actives, collapse = ", ")
  )
}

if (length(intersect(variables_exclues_principale, variables_actives_principale)) > 0) {
  stop("Controle FAMD principale reduite : une variable explicitement exclue est active.")
}

donnees_famd_principale <- donnees |>
  dplyr::select(
    dplyr::all_of(variables_actives_principale),
    dplyr::all_of(variables_supplementaires_principale)
  ) |>
  dplyr::mutate(
    dplyr::across(dplyr::all_of(c(variables_quali_principale, "target", "course", "application_mode",
                                  "previous_qualification", "mothers_qualification",
                                  "fathers_qualification", "displaced")), as.factor),
    dplyr::across(where(is.character), as.factor)
  )

indices_supplementaires <- match(variables_supplementaires_principale, names(donnees_famd_principale))

set.seed(123)
res_famd_principale <- FactoMineR::FAMD(
  donnees_famd_principale,
  ncp = min(10, length(variables_actives_principale)),
  graph = FALSE,
  sup.var = indices_supplementaires
)

saveRDS(
  res_famd_principale,
  file.path("outputs", "models", "04_resultat_famd_principale_reduite.rds")
)

table_variables_actives_principale <- tibble::tibble(
  variable = variables_actives_principale,
  role = "active",
  type_statistique = dplyr::case_when(
    variable %in% variables_quanti_principale ~ "quantitative",
    variable %in% variables_quali_principale ~ "qualitative",
    TRUE ~ "non_precise"
  ),
  classe_R = purrr::map_chr(donnees_famd_principale[variables_actives_principale], classe_variable),
  commentaire = "Variable active de la FAMD principale reduite."
)

table_variables_supp_principale <- tibble::tibble(
  variable = variables_supplementaires_principale,
  role = "supplementaire_illustrative",
  type_statistique = purrr::map_chr(
    donnees_famd_principale[variables_supplementaires_principale],
    ~ if (inherits(.x, "factor")) "qualitative" else "quantitative"
  ),
  classe_R = purrr::map_chr(
    donnees_famd_principale[variables_supplementaires_principale],
    classe_variable
  ),
  commentaire = "Variable utilisee uniquement pour l'interpretation, non active."
)

readr::write_csv(
  table_variables_actives_principale,
  file.path("outputs", "tables", "04_principale_variables_actives.csv")
)

readr::write_csv(
  table_variables_supp_principale,
  file.path("outputs", "tables", "04_principale_variables_supplementaires.csv")
)

eig_principale <- factoextra::get_eigenvalue(res_famd_principale) |>
  as.data.frame() |>
  tibble::rownames_to_column("axe")

readr::write_csv(
  eig_principale,
  file.path("outputs", "tables", "04_principale_valeurs_propres.csv")
)

infos_var_principale <- factoextra::get_famd_var(res_famd_principale)

contrib_principale <- infos_var_principale$contrib |>
  as.data.frame() |>
  tibble::rownames_to_column("variable") |>
  dplyr::select("variable", dplyr::any_of(c("Dim.1", "Dim.2"))) |>
  dplyr::arrange(dplyr::desc(.data[["Dim.1"]]))

cos2_principale <- infos_var_principale$cos2 |>
  as.data.frame() |>
  tibble::rownames_to_column("variable") |>
  dplyr::select("variable", dplyr::any_of(c("Dim.1", "Dim.2"))) |>
  dplyr::arrange(dplyr::desc(.data[["Dim.1"]]))

readr::write_csv(
  contrib_principale,
  file.path("outputs", "tables", "04_principale_contributions_axes_1_2.csv")
)

readr::write_csv(
  cos2_principale,
  file.path("outputs", "tables", "04_principale_cos2_variables_axes_1_2.csv")
)

coord_ind_principale <- as.data.frame(res_famd_principale$ind$coord) |>
  tibble::rownames_to_column("id_individu") |>
  dplyr::bind_cols(tibble::tibble(target = donnees$target))

readr::write_csv(
  coord_ind_principale,
  file.path("outputs", "tables", "04_principale_coordonnees_individus.csv")
)

p_scree_principale <- factoextra::fviz_screeplot(res_famd_principale, addlabels = TRUE) +
  ggplot2::labs(title = "FAMD principale reduite - eboulis des valeurs propres") +
  theme_famd()

ggplot2::ggsave(
  file.path("outputs", "figures", "04_principale_screeplot.png"),
  p_scree_principale,
  width = 7,
  height = 5,
  dpi = 300
)

p_ind_principale <- creer_figure_individus(
  coord_ind_principale,
  eig_principale,
  "FAMD principale reduite"
)

ggplot2::ggsave(
  file.path("outputs", "figures", "04_principale_individus_target.png"),
  p_ind_principale,
  width = 8,
  height = 6,
  dpi = 300
)

p_bary_principale <- creer_figure_barycentres(
  coord_ind_principale,
  eig_principale,
  "FAMD principale reduite"
)

ggplot2::ggsave(
  file.path("outputs", "figures", "04_principale_barycentres_target.png"),
  p_bary_principale,
  width = 8,
  height = 6,
  dpi = 300
)

p_var_principale <- creer_figure_variables_top(
  contrib_principale,
  "FAMD principale reduite"
)

if (!is.null(p_var_principale)) {
  ggplot2::ggsave(
    file.path("outputs", "figures", "04_principale_variables_top.png"),
    p_var_principale,
    width = 9,
    height = 6,
    dpi = 300
  )
}

message("FAMD principale reduite terminee.")
message("FAMD globale, FAMD precoce et FAMD principale reduite terminees.")
message("Sorties creees dans outputs/models, outputs/tables et outputs/figures.")
