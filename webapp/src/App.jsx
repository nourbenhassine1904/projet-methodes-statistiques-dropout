import React, { useMemo, useState } from "react";
import {
  clusters,
  figures,
  kpis,
  limits,
  logitMetrics,
  methods,
  navItems,
  oddsRatios,
  pipeline,
  projectSubtitle,
  projectTitle,
  recommendationPlan,
  targetDistribution,
  targetStatuses,
  variableTypes
} from "./data/projectData.js";

function Sidebar({ activePage, onNavigate }) {
  return (
    <aside className="sidebar" aria-label="Navigation principale">
      <div className="brand">
        <span className="brandMark">MS</span>
        <div>
          <strong>Projet statistique</strong>
          <span>FAMD & clustering</span>
        </div>
      </div>

      <nav className="navList">
        {navItems.map((item, index) => (
          <button
            key={item.id}
            className={activePage === item.id ? "navItem active" : "navItem"}
            onClick={() => onNavigate(item.id)}
            type="button"
          >
            <span>{String(index + 1).padStart(2, "0")}</span>
            {item.label}
          </button>
        ))}
      </nav>
    </aside>
  );
}

function PageShell({ eyebrow, title, intro, contribution, story, message, children }) {
  return (
    <section className="page">
      <header className="pageHeader">
        <span className="eyebrow">{eyebrow}</span>
        <h1>{title}</h1>
        {intro && <p>{intro}</p>}
        <div className="contribution">
          <strong>Ce que cette page apporte au projet</strong>
          <span>{contribution}</span>
        </div>
      </header>

      {story && <StatisticalStory story={story} />}
      {children}
      <KeyMessageBox>{message}</KeyMessageBox>
    </section>
  );
}

function SectionIntro({ kicker, title, children }) {
  return (
    <div className="sectionIntro">
      <span>{kicker}</span>
      <h2>{title}</h2>
      <p>{children}</p>
    </div>
  );
}

function StatisticalStory({ story }) {
  const items = [
    ["Question statistique", story.question],
    ["Méthode utilisée", story.method],
    ["Résultat observé", story.result],
    ["Interprétation", story.interpretation],
    ["Limite", story.limit]
  ];

  return (
    <div className="storyGrid">
      {items.map(([title, text]) => (
        <InsightCard key={title} title={title} text={text} />
      ))}
    </div>
  );
}

function InsightCard({ title, text, tone = "default" }) {
  return (
    <article className={`insightCard ${tone}`}>
      <span>{title}</span>
      <p>{text}</p>
    </article>
  );
}

function MethodCard({ title, text, badge }) {
  return (
    <article className="methodCard">
      {badge && <span className="smallBadge neutral">{badge}</span>}
      <h3>{title}</h3>
      <p>{text}</p>
    </article>
  );
}

function MetricCard({ label, value, detail }) {
  return (
    <article className="metricCard">
      <span>{label}</span>
      <strong>{value}</strong>
      <p>{detail}</p>
    </article>
  );
}

function MetricGrid({ items }) {
  return (
    <div className="metricGrid">
      {items.map((item) => (
        <MetricCard key={item.label} {...item} />
      ))}
    </div>
  );
}

function FigureCard({ figure, featured = false }) {
  return (
    <article className={featured ? "figureCard featured" : "figureCard"}>
      <div className="figureHeader">
        <div>
          <h3>{figure.title}</h3>
          {figure.caption && <p>{figure.caption}</p>}
        </div>
      </div>
      <img src={figure.src} alt={figure.title} loading="lazy" />
      {figure.explanation && (
        <div className="figureExplanation">
          <strong>Lecture</strong>
          <p>{figure.explanation}</p>
        </div>
      )}
    </article>
  );
}

function FigureGrid({ items }) {
  return (
    <div className="figureGrid">
      {items.map((figure) => (
        <FigureCard figure={figure} key={figure.src} />
      ))}
    </div>
  );
}

