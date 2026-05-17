# ============================================================
# 06_modelisation_complementaire.R
# Objectif : modeles logistiques precoce et complet
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

set.seed(123)

chemin_rds <- file.path("data", "processed", "dropout_clean.rds")

if (!file.exists(chemin_rds)) {
  source(file.path("R", "02_preparation_donnees.R"))
}

donnees <- readRDS(chemin_rds)

if (!"target" %in% names(donnees)) {
  stop("La variable target est absente des donnees preparees.")
}

donnees_modele <- donnees |>
  dplyr::mutate(
    dropout_binaire = dplyr::if_else(.data$target == "Dropout", "Dropout", "Non_Dropout"),
    dropout_binaire = factor(.data$dropout_binaire, levels = c("Non_Dropout", "Dropout"))
  )

variables_entree <- c(
  "age_at_enrollment",
  "admission_grade",
  "previous_qualification_grade",
  "daytime_evening_attendance",
  "debtor",
  "tuition_fees_up_to_date",
  "gender",
  "scholarship_holder",
  "displaced"
)

variables_semestre_1 <- c(
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade"
)

variables_semestre_2 <- c(
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade"
)

variables_precoce <- intersect(c(variables_entree, variables_semestre_1), names(donnees_modele))
variables_complet <- intersect(c(variables_precoce, variables_semestre_2), names(donnees_modele))

variables_interdites <- c("target", "dropout_binary", "success_binary", "dropout_binaire")
if (length(intersect(variables_interdites, variables_precoce)) > 0 ||
    length(intersect(variables_interdites, variables_complet)) > 0) {
  stop("Variables cibles ou derivees presentes dans les predicteurs logistiques.")
}

indices_train <- donnees_modele |>
  dplyr::mutate(id = dplyr::row_number()) |>
  dplyr::group_by(.data$dropout_binaire) |>
  dplyr::slice_sample(prop = 0.8) |>
  dplyr::ungroup() |>
  dplyr::pull(.data$id)

train <- donnees_modele[indices_train, , drop = FALSE]
test <- donnees_modele[-indices_train, , drop = FALSE]

division_sure <- function(numerateur, denominateur) {
  if (is.na(denominateur) || denominateur == 0) {
    NA_real_
  } else {
    numerateur / denominateur
  }
}

