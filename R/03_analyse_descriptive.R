# ============================================================
# 03_analyse_descriptive.R
# Objectif : produire des sorties descriptives utiles au rapport
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

# ------------------------------------------------------------
# Fonctions utilitaires
# ------------------------------------------------------------

# Table croisee entre une variable qualitative et Target.
# Les pourcentages sont calcules dans chaque modalite de la variable.
table_target_par_categorie <- function(data, variable) {
  data |>
    count(.data[[variable]], target, name = "effectif") |>
    group_by(.data[[variable]]) |>
    mutate(
      total_modalite = sum(effectif),
      proportion = effectif / total_modalite,
      pourcentage = round(100 * proportion, 2)
    ) |>
    ungroup() |>
    rename(modalite = all_of(variable)) |>
    mutate(variable = variable, .before = 1)
}

# Graphique en barres empilees a 100 %, pratique pour comparer les profils.
plot_target_par_categorie <- function(data, variable, titre, x_label, nom_fichier) {
  table_plot <- table_target_par_categorie(data, variable)

  p <- ggplot(table_plot, aes(x = modalite, y = proportion, fill = target)) +
    geom_col(width = 0.75) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    labs(
      title = titre,
      x = x_label,
      y = "Proportion dans la modalite",
      fill = "Target"
    )

  ggsave(file.path("outputs", "figures", nom_fichier), p, width = 7, height = 5, dpi = 300)
  table_plot
}

# Resume numerique par Target pour les variables quantitatives.
resume_numerique_par_target <- function(data, variables) {
  data |>
    select(target, all_of(variables)) |>
    tidyr::pivot_longer(-target, names_to = "variable", values_to = "valeur") |>
    group_by(variable, target) |>
    summarise(
      n = sum(!is.na(valeur)),
      moyenne = mean(valeur, na.rm = TRUE),
      ecart_type = sd(valeur, na.rm = TRUE),
      mediane = median(valeur, na.rm = TRUE),
      q1 = quantile(valeur, 0.25, na.rm = TRUE),
      q3 = quantile(valeur, 0.75, na.rm = TRUE),
      min = min(valeur, na.rm = TRUE),
      max = max(valeur, na.rm = TRUE),
      .groups = "drop"
    )
}

# Boxplot d'une variable quantitative selon Target.
plot_numerique_par_target <- function(data, variable, titre, y_label, nom_fichier) {
  p <- ggplot(data, aes(x = target, y = .data[[variable]], fill = target)) +
    geom_boxplot(show.legend = FALSE, alpha = 0.85, outlier.alpha = 0.35) +
    labs(
      title = titre,
      x = "Target",
      y = y_label
    )

  ggsave(file.path("outputs", "figures", nom_fichier), p, width = 7, height = 5, dpi = 300)
  p
}

# ------------------------------------------------------------
# A. Distribution globale de Target
# ------------------------------------------------------------

table_target <- donnees |>
  count(target, name = "effectif") |>
  mutate(
    proportion = effectif / sum(effectif),
    pourcentage = round(100 * proportion, 2)
  )

readr::write_csv(table_target, file.path("outputs", "tables", "03_a_distribution_target.csv"))

p_target <- ggplot(table_target, aes(x = target, y = proportion, fill = target)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_text(aes(label = paste0(pourcentage, "%")), vjust = -0.35) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, max(table_target$proportion) * 1.15)) +
  labs(
    title = "Distribution globale de Target",
    x = "Statut final",
    y = "Proportion"
  )

ggsave(file.path("outputs", "figures", "03_a_distribution_target.png"), p_target, width = 7, height = 5, dpi = 300)

# ------------------------------------------------------------
# B. Variables socio-demographiques
# ------------------------------------------------------------

tables_socio_demo <- list(
  gender = plot_target_par_categorie(
    donnees,
    "gender",
    "Target selon le genre",
    "Genre",
    "03_b_target_selon_gender.png"
  ),
  displaced = plot_target_par_categorie(
    donnees,
    "displaced",
    "Target selon la situation de deplacement",
    "Etudiant deplace",
    "03_b_target_selon_displaced.png"
  ),
  international = plot_target_par_categorie(
    donnees,
    "international",
    "Target selon le statut international",
    "Etudiant international",
    "03_b_target_selon_international.png"
  )
)

readr::write_csv(bind_rows(tables_socio_demo), file.path("outputs", "tables", "03_b_socio_demographique_target.csv"))

plot_numerique_par_target(
  donnees,
  "age_at_enrollment",
  "Age a l'inscription selon Target",
  "Age a l'inscription",
  "03_b_age_at_enrollment_selon_target.png"
)

# ------------------------------------------------------------
# C. Variables socio-economiques
# ------------------------------------------------------------

