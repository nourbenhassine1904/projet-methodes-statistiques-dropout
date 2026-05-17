const assetBase = "/project-assets";

export const navItems = [
  { id: "accueil", label: "Accueil" },
  { id: "dataset", label: "Dataset" },
  { id: "descriptive", label: "Analyse descriptive" },
  { id: "famd", label: "FAMD" },
  { id: "clustering", label: "Clustering" },
  { id: "logit", label: "Regression logistique" },
  { id: "recommandations", label: "Recommandations" }
];

export const projectTitle =
  "Analyse multivariee des profils d'etudiants en enseignement superieur";

export const projectSubtitle =
  "FAMD principale reduite, clustering sur coordonnees FAMD et regression logistique complementaire";

export const pipeline = [
  "Import",
  "Preparation",
  "Analyse descriptive",
  "FAMD principale reduite",
  "Clustering k = 2",
  "Regression logistique",
  "Recommandations"
];

export const kpis = [
  { label: "Etudiants", value: "4424", detail: "observations analysees" },
  { label: "Variables actives FAMD", value: "11", detail: "FAMD principale reduite" },
  { label: "Target", value: "illustrative", detail: "jamais active dans la FAMD ni le clustering" },
  { label: "Solution clustering", value: "k = 2", detail: "nb_axes = 2, silhouette 0,508" },
  { label: "AUC logit complet", value: "0,909", detail: "modele complementaire plus tardif" }
];

export const targetDistribution = [
  { target: "Dropout", effectif: 1421, pourcentage: "32,12 %" },
  { target: "Enrolled", effectif: 794, pourcentage: "17,95 %" },
  { target: "Graduate", effectif: 2209, pourcentage: "49,93 %" }
];

export const targetStatuses = [
  {
    title: "Dropout",
    text: "Etudiants sortis du parcours avant l'obtention du diplome."
  },
  {
    title: "Enrolled",
    text: "Etudiants encore inscrits au moment de l'observation."
  },
  {
    title: "Graduate",
    text: "Etudiants ayant termine le parcours avec succes."
  }
];

export const variableTypes = [
  {
    title: "Actives quantitatives",
    text: "Qualification precedente, note d'admission, age, evaluations, unites approuvees et note du premier semestre."
  },
  {
    title: "Actives qualitatives",
    text: "Regime jour/soir, debiteur, frais de scolarite a jour, genre et statut de boursier."
  },
  {
    title: "Supplementaires",
    text: "Target, semestre 2, variables economiques et autres variables de contexte servent a interpreter."
  },
  {
    title: "Cible",
    text: "Target reste illustrative pour lire les axes et les clusters apres leur construction."
  }
];

export const methods = [
  {
    title: "Analyse descriptive",
    text: "Comparer les distributions et reperer les premieres differences entre statuts."
  },
  {
    title: "FAMD principale reduite",
    text: "Projeter 11 variables actives mixtes dans un espace commun."
  },
  {
    title: "Clustering",
    text: "Former deux profils principaux a partir des coordonnees FAMD."
  },
  {
    title: "Regression logistique",
    text: "Comparer deux modeles complementaires, precoce et complet."
  }
];

