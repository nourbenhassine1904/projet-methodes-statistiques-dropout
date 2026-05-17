library(shiny)
library(bslib)
library(DT)

trouver_racine_projet <- function() {
  candidats <- unique(normalizePath(
    c(getwd(), file.path(getwd(), "..")),
    winslash = "/",
    mustWork = FALSE
  ))

  valides <- candidats[
    file.exists(file.path(candidats, "outputs", "tables")) &
      file.exists(file.path(candidats, "outputs", "figures"))
  ]

  if (length(valides) > 0) {
    return(valides[[1]])
  }

  normalizePath(file.path(getwd(), ".."), winslash = "/", mustWork = FALSE)
}

racine_projet <- trouver_racine_projet()
dossier_tables <- file.path(racine_projet, "outputs", "tables")
dossier_figures <- file.path(racine_projet, "outputs", "figures")

if (dir.exists(dossier_figures)) {
  addResourcePath("figures", dossier_figures)
}

lire_table <- function(nom_fichier) {
  chemin <- file.path(dossier_tables, nom_fichier)

  if (!file.exists(chemin)) {
    return(data.frame(Message = paste("Fichier non disponible :", nom_fichier)))
  }

  read.csv(
    chemin,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

table_dimensions <- lire_table("01_dimensions.csv")
table_target <- lire_table("03_a_distribution_target.csv")
table_dictionnaire <- lire_table("02_dictionnaire_variables.csv")
table_famd_valeurs <- lire_table("04_principale_valeurs_propres.csv")
table_famd_contributions <- lire_table("04_principale_contributions_axes_1_2.csv")
table_k_recommande <- lire_table("05_recommandation_solution_clustering_principale.csv")
table_profils_clusters <- lire_table("05_profils_clusters_principale.csv")
table_logit_metriques <- lire_table("06_comparaison_modeles_logit.csv")
table_logit_confusion <- lire_table("06_matrice_confusion.csv")
table_logit_odds <- lire_table("06_interpretation_odds_ratios.csv")

valeur_dimension <- function(indicateur) {
  if (!all(c("indicateur", "valeur") %in% names(table_dimensions))) {
    return("Non disponible")
  }

  valeur <- table_dimensions$valeur[table_dimensions$indicateur == indicateur]

  if (length(valeur) == 0) {
    return("Non disponible")
  }

  format(valeur[[1]], big.mark = " ", scientific = FALSE)
}

valeur_k <- function() {
  if ("k" %in% names(table_k_recommande)) {
    return(table_k_recommande$k[[1]])
  }

  if ("k_recommande" %in% names(table_k_recommande)) {
    return(table_k_recommande$k_recommande[[1]])
  }

  return("Non disponible")
}

valeur_silhouette <- function() {
  if (!"silhouette_moyenne" %in% names(table_k_recommande)) {
    return("Non disponible")
  }

  format(round(table_k_recommande$silhouette_moyenne[[1]], 3), decimal.mark = ",")
}

formatter_p_values <- function(donnees) {
  colonnes_p <- intersect(c("p_value", "p.value"), names(donnees))
  if (length(colonnes_p) == 0) {
    return(donnees)
  }

  for (colonne in colonnes_p) {
    valeurs <- suppressWarnings(as.numeric(donnees[[colonne]]))
    donnees[[colonne]] <- ifelse(
      is.na(valeurs),
      NA,
      ifelse(
        valeurs < 0.001,
        "p < 0.001",
        formatC(valeurs, format = "f", digits = 3, decimal.mark = ",")
      )
    )
  }

  donnees
}

carte_info <- function(titre, valeur, texte) {
  div(
    class = "metric-card",
    div(class = "metric-label", titre),
    div(class = "metric-value", valeur),
    div(class = "metric-text", texte)
  )
}

bloc_figure <- function(nom_fichier, titre, commentaire = NULL) {
  chemin <- file.path(dossier_figures, nom_fichier)

  bslib::card(
    class = "result-card",
    bslib::card_header(titre),
    if (file.exists(chemin)) {
      tags$img(
        src = paste0("figures/", nom_fichier),
        alt = titre,
        class = "figure-img"
      )
    } else {
      div(class = "missing-box", paste("Figure non disponible :", nom_fichier))
    },
    if (!is.null(commentaire)) {
      p(class = "figure-caption", commentaire)
    }
  )
}

bloc_table <- function(id, titre, commentaire = NULL) {
  bslib::card(
    class = "result-card",
    bslib::card_header(titre),
    if (!is.null(commentaire)) {
      p(class = "table-caption", commentaire)
    },
    DTOutput(id)
  )
}

options_dt <- list(
  pageLength = 8,
  scrollX = TRUE,
  autoWidth = TRUE,
  language = list(
    search = "Rechercher :",
    lengthMenu = "Afficher _MENU_ lignes",
    info = "Lignes _START_ a _END_ sur _TOTAL_",
    infoEmpty = "Aucune ligne",
    zeroRecords = "Aucun resultat",
    paginate = list(
      previous = "Precedent",
      `next` = "Suivant"
    )
  )
)

afficher_dt <- function(donnees, page_length = 8) {
  opts <- options_dt
  opts$pageLength <- page_length
  donnees <- formatter_p_values(donnees)

  DT::datatable(
    donnees,
    rownames = FALSE,
    filter = "top",
    options = opts,
    class = "stripe hover compact"
  )
}

theme_app <- bslib::bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#23546b",
  secondary = "#7b6f58",
  success = "#3f7d5b",
  info = "#4d6f91",
  warning = "#b8802f",
  danger = "#a84e4e"
)

ui <- navbarPage(
  title = "Projet statistique",
  theme = theme_app,
  id = "navigation",
  header = tags$head(
    tags$style(HTML("
      body {
        background: #f6f7f4;
        color: #22313a;
      }

      .navbar {
        box-shadow: 0 2px 14px rgba(21, 36, 43, 0.10);
      }

      .tab-pane {
        padding-top: 22px;
        padding-bottom: 36px;
      }

      .hero {
        padding: 30px 0 24px;
        border-bottom: 1px solid rgba(35, 84, 107, 0.15);
        margin-bottom: 22px;
      }

      .hero h1 {
        font-size: 34px;
        line-height: 1.15;
        margin-bottom: 12px;
        max-width: 1100px;
      }

      .hero p {
        font-size: 18px;
        max-width: 980px;
        color: #3e4b52;
      }

      .section-title {
        font-size: 24px;
        margin: 8px 0 14px;
      }

      .lead-note {
        background: #ffffff;
        border-left: 5px solid #3f7d5b;
        border-radius: 8px;
        padding: 16px 18px;
        margin-bottom: 18px;
        box-shadow: 0 8px 22px rgba(27, 47, 56, 0.07);
      }

      .interpretation {
        background: #eef3f0;
        border: 1px solid rgba(63, 125, 91, 0.22);
        border-radius: 8px;
        padding: 16px 18px;
        margin: 16px 0 22px;
      }

      .interpretation strong {
        color: #23546b;
      }

      .pipeline {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        margin: 18px 0 8px;
      }

      .pipeline-step {
        background: #ffffff;
        border: 1px solid rgba(35, 84, 107, 0.18);
        border-radius: 8px;
        padding: 10px 13px;
        font-weight: 650;
        box-shadow: 0 5px 16px rgba(31, 50, 58, 0.06);
      }

      .metric-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
        gap: 14px;
        margin-bottom: 20px;
      }

      .metric-card {
        background: #ffffff;
        border-radius: 8px;
        border: 1px solid rgba(35, 84, 107, 0.14);
        padding: 16px;
        box-shadow: 0 8px 22px rgba(27, 47, 56, 0.07);
      }

      .metric-label {
        color: #68767c;
        font-size: 14px;
        font-weight: 700;
        text-transform: uppercase;
      }

      .metric-value {
        color: #23546b;
        font-size: 34px;
        line-height: 1.1;
        font-weight: 800;
        margin: 8px 0;
      }

      .metric-text {
        color: #4a565b;
      }

      .result-card {
        border-radius: 8px;
        border: 1px solid rgba(35, 84, 107, 0.14);
        box-shadow: 0 8px 22px rgba(27, 47, 56, 0.07);
        margin-bottom: 18px;
      }

      .card-header {
        font-weight: 750;
        color: #23546b;
        background: #ffffff;
      }

      .figure-img {
        width: 100%;
        max-height: 640px;
        object-fit: contain;
        background: #ffffff;
        border-radius: 6px;
      }

      .figure-caption,
      .table-caption {
        color: #536167;
        margin-top: 10px;
      }

      .missing-box {
        padding: 22px;
        border-radius: 8px;
        background: #fff5e8;
        color: #7b4f17;
        border: 1px solid rgba(184, 128, 47, 0.3);
      }

      .recommendation-list li,
      .limit-list li {
        margin-bottom: 8px;
      }

      @media (max-width: 768px) {
        .hero h1 {
          font-size: 27px;
        }

        .hero p {
          font-size: 16px;
        }
      }
    "))
  ),

  tabPanel(
    "Accueil",
    div(
      class = "hero",
      h1("Analyse multivariee des profils d'etudiants en enseignement superieur"),
      p("Facteurs socio-economiques, parcours academique et reussite a l'aide de la FAMD et du clustering.")
    ),
    fluidRow(
      column(
        6,
        div(
          class = "lead-note",
          h3(class = "section-title", "Problematique"),
          p("Comment identifier des profils d'etudiants associes a la reussite, a l'inscription en cours ou au decrochage, en combinant des variables academiques, socio-economiques et administratives ?")
        )
      ),
      column(
        6,
        div(
          class = "lead-note",
          h3(class = "section-title", "Objectif general"),
          p("Construire une lecture statistique claire des profils etudiants afin de mettre en evidence des associations utiles pour l'interpretation et les recommandations.")
        )
      )
    ),
    div(
      class = "interpretation",
      p(strong("Dataset utilise : "), "UCI Machine Learning Repository, Predict Students' Dropout and Academic Success."),
      p(strong("Message cle : "), "identifier des profils etudiants associes a la reussite ou au decrochage, sans conclure a une relation causale.")
    ),
    h3(class = "section-title", "Pipeline methodologique"),
    div(
      class = "pipeline",
      span(class = "pipeline-step", "Import"),
      span(class = "pipeline-step", "Preparation"),
      span(class = "pipeline-step", "Analyse descriptive"),
      span(class = "pipeline-step", "FAMD"),
      span(class = "pipeline-step", "Clustering"),
      span(class = "pipeline-step", "Regression logistique"),
      span(class = "pipeline-step", "Recommandations")
    )
  ),

  tabPanel(
    "Donnees",
    h2("Donnees utilisees"),
    div(
      class = "metric-grid",
      carte_info("Nombre de lignes", valeur_dimension("nombre_lignes"), "Lu depuis outputs/tables/01_dimensions.csv."),
      carte_info("Nombre de colonnes", valeur_dimension("nombre_colonnes"), "Lu depuis outputs/tables/01_dimensions.csv.")
    ),
    div(
      class = "interpretation",
      p(strong("Lecture de Target : "), code("Dropout"), " correspond au decrochage, ", code("Enrolled"), " aux etudiants encore inscrits, et ", code("Graduate"), " aux etudiants diplomes."),
      p("Cette repartition sert de point de depart pour comparer les profils, sans supposer que les variables observees expliquent causalement le statut final.")
    ),
    fluidRow(
      column(6, bloc_table("table_target", "Distribution de Target", "Effectifs, proportions et pourcentages issus du fichier CSV exporte.")),
      column(6, bloc_figure("03_a_distribution_target.png", "Distribution graphique de Target"))
    ),
    bloc_table("table_dictionnaire", "Dictionnaire des variables", "Affiche si outputs/tables/02_dictionnaire_variables.csv est disponible.")
  ),

  tabPanel(
    "Analyse descriptive",
    h2("Analyse descriptive"),
    div(
      class = "interpretation",
      p("Les graphiques descriptifs mettent en evidence que les variables academiques differencient fortement les statuts ", code("Dropout"), ", ", code("Enrolled"), " et ", code("Graduate"), "."),
      p("Cette lecture suggere une association entre performances academiques et statut final, tout en restant descriptive.")
    ),
    fluidRow(
      column(6, bloc_figure("03_d_1st_sem_grade_selon_target.png", "Notes du premier semestre selon Target")),
      column(6, bloc_figure("03_d_2nd_sem_grade_selon_target.png", "Notes du deuxieme semestre selon Target"))
    ),
    fluidRow(
      column(6, bloc_figure("03_d_1st_sem_approved_selon_target.png", "Unites approuvees au premier semestre selon Target")),
      column(6, bloc_figure("03_d_2nd_sem_approved_selon_target.png", "Unites approuvees au deuxieme semestre selon Target"))
    )
  ),

  tabPanel(
    "FAMD",
    h2("FAMD"),
    div(
      class = "interpretation",
      p(strong("Interpretation retenue : "), "la FAMD principale reduite utilise 11 variables actives. La dimension 1 correspond principalement a un axe academique, tandis que la dimension 2 complete avec le contexte de parcours."),
      p("La variable ", code("Target"), " est utilisee comme variable illustrative ou supplementaire : elle aide a interpreter les positions des individus mais ne pilote pas la construction des axes. Les variables du semestre 2 et les variables economiques sont supplementaires.")
    ),
    fluidRow(
      column(6, bloc_figure("04_principale_screeplot.png", "FAMD principale reduite - valeurs propres")),
      column(6, bloc_figure("04_principale_variables_top.png", "FAMD principale reduite - variables contributives"))
    ),
    fluidRow(
      column(6, bloc_figure("04_principale_individus_target.png", "FAMD principale reduite - individus selon Target illustrative")),
      column(6, bloc_figure("04_principale_barycentres_target.png", "FAMD principale reduite - barycentres Target"))
    ),
    fluidRow(
      column(6, bloc_table("table_famd_valeurs", "Valeurs propres")),
      column(6, bloc_table("table_famd_contributions", "Contributions des variables aux axes 1 et 2"))
    )
  ),

  tabPanel(
    "Clustering",
    h2("Clustering sur les coordonnees FAMD"),
    div(
      class = "metric-grid",
      carte_info("Solution principale", paste0("k = ", valeur_k()), "Clustering sur coordonnees de la FAMD principale reduite."),
      carte_info("Silhouette moyenne", valeur_silhouette(), "Valeur issue de la recommandation finale.")
    ),
    div(
      class = "interpretation",
      p("La solution principale finale est nb_axes = 2, k = ", valeur_k(), ", avec une silhouette moyenne d'environ ", valeur_silhouette(), "."),
      p("Le cluster 1 correspond au profil a risque eleve : 929 etudiants et 81,5 % de Dropout. Le cluster 2 correspond au profil majoritaire favorable : 3495 etudiants, 19,0 % de Dropout et 60,8 % de Graduate."),
      p("Le clustering reste exploratoire et descriptif : il met en evidence des groupes utiles pour l'analyse, mais ne constitue pas une preuve causale.")
    ),
    fluidRow(
      column(6, bloc_figure("05_principale_silhouette_moyenne.png", "Solution principale k = 2 - silhouette moyenne")),
      column(6, bloc_figure("05_principale_methode_coude.png", "Solution principale k = 2 - methode du coude"))
    ),
    fluidRow(
      column(6, bloc_figure("05_principale_clusters_famd.png", "Clusters principaux sur coordonnees FAMD")),
      column(6, bloc_figure("05_principale_composition_clusters_target.png", "Composition des deux clusters selon Target illustrative"))
    ),
    fluidRow(
      column(5, bloc_table("table_k_recommande", "Choix de k")),
      column(7, bloc_table("table_profils_clusters", "Profils de clusters interpretes"))
    )
  ),

  tabPanel(
    "Regression logistique",
    h2("Regression logistique complementaire"),
    div(
      class = "interpretation",
      p("Cette partie complete l'analyse exploratoire en etudiant la distinction ", code("Dropout"), " vs ", code("Non_Dropout"), ". Elle compare un modele precoce et un modele complet."),
      p("Modele precoce : accuracy 0,849, recall Dropout 0,716, AUC 0,884. Modele complet : accuracy 0,865, recall Dropout 0,747, AUC 0,909."),
      p("Les odds ratios doivent etre interpretes comme des associations statistiques. Ils ne permettent pas, a eux seuls, de conclure a un effet causal.")
    ),
    fluidRow(
      column(6, bloc_table("table_logit_metriques", "Metriques detaillees du modele")),
      column(6, bloc_table("table_logit_confusion", "Matrice de confusion"))
    ),
    bloc_table("table_logit_odds", "Interpretation des odds ratios"),
    bloc_figure("06_probabilites_dropout.png", "Probabilites estimees de Dropout")
  ),

  tabPanel(
    "Synthese et recommandations",
    h2("Synthese et recommandations"),
    div(
      class = "interpretation",
      h3(class = "section-title", "Resultats principaux"),
      tags$ul(
        tags$li("La FAMD principale reduite utilise 11 variables actives."),
        tags$li("Target est illustrative uniquement ; semestre 2 et variables economiques sont supplementaires."),
        tags$li("Le clustering principal retient nb_axes = 2, k = ", valeur_k(), "."),
        tags$li("Le cluster 1 est le profil a risque eleve : 929 etudiants, 81,5 % de Dropout."),
        tags$li("Le cluster 2 est le profil majoritaire favorable : 3495 etudiants, 60,8 % de Graduate.")
      )
    ),
    fluidRow(
      column(
        6,
        bslib::card(
          class = "result-card",
          bslib::card_header("Recommandations"),
          tags$ul(
            class = "recommendation-list",
            tags$li("Mettre en place un suivi academique precoce."),
            tags$li("Prevoir un accompagnement financier pour les situations fragiles."),
            tags$li("Surveiller les etudiants debiteurs dans une logique d'aide et de prevention."),
            tags$li("Accompagner les etudiants ayant un faible nombre d'unites approuvees."),
            tags$li("Renforcer le suivi du deuxieme semestre, qui semble fortement informatif.")
          )
        )
      ),
      column(
        6,
        bslib::card(
          class = "result-card",
          bslib::card_header("Limites"),
          tags$ul(
            class = "limit-list",
            tags$li("L'analyse reste exploratoire."),
            tags$li("Les resultats ne permettent pas d'etablir une causalite."),
            tags$li("Les conclusions dependent du dataset utilise."),
            tags$li("La silhouette est moderee et invite a rester prudent."),
            tags$li("Une validation sur d'autres cohortes serait necessaire.")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  output$table_target <- renderDT(afficher_dt(table_target, page_length = 5))
  output$table_dictionnaire <- renderDT(afficher_dt(table_dictionnaire, page_length = 10))
  output$table_famd_valeurs <- renderDT(afficher_dt(table_famd_valeurs, page_length = 8))
  output$table_famd_contributions <- renderDT(afficher_dt(table_famd_contributions, page_length = 8))
  output$table_k_recommande <- renderDT(afficher_dt(table_k_recommande, page_length = 5))
  output$table_profils_clusters <- renderDT(afficher_dt(table_profils_clusters, page_length = 8))
  output$table_logit_metriques <- renderDT(afficher_dt(table_logit_metriques, page_length = 5))
  output$table_logit_confusion <- renderDT(afficher_dt(table_logit_confusion, page_length = 5))
  output$table_logit_odds <- renderDT(afficher_dt(table_logit_odds, page_length = 8))
}

shinyApp(ui = ui, server = server)