function WarningBox({ title = "Précaution d'interprétation", children }) {
  return (
    <aside className="warningBox">
      <strong>{title}</strong>
      <p>{children}</p>
    </aside>
  );
}

function KeyMessageBox({ children }) {
  return (
    <aside className="keyMessage">
      <span>Message clé</span>
      <p>{children}</p>
    </aside>
  );
}

function RiskBadge({ risk }) {
  const slug = risk
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, "-");

  return <span className={`riskBadge ${slug}`}>{risk}</span>;
}

function ClusterProfileCard({ cluster }) {
  return (
    <article className={cluster.critical ? "clusterCard critical" : "clusterCard"}>
      <div className="clusterTop">
        <span>Cluster {cluster.id}</span>
        <RiskBadge risk={cluster.risk} />
      </div>
      <p className="clusterCategory">{cluster.category}</p>
      <h3>{cluster.name}</h3>
      <p>{cluster.description}</p>
      <dl>
        <div>
          <dt>Effectif</dt>
          <dd>{cluster.size}</dd>
        </div>
        <div>
          <dt>Dropout</dt>
          <dd>{cluster.dropout}</dd>
        </div>
        <div>
          <dt>Graduate</dt>
          <dd>{cluster.graduate}</dd>
        </div>
      </dl>
    </article>
  );
}

