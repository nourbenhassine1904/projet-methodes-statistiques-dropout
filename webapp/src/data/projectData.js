const assetBase = "/project-assets";

export const projectTitle =
  "Analyse multivariee des profils d'etudiants en enseignement superieur";

export const projectSubtitle =
  "FAMD principale reduite, clustering sur coordonnees FAMD et modeles logistiques complementaires";

export const navItems = [
  { id: "overview", label: "Vue d'ensemble" },
  { id: "variables", label: "Donnees et variables" },
  { id: "famd", label: "FAMD" },
  { id: "clustering", label: "Clustering" },
  { id: "logit", label: "Regression logistique" },
  { id: "interpretation", label: "Interpretation finale" },
  { id: "defense", label: "Preparation soutenance" }
];

export const headlineKpis = [
  { label: "Observations", value: "4 424", detail: "etudiants du dataset UCI" },
  { label: "Variables", value: "39", detail: "apres preparation, cible incluse" },
  { label: "Methode principale", value: "FAMD reduite", detail: "11 variables actives mixtes" },
  { label: "Clustering", value: "2 axes, k = 2", detail: "solution principale recalculée" },
  { label: "Silhouette", value: "0,508", detail: "solution stable et lisible" },
  { label: "Profil a risque", value: "81,5 %", detail: "Dropout dans le cluster 1" },
  { label: "Profil favorable", value: "60,8 %", detail: "Graduate dans le cluster 2" },
  { label: "AUC precoce", value: "0,884", detail: "modele d'alerte plus tot" },
  { label: "AUC complet", value: "0,909", detail: "modele plus performant, plus tardif" }
];

export const targetDistribution = [
  { target: "Dropout", effectif: "1 421", pourcentage: "32,12 %" },
  { target: "Enrolled", effectif: "794", pourcentage: "17,95 %" },
  { target: "Graduate", effectif: "2 209", pourcentage: "49,93 %" }
];

export const methodologyBadges = [
  "Target illustrative uniquement",
  "Semestre 2 supplementaire",
  "Variables economiques supplementaires",
  "Aucun clustering sur donnees brutes",
  "dropout_binary et success_binary exclus"
];

export const pipelineSteps = [
  {
    title: "Preparation",
    text: "Nettoyage des noms, typage statistique des variables, conversion des codes qualitatifs en facteurs."
  },
  {
    title: "FAMD principale reduite",
    text: "Construction d'un espace factoriel mixte avec 11 variables actives defendables."
  },
  {
    title: "Clustering principal",
    text: "k-means applique uniquement aux coordonnees individuelles issues de la FAMD."
  },
  {
    title: "Validation",
    text: "Grille axes-k, silhouette, tailles des groupes, stabilite et tests par cluster."
  },
  {
    title: "Modeles logistiques",
    text: "Comparaison d'un modele precoce et d'un modele complet en lecture complementaire."
  }
];

export const variableFamilies = [
  {
    id: "administrative",
    family: "Variables d'entree administratives",
    role: "Actives ou supplementaires selon leur lisibilite",
    examples: "daytime_evening_attendance, debtor, tuition_fees_up_to_date, gender, scholarship_holder",
    explanation:
      "Elles decrivent le contexte d'inscription et certaines contraintes administratives ou financieres."
  },
  {
    id: "semester1",
    family: "Variables academiques semestre 1",
    role: "Actives dans la FAMD principale reduite",
    examples:
      "curricular_units_1st_sem_evaluations, approved, grade, admission_grade",
    explanation:
      "Elles sont disponibles tot dans le parcours et structurent fortement l'axe academique."
  },
  {
    id: "semester2",
    family: "Variables academiques semestre 2",
    role: "Supplementaires dans la FAMD principale reduite",
    examples:
      "curricular_units_2nd_sem_evaluations, approved, grade",
    explanation:
      "Elles enrichissent l'interpretation mais ne construisent pas la FAMD principale reduite."
  },
  {
    id: "economic",
    family: "Variables economiques",
    role: "Supplementaires ou descriptives",
    examples: "unemployment_rate, inflation_rate, gdp",
    explanation:
      "Elles donnent un contexte macro-economique mais ne sont pas actives dans la FAMD principale."
  },
  {
    id: "target",
    family: "Variable cible",
    role: "Illustrative uniquement",
    examples: "target = Dropout, Enrolled, Graduate",
    explanation:
      "Elle sert a caracteriser les profils apres calcul, sans construire les axes ni les clusters."
  },
  {
    id: "excluded",
    family: "Variables creees ou exclues",
    role: "Jamais actives dans les analyses non supervisees",
    examples: "dropout_binary, success_binary",
    explanation:
      "Ces variables derivent de la cible et seraient une fuite d'information dans la FAMD ou le clustering."
  }
];