calculer_auc <- function(reel, score) {
  reel_num <- as.integer(reel == "Dropout")
  n_pos <- sum(reel_num == 1)
  n_neg <- sum(reel_num == 0)
  if (n_pos == 0 || n_neg == 0) return(NA_real_)
  rangs <- rank(score, ties.method = "average")
  (sum(rangs[reel_num == 1]) - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
}

calculer_roc <- function(reel, score, n_points = 200) {
  seuils <- seq(1, 0, length.out = n_points)
  purrr::map_dfr(seuils, function(seuil) {
    prediction <- ifelse(score >= seuil, "Dropout", "Non_Dropout")
    tp <- sum(reel == "Dropout" & prediction == "Dropout")
    fp <- sum(reel == "Non_Dropout" & prediction == "Dropout")
    fn <- sum(reel == "Dropout" & prediction == "Non_Dropout")
    tn <- sum(reel == "Non_Dropout" & prediction == "Non_Dropout")
    tibble::tibble(
      seuil = seuil,
      sensibilite = division_sure(tp, tp + fn),
      specificite = division_sure(tn, tn + fp),
      fpr = 1 - specificite
    )
  })
}

calculer_metriques <- function(reel, proba, seuil = 0.5) {
  prediction <- factor(
    ifelse(proba >= seuil, "Dropout", "Non_Dropout"),
    levels = c("Non_Dropout", "Dropout")
  )
  reel <- factor(reel, levels = c("Non_Dropout", "Dropout"))

  tp <- sum(reel == "Dropout" & prediction == "Dropout")
  fp <- sum(reel == "Non_Dropout" & prediction == "Dropout")
  fn <- sum(reel == "Dropout" & prediction == "Non_Dropout")
  tn <- sum(reel == "Non_Dropout" & prediction == "Non_Dropout")

  precision <- division_sure(tp, tp + fp)
  rappel <- division_sure(tp, tp + fn)

  tibble::tibble(
    accuracy = division_sure(tp + tn, tp + fp + fn + tn),
    precision_dropout = precision,
    recall_dropout = rappel,
    f1_dropout = division_sure(2 * precision * rappel, precision + rappel),
    specificity_non_dropout = division_sure(tn, tn + fp),
    auc = calculer_auc(reel, proba),
    vrais_positifs = tp,
    faux_positifs = fp,
    faux_negatifs = fn,
    vrais_negatifs = tn,
    seuil_prediction = seuil,
    jeu_evaluation = "test"
  )
}

evaluer_validation_croisee <- function(data, variables, k_folds = 5, seed = 123) {
  set.seed(seed)
  data_cv <- data |>
    dplyr::mutate(fold = sample(rep(seq_len(k_folds), length.out = dplyr::n())))

  purrr::map_dfr(seq_len(k_folds), function(fold_id) {
    train_cv <- data_cv |> dplyr::filter(.data$fold != fold_id)
    test_cv <- data_cv |> dplyr::filter(.data$fold == fold_id)
    formule <- stats::reformulate(variables, response = "dropout_binaire")
    modele <- stats::glm(formule, data = train_cv, family = binomial(link = "logit"))
    proba <- stats::predict(modele, newdata = test_cv, type = "response")
    calculer_metriques(test_cv$dropout_binaire, proba) |>
      dplyr::mutate(fold = fold_id)
  }) |>
    dplyr::summarise(
      cv_accuracy_moyenne = mean(.data$accuracy, na.rm = TRUE),
      cv_auc_moyenne = mean(.data$auc, na.rm = TRUE),
      cv_f1_dropout_moyen = mean(.data$f1_dropout, na.rm = TRUE),
      .groups = "drop"
    )
}

ajuster_modele <- function(nom_modele, variables) {
  formule <- stats::reformulate(variables, response = "dropout_binaire")
  modele <- stats::glm(formule, data = train, family = binomial(link = "logit"))
  saveRDS(modele, file.path("outputs", "models", paste0("06_modele_logit_", nom_modele, ".rds")))

  proba_test <- stats::predict(modele, newdata = test, type = "response")
  metriques <- calculer_metriques(test$dropout_binaire, proba_test) |>
    dplyr::mutate(modele = nom_modele, nb_variables = length(variables), .before = 1)

  odds_ratios <- broom::tidy(modele, conf.int = TRUE, exponentiate = TRUE) |>
    dplyr::rename(
      odds_ratio = .data$estimate,
      ic_bas = .data$conf.low,
      ic_haut = .data$conf.high
    ) |>
    dplyr::mutate(
      modele = nom_modele,
      interpretation = dplyr::case_when(
        .data$term == "(Intercept)" ~ "Constante du modele.",
        .data$p.value > 0.05 ~ "Association non nette au seuil 5% dans ce modele.",
        .data$odds_ratio > 1 ~ "Variable associee a une probabilite plus elevee de Dropout dans ce modele.",
        .data$odds_ratio < 1 ~ "Variable associee a une probabilite plus faible de Dropout dans ce modele.",
        TRUE ~ "Association proche de 1 dans ce modele."
      ),
      .before = 1
    )

  roc <- calculer_roc(test$dropout_binaire, proba_test) |>
    dplyr::mutate(modele = nom_modele, .before = 1)

  p_roc <- roc |>
    ggplot2::ggplot(ggplot2::aes(x = .data$fpr, y = .data$sensibilite)) +
    ggplot2::geom_line(color = "#2F6F7E", linewidth = 0.9) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = paste("Courbe ROC - modele", nom_modele),
      subtitle = paste("AUC test =", round(metriques$auc[[1]], 3)),
      x = "1 - specificite",
      y = "sensibilite"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    file.path("outputs", "figures", paste0("06_roc_logit_", nom_modele, ".png")),
    p_roc,
    width = 6,
    height = 5,
    dpi = 300
  )

  pred_test <- test |>
    dplyr::mutate(
      proba_dropout = proba_test,
      prediction = factor(
        ifelse(.data$proba_dropout >= 0.5, "Dropout", "Non_Dropout"),
        levels = c("Non_Dropout", "Dropout")
      )
    )

  list(
    modele = modele,
    variables = variables,
    metriques = metriques,
    odds_ratios = odds_ratios,
    roc = roc,
    pred_test = pred_test,
    cv = evaluer_validation_croisee(donnees_modele, variables) |>
      dplyr::mutate(modele = nom_modele, .before = 1)
  )
}

