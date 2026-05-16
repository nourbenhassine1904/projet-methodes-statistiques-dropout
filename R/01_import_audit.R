# ============================================================
# 01_import_audit.R
# Objectif : importer le CSV brut et realiser un premier audit
# ============================================================

# Ce bloc permet d'executer le script depuis la racine du projet
# ou depuis le dossier R dans RStudio.
chemins_possibles <- c(getwd(), dirname(getwd()))
racine_projet <- chemins_possibles[
  file.exists(file.path(chemins_possibles, "R", "00_packages_config.R"))
][1]

if (is.na(racine_projet)) {
  stop("Impossible de trouver la racine du projet. Ouvrir le projet depuis son dossier principal.")
}

setwd(racine_projet)
source(file.path("R", "00_packages_config.R"))

chemin_csv <- file.path("data", "raw", "dropout_academic_success.csv")

if (!file.exists(chemin_csv)) {
  stop("Fichier CSV introuvable : ", chemin_csv)
}

# Le fichier UCI est separe par des points-virgules.
donnees_brutes <- readr::read_delim(
  file = chemin_csv,
  delim = ";",
  show_col_types = FALSE,
  trim_ws = TRUE
)

# Dimensions et noms des colonnes.
dimensions <- tibble::tibble(
  indicateur = c("nombre_lignes", "nombre_colonnes"),
  valeur = c(nrow(donnees_brutes), ncol(donnees_brutes))
)

noms_colonnes <- tibble::tibble(
  position = seq_along(names(donnees_brutes)),
  nom_original = names(donnees_brutes),
  nom_nettoye = janitor::make_clean_names(names(donnees_brutes))
)

print(dimensions)
print(noms_colonnes, n = Inf)

# Structure generale et apercu.
dplyr::glimpse(donnees_brutes)

# Valeurs manquantes par variable.
valeurs_manquantes <- donnees_brutes |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  tidyr::pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "nb_na"
  ) |>
  mutate(
    pct_na = round(100 * nb_na / nrow(donnees_brutes), 2)
  ) |>
  arrange(desc(nb_na), variable)

print(valeurs_manquantes, n = Inf)

# Distribution de la variable cible.
distribution_target <- donnees_brutes |>
  count(Target, name = "effectif") |>
  mutate(pourcentage = round(100 * effectif / sum(effectif), 2)) |>
  arrange(desc(effectif))

print(distribution_target)

# Audit synthetique avec skimr.
audit_skim <- skimr::skim(donnees_brutes)
print(audit_skim)

# Export des premiers tableaux d'audit.
readr::write_csv(dimensions, file.path("outputs", "tables", "01_dimensions.csv"))
readr::write_csv(noms_colonnes, file.path("outputs", "tables", "01_noms_colonnes.csv"))
readr::write_csv(valeurs_manquantes, file.path("outputs", "tables", "01_valeurs_manquantes.csv"))
readr::write_csv(distribution_target, file.path("outputs", "tables", "01_distribution_target.csv"))
readr::write_csv(as.data.frame(audit_skim), file.path("outputs", "tables", "01_skim.csv"))
