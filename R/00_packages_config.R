# ============================================================
# Projet : Analyse multivariée des profils d'étudiants
# Dataset : Predict Students' Dropout and Academic Success
# Script 00 : Installation et chargement des packages
# ============================================================

# Objectif :
# Installer et charger uniquement les packages nécessaires au projet.
# Sur Windows, on force l'installation en version binaire pour éviter
# les problèmes de compilation avec Rtools.

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  install.packages.compile.from.source = "never"
)

packages_requis <- c(
  "tidyverse",    # manipulation et visualisation
  "janitor",      # nettoyage des noms de colonnes
  "skimr",        # résumé statistique propre
  "naniar",       # visualisation des valeurs manquantes
  "FactoMineR",   # FAMD, ACP, ACM
  "factoextra",   # visualisation des analyses factorielles
  "cluster",      # silhouette et clustering
  "corrplot",     # matrice de corrélation
  "broom",        # mise en forme des résultats de modèles
  "nnet",         # régression logistique multinomiale
  "knitr",        # tableaux dans RMarkdown
  "kableExtra",   # tableaux propres dans le rapport
  "shiny",        # interface interactive
  "bslib",        # theme moderne pour Shiny
  "DT",           # tableaux interactifs
  "rmarkdown"     # génération du rapport
)

installer_si_absent <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installation du package : ", pkg)
    install.packages(pkg, type = "binary", dependencies = TRUE)
  }
}

invisible(lapply(packages_requis, installer_si_absent))

# Chargement des packages
invisible(lapply(packages_requis, library, character.only = TRUE))

message("Tous les packages nécessaires sont installés et chargés.")