export const figures = {
  target: {
    src: `${assetBase}/figures/03_a_distribution_target.png`,
    title: "Distribution de la variable Target",
    caption: "Effectifs par statut : Dropout, Enrolled et Graduate.",
    explanation:
      "Target sert de repere descriptif pour qualifier les profils, sans construire les axes FAMD ni les clusters."
  },
  descriptive: [
    {
      src: `${assetBase}/figures/03_d_1st_sem_grade_selon_target.png`,
      title: "Notes du 1er semestre selon Target",
      caption: "Comparaison descriptive des notes académiques au premier semestre.",
      explanation:
        "Les ecarts de niveau indiquent une association descriptive entre performance academique et trajectoire observee."
    },
    {
      src: `${assetBase}/figures/03_d_2nd_sem_grade_selon_target.png`,
      title: "Notes du 2e semestre selon Target",
      caption: "Variable supplementaire dans la FAMD principale reduite.",
      explanation:
        "Le semestre 2 est informatif pour l'interpretation, mais il ne construit pas la FAMD principale reduite."
    },
    {
      src: `${assetBase}/figures/03_d_1st_sem_approved_selon_target.png`,
      title: "Unites approuvees au 1er semestre",
      caption: "Variable active de la FAMD principale reduite.",
      explanation:
        "Le nombre d'unites approuvees au premier semestre contribue fortement a l'axe academique."
    },
    {
      src: `${assetBase}/figures/03_d_2nd_sem_approved_selon_target.png`,
      title: "Unites approuvees au 2e semestre",
      caption: "Variable supplementaire dans la FAMD principale reduite.",
      explanation:
        "Le semestre 2 aide a qualifier les profils apres la construction de la typologie."
    }
  ],
  famd: [
    {
      src: `${assetBase}/figures/04_principale_screeplot.png`,
      title: "FAMD principale reduite - inertie",
      caption: "Valeurs propres des dimensions de la FAMD principale reduite.",
      explanation:
        "Le plan 1-2 resume une partie de l'information et sert de support visuel a l'interpretation."
    },
    {
      src: `${assetBase}/figures/04_principale_variables_top.png`,
      title: "FAMD principale reduite - variables contributives",
      caption: "Variables actives contribuant aux premiers axes.",
      explanation:
        "Les contributions aident a lire un axe principalement academique et un axe de contexte de parcours."
    },
    {
      src: `${assetBase}/figures/04_principale_individus_target.png`,
      title: "FAMD principale reduite - individus",
      caption: "Projection des etudiants, avec Target uniquement illustrative.",
      explanation:
        "La couleur Target aide l'interpretation apres calcul ; elle ne construit pas les axes."
    },
    {
      src: `${assetBase}/figures/04_principale_barycentres_target.png`,
      title: "FAMD principale reduite - barycentres Target",
      caption: "Position des statuts Target comme information illustrative.",
      explanation:
        "Les barycentres montrent une lecture a posteriori des statuts dans l'espace factoriel."
    }
  ],
  clustering: [
    {
      src: `${assetBase}/figures/05_principale_silhouette_moyenne.png`,
      title: "Solution principale k = 2 - silhouette",
      caption: "Silhouette moyenne de la grille axes-k ; solution finale autour de 0,508.",
      explanation:
        "La solution nb_axes = 2, k = 2 combine lisibilite, silhouette elevee et stabilite."
    },
    {
      src: `${assetBase}/figures/05_principale_methode_coude.png`,
      title: "Solution principale k = 2 - methode du coude",
      caption: "Lecture de l'inertie intra-classe pour le clustering principal.",
      explanation:
        "Le coude reste un repere descriptif ; la recommandation finale vient de la grille complete."
    },
    {
      src: `${assetBase}/figures/05_principale_clusters_famd.png`,
      title: "Clusters principaux sur coordonnees FAMD",
      caption: "Projection de la solution principale nb_axes = 2, k = 2.",
      explanation:
        "Les groupes sont construits sur les coordonnees FAMD, pas directement sur les variables brutes."
    },
    {
      src: `${assetBase}/figures/05_principale_composition_clusters_target.png`,
      title: "Composition des deux clusters par Target",
      caption: "Target sert uniquement a qualifier les deux profils apres clustering.",
      explanation:
        "Le cluster 1 est a risque eleve ; le cluster 2 est majoritaire et favorable."
    }
  ],
  logit: {
    src: `${assetBase}/figures/06_probabilites_dropout.png`,
    title: "Probabilites estimees de Dropout",
    caption: "Distribution des probabilites produites par le modele logistique.",
    explanation:
      "La regression logistique reste complementaire et decrit des associations conditionnelles."
  }
};

export const clusters = [
  {
    id: 1,
    name: "Profil a risque eleve",
    size: 929,
    dropout: "81,5 %",
    graduate: "8,9 %",
    risk: "Eleve",
    category: "Profil prioritaire",
    critical: true,
    description:
      "Groupe avec forte proportion de Dropout et indicateurs academiques fragiles des le premier semestre."
  },
  {
    id: 2,
    name: "Profil majoritaire favorable",
    size: 3495,
    dropout: "19,0 %",
    graduate: "60,8 %",
    risk: "Faible",
    category: "Profil favorable",
    description:
      "Groupe majoritaire avec indicateurs academiques plus favorables et forte proportion de Graduate."
  }
];