export const activeVariables = [
  { variable: "previous_qualification_grade", type: "Quantitative", group: "Entree" },
  { variable: "admission_grade", type: "Quantitative", group: "Entree" },
  { variable: "age_at_enrollment", type: "Quantitative", group: "Entree" },
  { variable: "curricular_units_1st_sem_evaluations", type: "Quantitative", group: "Semestre 1" },
  { variable: "curricular_units_1st_sem_approved", type: "Quantitative", group: "Semestre 1" },
  { variable: "curricular_units_1st_sem_grade", type: "Quantitative", group: "Semestre 1" },
  { variable: "daytime_evening_attendance", type: "Qualitative", group: "Entree" },
  { variable: "debtor", type: "Qualitative", group: "Socio-administratif" },
  { variable: "tuition_fees_up_to_date", type: "Qualitative", group: "Socio-administratif" },
  { variable: "gender", type: "Qualitative", group: "Socio-demographique" },
  { variable: "scholarship_holder", type: "Qualitative", group: "Socio-administratif" }
];

export const supplementaryVariables = [
  "target",
  "course",
  "curricular_units_2nd_sem_evaluations",
  "curricular_units_2nd_sem_approved",
  "curricular_units_2nd_sem_grade",
  "unemployment_rate",
  "inflation_rate",
  "gdp",
  "application_mode",
  "application_order",
  "previous_qualification",
  "mothers_qualification",
  "fathers_qualification",
  "displaced"
];

export const auditChecks = [
  { check: "target jamais active", status: "OK" },
  { check: "dropout_binary et success_binary jamais actives", status: "OK" },
  { check: "semestre 2 non actif dans la FAMD principale reduite", status: "OK" },
  { check: "variables economiques non actives dans la FAMD principale reduite", status: "OK" },
  { check: "clustering principal base sur coordonnees FAMD", status: "OK" },
  { check: "tests statistiques par cluster presents", status: "OK" }
];

export const famdMetrics = [
  { label: "Variables actives", value: "11", detail: "6 quantitatives + 5 qualitatives" },
  { label: "Dim.1", value: "21,81 %", detail: "inertie expliquee" },
  { label: "Dim.2", value: "15,95 %", detail: "inertie expliquee" },
  { label: "Dim.1 + Dim.2", value: "37,76 %", detail: "inertie cumulee" }
];

export const famdAxisReadings = [
  {
    title: "Dim.1 : niveau academique",
    text:
      "Elle est surtout liee aux unites validees, aux notes et aux evaluations du premier semestre."
  },
  {
    title: "Dim.2 : lecture complementaire",
    text:
      "Elle ajoute une lecture de contexte de parcours : age, admission, qualification precedente, regime jour/soir et dimensions socio-administratives."
  }
];

export const clusteringRecommendation = {
  solution: "nb_axes = 2, k = 2",
  silhouette: "0,508",
  inertia: "10 802,55",
  minSize: "929",
  maxSize: "3 495",
  ratio: "3,76",
  stability: "stable",
  ari: "1,00"
};

export const clusters = [
  {
    id: 1,
    name: "Profil a risque eleve",
    size: "929",
    dropout: "81,5 %",
    enrolled: "9,6 %",
    graduate: "8,9 %",
    risk: "Eleve",
    description:
      "Groupe plus fragile, avec des indicateurs academiques nettement plus faibles et une forte proportion de Dropout.",
    academicNote:
      "Moyenne S1 approved : 0,70 ; moyenne S1 grade : 2,68 ; moyenne S2 grade : 2,47."
  },
  {
    id: 2,
    name: "Profil majoritaire favorable",
    size: "3 495",
    dropout: "19,0 %",
    enrolled: "20,2 %",
    graduate: "60,8 %",
    risk: "Faible",
    description:
      "Groupe majoritaire, avec de meilleurs indicateurs academiques et une proportion elevee de Graduate.",
    academicNote:
      "Moyenne S1 approved : 5,77 ; moyenne S1 grade : 12,76 ; moyenne S2 grade : 12,29."
  }
];

export const clusterValidationRows = [
  { metric: "Solution recommandee", value: "2 axes FAMD, k = 2", reading: "Solution principale apres recalcul." },
  { metric: "Silhouette moyenne", value: "0,508", reading: "Separation correcte pour une typologie exploratoire." },
  { metric: "Taille minimale", value: "929", reading: "Aucun petit groupe instable." },
  { metric: "Stabilite", value: "ARI moyen = 1,00", reading: "Solution stable sur 30 repetitions." },
  { metric: "Cluster x Target", value: "V de Cramer = 0,549", reading: "Association forte apres clustering non supervise." }
];

