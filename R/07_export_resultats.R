# ============================================================
# 07_export_resultats.R
# Objectif : verifier les sorties finales du projet
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

# Executer les scripts principaux si les sorties attendues sont absentes.
if (!file.exists(file.path("data", "processed", "dropout_clean.rds"))) {
  source(file.path("R", "02_preparation_donnees.R"))
}

if (!file.exists(file.path("outputs", "models", "04_resultat_famd.rds"))) {
  source(file.path("R", "04_famd.R"))
}

if (!file.exists(file.path("outputs", "models", "05_kmeans.rds"))) {
  source(file.path("R", "05_clustering.R"))
}

if (!file.exists(file.path("outputs", "models", "06_modele_logistique_dropout.rds"))) {
  source(file.path("R", "06_modelisation_complementaire.R"))
}

# Inventaire des fichiers exportes.
inventaire_outputs <- tibble::tibble(
  chemin = list.files("outputs", recursive = TRUE, full.names = TRUE)
) |>
  mutate(
    type = tools::file_ext(chemin),
    taille_ko = round(file.info(chemin)$size / 1024, 2),
    date_modification = file.info(chemin)$mtime
  ) |>
  arrange(chemin)

readr::write_csv(inventaire_outputs, file.path("outputs", "tables", "07_inventaire_outputs.csv"))

print(inventaire_outputs, n = Inf)

# Verification minimale des sorties importantes.
sorties_attendues <- tibble::tibble(
  sortie = c(
    "data/processed/dropout_clean.rds",
    "outputs/models/04_resultat_famd.rds",
    "outputs/models/05_kmeans.rds",
    "outputs/models/06_modele_logistique_dropout.rds",
    "outputs/tables/04_famd_valeurs_propres.csv",
    "outputs/tables/05_croisement_cluster_target.csv",
    "outputs/tables/06_logit_odds_ratios.csv"
  )
) |>
  mutate(existe = file.exists(sortie))

readr::write_csv(sorties_attendues, file.path("outputs", "tables", "07_verification_sorties.csv"))

if (any(!sorties_attendues$existe)) {
  warning("Certaines sorties attendues sont absentes. Voir outputs/tables/07_verification_sorties.csv")
} else {
  message("Toutes les sorties principales sont presentes.")
}