export const logitMetrics = [
  {
    label: "Modele precoce - accuracy",
    value: "0,849",
    measure: "Variables d'entree et premier semestre.",
    interpretation: "Modele utilisable plus tot, avec une performance deja solide."
  },
  {
    label: "Modele precoce - recall Dropout",
    value: "0,716",
    measure: "Part des Dropout reperes par le modele precoce.",
    interpretation: "Environ sept Dropout sur dix sont reperes dans le jeu de test."
  },
  {
    label: "Modele precoce - AUC",
    value: "0,884",
    measure: "Capacite de discrimination du modele precoce.",
    interpretation: "Bonne discrimination pour un modele disponible plus tot."
  },
  {
    label: "Modele complet - accuracy",
    value: "0,865",
    measure: "Variables d'entree, semestre 1 et semestre 2.",
    interpretation: "Performance globale plus elevee, mais avec des informations plus tardives."
  },
  {
    label: "Modele complet - recall Dropout",
    value: "0,747",
    measure: "Part des Dropout reperes par le modele complet.",
    interpretation: "Rappel plus eleve que le modele precoce."
  },
  {
    label: "Modele complet - AUC",
    value: "0,909",
    measure: "Capacite de discrimination du modele complet.",
    interpretation: "Meilleure discrimination, en contrepartie d'un usage plus tardif."
  }
];

export const oddsRatios = [
  {
    variable: "Age a l'inscription",
    oddsRatio: "1,05",
    badge: "association positive",
    tone: "up",
    interpretation: "Un age plus eleve est associe a une probabilite plus forte de Dropout dans le modele."
  },
  {
    variable: "Debiteur",
    oddsRatio: "1,68",
    badge: "association positive",
    tone: "up",
    interpretation: "Le statut debiteur est associe a une probabilite plus forte de Dropout."
  },
  {
    variable: "Frais de scolarite a jour",
    oddsRatio: "0,11",
    badge: "association negative",
    tone: "down",
    interpretation: "Etre a jour dans les frais est associe a une probabilite plus faible de Dropout."
  },
  {
    variable: "Boursier",
    oddsRatio: "0,43",
    badge: "association negative",
    tone: "down",
    interpretation: "Le statut boursier est associe a une probabilite plus faible de Dropout."
  },
  {
    variable: "Unites approuvees au 2e semestre",
    oddsRatio: "0,65",
    badge: "association negative",
    tone: "down",
    interpretation: "Le semestre 2 ameliore le modele complet, mais arrive plus tard dans le parcours."
  }
];

export const recommendationPlan = [
  {
    result: "Cluster 1",
    interpretation: "Profil a risque eleve : 929 etudiants, 81,5 % de Dropout.",
    action: "Prioriser le suivi academique et administratif de ce groupe."
  },
  {
    result: "Cluster 2",
    interpretation: "Profil majoritaire favorable : 3495 etudiants, 60,8 % de Graduate.",
    action: "Utiliser ce groupe comme reference descriptive des parcours plus favorables."
  },
  {
    result: "Variables du premier semestre",
    interpretation: "Elles structurent fortement la FAMD principale reduite.",
    action: "Mettre en place un suivi precoce apres le premier semestre."
  },
  {
    result: "Modele complet",
    interpretation: "AUC 0,909, plus performant mais plus tardif.",
    action: "Le reserver a une lecture complementaire apres disponibilite du semestre 2."
  },
  {
    result: "Target illustrative",
    interpretation: "Target qualifie les groupes apres construction non supervisee.",
    action: "Eviter toute lecture causale ou supervisee du clustering."
  }
];

export const limits = [
  "Analyse exploratoire.",
  "Target illustrative uniquement dans la FAMD et le clustering.",
  "Projection factorielle 1-2 partielle.",
  "Clustering k = 2 robuste mais moins detaille.",
  "Modele complet plus performant mais plus tardif.",
  "Validation externe absente."
];
