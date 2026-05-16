const assetBase = "/project-assets";

export const navItems = [
  { id: "accueil", label: "Accueil" },
  { id: "dataset", label: "Dataset" },
  { id: "descriptive", label: "Analyse descriptive" },
  { id: "famd", label: "FAMD" },
  { id: "clustering", label: "Clustering" },
  { id: "logit", label: "Régression logistique" },
  { id: "recommandations", label: "Recommandations" }
];

export const projectTitle =
  "Analyse multivariée des profils d'étudiants en enseignement supérieur";

export const projectSubtitle =
  "Facteurs socio-économiques, parcours académique et réussite à l'aide de la FAMD et du clustering";

export const pipeline = [
  "Import",
  "Préparation",
  "Analyse descriptive",
  "FAMD",
  "Clustering",
  "Régression logistique",
  "Recommandations"
];

export const kpis = [
  { label: "Étudiants", value: "4424", detail: "observations analysées" },
  { label: "Variables", value: "37", detail: "descripteurs du parcours" },
  { label: "Statuts", value: "3", detail: "Dropout, Enrolled, Graduate" },
  { label: "Profils", value: "6", detail: "clusters interprétés" },
  { label: "Accuracy logistique", value: "85,76 %", detail: "modèle complémentaire" }
];

export const targetDistribution = [
  { target: "Dropout", effectif: 1421, pourcentage: "32,12 %" },
  { target: "Enrolled", effectif: 794, pourcentage: "17,95 %" },
  { target: "Graduate", effectif: 2209, pourcentage: "49,93 %" }
];

export const targetStatuses = [
  {
    title: "Dropout",
    text: "Étudiants sortis du parcours avant l'obtention du diplôme."
  },
  {
    title: "Enrolled",
    text: "Étudiants encore inscrits au moment de l'observation."
  },
  {
    title: "Graduate",
    text: "Étudiants ayant terminé le parcours avec succès."
  }
];

export const variableTypes = [
  {
    title: "Académiques",
    text: "Notes, unités inscrites et unités approuvées, principalement par semestre."
  },
  {
    title: "Socio-économiques",
    text: "Bourse, statut débiteur, frais de scolarité et indicateurs de contexte."
  },
  {
    title: "Administratives",
    text: "Régime, statut de déplacement, caractéristiques d'inscription et de parcours."
  },
  {
    title: "Économiques",
    text: "Variables de contexte comme le PIB, l'inflation et le chômage."
  }
];

export const methods = [
  {
    title: "Analyse descriptive",
    text: "Comparer les distributions et repérer les premières différences entre statuts."
  },
  {
    title: "FAMD",
    text: "Projeter simultanément les variables quantitatives et qualitatives dans un espace commun."
  },
  {
    title: "Clustering",
    text: "Transformer l'espace factoriel en profils étudiants interprétables."
  },
  {
    title: "Régression logistique",
    text: "Vérifier, en complément, les associations avec une cible binaire Dropout vs Non_Dropout."
  }
];