function SimpleTable({ columns, rows }) {
  return (
    <div className="tableWrap">
      <table>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.key}>{column.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={Object.values(row).join("-")}>
              {columns.map((column) => (
                <td key={column.key}>{row[column.key]}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function CardGrid({ children, columns = "three" }) {
  return <div className={`cardGrid ${columns}`}>{children}</div>;
}

function Timeline() {
  return (
    <div className="timeline">
      {pipeline.map((step, index) => (
        <div className="timelineStep" key={step}>
          <span>{String(index + 1).padStart(2, "0")}</span>
          <strong>{step}</strong>
        </div>
      ))}
    </div>
  );
}

function HomePage() {
  return (
    <PageShell
      eyebrow="Vue d'ensemble"
      title={projectTitle}
      intro={projectSubtitle}
      contribution="Elle pose la problématique, le fil conducteur et la logique des méthodes mobilisées."
      story={{
        question: "Quels profils étudiants peut-on construire à partir des informations disponibles ?",
        method: "Chaîne complète : préparation, description, FAMD, clustering et régression logistique complémentaire.",
        result: "Les résultats sont organisés autour de 6 profils et d'une lecture académique puis socio-administrative.",
        interpretation: "Le projet vise à construire des profils étudiants interprétables, pas seulement à prédire un statut.",
        limit: "L'interface présente les résultats produits avec R ; elle ne refait pas les calculs statistiques."
      }}
      message="Le projet vise à construire des profils étudiants interprétables, pas seulement à prédire un statut."
    >
      <MetricGrid items={kpis} />

      <SectionIntro kicker="Fil conducteur" title="Une soutenance guidée par la question statistique">
        Le tableau de bord suit la même progression que l'analyse : comprendre les données, réduire
        leur complexité, former des profils, puis traduire les résultats en recommandations.
      </SectionIntro>
      <Timeline />

      <CardGrid columns="two">
        <InsightCard
          title="Ce que le projet cherche à comprendre"
          text="Le projet cherche à repérer des groupes d'étudiants proches par leurs caractéristiques académiques, socio-économiques et administratives."
        />
        <InsightCard
          title="Résultat final attendu"
          text="Une typologie lisible des profils étudiants, utile pour prioriser les actions et discuter les limites méthodologiques."
        />
      </CardGrid>

      <SectionIntro kicker="Méthodes mobilisées" title="Une analyse multivariée, puis une lecture décisionnelle">
        Chaque méthode apporte une pièce différente : description, projection factorielle,
        segmentation, puis validation complémentaire par modèle logistique.
      </SectionIntro>
      <CardGrid columns="four">
        {methods.map((method) => (
          <MethodCard key={method.title} title={method.title} text={method.text} />
        ))}
      </CardGrid>
    </PageShell>
  );
}

function DatasetPage() {
  return (
    <PageShell
      eyebrow="Données"
      title="Dataset et variable cible"
      intro="Le dataset provient de UCI Machine Learning Repository, Predict Students' Dropout and Academic Success."
      contribution="Elle définit la cible, les types de variables et le rôle de Target dans l'interprétation."
      story={{
        question: "Quels statuts étudiants cherche-t-on à comparer ?",
        method: "Description de Target et des familles de variables présentes dans le dataset.",
        result: "Target distingue Dropout, Enrolled et Graduate sur 4424 étudiants.",
        interpretation: "Target sert à interpréter les figures, les axes FAMD et la composition des clusters.",
        limit: "Target renseigne un statut observé dans ce dataset ; elle ne suffit pas à expliquer seule les trajectoires."
      }}
      message="Target est centrale pour lire les profils, mais elle est utilisée comme repère d'interprétation plutôt que comme unique explication."
    >
      <div className="splitLayout">
        <FigureCard figure={figures.target} featured />
        <div className="panel">
          <h2>Répartition de Target</h2>
          <SimpleTable
            columns={[
              { key: "target", label: "Statut" },
              { key: "effectif", label: "Effectif" },
              { key: "pourcentage", label: "Pourcentage" }
            ]}
            rows={targetDistribution}
          />
          <p className="caption">Table reprise de 03_a_distribution_target.csv.</p>
        </div>
      </div>

      <CardGrid columns="three">
        {targetStatuses.map((status) => (
          <InsightCard key={status.title} title={status.title} text={status.text} />
        ))}
      </CardGrid>

      <CardGrid columns="two">
        <InsightCard
          title="Pourquoi Target est importante ?"
          text="Elle permet de comparer les profils découverts aux statuts observés et de qualifier les groupes comme favorables, intermédiaires ou à risque."
        />
        <InsightCard
          title="Utilisation dans le projet"
          text="Target est utilisée pour interpréter les profils, notamment dans la carte des individus FAMD et la composition des clusters."
        />
      </CardGrid>

      <SectionIntro kicker="Variables" title="Quatre familles de variables pour lire les profils">
        Les profils sont construits à partir d'informations académiques, socio-économiques,
        administratives et économiques, ce qui justifie une méthode adaptée aux données mixtes.
      </SectionIntro>
      <CardGrid columns="four">
        {variableTypes.map((type) => (
          <MethodCard key={type.title} title={type.title} text={type.text} />
        ))}
      </CardGrid>
    </PageShell>
  );
}

function DescriptivePage() {
  return (
    <PageShell
      eyebrow="Exploration"
      title="Analyse descriptive"
      intro="Les figures académiques comparent les distributions des notes et des unités approuvées selon Target."
      contribution="Elle montre les premiers contrastes visibles avant de passer à une méthode multivariée."
      story={{
        question: "Les variables académiques distinguent-elles les statuts étudiants ?",
        method: "Comparaison graphique des notes et unités approuvées par statut Target.",
        result: "Les distributions académiques mettent en évidence des écarts entre Dropout, Enrolled et Graduate.",
        interpretation: "Les variables académiques semblent structurer fortement les trajectoires observées.",
        limit: "Une lecture variable par variable ne suffit pas à étudier simultanément toutes les dimensions du dataset."
      }}
      message="Les variables académiques différencient nettement les statuts des étudiants et préparent la lecture factorielle."
    >
      <FigureGrid items={figures.descriptive} />

      <WarningBox title="Pourquoi passer à la FAMD ?">
        L'analyse descriptive est utile pour comprendre chaque variable, mais elle ne suffit pas pour
        étudier simultanément toutes les variables quantitatives et qualitatives. La FAMD fournit un
        espace commun pour résumer cette structure.
      </WarningBox>
    </PageShell>
  );
}

function FamdPage() {
  return (
    <PageShell
      eyebrow="Analyse factorielle"
      title="FAMD"
      intro="La FAMD est mobilisée parce que les données combinent variables quantitatives et qualitatives."
      contribution="Elle réduit la complexité du dataset et fournit l'espace factoriel utilisé ensuite pour le clustering."
      story={{
        question: "Quels axes résument la structure multivariée des profils étudiants ?",
        method: "FAMD sur les variables actives mixtes, avec Target comme variable illustrative.",
        result: "Dim 1 se lit comme un axe académique ; Dim 2 comme un axe socio-administratif.",
        interpretation: "La structuration principale des profils est d'abord académique, puis socio-administrative.",
        limit: "Les deux premières dimensions ne résument pas toute l'information, ce qui est normal avec des données mixtes."
      }}
      message="La FAMD montre que la structuration principale des profils est d'abord académique, puis socio-administrative."
    >
      <CardGrid columns="three">
        <MethodCard
          title="Pourquoi FAMD et pas ACP ou ACM ?"
          text="L'ACP cible surtout les variables quantitatives, l'ACM les variables qualitatives. La FAMD combine les deux familles dans une même analyse."
          badge="Données mixtes"
        />
        <MethodCard
          title="Variables actives et variable illustrative"
          text="Les variables actives construisent les axes. Target est supplémentaire : elle aide à interpréter les profils sans construire les dimensions."
          badge="Target illustrative"
        />
        <MethodCard
          title="Lecture de l'inertie"
          text="Dim 1 et Dim 2 résument une partie de l'information. Ce n'est pas une faiblesse en soi : le dataset contient de nombreuses dimensions."
          badge="Interprétation prudente"
        />
      </CardGrid>

      <CardGrid columns="two">
        <InsightCard
          title="Dim 1 = axe académique"
          text="Cet axe est associé aux unités approuvées, aux unités inscrites et aux notes. Il oppose les parcours académiques plus solides aux parcours fragiles."
          tone="strong"
        />
        <InsightCard
          title="Dim 2 = axe socio-administratif"
          text="Cet axe est associé à l'âge, au déplacement, aux frais de scolarité, à la bourse et au régime, selon les contributions observées."
          tone="strong"
        />
      </CardGrid>

      <FigureGrid items={figures.famd} />

      <CardGrid columns="two">
        <InsightCard
          title="Comment lire la carte des individus ?"
          text="Chaque point représente un étudiant. Des points proches indiquent des profils proches dans l'espace factoriel ; Target colore l'interprétation."
        />
        <InsightCard
          title="Comment lire la carte des variables ?"
          text="Les variables proches d'un axe ou d'une direction contribuent à nommer cette dimension et à comprendre ce qu'elle oppose."
        />
      </CardGrid>
    </PageShell>
  );
}

function ClusteringPage() {
  const criticalCluster = useMemo(() => clusters.find((cluster) => cluster.critical), []);

  return (
    <PageShell
      eyebrow="Segmentation"
      title="Clustering k-means"
      intro="Le clustering est réalisé sur les coordonnées FAMD afin de regrouper les étudiants dans l'espace factoriel."
      contribution="Elle transforme les coordonnées factorielles en profils étudiants interprétables et actionnables."
      story={{
        question: "Peut-on transformer l'espace FAMD en groupes d'étudiants lisibles ?",
        method: "k-means appliqué sur les coordonnées FAMD.",
        result: "Le choix k = 6 permet d'obtenir six profils interprétables.",
        interpretation: "Les clusters distinguent profils favorables, intermédiaires, à risque et critique.",
        limit: "La silhouette reste modérée ; le clustering doit être lu comme une typologie exploratoire."
      }}
      message="Le clustering transforme l'espace factoriel en profils étudiants interprétables."
    >
      <CardGrid columns="three">
        <MethodCard
          title="Pourquoi faire un clustering après la FAMD ?"
          text="La FAMD réduit et structure l'information. Le clustering exploite ensuite ces coordonnées pour former des groupes plus lisibles."
          badge="Coordonnées FAMD"
        />
        <MethodCard
          title="Choix de k = 6"
          text="k = 6 est retenu car il est techniquement recommandé par la silhouette et reste interprétable pour la soutenance."
          badge="Six profils"
        />
        <WarningBox title="Silhouette modérée">
          La séparation des groupes suggère une structure utile, mais elle ne doit pas être interprétée comme une segmentation définitive.
        </WarningBox>
      </CardGrid>

      <FigureGrid items={figures.clustering} />

      {criticalCluster && (
        <article className="criticalCard">
          <div>
            <span>Profil le plus critique</span>
            <h2>Cluster {criticalCluster.id} : {criticalCluster.name}</h2>
            <p>{criticalCluster.description}</p>
          </div>
          <div className="criticalStats">
            <strong>{criticalCluster.dropout}</strong>
            <span>de Dropout</span>
          </div>
        </article>
      )}

      <SectionIntro kicker="Classement" title="Lecture décisionnelle des profils">
        Les profils ne servent pas seulement à nommer des groupes : ils permettent de prioriser les
        actions selon le niveau de risque et la composition observée.
      </SectionIntro>
      <div className="rankingGrid">
        <InsightCard title="Profils favorables" text="Clusters 2 et 3 : forte proportion de Graduate et risque faible." />
        <InsightCard title="Profil intermédiaire" text="Cluster 5 : situation de transition avec risque non négligeable." />
        <InsightCard title="Profils à risque" text="Clusters 1, 4 et 6 : proportion élevée de Dropout." />
        <InsightCard title="Profil critique" text="Cluster 4 : priorité d'intervention dans une lecture opérationnelle." tone="danger" />
      </div>

      <div className="clusterGrid">
        {clusters.map((cluster) => (
          <ClusterProfileCard cluster={cluster} key={cluster.id} />
        ))}
      </div>
    </PageShell>
  );
}

function LogisticPage() {
  return (
    <PageShell
      eyebrow="Modélisation complémentaire"
      title="Régression logistique"
      intro="La régression logistique complète la typologie avec une cible binaire : Dropout vs Non_Dropout."
      contribution="Elle vérifie la cohérence des associations observées avec un modèle de classification."
      story={{
        question: "Quels facteurs sont associés au risque binaire Dropout vs Non_Dropout ?",
        method: "Régression logistique et lecture prudente des métriques et odds ratios.",
        result: "Le modèle atteint 85,76 % d'accuracy, avec un rappel Dropout de 71,13 %.",
        interpretation: "Les résultats sont cohérents avec l'importance des dimensions académiques et socio-administratives.",
        limit: "Les odds ratios indiquent des associations conditionnelles dans le modèle, pas des relations causales."
      }}
      message="La régression logistique confirme la cohérence des facteurs académiques et socio-administratifs associés au risque de décrochage."
    >
      <CardGrid columns="two">
        <MethodCard
          title="Pourquoi une régression logistique complémentaire ?"
          text="Elle ne remplace pas le clustering : elle apporte une lecture supervisée du risque Dropout vs Non_Dropout."
          badge="Complément"
        />
        <WarningBox>
          Les odds ratios indiquent des associations conditionnelles dans le modèle. Ils ne doivent pas être lus comme des relations causales.
        </WarningBox>
      </CardGrid>

      <MetricGrid items={logitMetrics.map((metric) => ({ ...metric, detail: metric.measure }))} />

      <SectionIntro kicker="Métriques" title="Comment lire les performances du modèle ?">
        Les métriques ne racontent pas la même chose : certaines évaluent la performance globale,
        d'autres ciblent spécifiquement la classe Dropout.
      </SectionIntro>
      <SimpleTable
        columns={[
          { key: "label", label: "Métrique" },
          { key: "measure", label: "Ce que cela mesure" },
          { key: "interpretation", label: "Interprétation dans le projet" }
        ]}
        rows={logitMetrics}
      />

      <div className="splitLayout">
        <FigureCard figure={figures.logit} featured />
        <div className="panel">
          <h2>Odds ratios importants</h2>
          <p>
            Les variables suivantes sont affichées avec une interprétation prudente. Les badges
            indiquent le sens de l'association dans le modèle.
          </p>
          <SimpleTable
            columns={[
              { key: "variable", label: "Variable" },
              { key: "oddsRatio", label: "Odds ratio" },
              { key: "badgeNode", label: "Lecture" },
              { key: "interpretation", label: "Interprétation prudente" }
            ]}
            rows={oddsRatios.map((item) => ({
              ...item,
              badgeNode: <span className={`smallBadge ${item.tone}`}>{item.badge}</span>
            }))}
          />
        </div>
      </div>
    </PageShell>
  );
}

function RecommendationsPage() {
  return (
    <PageShell
      eyebrow="Décision"
      title="Synthèse et recommandations"
      intro="Les résultats sont traduits en pistes d'action pour une lecture opérationnelle des profils étudiants."
      contribution="Elle relie les résultats observés aux recommandations et aux limites méthodologiques."
      story={{
        question: "Comment transformer les résultats statistiques en priorités d'action ?",
        method: "Synthèse des axes FAMD, des clusters, de la régression logistique et des limites.",
        result: "Les profils à risque se concentrent notamment dans les clusters 4, 1 et 6.",
        interpretation: "Les actions doivent cibler à la fois le suivi académique et la fragilité financière.",
        limit: "Les recommandations doivent être validées sur d'autres cohortes avant généralisation."
      }}
      message="L'analyse permet de prioriser les profils les plus exposés tout en conservant une lecture exploratoire et prudente."
    >
      <SectionIntro kicker="Plan d'action" title="Résultat observé → interprétation → action recommandée">
        Cette grille transforme les résultats en décisions possibles, sans dépasser ce que les
        données permettent d'affirmer.
      </SectionIntro>
      <SimpleTable
        columns={[
          { key: "result", label: "Résultat observé" },
          { key: "interpretation", label: "Interprétation" },
          { key: "action", label: "Action recommandée" }
        ]}
        rows={recommendationPlan}
      />

      <CardGrid columns="two">
        <div className="panel">
          <h2>Limites méthodologiques</h2>
          <ul>
            {limits.map((limit) => (
              <li key={limit}>{limit}</li>
            ))}
          </ul>
        </div>
        <div className="panel accentPanel">
          <h2>Conclusion opérationnelle</h2>
          <p>
            Le tableau de bord suggère une priorisation des actions : repérer tôt les fragilités
            académiques, surveiller les contraintes financières, puis concentrer l'accompagnement
            sur les profils critiques comme le cluster 4.
          </p>
        </div>
      </CardGrid>
    </PageShell>
  );
}

const pageComponents = {
  accueil: <HomePage />,
  dataset: <DatasetPage />,
  descriptive: <DescriptivePage />,
  famd: <FamdPage />,
  clustering: <ClusteringPage />,
  logit: <LogisticPage />,
  recommandations: <RecommendationsPage />
};

export default function App() {
  const [activePage, setActivePage] = useState("accueil");
  const currentIndex = navItems.findIndex((item) => item.id === activePage);

  function navigateTo(pageId) {
    setActivePage(pageId);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function goTo(offset) {
    const nextItem = navItems[currentIndex + offset];
    if (nextItem) {
      navigateTo(nextItem.id);
    }
  }

  return (
    <div className="app">
      <Sidebar activePage={activePage} onNavigate={navigateTo} />
      <main className="content">
        {pageComponents[activePage]}
        <div className="pager">
          <button type="button" onClick={() => goTo(-1)} disabled={currentIndex === 0}>
            Précédent
          </button>
          <span>
            {currentIndex + 1} / {navItems.length}
          </span>
          <button type="button" onClick={() => goTo(1)} disabled={currentIndex === navItems.length - 1}>
            Suivant
          </button>
        </div>
      </main>
    </div>
  );
}
