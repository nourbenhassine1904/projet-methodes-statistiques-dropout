# ============================================================
# 06_modelisation_complementaire.R
# Objectif : regression logistique binaire Dropout vs Non-Dropout
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

# Construction d'une cible binaire :
# 1 = Dropout, 0 = Non-Dropout. Les etudiants Enrolled et Graduate
# sont regroupes ici pour une premiere analyse complementaire simple.
donnees_modele <- donnees |>
  mutate(
    dropout_binaire = if_else(target == "Dropout", 1, 0),
    dropout_binaire = factor(dropout_binaire, levels = c(0, 1), labels = c("Non_Dropout", "Dropout"))
  )

# Variables explicatives volontairement limitees pour un squelette robuste.
# Elles melangent dimensions socio-economiques et parcours academique.
variables_modele <- c(
  "age_at_enrollment",
  "admission_grade",
  "debtor",
  "tuition_fees_up_to_date",
  "scholarship_holder",
  "gender",
  "displaced",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade"
)

variables_modele <- intersect(variables_modele, names(donnees_modele))

formule_modele <- reformulate(
  termlabels = variables_modele,
  response = "dropout_binaire"
)

set.seed(123)
indices_train <- sample(seq_len(nrow(donnees_modele)), size = floor(0.8 * nrow(donnees_modele)))

train <- donnees_modele[indices_train, ]
test <- donnees_modele[-indices_train, ]

modele_logit <- glm(
  formula = formule_modele,
  data = train,
  family = binomial(link = "logit")
)

saveRDS(modele_logit, file.path("outputs", "models", "06_modele_logistique_dropout.rds"))

# Coefficients et odds ratios.
coef_modele <- broom::tidy(modele_logit, conf.int = TRUE, exponentiate = TRUE) |>
  rename(
    odds_ratio = estimate,
    ic_bas = conf.low,
    ic_haut = conf.high
  )

readr::write_csv(coef_modele, file.path("outputs", "tables", "06_logit_odds_ratios.csv"))

# Interpretation prudente des odds ratios.
# Une odds ratio > 1 indique une association avec une probabilite plus forte
# de Dropout, tandis qu'une odds ratio < 1 indique une association inverse.
# Cette lecture reste associative et ne doit pas etre interpretee causalement.
interpretation_odds_ratios <- coef_modele |>
  transmute(
    term,
    odds_ratio,
    p.value,
    interpretation = case_when(
      term == "(Intercept)" ~ "Constante du modele, non interpretee comme une variable explicative.",
      odds_ratio > 1 ~ "Variable associee a une augmentation du risque de Dropout, toutes choses egales par ailleurs dans ce modele.",
      odds_ratio < 1 ~ "Variable associee a une diminution du risque de Dropout, toutes choses egales par ailleurs dans ce modele.",
      TRUE ~ "Variable sans variation apparente du risque de Dropout dans ce modele."
    )
  )

readr::write_csv(
  interpretation_odds_ratios,
  file.path("outputs", "tables", "06_interpretation_odds_ratios.csv")
)

# Predictions sur l'echantillon test.
pred_test <- test |>
  mutate(
    proba_dropout = predict(modele_logit, newdata = test, type = "response"),
    prediction = factor(
      if_else(proba_dropout >= 0.5, "Dropout", "Non_Dropout"),
      levels = c("Non_Dropout", "Dropout")
    )
  )

matrice_confusion <- pred_test |>
  count(dropout_binaire, prediction, name = "effectif") |>
  tidyr::complete(dropout_binaire, prediction, fill = list(effectif = 0))

readr::write_csv(matrice_confusion, file.path("outputs", "tables", "06_matrice_confusion.csv"))

extraire_cellule <- function(reel, predit) {
  valeur <- matrice_confusion |>
    filter(dropout_binaire == reel, prediction == predit) |>
    pull(effectif)

  if (length(valeur) == 0) {
    0
  } else {
    valeur
  }
}

division_sure <- function(numerateur, denominateur) {
  if (denominateur == 0) {
    NA_real_
  } else {
    numerateur / denominateur
  }
}

vrais_positifs <- extraire_cellule("Dropout", "Dropout")
faux_positifs <- extraire_cellule("Non_Dropout", "Dropout")
faux_negatifs <- extraire_cellule("Dropout", "Non_Dropout")
vrais_negatifs <- extraire_cellule("Non_Dropout", "Non_Dropout")

metriques <- matrice_confusion |>
  summarise(
    accuracy = sum(effectif[dropout_binaire == prediction]) / sum(effectif)
  )

readr::write_csv(metriques, file.path("outputs", "tables", "06_metriques_logit.csv"))

precision_dropout <- division_sure(vrais_positifs, vrais_positifs + faux_positifs)
recall_dropout <- division_sure(vrais_positifs, vrais_positifs + faux_negatifs)
f1_dropout <- division_sure(2 * precision_dropout * recall_dropout, precision_dropout + recall_dropout)
specificity_non_dropout <- division_sure(vrais_negatifs, vrais_negatifs + faux_positifs)

metriques_detaillees <- tibble::tibble(
  accuracy = metriques$accuracy,
  precision_dropout = precision_dropout,
  recall_dropout = recall_dropout,
  f1_dropout = f1_dropout,
  specificity_non_dropout = specificity_non_dropout,
  vrais_positifs = vrais_positifs,
  faux_positifs = faux_positifs,
  faux_negatifs = faux_negatifs,
  vrais_negatifs = vrais_negatifs,
  seuil_prediction = 0.5
)

readr::write_csv(
  metriques_detaillees,
  file.path("outputs", "tables", "06_metriques_detaillees_logit.csv")
)

p_proba <- ggplot(pred_test, aes(x = proba_dropout, fill = dropout_binaire)) +
  geom_histogram(position = "identity", alpha = 0.55, bins = 30) +
  labs(
    title = "Probabilites predites de dropout",
    x = "Probabilite predite",
    y = "Effectif",
    fill = "Classe reelle"
  )

ggsave(file.path("outputs", "figures", "06_probabilites_dropout.png"), p_proba, width = 7, height = 5, dpi = 300)

message("Modele logistique binaire exporte dans outputs/models.")
