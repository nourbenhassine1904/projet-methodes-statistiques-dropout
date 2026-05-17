import React, { useMemo, useState } from "react";
import {
  activeVariables,
  auditChecks,
  clusterValidationRows,
  clusteringRecommendation,
  clusters,
  defenseQuestions,
  famdAxisReadings,
  famdMetrics,
  figures,
  finalInterpretation,
  headlineKpis,
  logisticOddsNotes,
  logitComparison,
  methodologyBadges,
  metricGlossary,
  navItems,
  pipelineSteps,
  projectSubtitle,
  projectTitle,
  qualitativeTests,
  quantitativeTests,
  recommendationPlan,
  supplementaryVariables,
  targetDistribution,
  variableFamilies
} from "./data/projectData.js";

function Logo({ compact = false }) {
  const [logoOk, setLogoOk] = useState(true);

  if (!logoOk) {
    return <span className={compact ? "logoFallback compact" : "logoFallback"}>DS</span>;
  }

  return (
    <img
      className={compact ? "projectLogo compact" : "projectLogo"}
      src="/project-assets/logo.png"
      alt="Logo du projet"
      onError={() => setLogoOk(false)}
    />
  );
}

function Sidebar({ activePage, onNavigate }) {
  return (
    <aside className="sidebar" aria-label="Navigation principale">
      <div className="brand">
        <Logo compact />
        <div>
          <strong>Dropout dashboard</strong>
          <span>FAMD reduite + clustering</span>
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

function PageShell({ eyebrow, title, intro, children, takeaway }) {
  return (
    <section className="page">
      <header className="pageHeader heroPanel">
        <div className="heroLogoLine">
          <Logo />
          <span className="eyebrow">{eyebrow}</span>
        </div>
        <div>
          <h1>{title}</h1>
          {intro && <p>{intro}</p>}
        </div>
      </header>
      {children}
      {takeaway && (
        <Callout tone="key" title="A retenir">
          {takeaway}
        </Callout>
      )}
    </section>
  );
}

function SectionIntro({ eyebrow, title, children }) {
  return (
    <div className="sectionIntro">
      <span>{eyebrow}</span>
      <h2>{title}</h2>
      <p>{children}</p>
    </div>
  );
}

function KpiGrid({ items }) {
  return (
    <div className="kpiGrid">
      {items.map((item) => (
        <article className="kpiCard" key={item.label}>
          <span>{item.label}</span>
          <strong>{item.value}</strong>
          <p>{item.detail}</p>
        </article>
      ))}
    </div>
  );
}

function BadgeRow({ items }) {
  return (
    <div className="badgeRow">
      {items.map((item) => (
        <span className="badge" key={item}>
          {item}
        </span>
      ))}
    </div>
  );
}

function Card({ title, children, tone = "default", badge }) {
  return (
    <article className={`card ${tone}`}>
      {badge && <span className="badge compact">{badge}</span>}
      <h3>{title}</h3>
      <div>{children}</div>
    </article>
  );
}

function Callout({ title, children, tone = "note" }) {
  return (
    <aside className={`callout ${tone}`}>
      <strong>{title}</strong>
      <p>{children}</p>
    </aside>
  );
}

function FigureCard({ figure }) {
  return (
    <article className="figureCard">
      <div className="figureHeader">
        <h3>{figure.title}</h3>
        <p>{figure.caption}</p>
      </div>
      <img src={figure.src} alt={figure.title} loading="lazy" />
    </article>
  );
}

function FigureGrid({ items, columns = "two" }) {
  return (
    <div className={`figureGrid ${columns}`}>
      {items.map((figure) => (
        <FigureCard figure={figure} key={figure.src} />
      ))}
    </div>
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
          {rows.map((row, rowIndex) => (
            <tr key={`${rowIndex}-${Object.values(row).join("-")}`}>
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

function FilterButtons({ options, active, onChange }) {
  return (
    <div className="filterBar">
      {options.map((option) => (
        <button
          type="button"
          key={option}
          className={active === option ? "filterButton active" : "filterButton"}
          onClick={() => onChange(option)}
        >
          {option}
        </button>
      ))}
    </div>
  );
}

function OverviewPage() {
  return (
    <PageShell
      eyebrow="Vue d'ensemble"
      title={projectTitle}
      intro={projectSubtitle}
      takeaway="La solution principale du dashboard est unique : FAMD principale reduite, puis clustering sur 2 axes avec k = 2."
    >
      <KpiGrid items={headlineKpis} />
      <BadgeRow items={methodologyBadges} />

      <div className="marqueeStrip" aria-label="Methodologie finale">
        <span>Dataset</span>
        <span>Preparation</span>
        <span>FAMD reduite</span>
        <span>Clustering k = 2</span>
        <span>Logistique precoce/complet</span>
        <span>Soutenance</span>
      </div>

      <div className="splitLayout">
        <Card title="Sujet du projet" tone="accent">
          <p>
            Le projet etudie le dataset Predict Students' Dropout and Academic
            Success afin de construire des profils etudiants lisibles a partir de
            variables administratives, socio-economiques et academiques.
          </p>
        </Card>
        <Card title="Logique statistique" tone="accent">
          <p>
            L'analyse principale est exploratoire : la FAMD reduit l'information
            multivariee, puis le clustering segmente les etudiants dans l'espace
            factoriel. La regression logistique est complementaire.
          </p>
        </Card>
      </div>

      <SectionIntro eyebrow="Pipeline" title="De la donnee brute aux profils defendables">
        Chaque etape a un role precis : preparer les variables, construire un espace
        factoriel coherent, segmenter les individus, puis valider la lecture avec des
        tests et des modeles complementaires.
      </SectionIntro>
      <div className="timeline">
        {pipelineSteps.map((step, index) => (
          <article className="timelineStep" key={step.title}>
            <span>{String(index + 1).padStart(2, "0")}</span>
            <h3>{step.title}</h3>
            <p>{step.text}</p>
          </article>
        ))}
      </div>

      <div className="profileStrip">
        {clusters.map((cluster) => (
          <article className={cluster.id === 1 ? "profileTile risk" : "profileTile"} key={cluster.id}>
            <span>Cluster {cluster.id}</span>
            <h2>{cluster.name}</h2>
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
        ))}
      </div>
    </PageShell>
  );
}

function VariablesPage() {
  const [filter, setFilter] = useState("Toutes");
  const variableRows = useMemo(() => {
    if (filter === "Toutes") return activeVariables;
    return activeVariables.filter((row) => row.type === filter || row.group === filter);
  }, [filter]);

  return (
    <PageShell
      eyebrow="Donnees et variables"
      title="Typologie statistique et roles dans l'analyse"
      intro="Le dataset est mixte : certaines variables sont quantitatives, d'autres qualitatives meme lorsqu'elles sont codees par des entiers."
      takeaway="Le type informatique ne suffit pas : une variable codee par des entiers peut representer des categories et doit alors etre traitee comme qualitative."
    >
      <div className="splitLayout">
        <FigureCard figure={figures.target} />
        <Card title="Distribution de Target">
          <SimpleTable
            columns={[
              { key: "target", label: "Statut" },
              { key: "effectif", label: "Effectif" },
              { key: "pourcentage", label: "Pourcentage" }
            ]}
            rows={targetDistribution}
          />
        </Card>
      </div>

      <SectionIntro eyebrow="Roles" title="Variables actives, supplementaires et cible illustrative">
        Les variables actives construisent la FAMD principale reduite. Les variables
        supplementaires enrichissent la lecture apres calcul. Target reste illustrative
        et ne construit jamais les axes ni les clusters.
      </SectionIntro>

      <div className="familyGrid">
        {variableFamilies.map((family) => (
          <Card title={family.family} key={family.id} badge={family.role}>
            <p>{family.explanation}</p>
            <p className="examples">{family.examples}</p>
          </Card>
        ))}
      </div>

      <Card title="Variables actives de la FAMD principale reduite">
        <FilterButtons
          options={["Toutes", "Quantitative", "Qualitative", "Semestre 1", "Socio-administratif"]}
          active={filter}
          onChange={setFilter}
        />
        <SimpleTable
          columns={[
            { key: "variable", label: "Variable" },
            { key: "type", label: "Type statistique" },
            { key: "group", label: "Famille" }
          ]}
          rows={variableRows}
        />
      </Card>

      <Card title="Variables supplementaires principales">
        <div className="tokenList">
          {supplementaryVariables.map((variable) => (
            <span key={variable}>{variable}</span>
          ))}
        </div>
      </Card>

      <Card title="Controles automatiques">
        <SimpleTable
          columns={[
            { key: "check", label: "Controle" },
            { key: "status", label: "Statut" }
          ]}
          rows={auditChecks}
        />
      </Card>
    </PageShell>
  );
}

function FamdPage() {
  return (
    <PageShell
      eyebrow="FAMD"
      title="FAMD principale reduite"
      intro="La FAMD est adaptee parce que l'analyse combine des mesures numeriques et des variables qualitatives."
    >
      <KpiGrid items={famdMetrics} />

      <div className="tripleGrid">
        <Card title="ACP" badge="Quantitatif">
          <p>Approche adaptee aux variables numeriques, moins adaptee aux codes qualitatifs.</p>
        </Card>
        <Card title="ACM" badge="Qualitatif">
          <p>Approche adaptee aux categories, mais moins directe pour conserver les notes et les comptages.</p>
        </Card>
        <Card title="FAMD" badge="Mixte">
          <p>Compromis coherent : variables quantitatives et qualitatives dans un meme espace factoriel.</p>
        </Card>
      </div>

      <div className="splitLayout">
        {famdAxisReadings.map((axis) => (
          <Card title={axis.title} tone="accent" key={axis.title}>
            <p>{axis.text}</p>
          </Card>
        ))}
      </div>

      <FigureGrid items={figures.famd} />
    </PageShell>
  );
}

function ClusteringPage() {
  const [testView, setTestView] = useState("Quantitatives");
  const tests = testView === "Quantitatives" ? quantitativeTests : qualitativeTests;
  const columns =
    testView === "Quantitatives"
      ? [
          { key: "variable", label: "Variable" },
          { key: "test", label: "Test" },
          { key: "pValue", label: "p-value" },
          { key: "reading", label: "Lecture" }
        ]
      : [
          { key: "variable", label: "Variable" },
          { key: "test", label: "Test" },
          { key: "pValue", label: "p-value" },
          { key: "effect", label: "Effet" }
        ];

  return (
    <PageShell
      eyebrow="Clustering"
      title="Segmentation sur coordonnees FAMD"
      intro="Le clustering principal utilise les coordonnees individuelles de la FAMD principale reduite, pas les donnees brutes."
      takeaway="k = 2 est la seule solution principale affichee et interpretee dans le dashboard."
    >
      <KpiGrid
        items={[
          { label: "Solution", value: clusteringRecommendation.solution, detail: "apres grille axes-k" },
          { label: "Silhouette", value: clusteringRecommendation.silhouette, detail: "moyenne de la solution" },
          { label: "Taille min", value: clusteringRecommendation.minSize, detail: "cluster 1" },
          { label: "Taille max", value: clusteringRecommendation.maxSize, detail: "cluster 2" },
          { label: "Stabilite", value: clusteringRecommendation.stability, detail: `ARI ${clusteringRecommendation.ari}` }
        ]}
      />

      <div className="tripleGrid">
        <Card title="Pourquoi sur coordonnees FAMD ?" badge="Distance defendable">
          <p>Les axes FAMD fournissent un espace numerique coherent pour variables mixtes.</p>
        </Card>
        <Card title="K-means" badge="Segmentation">
          <p>La methode regroupe les individus autour de centres proches dans l'espace factoriel.</p>
        </Card>
        <Card title="Silhouette" badge="Validation">
          <p>Elle mesure si les individus sont plus proches de leur groupe que des autres groupes.</p>
        </Card>
      </div>

      <FigureGrid items={figures.clustering} />

      <SectionIntro eyebrow="Profils" title="Deux profils finaux pour la soutenance">
        La typologie finale oppose un groupe a risque eleve et un groupe majoritaire
        favorable. La lecture de Target intervient seulement apres la formation des clusters.
      </SectionIntro>

      <div className="profileStrip">
        {clusters.map((cluster) => (
          <article className={cluster.id === 1 ? "profileTile risk" : "profileTile"} key={cluster.id}>
            <span>Cluster {cluster.id}</span>
            <h2>{cluster.name}</h2>
            <p>{cluster.description}</p>
            <p className="academicNote">{cluster.academicNote}</p>
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
        ))}
      </div>

      <Card title="Validation statistique">
        <SimpleTable
          columns={[
            { key: "metric", label: "Element" },
            { key: "value", label: "Valeur" },
            { key: "reading", label: "Lecture" }
          ]}
          rows={clusterValidationRows}
        />
      </Card>

      <Card title="Tests de differenciation des clusters">
        <FilterButtons
          options={["Quantitatives", "Qualitatives"]}
          active={testView}
          onChange={setTestView}
        />
        <SimpleTable columns={columns} rows={tests} />
      </Card>

      <Callout title="Limites du clustering" tone="warning">
        Le clustering est non supervise et exploratoire. Les groupes indiquent une
        structure statistique utile, mais ils ne remplacent pas une evaluation individuelle.
        k = 2 donne une typologie robuste et lisible, mais moins detaillee.
      </Callout>
    </PageShell>
  );
}

function LogisticPage() {
  return (
    <PageShell
      eyebrow="Regression logistique"
      title="Modeles complementaires : precoce et complet"
      intro="La regression logistique compare Dropout a Non_Dropout. Elle complete l'analyse principale sans remplacer la FAMD ni le clustering."
      takeaway="Le modele complet est plus performant, mais le modele precoce est plus utile pour une logique d'alerte."
    >
      <SimpleTable
        columns={[
          { key: "model", label: "Modele" },
          { key: "inputs", label: "Variables" },
          { key: "accuracy", label: "Accuracy" },
          { key: "recall", label: "Recall Dropout" },
          { key: "f1", label: "F1 Dropout" },
          { key: "auc", label: "AUC" },
          { key: "reading", label: "Lecture" }
        ]}
        rows={logitComparison}
      />

      <FigureGrid items={figures.logit} />

      <div className="splitLayout">
        <Card title="Comment lire les metriques ?">
          <SimpleTable
            columns={[
              { key: "metric", label: "Metrique" },
              { key: "meaning", label: "Signification" }
            ]}
            rows={metricGlossary}
          />
        </Card>
        <Card title="Lecture des odds ratios" tone="accent">
          <ul>
            {logisticOddsNotes.map((note) => (
              <li key={note}>{note}</li>
            ))}
          </ul>
        </Card>
      </div>
    </PageShell>
  );
}

function InterpretationPage() {
  return (
    <PageShell
      eyebrow="Interpretation finale"
      title="Relier FAMD, clustering et modeles"
      intro="Cette synthese rassemble les resultats principaux dans une lecture pedagogique pour la soutenance."
    >
      <div className="familyGrid">
        {finalInterpretation.map((item) => (
          <Card title={item.title} key={item.title} tone="accent">
            <p>{item.text}</p>
          </Card>
        ))}
      </div>

      <Card title="Plan d'action statistique">
        <SimpleTable
          columns={[
            { key: "result", label: "Resultat" },
            { key: "interpretation", label: "Interpretation" },
            { key: "action", label: "Usage possible" }
          ]}
          rows={recommendationPlan}
        />
      </Card>

    </PageShell>
  );
}

function DefensePage() {
  const [query, setQuery] = useState("");
  const filteredQuestions = useMemo(() => {
    const cleanQuery = query.trim().toLowerCase();
    if (!cleanQuery) return defenseQuestions;
    return defenseQuestions.filter(
      (item) =>
        item.question.toLowerCase().includes(cleanQuery) ||
        item.answer.toLowerCase().includes(cleanQuery)
    );
  }, [query]);

  return (
    <PageShell
      eyebrow="Preparation soutenance"
      title="Questions frequentes et reponses courtes"
      intro="Cette section aide a defendre les choix statistiques sans surinterpreter les resultats."
    >
      <div className="searchBox">
        <label htmlFor="faq-search">Filtrer les questions</label>
        <input
          id="faq-search"
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Exemple : FAMD, target, k = 2, silhouette..."
        />
      </div>

      <div className="faqList">
        {filteredQuestions.map((item) => (
          <details key={item.question} open={query.length > 0}>
            <summary>{item.question}</summary>
            <p>{item.answer}</p>
          </details>
        ))}
      </div>
    </PageShell>
  );
}

const pages = {
  overview: <OverviewPage />,
  variables: <VariablesPage />,
  famd: <FamdPage />,
  clustering: <ClusteringPage />,
  logit: <LogisticPage />,
  interpretation: <InterpretationPage />,
  defense: <DefensePage />
};

export default function App() {
  const [activePage, setActivePage] = useState("overview");
  const currentIndex = navItems.findIndex((item) => item.id === activePage);

  function navigateTo(pageId) {
    setActivePage(pageId);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function goTo(offset) {
    const nextItem = navItems[currentIndex + offset];
    if (nextItem) navigateTo(nextItem.id);
  }

  return (
    <div className="app">
      <Sidebar activePage={activePage} onNavigate={navigateTo} />
      <main className="content">
        {pages[activePage]}
        <div className="pager">
          <button type="button" onClick={() => goTo(-1)} disabled={currentIndex === 0}>
            Precedent
          </button>
          <span>
            {currentIndex + 1} / {navItems.length}
          </span>
          <button
            type="button"
            onClick={() => goTo(1)}
            disabled={currentIndex === navItems.length - 1}
          >
            Suivant
          </button>
        </div>
        <footer className="appFooter">
          <Logo compact />
          <div>
            <strong>Projet methodes statistiques</strong>
            <span>FAMD principale reduite - clustering principal nb_axes = 2, k = 2.</span>
          </div>
        </footer>
      </main>
    </div>
  );
}
