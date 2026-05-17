# ============================================================
# 08_audit_technique.R
# Objectif : couche de validation technique avant interface
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

message("Debut de l'audit technique.")

fichiers_entree <- c(
  donnees = file.path("data", "processed", "dropout_clean.rds"),
  famd_variables_actives = file.path("outputs", "tables", "04_famd_variables_actives.csv"),
  famd_valeurs_propres = file.path("outputs", "tables", "04_famd_valeurs_propres.csv"),
  famd_contributions_axes_1_2 = file.path("outputs", "tables", "04_famd_contributions_axes_1_2.csv"),
  kmeans_silhouette = file.path("outputs", "tables", "05_kmeans_silhouette.csv"),
  k_recommande = file.path("outputs", "tables", "05_k_recommande.csv"),
  profils_clusters_interpretes = file.path("outputs", "tables", "05_profils_clusters_interpretes.csv"),
  metriques_detaillees_logit = file.path("outputs", "tables", "06_metriques_detaillees_logit.csv")
)

fichiers_absents <- fichiers_entree[!file.exists(fichiers_entree)]
if (length(fichiers_absents) > 0) {
  stop(
    "Fichiers d'entree manquants : ",
    paste(unname(fichiers_absents), collapse = ", ")
  )
}

message("Lecture des donnees et des sorties existantes.")

donnees <- readRDS(fichiers_entree[["donnees"]])
variables_actives_famd <- readr::read_csv(
  fichiers_entree[["famd_variables_actives"]],
  show_col_types = FALSE
)
valeurs_propres <- readr::read_csv(
  fichiers_entree[["famd_valeurs_propres"]],
  show_col_types = FALSE
)
contributions_axes <- readr::read_csv(
  fichiers_entree[["famd_contributions_axes_1_2"]],
  show_col_types = FALSE
)
silhouette <- readr::read_csv(
  fichiers_entree[["kmeans_silhouette"]],
  show_col_types = FALSE
)
k_recommande <- readr::read_csv(
  fichiers_entree[["k_recommande"]],
  show_col_types = FALSE
)
profils_clusters_interpretes <- readr::read_csv(
  fichiers_entree[["profils_clusters_interpretes"]],
  show_col_types = FALSE
)
metriques_logit <- readr::read_csv(
  fichiers_entree[["metriques_detaillees_logit"]],
  show_col_types = FALSE
)