export const figures = {
  target: {
    src: `${assetBase}/figures/03_a_distribution_target.png`,
    title: "Distribution de la variable Target",
    caption: "Effectifs par statut : Dropout, Enrolled et Graduate.",
    explanation:
      "Le graphique donne le poids relatif de chaque statut et sert de point de départ pour comparer les profils."
  },
  descriptive: [
    {
      src: `${assetBase}/figures/03_d_1st_sem_grade_selon_target.png`,
      title: "Notes du 1er semestre selon Target",
      caption: "Comparaison des notes académiques au premier semestre.",
      explanation:
        "La lecture se fait par statut : les écarts de niveau suggèrent que la performance académique différencie déjà les trajectoires."
    },
    {
      src: `${assetBase}/figures/03_d_2nd_sem_grade_selon_target.png`,
      title: "Notes du 2e semestre selon Target",
      caption: "Comparaison des notes académiques au deuxième semestre.",
      explanation:
        "Le deuxième semestre met en évidence des différences utiles pour identifier les situations à risque et préparer la modélisation."
    },
    {
      src: `${assetBase}/figures/03_d_1st_sem_approved_selon_target.png`,
      title: "Unités approuvées au 1er semestre",
      caption: "Unités validées selon le statut final.",
      explanation:
        "Le nombre d'unités approuvées indique l'avancement académique et nourrit l'axe académique observé ensuite en FAMD."
    },
    {
      src: `${assetBase}/figures/03_d_2nd_sem_approved_selon_target.png`,
      title: "Unités approuvées au 2e semestre",
      caption: "Unités validées au deuxième semestre selon Target.",
      explanation:
        "Cette figure est importante car le deuxième semestre apparaît informatif pour distinguer les profils de réussite et de décrochage."
    }
  ],
  famd: [
    {
      src: `${assetBase}/figures/04_famd_screeplot.png`,
      title: "Lecture de l'inertie",
      caption: "Valeurs propres des dimensions de la FAMD.",
      explanation:
        "Les premières dimensions résument une partie de l'information seulement, ce qui est attendu avec des données mixtes et nombreuses."
    },
    {
      src: `${assetBase}/figures/04_famd_contributions_axes_1_2.png`,
      title: "Contributions aux axes 1 et 2",
      caption: "Variables contribuant à la construction des deux premiers axes.",
      explanation:
        "Les contributions aident à nommer les axes et à distinguer les dimensions académique et socio-administrative."
    },
    {
      src: `${assetBase}/figures/04_famd_individus_target.png`,
      title: "Carte des individus",
      caption: "Projection des étudiants, avec Target utilisée comme information illustrative.",
      explanation:
        "Les proximités entre individus suggèrent des profils voisins ; la couleur Target aide l'interprétation sans construire les axes."
    },
    {
      src: `${assetBase}/figures/04_famd_variables.png`,
      title: "Carte des variables",
      caption: "Projection des variables dans l'espace factoriel.",
      explanation:
        "Les variables proches d'un axe contribuent à son interprétation statistique et pédagogique."
    }
  ],
  clustering: [
    {
      src: `${assetBase}/figures/05_silhouette_moyenne.png`,
      title: "Silhouette moyenne",
      caption: "Critère technique pour comparer plusieurs valeurs de k.",
      explanation:
        "La silhouette soutient le choix de k, tout en rappelant que la séparation des groupes reste exploratoire."
    },
    {
      src: `${assetBase}/figures/05_methode_coude.png`,
      title: "Méthode du coude",
      caption: "Lecture de l'inertie intra-classe selon le nombre de clusters.",
      explanation:
        "La méthode du coude complète la silhouette et aide à retenir un nombre de profils interprétable."
    },
    {
      src: `${assetBase}/figures/05_clusters_kmeans_famd.png`,
      title: "Clusters k-means sur coordonnées FAMD",
      caption: "Projection des profils dans l'espace factoriel.",
      explanation:
        "Les clusters transforment les coordonnées FAMD en groupes lisibles pour la soutenance et la décision."
    },
    {
      src: `${assetBase}/figures/05_composition_clusters_target.png`,
      title: "Composition des clusters par Target",
      caption: "Répartition de Dropout, Enrolled et Graduate dans chaque cluster.",
      explanation:
        "La composition par Target permet de qualifier les profils favorables, intermédiaires ou à risque."
    }
  ],
  logit: {
    src: `${assetBase}/figures/06_probabilites_dropout.png`,
    title: "Probabilités estimées de Dropout",
    caption: "Distribution des probabilités produites par le modèle logistique.",
    explanation:
      "La figure permet de voir comment le modèle sépare les situations estimées comme plus ou moins proches du Dropout."
  }
};

export const clusters = [
  {
    id: 1,
    name: "Profil fragile à risque académique",
    size: 74,
    dropout: "64,86 %",
    graduate: "17,57 %",
    risk: "Élevé",
    category: "Profil à risque",
    description: "Petit groupe avec forte proportion de Dropout et faibles performances académiques."
  },
  {
    id: 2,
    name: "Profil performant à forte réussite",
    size: 619,
    dropout: "18,26 %",
    graduate: "64,62 %",
    risk: "Faible",
    category: "Profil favorable",
    description: "Groupe avec forte proportion de Graduate, note d'admission élevée et bonnes performances académiques."
  },
  {
    id: 3,
    name: "Profil stable majoritaire",
    size: 2158,
    dropout: "14,97 %",
    graduate: "64,37 %",
    risk: "Faible",
    category: "Profil favorable",
    description: "Groupe majoritaire avec forte proportion de Graduate et situation globale stable."
  },
  {
    id: 4,
    name: "Profil critique de décrochage",
    size: 619,
    dropout: "79,48 %",
    graduate: "11,31 %",
    risk: "Très élevé",
    category: "Profil critique",
    critical: true,
    description: "Groupe avec très forte proportion de Dropout, très faibles unités approuvées et notes très faibles."
  },
  {
    id: 5,
    name: "Profil intermédiaire en transition",
    size: 585,
    dropout: "36,58 %",
    graduate: "47,18 %",
    risk: "Modéré",
    category: "Profil intermédiaire",
    description: "Groupe combinant réussite, inscription en cours et risque de Dropout non négligeable."
  },
  {
    id: 6,
    name: "Profil à risque élevé",
    size: 369,
    dropout: "62,60 %",
    graduate: "16,53 %",
    risk: "Élevé",
    category: "Profil à risque",
    description: "Groupe avec forte proportion de Dropout et profil académique à surveiller."
  }
];

