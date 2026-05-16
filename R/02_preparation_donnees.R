# ============================================================
# 02_preparation_donnees.R
# Objectif : nettoyer les noms, typer les variables et sauvegarder un RDS
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

chemin_csv <- file.path("data", "raw", "dropout_academic_success.csv")

donnees <- readr::read_delim(
  file = chemin_csv,
  delim = ";",
  show_col_types = FALSE,
  trim_ws = TRUE
) |>
  janitor::clean_names()

# Variables codees numeriquement mais qualitatives.
# Elles doivent etre converties en factor avant FAMD et analyses descriptives.
variables_categorielles <- c(
  "marital_status",
  "application_mode",
  "course",
  "daytime_evening_attendance",
  "previous_qualification",
  "nacionality",
  "mothers_qualification",
  "fathers_qualification",
  "mothers_occupation",
  "fathers_occupation",
  "displaced",
  "educational_special_needs",
  "debtor",
  "tuition_fees_up_to_date",
  "gender",
  "scholarship_holder",
  "international",
  "target"
)

variables_presentes <- intersect(variables_categorielles, names(donnees))
variables_absentes <- setdiff(variables_categorielles, names(donnees))

if (length(variables_absentes) > 0) {
  warning(
    "Variables categorielles absentes apres nettoyage des noms : ",
    paste(variables_absentes, collapse = ", ")
  )
}

donnees_clean <- donnees |>
  mutate(across(all_of(variables_presentes), as.factor))

# Labels lisibles pour les variables binaires.
# Le codage du dataset UCI est conserve, mais les modalites deviennent
# plus faciles a lire dans les tableaux et figures.
label_oui_non <- function(x, label_0 = "Non", label_1 = "Oui") {
  factor(as.character(x), levels = c("0", "1"), labels = c(label_0, label_1))
}

variables_binaires_oui_non <- c(
  "displaced",
  "educational_special_needs",
  "debtor",
  "tuition_fees_up_to_date",
  "scholarship_holder",
  "international"
)

variables_binaires_presentes <- intersect(variables_binaires_oui_non, names(donnees_clean))

donnees_clean <- donnees_clean |>
  mutate(across(all_of(variables_binaires_presentes), label_oui_non))

if ("gender" %in% names(donnees_clean)) {
  donnees_clean <- donnees_clean |>
    mutate(gender = label_oui_non(gender, label_0 = "Femme", label_1 = "Homme"))
}

# Ordre explicite de Target pour garder une lecture stable des sorties.
if ("target" %in% names(donnees_clean)) {
  donnees_clean <- donnees_clean |>
    mutate(
      target = factor(target, levels = c("Dropout", "Enrolled", "Graduate")),
      dropout_binary = factor(
        if_else(target == "Dropout", "Dropout", "Non_Dropout"),
        levels = c("Non_Dropout", "Dropout")
      ),
      success_binary = factor(
        if_else(target == "Graduate", "Graduate", "Non_Graduate"),
        levels = c("Non_Graduate", "Graduate")
      )
    )
}

# Controle des types apres preparation.
types_variables <- tibble::tibble(
  variable = names(donnees_clean),
  classe = purrr::map_chr(donnees_clean, ~ paste(class(.x), collapse = " / ")),
  nb_modalites = purrr::map_int(donnees_clean, ~ dplyr::n_distinct(.x, na.rm = TRUE))
)

print(types_variables, n = Inf)