tables_socio_eco <- list(
  scholarship_holder = plot_target_par_categorie(
    donnees,
    "scholarship_holder",
    "Target selon le statut de boursier",
    "Boursier",
    "03_c_target_selon_scholarship_holder.png"
  ),
  debtor = plot_target_par_categorie(
    donnees,
    "debtor",
    "Target selon le statut de debiteur",
    "Debiteur",
    "03_c_target_selon_debtor.png"
  ),
  tuition_fees_up_to_date = plot_target_par_categorie(
    donnees,
    "tuition_fees_up_to_date",
    "Target selon le paiement des frais de scolarite",
    "Frais de scolarite a jour",
    "03_c_target_selon_tuition_fees_up_to_date.png"
  )
)

readr::write_csv(bind_rows(tables_socio_eco), file.path("outputs", "tables", "03_c_socio_economique_target.csv"))

# ------------------------------------------------------------
# D. Variables academiques
# ------------------------------------------------------------

variables_academiques <- c(
  "admission_grade",
  "curricular_units_1st_sem_approved",
  "curricular_units_2nd_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_grade"
)

resume_academique <- resume_numerique_par_target(donnees, variables_academiques)
readr::write_csv(resume_academique, file.path("outputs", "tables", "03_d_resume_academique_par_target.csv"))

plot_numerique_par_target(
  donnees,
  "admission_grade",
  "Note d'admission selon Target",
  "Note d'admission",
  "03_d_admission_grade_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "curricular_units_1st_sem_approved",
  "Unites approuvees au 1er semestre selon Target",
  "Unites approuvees au 1er semestre",
  "03_d_1st_sem_approved_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "curricular_units_2nd_sem_approved",
  "Unites approuvees au 2e semestre selon Target",
  "Unites approuvees au 2e semestre",
  "03_d_2nd_sem_approved_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "curricular_units_1st_sem_grade",
  "Note moyenne au 1er semestre selon Target",
  "Note moyenne au 1er semestre",
  "03_d_1st_sem_grade_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "curricular_units_2nd_sem_grade",
  "Note moyenne au 2e semestre selon Target",
  "Note moyenne au 2e semestre",
  "03_d_2nd_sem_grade_selon_target.png"
)

# Nuage de points utile pour visualiser la relation entre les deux semestres.
p_academique_scatter <- ggplot(
  donnees,
  aes(
    x = curricular_units_1st_sem_approved,
    y = curricular_units_2nd_sem_approved,
    color = target
  )
) +
  geom_jitter(alpha = 0.45, width = 0.15, height = 0.15) +
  labs(
    title = "Unites approuvees au 1er et 2e semestre",
    x = "Unites approuvees 1er semestre",
    y = "Unites approuvees 2e semestre",
    color = "Target"
  )

ggsave(file.path("outputs", "figures", "03_d_unites_approuvees_scatter.png"), p_academique_scatter, width = 7, height = 5, dpi = 300)

# ------------------------------------------------------------
# E. Contexte economique
# ------------------------------------------------------------

variables_contexte <- c("unemployment_rate", "inflation_rate", "gdp")

resume_contexte <- resume_numerique_par_target(donnees, variables_contexte)
readr::write_csv(resume_contexte, file.path("outputs", "tables", "03_e_resume_contexte_economique_par_target.csv"))

plot_numerique_par_target(
  donnees,
  "unemployment_rate",
  "Taux de chomage selon Target",
  "Taux de chomage",
  "03_e_unemployment_rate_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "inflation_rate",
  "Taux d'inflation selon Target",
  "Taux d'inflation",
  "03_e_inflation_rate_selon_target.png"
)

plot_numerique_par_target(
  donnees,
  "gdp",
  "PIB selon Target",
  "PIB",
  "03_e_gdp_selon_target.png"
)

# ------------------------------------------------------------
# Sorties complementaires
# ------------------------------------------------------------

variables_numeriques <- donnees |>
  select(where(is.numeric)) |>
  names()

resume_numerique_global <- resume_numerique_par_target(donnees, variables_numeriques)
readr::write_csv(resume_numerique_global, file.path("outputs", "tables", "03_resume_numerique_par_target.csv"))

correlations <- donnees |>
  select(where(is.numeric)) |>
  cor(use = "pairwise.complete.obs")

readr::write_csv(
  as.data.frame(correlations) |> tibble::rownames_to_column("variable"),
  file.path("outputs", "tables", "03_matrice_correlation.csv")
)

png(file.path("outputs", "figures", "03_matrice_correlation_variables_numeriques.png"), width = 1200, height = 1000, res = 150)
corrplot::corrplot(correlations, method = "color", type = "upper", tl.cex = 0.65, tl.col = "black")
dev.off()

message("Analyse descriptive terminee : figures et tableaux exportes.")