export const quantitativeTests = [
  { variable: "curricular_units_1st_sem_approved", test: "Kruskal-Wallis", pValue: "< 0,001", reading: "difference nette" },
  { variable: "curricular_units_1st_sem_grade", test: "Kruskal-Wallis", pValue: "< 0,001", reading: "difference nette" },
  { variable: "curricular_units_2nd_sem_approved", test: "Kruskal-Wallis", pValue: "< 0,001", reading: "difference nette" },
  { variable: "age_at_enrollment", test: "Kruskal-Wallis", pValue: "< 0,001", reading: "difference nette" }
];

export const qualitativeTests = [
  { variable: "tuition_fees_up_to_date", test: "Khi-deux", pValue: "< 0,001", effect: "V = 0,458" },
  { variable: "course", test: "Khi-deux", pValue: "< 0,001", effect: "V = 0,411" },
  { variable: "debtor", test: "Khi-deux", pValue: "< 0,001", effect: "V = 0,253" },
  { variable: "gender", test: "Khi-deux", pValue: "< 0,001", effect: "V = 0,233" }
];

export const logitComparison = [
  {
    model: "Modele precoce",
    inputs: "Variables d'entree + semestre 1",
    accuracy: "0,849",
    precision: "0,794",
    recall: "0,716",
    f1: "0,753",
    auc: "0,884",
    reading: "Plus utile pour une logique d'alerte plus tot."
  },
  {
    model: "Modele complet",
    inputs: "Variables d'entree + semestre 1 + semestre 2",
    accuracy: "0,865",
    precision: "0,816",
    recall: "0,747",
    f1: "0,780",
    auc: "0,909",
    reading: "Plus performant, mais disponible plus tard."
  }
];

export const metricGlossary = [
  { metric: "Accuracy", meaning: "Part globale de predictions correctes." },
  { metric: "Precision Dropout", meaning: "Parmi les predictions Dropout, part vraiment Dropout." },
  { metric: "Recall Dropout", meaning: "Parmi les vrais Dropout, part reperee par le modele." },
  { metric: "F1 Dropout", meaning: "Synthese precision/rappel pour la classe Dropout." },
  { metric: "AUC", meaning: "Capacite du modele a classer les risques relatifs." }
];

export const logisticOddsNotes = [
  "Les odds ratios indiquent des associations conditionnelles dans le modele.",
  "Les variables avec p-value > 0,05 ne sont pas lues comme clairement associees.",
  "Le modele complet inclut le semestre 2 : il est plus informatif, mais plus tardif.",
  "Le modele precoce est moins performant, mais mieux adapte a une logique d'alerte."
];

export const finalInterpretation = [
  {
    title: "Structure multivariee",
    text:
      "La FAMD met en evidence une structure fortement liee aux performances academiques du premier semestre."
  },
  {
    title: "Segmentation",
    text:
      "Le clustering sur coordonnees FAMD isole un profil a risque eleve et un profil majoritaire favorable."
  },
  {
    title: "Modelisation complementaire",
    text:
      "Les modeles logistiques indiquent que les variables academiques sont tres informatives pour Dropout vs Non_Dropout."
  },
  {
    title: "Lecture prudente",
    text:
      "Les resultats decrivent des associations dans ce dataset et doivent etre lus comme une analyse exploratoire."
  }
];

export const recommendationPlan = [
  {
    result: "Cluster 1",
    interpretation: "Profil a risque eleve : 929 etudiants, 81,5 % Dropout.",
    action: "Prioriser le suivi academique et administratif."
  },
  {
    result: "Cluster 2",
    interpretation: "Profil majoritaire favorable : 3 495 etudiants, 60,8 % Graduate.",
    action: "Utiliser comme reference descriptive des parcours plus favorables."
  },
  {
    result: "Modele precoce",
    interpretation: "AUC 0,884 avec variables d'entree et semestre 1.",
    action: "Support possible pour une logique d'alerte plus tot."
  },
  {
    result: "Modele complet",
    interpretation: "AUC 0,909 avec le semestre 2.",
    action: "Lecture complementaire plus performante mais plus tardive."
  }
];

