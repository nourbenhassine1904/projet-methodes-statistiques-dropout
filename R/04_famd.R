# ============================================================
# 04_famd.R
# Objectif : FAMD sur une selection de variables interpretables
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

chemin_rds <- file.path("data", "processed", "dropout_clean.rds")

if (!file.exists(chemin_rds)) {
  source(file.path("R", "02_preparation_donnees.R"))
}

donnees <- readRDS(chemin_rds)

if (!"target" %in% names(donnees)) {
  stop("La variable target est absente des donnees preparees.")
}

# ------------------------------------------------------------
# Selection des variables actives
# ------------------------------------------------------------

# On evite d'utiliser automatiquement toutes les variables :
# certaines variables qualitatives ont beaucoup de modalites et rendent
# l'interpretation de la FAMD plus difficile pour une soutenance.
variables_actives_famd <- c(
  # Socio-demographique
  "gender",
  "age_at_enrollment",
  "displaced",
  "educational_special_needs",
  "international",
  # Socio-economique
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  # Parcours academique avant/apres inscription
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
  "curricular_units_2nd_sem_without_evaluations",
  # Contexte economique
  "unemployment_rate",
  "inflation_rate",
  "gdp"
)

variables_actives_famd <- intersect(variables_actives_famd, names(donnees))

selection_famd <- tibble::tibble(
  variable = variables_actives_famd,
  classe = purrr::map_chr(donnees[variables_actives_famd], ~ paste(class(.x), collapse = " / ")),
  nb_modalites = purrr::map_int(donnees[variables_actives_famd], ~ dplyr::n_distinct(.x, na.rm = TRUE))
)

readr::write_csv(selection_famd, file.path("outputs", "tables", "04_famd_variables_actives.csv"))

donnees_famd <- donnees |>
  select(all_of(variables_actives_famd), target)

indice_target <- which(names(donnees_famd) == "target")

# ------------------------------------------------------------
# Estimation de la FAMD
# ------------------------------------------------------------

set.seed(123)
res_famd <- FactoMineR::FAMD(
  donnees_famd,
  ncp = 10,
  graph = FALSE,
  sup.var = indice_target
)

saveRDS(res_famd, file.path("outputs", "models", "04_resultat_famd.rds"))

# ------------------------------------------------------------
# Exports tabulaires
# ------------------------------------------------------------

eig_famd <- factoextra::get_eigenvalue(res_famd) |>
  as.data.frame() |>
  tibble::rownames_to_column("axe")

readr::write_csv(eig_famd, file.path("outputs", "tables", "04_famd_valeurs_propres.csv"))

coord_ind <- as.data.frame(res_famd$ind$coord) |>
  tibble::rownames_to_column("id_individu") |>
  bind_cols(target = donnees$target)

readr::write_csv(coord_ind, file.path("outputs", "tables", "04_famd_coordonnees_individus.csv"))

infos_variables <- factoextra::get_famd_var(res_famd)

coord_variables <- if (!is.null(infos_variables$coord)) {
  infos_variables$coord
} else if (!is.null(res_famd$var$coord)) {
  res_famd$var$coord
} else {
  matrix(nrow = 0, ncol = 0)
}

var_coord <- coord_variables |>
  as.data.frame() |>
  tibble::rownames_to_column("variable")

readr::write_csv(var_coord, file.path("outputs", "tables", "04_famd_coordonnees_variables.csv"))

contrib_variables <- if (!is.null(infos_variables$contrib)) {
  infos_variables$contrib |>
    as.data.frame() |>
    tibble::rownames_to_column("variable")
} else if (!is.null(res_famd$var$contrib)) {
  res_famd$var$contrib |>
    as.data.frame() |>
    tibble::rownames_to_column("variable")
} else {
  tibble::tibble(variable = character())
}

contrib_axes_1_2 <- contrib_variables |>
  select(variable, any_of(c("Dim.1", "Dim.2")))

if ("Dim.1" %in% names(contrib_axes_1_2)) {
  contrib_axes_1_2 <- contrib_axes_1_2 |>
    arrange(desc(.data[["Dim.1"]]))
}

readr::write_csv(contrib_axes_1_2, file.path("outputs", "tables", "04_famd_contributions_axes_1_2.csv"))

# ------------------------------------------------------------
# Exports graphiques
# ------------------------------------------------------------

p_scree <- factoextra::fviz_screeplot(res_famd, addlabels = TRUE) +
  labs(title = "FAMD - Eboulis des valeurs propres")

ggsave(file.path("outputs", "figures", "04_famd_screeplot.png"), p_scree, width = 7, height = 5, dpi = 300)

p_ind <- factoextra::fviz_famd_ind(
  res_famd,
  habillage = donnees_famd$target,
  addEllipses = TRUE,
  repel = TRUE,
  geom = "point",
  alpha.ind = 0.55
) +
  labs(title = "FAMD - Individus colores par Target")

ggsave(file.path("outputs", "figures", "04_famd_individus_target.png"), p_ind, width = 8, height = 6, dpi = 300)

p_var <- factoextra::fviz_famd_var(
  res_famd,
  repel = TRUE
) +
  labs(title = "FAMD - Carte des variables actives")

ggsave(file.path("outputs", "figures", "04_famd_variables.png"), p_var, width = 8, height = 6, dpi = 300)

# Graphiques des principales contributions aux axes 1 et 2.
if (all(c("Dim.1", "Dim.2") %in% names(contrib_axes_1_2))) {
  contrib_long <- contrib_axes_1_2 |>
    tidyr::pivot_longer(
      cols = c("Dim.1", "Dim.2"),
      names_to = "axe",
      values_to = "contribution"
    ) |>
    group_by(axe) |>
    slice_max(contribution, n = 12, with_ties = FALSE) |>
    ungroup()

  p_contrib <- ggplot(contrib_long, aes(x = reorder(variable, contribution), y = contribution, fill = axe)) +
    geom_col(show.legend = FALSE) +
    coord_flip() +
    facet_wrap(~ axe, scales = "free_y") +
    labs(
      title = "FAMD - principales contributions aux axes 1 et 2",
      x = "Variable",
      y = "Contribution"
    )

  ggsave(file.path("outputs", "figures", "04_famd_contributions_axes_1_2.png"), p_contrib, width = 9, height = 6, dpi = 300)
}

message("FAMD terminee sur une selection de variables actives interpretables.")