export const logitMetrics = [
  {
    label: "Accuracy",
    value: "85,76 %",
    measure: "Part des prédictions correctes sur l'ensemble des cas.",
    interpretation: "Le modèle classe correctement une grande part des étudiants."
  },
  {
    label: "Precision Dropout",
    value: "82,11 %",
    measure: "Parmi les étudiants prédits Dropout, part effectivement Dropout.",
    interpretation: "Les alertes Dropout sont relativement ciblées."
  },
  {
    label: "Recall Dropout",
    value: "71,13 %",
    measure: "Parmi les étudiants réellement Dropout, part repérée par le modèle.",
    interpretation: "Une partie des Dropout reste non repérée, ce qui invite à la prudence."
  },
  {
    label: "F1 Dropout",
    value: "76,23 %",
    measure: "Équilibre entre précision et rappel pour la classe Dropout.",
    interpretation: "La performance sur Dropout est cohérente mais non parfaite."
  },
  {
    label: "Specificity Non_Dropout",
    value: "92,68 %",
    measure: "Capacité à reconnaître les étudiants Non_Dropout.",
    interpretation: "Le modèle identifie bien les situations non associées au décrochage."
  }
];

export const oddsRatios = [
  {
    variable: "Âge à l'inscription",
    oddsRatio: "1,05",
    badge: "risque augmenté",
    tone: "up",
    interpretation: "Un âge plus élevé est associé à une probabilité plus forte de Dropout."
  },
  {
    variable: "Débiteur",
    oddsRatio: "1,68",
    badge: "risque augmenté",
    tone: "up",
    interpretation: "Le statut débiteur est associé à un risque de Dropout plus élevé."
  },
  {
    variable: "Frais de scolarité à jour",
    oddsRatio: "0,11",
    badge: "risque diminué",
    tone: "down",
    interpretation: "Être à jour dans les frais est associé à une probabilité plus faible de Dropout."
  },
  {
    variable: "Boursier",
    oddsRatio: "0,43",
    badge: "risque diminué",
    tone: "down",
    interpretation: "Le statut boursier est associé à une probabilité plus faible de Dropout."
  },
  {
    variable: "Unités approuvées au 2e semestre",
    oddsRatio: "0,65",
    badge: "risque diminué",
    tone: "down",
    interpretation: "Plus d'unités approuvées au 2e semestre est associé à une baisse du risque."
  }
];

export const recommendationPlan = [
  {
    result: "Faibles unités approuvées",
    interpretation: "Risque académique plus visible dans les profils fragiles.",
    action: "Mettre en place un suivi académique précoce."
  },
  {
    result: "Débiteur / frais non à jour",
    interpretation: "Fragilité financière associée au risque de décrochage.",
    action: "Proposer un accompagnement financier ciblé."
  },
  {
    result: "Cluster 4",
    interpretation: "Profil critique avec la plus forte proportion de Dropout.",
    action: "Déclencher une intervention prioritaire."
  },
  {
    result: "Deuxième semestre informatif",
    interpretation: "Les résultats du S2 affinent la lecture du risque.",
    action: "Suivre les étudiants après S1 et S2."
  },
  {
    result: "Silhouette modérée",
    interpretation: "Le clustering reste exploratoire.",
    action: "Tester les profils sur d'autres cohortes."
  }
];

export const limits = [
  "Analyse exploratoire.",
  "Absence de causalité démontrée.",
  "Dépendance au dataset étudié.",
  "Silhouette modérée.",
  "Généralisation à valider sur d'autres cohortes."
];