# Dictionnaire de variables exporte pour faciliter la redaction du rapport.
dictionnaire_manuel <- tibble::tribble(
  ~variable, ~bloc, ~role, ~description,
  "marital_status", "socio-demographique", "active possible", "Statut matrimonial, code qualitatif du dataset.",
  "application_mode", "parcours administratif", "contextuelle", "Mode de candidature, code qualitatif du dataset.",
  "application_order", "parcours administratif", "active possible", "Ordre de choix de la candidature.",
  "course", "parcours academique", "contextuelle", "Formation suivie, code qualitatif du dataset.",
  "daytime_evening_attendance", "parcours academique", "active possible", "Type de frequentation : jour ou soir, code qualitatif du dataset.",
  "previous_qualification", "parcours academique", "active possible", "Qualification precedente, code qualitatif du dataset.",
  "previous_qualification_grade", "parcours academique", "active possible", "Note associee a la qualification precedente.",
  "nacionality", "socio-demographique", "contextuelle", "Nationalite, code qualitatif du dataset.",
  "mothers_qualification", "socio-economique", "contextuelle", "Qualification de la mere, code qualitatif du dataset.",
  "fathers_qualification", "socio-economique", "contextuelle", "Qualification du pere, code qualitatif du dataset.",
  "mothers_occupation", "socio-economique", "contextuelle", "Occupation de la mere, code qualitatif du dataset.",
  "fathers_occupation", "socio-economique", "contextuelle", "Occupation du pere, code qualitatif du dataset.",
  "admission_grade", "parcours academique", "active possible", "Note d'admission.",
  "displaced", "socio-demographique", "active possible", "Etudiant deplace : Non / Oui.",
  "educational_special_needs", "socio-demographique", "active possible", "Besoins educatifs speciaux : Non / Oui.",
  "debtor", "socio-economique", "active possible", "Debiteur : Non / Oui.",
  "tuition_fees_up_to_date", "socio-economique", "active possible", "Frais de scolarite a jour : Non / Oui.",
  "gender", "socio-demographique", "active possible", "Genre : Femme / Homme selon le codage du dataset.",
  "scholarship_holder", "socio-economique", "active possible", "Boursier : Non / Oui.",
  "age_at_enrollment", "socio-demographique", "active possible", "Age au moment de l'inscription.",
  "international", "socio-demographique", "active possible", "Etudiant international : Non / Oui.",
  "curricular_units_1st_sem_credited", "parcours academique", "contextuelle", "Unites creditees au 1er semestre.",
  "curricular_units_1st_sem_enrolled", "parcours academique", "active possible", "Unites inscrites au 1er semestre.",
  "curricular_units_1st_sem_evaluations", "parcours academique", "active possible", "Evaluations au 1er semestre.",
  "curricular_units_1st_sem_approved", "parcours academique", "active possible", "Unites approuvees au 1er semestre.",
  "curricular_units_1st_sem_grade", "parcours academique", "active possible", "Note moyenne au 1er semestre.",
  "curricular_units_1st_sem_without_evaluations", "parcours academique", "active possible", "Unites sans evaluation au 1er semestre.",
  "curricular_units_2nd_sem_credited", "parcours academique", "contextuelle", "Unites creditees au 2e semestre.",
  "curricular_units_2nd_sem_enrolled", "parcours academique", "active possible", "Unites inscrites au 2e semestre.",
  "curricular_units_2nd_sem_evaluations", "parcours academique", "active possible", "Evaluations au 2e semestre.",
  "curricular_units_2nd_sem_approved", "parcours academique", "active possible", "Unites approuvees au 2e semestre.",
  "curricular_units_2nd_sem_grade", "parcours academique", "active possible", "Note moyenne au 2e semestre.",
  "curricular_units_2nd_sem_without_evaluations", "parcours academique", "active possible", "Unites sans evaluation au 2e semestre.",
  "unemployment_rate", "contexte economique", "active possible", "Taux de chomage.",
  "inflation_rate", "contexte economique", "active possible", "Taux d'inflation.",
  "gdp", "contexte economique", "active possible", "PIB.",
  "target", "cible", "variable supplementaire / cible", "Statut final : Dropout, Enrolled ou Graduate.",
  "dropout_binary", "cible", "cible binaire", "Dropout vs Non_Dropout.",
  "success_binary", "cible", "cible binaire", "Graduate vs Non_Graduate."
)

dictionnaire_variables <- types_variables |>
  left_join(dictionnaire_manuel, by = "variable") |>
  mutate(
    bloc = tidyr::replace_na(bloc, "a documenter"),
    role = tidyr::replace_na(role, "a documenter"),
    description = tidyr::replace_na(description, "Variable issue du dataset UCI."),
    modalites = purrr::map_chr(donnees_clean, function(x) {
      if (is.factor(x)) {
        paste(levels(x), collapse = " | ")
      } else {
        NA_character_
      }
    })
  ) |>
  select(variable, bloc, role, classe, nb_modalites, modalites, description)

# Sauvegardes.
saveRDS(donnees_clean, file.path("data", "processed", "dropout_clean.rds"))
readr::write_csv(types_variables, file.path("outputs", "tables", "02_types_variables.csv"))
readr::write_csv(dictionnaire_variables, file.path("outputs", "tables", "02_dictionnaire_variables.csv"))

message("Donnees nettoyees sauvegardees dans data/processed/dropout_clean.rds")