export const defenseQuestions = [
  {
    question: "Pourquoi utiliser la FAMD ?",
    answer:
      "Parce que le dataset contient des variables quantitatives et qualitatives. La FAMD traite ces deux types dans un meme espace factoriel."
  },
  {
    question: "Pourquoi pas une ACP seule ?",
    answer:
      "L'ACP suppose des variables quantitatives. Elle traiterait des codes qualitatifs comme des nombres, ce qui serait moins coherent."
  },
  {
    question: "Pourquoi target est illustrative ?",
    answer:
      "Pour eviter que le statut final construise les axes ou les clusters. Target sert seulement a interpreter apres calcul."
  },
  {
    question: "Pourquoi le semestre 2 est supplementaire ?",
    answer:
      "La FAMD principale reduite privilegie une lecture plus defendable et plus precoce. Le semestre 2 enrichit l'interpretation apres coup."
  },
  {
    question: "Pourquoi clustering sur coordonnees FAMD ?",
    answer:
      "Les coordonnees FAMD forment un espace numerique commun adapte aux variables mixtes. On evite ainsi un clustering direct sur des echelles brutes."
  },
  {
    question: "Pourquoi k = 2 ?",
    answer:
      "Apres recalcul sur la FAMD principale reduite, la grille axes-k recommande 2 axes et k = 2, avec silhouette 0,508 et stabilite ARI 1,00."
  },
  {
    question: "Pourquoi la projection 2D montre du chevauchement ?",
    answer:
      "Une projection 2D resume seulement une partie de l'information. Un chevauchement visuel reste normal dans une analyse exploratoire."
  },
  {
    question: "Que signifie la silhouette ?",
    answer:
      "Elle compare la proximite d'un individu a son cluster et aux autres clusters. Plus elle est elevee, plus la separation est nette."
  },
  {
    question: "Le modele logistique est-il une explication directe ?",
    answer:
      "Non. Il mesure des associations avec Dropout vs Non_Dropout dans ce dataset."
  },
  {
    question: "Difference entre modele precoce et complet ?",
    answer:
      "Le modele precoce utilise les variables d'entree et le semestre 1. Le modele complet ajoute le semestre 2, donc il est plus tardif."
  }
];

export const figures = {
  target: {
    src: `${assetBase}/figures/03_a_distribution_target.png`,
    title: "Distribution de Target",
    caption: "Statuts Dropout, Enrolled et Graduate."
  },
  famd: [
    {
      src: `${assetBase}/figures/04_principale_screeplot.png`,
      title: "FAMD principale reduite - eboulis",
      caption: "Inertie des dimensions factorielles."
    },
    {
      src: `${assetBase}/figures/04_principale_individus_target.png`,
      title: "Projection des individus",
      caption: "Target colore la projection, sans etre active."
    },
    {
      src: `${assetBase}/figures/04_principale_barycentres_target.png`,
      title: "Barycentres Target",
      caption: "Lecture illustrative des statuts dans l'espace FAMD."
    },
    {
      src: `${assetBase}/figures/04_principale_variables_top.png`,
      title: "Variables contributives",
      caption: "Variables actives les plus liees aux premiers axes."
    }
  ],
  clustering: [
    {
      src: `${assetBase}/figures/05_principale_clusters_famd.png`,
      title: "Clusters sur coordonnees FAMD",
      caption: "Solution principale : 2 axes FAMD, k = 2."
    },
    {
      src: `${assetBase}/figures/05_principale_composition_clusters_target.png`,
      title: "Composition Target par cluster",
      caption: "Target est utilisee apres clustering pour caracteriser les profils."
    },
    {
      src: `${assetBase}/figures/05_principale_methode_coude.png`,
      title: "Methode du coude",
      caption: "Inertie intra-classe selon k pour les axes retenus."
    },
    {
      src: `${assetBase}/figures/05_principale_silhouette_moyenne.png`,
      title: "Silhouette moyenne",
      caption: "Comparaison des valeurs de k."
    },
    {
      src: `${assetBase}/figures/05_principale_profils_academiques_clusters.png`,
      title: "Profils academiques",
      caption: "Indicateurs standardises par cluster."
    },
    {
      src: `${assetBase}/figures/05_principale_dendrogramme_cah.png`,
      title: "CAH complementaire",
      caption: "Validation descriptive sur les memes coordonnees FAMD."
    }
  ],
  logit: [
    {
      src: `${assetBase}/figures/06_roc_logit_precoce.png`,
      title: "ROC - modele precoce",
      caption: "AUC test : 0,884."
    },
    {
      src: `${assetBase}/figures/06_roc_logit_complet.png`,
      title: "ROC - modele complet",
      caption: "AUC test : 0,909."
    },
    {
      src: `${assetBase}/figures/06_probabilites_dropout.png`,
      title: "Probabilites estimees",
      caption: "Distribution des probabilites de Dropout du modele complet."
    }
  ]
};