resultat_precoce <- ajuster_modele("precoce", variables_precoce)
resultat_complet <- ajuster_modele("complet", variables_complet)

readr::write_csv(
  resultat_precoce$metriques,
  file.path("outputs", "tables", "06_metriques_logit_precoce.csv")
)

readr::write_csv(
  resultat_complet$metriques,
  file.path("outputs", "tables", "06_metriques_logit_complet.csv")
)

readr::write_csv(
  resultat_precoce$odds_ratios,
  file.path("outputs", "tables", "06_odds_ratios_logit_precoce.csv")
)

readr::write_csv(
  resultat_complet$odds_ratios,
  file.path("outputs", "tables", "06_odds_ratios_logit_complet.csv")
)

comparaison_modeles <- dplyr::bind_rows(
  resultat_precoce$metriques,
  resultat_complet$metriques
) |>
  dplyr::left_join(
    dplyr::bind_rows(resultat_precoce$cv, resultat_complet$cv),
    by = "modele"
  ) |>
  dplyr::mutate(
    type_modele = dplyr::case_when(
      modele == "precoce" ~ "variables d'entree + semestre 1",
      modele == "complet" ~ "variables d'entree + semestre 1 + semestre 2",
      TRUE ~ modele
    )
  ) |>
  dplyr::select(
    .data$modele,
    .data$type_modele,
    .data$nb_variables,
    .data$accuracy,
    .data$precision_dropout,
    .data$recall_dropout,
    .data$f1_dropout,
    .data$specificity_non_dropout,
    .data$auc,
    .data$cv_accuracy_moyenne,
    .data$cv_auc_moyenne,
    .data$cv_f1_dropout_moyen,
    .data$seuil_prediction,
    .data$jeu_evaluation
  )

readr::write_csv(
  comparaison_modeles,
  file.path("outputs", "tables", "06_comparaison_modeles_logit.csv")
)

# Exports de compatibilite : le modele complet remplace l'ancien modele unique.
saveRDS(resultat_complet$modele, file.path("outputs", "models", "06_modele_logistique_dropout.rds"))
readr::write_csv(resultat_complet$odds_ratios, file.path("outputs", "tables", "06_logit_odds_ratios.csv"))
readr::write_csv(resultat_complet$metriques |> dplyr::select(.data$accuracy), file.path("outputs", "tables", "06_metriques_logit.csv"))
readr::write_csv(resultat_complet$metriques, file.path("outputs", "tables", "06_metriques_detaillees_logit.csv"))

matrice_confusion <- resultat_complet$pred_test |>
  dplyr::count(.data$dropout_binaire, .data$prediction, name = "effectif") |>
  tidyr::complete(.data$dropout_binaire, .data$prediction, fill = list(effectif = 0))

readr::write_csv(matrice_confusion, file.path("outputs", "tables", "06_matrice_confusion.csv"))

interpretation_odds_ratios <- resultat_complet$odds_ratios |>
  dplyr::select(.data$term, .data$odds_ratio, .data$p.value, .data$interpretation)

readr::write_csv(
  interpretation_odds_ratios,
  file.path("outputs", "tables", "06_interpretation_odds_ratios.csv")
)

p_proba <- resultat_complet$pred_test |>
  ggplot2::ggplot(ggplot2::aes(x = .data$proba_dropout, fill = .data$dropout_binaire)) +
  ggplot2::geom_histogram(position = "identity", alpha = 0.55, bins = 30) +
  ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", color = "#B23A48") +
  ggplot2::labs(
    title = "Probabilites predites de dropout - modele complet",
    subtitle = "Seuil de prediction : 0,5",
    x = "Probabilite predite",
    y = "Effectif",
    fill = "Classe reelle"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  file.path("outputs", "figures", "06_probabilites_dropout.png"),
  p_proba,
  width = 7,
  height = 5,
  dpi = 300
)

message(
  "Modeles logistiques exportes : precoce AUC = ",
  round(resultat_precoce$metriques$auc[[1]], 3),
  ", complet AUC = ",
  round(resultat_complet$metriques$auc[[1]], 3),
  "."
)