if (!"target" %in% names(donnees)) {
  stop("La variable target est absente des donnees preparees.")
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

classe_variable <- function(x) {
  paste(class(x), collapse = " / ")
}

liste_presente <- function(vars) {
  intersect(vars, names(donnees))
}

valeur_axe <- function(table, axe_nom, colonne) {
  valeur <- table |>
    dplyr::filter(.data$axe == .env$axe_nom) |>
    dplyr::pull({{ colonne }})

  if (length(valeur) == 0) {
    NA_real_
  } else {
    valeur[[1]]
  }
}

cumul_axes <- function(table, n_axes) {
  table |>
    dplyr::slice_head(n = min(n_axes, nrow(table))) |>
    dplyr::summarise(cumul = sum(.data$variance.percent, na.rm = TRUE)) |>
    dplyr::pull(.data$cumul)
}

top_contributions <- function(table, axe, n = 5) {
  if (!axe %in% names(table) || !"variable" %in% names(table)) {
    return("contributions non disponibles")
  }

  variables <- table |>
    dplyr::select("variable", contribution = dplyr::all_of(axe)) |>
    dplyr::arrange(dplyr::desc(.data$contribution)) |>
    dplyr::slice_head(n = n) |>
    dplyr::pull(.data$variable)

  if (length(variables) == 0) {
    "contributions non disponibles"
  } else {
    paste(variables, collapse = ", ")
  }
}

# ------------------------------------------------------------
# 1. Typologie technique des variables
# ------------------------------------------------------------

message("Construction de 08_typologie_variables.csv.")

variables_codes_qualitatifs <- c(
  "marital_status",
  "application_mode",
  "course",
  "daytime_evening_attendance",
  "previous_qualification",
  "nacionality",
  "mothers_qualification",
  "fathers_qualification",
  "mothers_occupation",
  "fathers_occupation"
)

variables_binaires <- c(
  "displaced",
  "educational_special_needs",
  "debtor",
  "tuition_fees_up_to_date",
  "gender",
  "scholarship_holder",
  "international",
  "dropout_binary",
  "success_binary"
)

variables_quantitatives <- c(
  "application_order",
  "previous_qualification_grade",
  "admission_grade",
  "age_at_enrollment",
  "curricular_units_1st_sem_credited",
  "curricular_units_1st_sem_enrolled",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_1st_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_1st_sem_without_evaluations",
  "curricular_units_2nd_sem_credited",
  "curricular_units_2nd_sem_enrolled",
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade",
  "curricular_units_2nd_sem_without_evaluations",
  "unemployment_rate",
  "inflation_rate",
  "gdp"
)

variables_ordinales <- c("application_order")
variables_creees <- c("dropout_binary", "success_binary")

familles <- tibble::tribble(
  ~nom_variable, ~famille,
  "marital_status", "socio_demographique",
  "nacionality", "socio_demographique",
  "displaced", "socio_demographique",
  "educational_special_needs", "socio_demographique",
  "gender", "socio_demographique",
  "age_at_enrollment", "socio_demographique",
  "international", "socio_demographique",
  "application_mode", "inscription",
  "application_order", "inscription",
  "course", "inscription",
  "daytime_evening_attendance", "inscription",
  "previous_qualification", "inscription",
  "previous_qualification_grade", "inscription",
  "admission_grade", "inscription",
  "mothers_qualification", "familiale",
  "fathers_qualification", "familiale",
  "mothers_occupation", "familiale",
  "fathers_occupation", "familiale",
  "debtor", "socio_economique",
  "tuition_fees_up_to_date", "socio_economique",
  "scholarship_holder", "socio_economique",
  "curricular_units_1st_sem_credited", "academique_s1",
  "curricular_units_1st_sem_enrolled", "academique_s1",
  "curricular_units_1st_sem_evaluations", "academique_s1",
  "curricular_units_1st_sem_approved", "academique_s1",
  "curricular_units_1st_sem_grade", "academique_s1",
  "curricular_units_1st_sem_without_evaluations", "academique_s1",
  "curricular_units_2nd_sem_credited", "academique_s2",
  "curricular_units_2nd_sem_enrolled", "academique_s2",
  "curricular_units_2nd_sem_evaluations", "academique_s2",
  "curricular_units_2nd_sem_approved", "academique_s2",
  "curricular_units_2nd_sem_grade", "academique_s2",
  "curricular_units_2nd_sem_without_evaluations", "academique_s2",
  "unemployment_rate", "contexte_economique",
  "inflation_rate", "contexte_economique",
  "gdp", "contexte_economique",
  "target", "cible",
  "dropout_binary", "variable_creee",
  "success_binary", "variable_creee"
)

actives_famd <- variables_actives_famd |>
  dplyr::pull(.data$variable)

typologie_variables <- tibble::tibble(
  nom_variable = names(donnees),
  classe_R = purrr::map_chr(donnees, classe_variable),
  nb_modalites = purrr::map_int(donnees, ~ dplyr::n_distinct(.x, na.rm = TRUE)),
  est_factor = purrr::map_lgl(donnees, ~ inherits(.x, "factor"))
) |>
  dplyr::left_join(familles, by = "nom_variable") |>
  dplyr::mutate(
    famille = dplyr::coalesce(.data$famille, "inscription"),
    type_statistique_recommande = dplyr::case_when(
      .data$nom_variable == "target" ~ "cible",
      .data$nom_variable %in% variables_creees ~ "variable_creee",
      .data$nom_variable %in% variables_ordinales ~ "ordinale",
      .data$nom_variable %in% variables_binaires | .data$nb_modalites == 2 ~ "qualitative_binaire",
      .data$nom_variable %in% variables_codes_qualitatifs ~ "qualitative_nominale",
      .data$nom_variable %in% variables_quantitatives ~ "quantitative",
      .data$est_factor ~ "qualitative_nominale",
      TRUE ~ "quantitative"
    ),
    role_recommande = dplyr::case_when(
      .data$nom_variable == "target" ~ "cible",
      .data$nom_variable %in% variables_creees ~ "exclue_famd_principale",
      .data$nom_variable %in% actives_famd ~ "active_famd_possible",
      .data$nom_variable %in% c("course", "application_mode", "nacionality",
                                "mothers_occupation", "fathers_occupation",
                                "mothers_qualification", "fathers_qualification") ~ "illustrative_possible",
      TRUE ~ "illustrative_possible"
    ),
    commentaire = dplyr::case_when(
      .data$nom_variable == "target" ~
        "Variable cible conservee comme illustrative dans la FAMD pour ne pas orienter la construction des axes.",
      .data$nom_variable %in% variables_creees ~
        "Variable creee a partir de la cible; a exclure de la FAMD principale pour eviter une fuite d'information.",
      .data$nom_variable %in% variables_codes_qualitatifs ~
        "Variable issue de codes entiers dans les donnees brutes; malgre un codage integer possible, elle represente des categories qualitatives et non une mesure continue.",
      .data$nom_variable %in% variables_binaires ~
        "Variable binaire qualitative; la classe R peut etre factor apres preparation.",
      .data$type_statistique_recommande == "quantitative" ~
        "Variable numerique interpretable comme mesure ou comptage.",
      TRUE ~
        "Variable conservee pour interpretation technique selon son role recommande."
    )
  ) |>
  dplyr::select(
    nom_variable,
    classe_R,
    type_statistique_recommande,
    famille,
    role_recommande,
    commentaire
  )

readr::write_csv(
  typologie_variables,
  file.path("outputs", "tables", "08_typologie_variables.csv")
)

# ------------------------------------------------------------
# 2. Audit des zeros academiques
# ------------------------------------------------------------

message("Construction de 08_audit_zeros_academiques.csv.")

variables_zeros <- c(
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_grade",
  "curricular_units_1st_sem_approved",
  "curricular_units_2nd_sem_approved",
  "curricular_units_1st_sem_evaluations",
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_1st_sem_without_evaluations",
  "curricular_units_2nd_sem_without_evaluations"
)

variables_zeros_presentes <- liste_presente(variables_zeros)

if (length(variables_zeros_presentes) != length(variables_zeros)) {
  warning(
    "Variables academiques absentes de dropout_clean.rds : ",
    paste(setdiff(variables_zeros, variables_zeros_presentes), collapse = ", ")
  )
}

audit_zeros_academiques <- donnees |>
  dplyr::select("target", dplyr::all_of(variables_zeros_presentes)) |>
  tidyr::pivot_longer(
    cols = -target,
    names_to = "variable",
    values_to = "valeur"
  ) |>
  dplyr::group_by(.data$variable, .data$target) |>
  dplyr::summarise(
    effectif_total_target = dplyr::n(),
    nombre_zero = sum(.data$valeur == 0, na.rm = TRUE),
    pourcentage_zero = round(100 * .data$nombre_zero / .data$effectif_total_target, 2),
    moyenne = mean(.data$valeur, na.rm = TRUE),
    mediane = stats::median(.data$valeur, na.rm = TRUE),
    q1 = stats::quantile(.data$valeur, probs = 0.25, na.rm = TRUE, names = FALSE),
    q3 = stats::quantile(.data$valeur, probs = 0.75, na.rm = TRUE, names = FALSE),
    min = min(.data$valeur, na.rm = TRUE),
    max = max(.data$valeur, na.rm = TRUE),
    .groups = "drop"
  )

readr::write_csv(
  audit_zeros_academiques,
  file.path("outputs", "tables", "08_audit_zeros_academiques.csv")
)

# ------------------------------------------------------------
# 3. Coherence technique zeros / notes / validations
# ------------------------------------------------------------

message("Construction de 08_coherence_zeros_notes.csv.")

controles <- list(
  "grade_1st_sem = 0 et approved_1st_sem = 0" = list(
    expression = quote(curricular_units_1st_sem_grade == 0 & curricular_units_1st_sem_approved == 0),
    interpretation = "Cas coherent techniquement : absence de note moyenne au premier semestre avec aucune unite approuvee."
  ),
  "grade_1st_sem = 0 et approved_1st_sem > 0" = list(
    expression = quote(curricular_units_1st_sem_grade == 0 & curricular_units_1st_sem_approved > 0),
    interpretation = "Cas atypique a surveiller : des unites sont approuvees alors que la note moyenne du premier semestre vaut zero."
  ),
  "grade_2nd_sem = 0 et approved_2nd_sem = 0" = list(
    expression = quote(curricular_units_2nd_sem_grade == 0 & curricular_units_2nd_sem_approved == 0),
    interpretation = "Cas coherent techniquement : absence de note moyenne au second semestre avec aucune unite approuvee."
  ),
  "grade_2nd_sem = 0 et approved_2nd_sem > 0" = list(
    expression = quote(curricular_units_2nd_sem_grade == 0 & curricular_units_2nd_sem_approved > 0),
    interpretation = "Cas atypique a surveiller : des unites sont approuvees alors que la note moyenne du second semestre vaut zero."
  ),
  "grade_1st_sem > 0 et evaluations_1st_sem = 0" = list(
    expression = quote(curricular_units_1st_sem_grade > 0 & curricular_units_1st_sem_evaluations == 0),
    interpretation = "Cas incoherent attendu rare : une note positive existe alors qu'aucune evaluation du premier semestre n'est enregistree."
  ),
  "grade_2nd_sem > 0 et evaluations_2nd_sem = 0" = list(
    expression = quote(curricular_units_2nd_sem_grade > 0 & curricular_units_2nd_sem_evaluations == 0),
    interpretation = "Cas incoherent attendu rare : une note positive existe alors qu'aucune evaluation du second semestre n'est enregistree."
  )
)

coherence_zeros_notes <- purrr::imap_dfr(controles, function(spec_controle, nom_controle) {
  donnees_controle <- donnees |>
    dplyr::mutate(condition_controle = eval(spec_controle$expression, envir = donnees))

  donnees_controle |>
    dplyr::group_by(.data$target) |>
    dplyr::summarise(effectif = sum(.data$condition_controle, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(
      controle = nom_controle,
      interpretation_technique = spec_controle$interpretation
    ) |>
    dplyr::select("controle", "target", "effectif", "interpretation_technique")
})

readr::write_csv(
  coherence_zeros_notes,
  file.path("outputs", "tables", "08_coherence_zeros_notes.csv")
)

# ------------------------------------------------------------
# 4. Resume technique FAMD
# ------------------------------------------------------------

message("Construction de 08_resume_famd_technique.csv.")

resume_famd_technique <- tibble::tibble(
  `inertie Dim 1` = valeur_axe(valeurs_propres, "Dim.1", variance.percent),
  `inertie Dim 2` = valeur_axe(valeurs_propres, "Dim.2", variance.percent),
  `cumul Dim 1 + Dim 2` = valeur_axe(valeurs_propres, "Dim.2", cumulative.variance.percent),
  `cumul des 5 premiers axes` = cumul_axes(valeurs_propres, 5),
  `cumul des 8 premiers axes` = cumul_axes(valeurs_propres, 8),
  `cumul des 10 premiers axes` = cumul_axes(valeurs_propres, 10),
  interpretation_dim1 = paste(
    "Dim.1 est principalement lue a partir des plus fortes contributions observees :",
    top_contributions(contributions_axes, "Dim.1")
  ),
  interpretation_dim2 = paste(
    "Dim.2 est principalement lue a partir des plus fortes contributions observees :",
    top_contributions(contributions_axes, "Dim.2")
  ),
  remarque_sur_inertie = "Dim.1-Dim.2 fournissent une lecture synthetique mais ne resument pas toute l'information; les axes suivants restent utiles pour interpreter la structure globale."
)

readr::write_csv(
  resume_famd_technique,
  file.path("outputs", "tables", "08_resume_famd_technique.csv")
)

# ------------------------------------------------------------
# 5. Questions possibles de soutenance
# ------------------------------------------------------------

message("Construction de 08_questions_soutenance_reponses.csv.")

k_retenu <- if ("k_recommande" %in% names(k_recommande)) {
  k_recommande$k_recommande[[1]]
} else {
  NA_integer_
}

silhouette_k <- if (!is.na(k_retenu) && all(c("k", "silhouette_moyenne") %in% names(silhouette))) {
  silhouette |>
    dplyr::filter(.data$k == k_retenu) |>
    dplyr::pull(.data$silhouette_moyenne) |>
    dplyr::first(default = NA_real_)
} else {
  NA_real_
}

accuracy_logit <- if ("accuracy" %in% names(metriques_logit)) {
  metriques_logit$accuracy[[1]]
} else {
  NA_real_
}

nb_clusters_interpretes <- if ("cluster_kmeans" %in% names(profils_clusters_interpretes)) {
  dplyr::n_distinct(profils_clusters_interpretes$cluster_kmeans)
} else {
  NA_integer_
}

questions_soutenance_reponses <- tibble::tribble(
  ~question_possible, ~reponse_courte, ~reponse_detaillee,
  "Pourquoi FAMD alors que plusieurs variables sont integer ?",
  "Parce que le type statistique depend du sens de la variable, pas seulement de sa classe informatique.",
  "Certaines variables peuvent etre codees par des entiers dans les donnees brutes tout en representant des categories, par exemple des statuts, formations ou modes de candidature. La FAMD permet de traiter ensemble des variables quantitatives et qualitatives apres preparation, ce qui correspond mieux a la nature mixte du jeu de donnees.",
  "Pourquoi ne pas utiliser ACP ?",
  "L'ACP seule est adaptee aux variables quantitatives continues.",
  "Une ACP imposerait de traiter les codes de categories comme des mesures numeriques ordonnees, ce qui serait trompeur pour les variables comme course, application_mode ou previous_qualification. La FAMD evite cette confusion en combinant la logique de l'ACP pour le quantitatif et de l'ACM pour le qualitatif.",
  "Pourquoi ne pas utiliser ACM seulement ?",
  "L'ACM seule est adaptee aux variables qualitatives.",
  "Le projet contient aussi des notes, ages, nombres d'unites, taux de chomage, inflation et PIB. Transformer toutes ces variables en classes ferait perdre de l'information numerique. La FAMD conserve mieux les deux types d'information.",
  "Pourquoi Target est illustrative ?",
  "Pour analyser la structure des profils sans laisser la cible construire les axes.",
  "La variable target sert a lire les groupes et les axes apres coup. Si elle etait active, les dimensions FAMD seraient orientees par la cible, ce qui rendrait moins neutre l'analyse exploratoire des profils et augmenterait le risque d'une interpretation circulaire.",
  "Pourquoi les groupes se chevauchent dans la FAMD ?",
  "Parce que Dim.1 et Dim.2 ne montrent qu'une partie de l'information.",
  paste0(
    "Les deux premiers axes cumulent ",
    round(resume_famd_technique$`cumul Dim 1 + Dim 2`[[1]], 2),
    "% de l'inertie. Ils donnent une projection lisible, mais les individus restent decrits par plusieurs dimensions et par des variables mixtes. Un chevauchement visuel est donc normal."
  ),
  "Pourquoi faire le clustering sur les coordonnees FAMD ?",
  "Pour regrouper les individus dans un espace factoriel comparable et denoise.",
  "Les coordonnees FAMD synthetisent les variables actives en axes comparables. Le k-means travaille alors sur une representation numerique commune qui respecte mieux le melange quantitatif/qualitatif que les donnees brutes.",
  "Pourquoi ne pas faire le clustering directement sur les donnees brutes ?",
  "Les donnees brutes melangent echelles, comptages, notes et categories.",
  "Un clustering direct donnerait beaucoup de poids aux variables a grande variance ou aux codages arbitraires des categories. Les coordonnees FAMD reduisent ce probleme en placant les individus dans un espace commun issu de l'analyse factorielle.",
  "Pourquoi tester plusieurs k ?",
  "Parce que le nombre de clusters n'est pas connu a l'avance.",
  "Le script 05 compare plusieurs valeurs de k avec le coude et la silhouette. Cette comparaison permet de documenter le choix technique au lieu de fixer arbitrairement un nombre de groupes.",
  "Pourquoi retenir ce nombre de clusters si la silhouette est moderee ?",
  "Parce que la solution retenue est choisie apres comparaison des axes et des valeurs de k, avec une interpretation prudente.",
  paste0(
    "La table existante recommande k = ",
    k_retenu,
    " apres comparaison des solutions candidates",
    ifelse(is.na(silhouette_k), ".", paste0(" (", round(silhouette_k, 3), ").")),
    " Une silhouette moderee indique que les profils ne sont pas totalement separes; le choix doit donc etre defendu avec les profils interpretes",
    ifelse(is.na(nb_clusters_interpretes), ".", paste0(" (", nb_clusters_interpretes, " profils documentes)."))
  ),
  "Que signifient les zeros dans les boxplots ?",
  "Ils peuvent representer une absence de note, d'unites approuvees ou d'evaluations selon la variable.",
  "Les zeros ne doivent pas etre lus automatiquement comme des erreurs. Pour les notes, un zero peut correspondre a aucune performance academique observee; pour approved, a aucune unite approuvee; pour evaluations, a aucune evaluation. Les fichiers 08_audit_zeros_academiques.csv et 08_coherence_zeros_notes.csv quantifient ces cas par target.",
  "La regression logistique est-elle causale ?",
  "Non, elle mesure des associations conditionnelles dans ce jeu de donnees.",
  "La regression logistique estime des relations entre variables et probabilite de Dropout dans le cadre du modele, toutes choses egales par ailleurs dans les variables incluses. Elle indique des associations et non un mecanisme direct, car il peut exister des facteurs non observes, des biais de selection ou des temporalites non controlees.",
  "Le modele logistique est-il un modele de prediction precoce ?",
  "Pas strictement, car il utilise des variables academiques des semestres.",
  paste0(
    "Le modele actuel inclut des informations comme les unites approuvees et les notes des premier et second semestres. Il sert donc surtout d'analyse complementaire et de prediction apres observation du parcours. Pour une prediction precoce, il faudrait limiter les variables a celles disponibles avant ou au tout debut de l'inscription. Accuracy observee dans la sortie existante : ",
    ifelse(is.na(accuracy_logit), "non disponible", round(accuracy_logit, 3)),
    "."
  )
)

readr::write_csv(
  questions_soutenance_reponses,
  file.path("outputs", "tables", "08_questions_soutenance_reponses.csv")
)

# ------------------------------------------------------------
# Figures zeros academiques par target
# ------------------------------------------------------------

message("Creation des figures 08_zeros_notes_par_target.png et 08_zeros_approved_par_target.png.")

donnees_zeros_plot <- donnees |>
  dplyr::select("target", dplyr::all_of(variables_zeros_presentes)) |>
  tidyr::pivot_longer(
    cols = -target,
    names_to = "variable",
    values_to = "valeur"
  ) |>
  dplyr::mutate(est_zero = .data$valeur == 0) |>
  dplyr::group_by(.data$target, .data$variable) |>
  dplyr::summarise(pourcentage_zero = mean(.data$est_zero, na.rm = TRUE) * 100, .groups = "drop")

variables_notes <- c(
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_grade"
)

variables_approved <- c(
  "curricular_units_1st_sem_approved",
  "curricular_units_2nd_sem_approved"
)

p_zeros_notes <- donnees_zeros_plot |>
  dplyr::filter(.data$variable %in% variables_notes) |>
  ggplot2::ggplot(ggplot2::aes(x = .data$target, y = .data$pourcentage_zero, fill = .data$target)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::facet_wrap(ggplot2::vars(.data$variable)) +
  ggplot2::labs(
    title = "Zeros des notes academiques par Target",
    x = "Target",
    y = "Pourcentage de zeros"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path("outputs", "figures", "08_zeros_notes_par_target.png"),
  p_zeros_notes,
  width = 8,
  height = 5,
  dpi = 300
)

p_zeros_approved <- donnees_zeros_plot |>
  dplyr::filter(.data$variable %in% variables_approved) |>
  ggplot2::ggplot(ggplot2::aes(x = .data$target, y = .data$pourcentage_zero, fill = .data$target)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::facet_wrap(ggplot2::vars(.data$variable)) +
  ggplot2::labs(
    title = "Zeros des unites approuvees par Target",
    x = "Target",
    y = "Pourcentage de zeros"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(
  file.path("outputs", "figures", "08_zeros_approved_par_target.png"),
  p_zeros_approved,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 7. Audits de la FAMD principale reduite, du clustering et des modeles
# ------------------------------------------------------------

message("Construction des audits principaux demandes.")

statut_bool <- function(condition) {
  if (isTRUE(condition)) "OK" else "ERREUR"
}

presence_fichier <- function(chemin) {
  tibble::tibble(
    controle = paste0("presence fichier ", chemin),
    statut = statut_bool(file.exists(chemin)),
    detail = ifelse(file.exists(chemin), "Fichier present.", "Fichier absent.")
  )
}

chemin_actives_principale <- file.path("outputs", "tables", "04_principale_variables_actives.csv")
chemin_supp_principale <- file.path("outputs", "tables", "04_principale_variables_supplementaires.csv")

actives_principale <- if (file.exists(chemin_actives_principale)) {
  readr::read_csv(chemin_actives_principale, show_col_types = FALSE)
} else {
  tibble::tibble(variable = character())
}

supp_principale <- if (file.exists(chemin_supp_principale)) {
  readr::read_csv(chemin_supp_principale, show_col_types = FALSE)
} else {
  tibble::tibble(variable = character())
}

variables_actives_principales <- actives_principale |>
  dplyr::pull(.data$variable)

variables_supp_principales <- supp_principale |>
  dplyr::pull(.data$variable)

fichiers_famd_principale <- c(
  file.path("outputs", "models", "04_resultat_famd_principale_reduite.rds"),
  file.path("outputs", "tables", "04_principale_variables_actives.csv"),
  file.path("outputs", "tables", "04_principale_variables_supplementaires.csv"),
  file.path("outputs", "tables", "04_principale_valeurs_propres.csv"),
  file.path("outputs", "tables", "04_principale_contributions_axes_1_2.csv"),
  file.path("outputs", "tables", "04_principale_cos2_variables_axes_1_2.csv"),
  file.path("outputs", "tables", "04_principale_coordonnees_individus.csv"),
  file.path("outputs", "figures", "04_principale_screeplot.png"),
  file.path("outputs", "figures", "04_principale_individus_target.png"),
  file.path("outputs", "figures", "04_principale_barycentres_target.png"),
  file.path("outputs", "figures", "04_principale_variables_top.png")
)

audit_famd_principale <- dplyr::bind_rows(
  purrr::map_dfr(fichiers_famd_principale, presence_fichier),
  tibble::tibble(
    controle = c(
      "target jamais active",
      "dropout_binary et success_binary jamais actives",
      "semestre 2 non actif dans FAMD principale reduite",
      "variables economiques non actives dans FAMD principale reduite",
      "target disponible comme variable supplementaire",
      "variables du semestre 2 disponibles comme supplementaires",
      "variables economiques disponibles comme supplementaires"
    ),
    statut = c(
      statut_bool(!"target" %in% variables_actives_principales),
      statut_bool(length(intersect(c("dropout_binary", "success_binary"), variables_actives_principales)) == 0),
      statut_bool(!any(grepl("2nd_sem", variables_actives_principales))),
      statut_bool(length(intersect(c("unemployment_rate", "inflation_rate", "gdp"), variables_actives_principales)) == 0),
      statut_bool("target" %in% variables_supp_principales),
      statut_bool(all(c("curricular_units_2nd_sem_evaluations", "curricular_units_2nd_sem_approved", "curricular_units_2nd_sem_grade") %in% variables_supp_principales)),
      statut_bool(all(c("unemployment_rate", "inflation_rate", "gdp") %in% variables_supp_principales))
    ),
    detail = c(
      paste("Variables actives :", paste(variables_actives_principales, collapse = ", ")),
      paste("Variables derivees actives :", paste(intersect(c("dropout_binary", "success_binary"), variables_actives_principales), collapse = ", ")),
      paste("Variables semestre 2 actives :", paste(grep("2nd_sem", variables_actives_principales, value = TRUE), collapse = ", ")),
      paste("Variables economiques actives :", paste(intersect(c("unemployment_rate", "inflation_rate", "gdp"), variables_actives_principales), collapse = ", ")),
      paste("Variables supplementaires :", paste(variables_supp_principales, collapse = ", ")),
      "Les variables academiques S2 doivent etre supplementaires uniquement.",
      "Les variables economiques doivent etre supplementaires uniquement."
    )
  )
)

readr::write_csv(
  audit_famd_principale,
  file.path("outputs", "tables", "08_audit_famd_principale_reduite.csv")
)

fichiers_clustering_principal <- c(
  file.path("outputs", "tables", "05_grille_validation_k_axes_principale.csv"),
  file.path("outputs", "tables", "05_recommandation_solution_clustering_principale.csv"),
  file.path("outputs", "tables", "05_clusters_individus_principale.csv"),
  file.path("outputs", "tables", "05_croisement_cluster_target_principale.csv"),
  file.path("outputs", "tables", "05_profils_clusters_principale.csv"),
  file.path("outputs", "tables", "05_silhouette_par_cluster_principale.csv"),
  file.path("outputs", "tables", "05_stabilite_clustering_principale.csv"),
  file.path("outputs", "tables", "05_tests_quanti_par_cluster.csv"),
  file.path("outputs", "tables", "05_tests_quali_par_cluster.csv"),
  file.path("outputs", "tables", "05_test_cluster_target.csv"),
  file.path("outputs", "tables", "05_effets_variables_clusters.csv"),
  file.path("outputs", "figures", "05_principale_methode_coude.png"),
  file.path("outputs", "figures", "05_principale_silhouette_moyenne.png"),
  file.path("outputs", "figures", "05_principale_clusters_famd.png"),
  file.path("outputs", "figures", "05_principale_composition_clusters_target.png"),
  file.path("outputs", "figures", "05_principale_profils_academiques_clusters.png"),
  file.path("outputs", "figures", "05_principale_dendrogramme_cah.png")
)

clusters_principaux <- if (file.exists(file.path("outputs", "tables", "05_clusters_individus_principale.csv"))) {
  readr::read_csv(file.path("outputs", "tables", "05_clusters_individus_principale.csv"), show_col_types = FALSE)
} else {
  tibble::tibble()
}

audit_clustering_principal <- dplyr::bind_rows(
  purrr::map_dfr(fichiers_clustering_principal, presence_fichier),
  tibble::tibble(
    controle = c(
      "clustering principal base sur coordonnees FAMD principale reduite",
      "target non utilisee comme coordonnee de clustering",
      "dropout_binary/success_binary absentes de la table clusters",
      "tests statistiques par cluster presents"
    ),
    statut = c(
      statut_bool(all(c("Dim.1", "Dim.2", "cluster_kmeans") %in% names(clusters_principaux))),
      statut_bool(!"target" %in% grep("^Dim\\.", names(clusters_principaux), value = TRUE)),
      statut_bool(length(intersect(c("dropout_binary", "success_binary"), names(clusters_principaux))) == 0),
      statut_bool(all(file.exists(c(
        file.path("outputs", "tables", "05_tests_quanti_par_cluster.csv"),
        file.path("outputs", "tables", "05_tests_quali_par_cluster.csv"),
        file.path("outputs", "tables", "05_test_cluster_target.csv"),
        file.path("outputs", "tables", "05_effets_variables_clusters.csv")
      ))))
    ),
    detail = c(
      "La table individuelle principale contient les coordonnees Dim.* issues de la FAMD principale reduite.",
      "Target peut etre conservee pour interpretation apres clustering, pas comme coordonnee.",
      "Les variables derivees de target ne doivent pas apparaitre dans la table individuelle de clustering.",
      "Les tests Kruskal-Wallis et Khi-deux doivent etre disponibles."
    )
  )
)

readr::write_csv(
  audit_clustering_principal,
  file.path("outputs", "tables", "08_audit_clustering_principal.csv")
)

fichiers_modeles_logistiques <- c(
  file.path("outputs", "tables", "06_comparaison_modeles_logit.csv"),
  file.path("outputs", "tables", "06_metriques_logit_precoce.csv"),
  file.path("outputs", "tables", "06_metriques_logit_complet.csv"),
  file.path("outputs", "tables", "06_odds_ratios_logit_precoce.csv"),
  file.path("outputs", "tables", "06_odds_ratios_logit_complet.csv"),
  file.path("outputs", "figures", "06_roc_logit_precoce.png"),
  file.path("outputs", "figures", "06_roc_logit_complet.png")
)

comparaison_logit <- if (file.exists(file.path("outputs", "tables", "06_comparaison_modeles_logit.csv"))) {
  readr::read_csv(file.path("outputs", "tables", "06_comparaison_modeles_logit.csv"), show_col_types = FALSE)
} else {
  tibble::tibble()
}

audit_modeles_logistiques <- dplyr::bind_rows(
  purrr::map_dfr(fichiers_modeles_logistiques, presence_fichier),
  tibble::tibble(
    controle = c(
      "modele precoce disponible",
      "modele complet disponible",
      "validation train/test presente",
      "validation croisee simple presente",
      "seuil de prediction documente"
    ),
    statut = c(
      statut_bool("precoce" %in% comparaison_logit$modele),
      statut_bool("complet" %in% comparaison_logit$modele),
      statut_bool("jeu_evaluation" %in% names(comparaison_logit) && all(comparaison_logit$jeu_evaluation == "test")),
      statut_bool(all(c("cv_accuracy_moyenne", "cv_auc_moyenne") %in% names(comparaison_logit))),
      statut_bool("seuil_prediction" %in% names(comparaison_logit) && all(comparaison_logit$seuil_prediction == 0.5))
    ),
    detail = c(
      "Le modele precoce doit utiliser les variables d'entree et le semestre 1.",
      "Le modele complet doit ajouter les variables du semestre 2.",
      "Les metriques principales sont calculees sur un jeu de test.",
      "Une validation croisee simple est resumee dans la comparaison.",
      "Le seuil de classification attendu est 0,5."
    )
  )
)

readr::write_csv(
  audit_modeles_logistiques,
  file.path("outputs", "tables", "08_audit_modeles_logistiques.csv")
)

audits_principaux <- dplyr::bind_rows(
  audit_famd_principale |> dplyr::mutate(audit = "famd_principale"),
  audit_clustering_principal |> dplyr::mutate(audit = "clustering_principal"),
  audit_modeles_logistiques |> dplyr::mutate(audit = "modeles_logistiques")
)

if (any(audits_principaux$statut == "ERREUR")) {
  warning(
    "Certains audits principaux signalent une ERREUR : consulter 08_audit_famd_principale_reduite.csv, ",
    "08_audit_clustering_principal.csv et 08_audit_modeles_logistiques.csv."
  )
}

message("Audit technique termine.")
message("Sorties creees dans outputs/tables et outputs/figures.")
