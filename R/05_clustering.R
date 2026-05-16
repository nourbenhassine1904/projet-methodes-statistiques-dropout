# ============================================================
# 05_clustering.R
# Objectif : clustering sur les coordonnees FAMD et profils de clusters
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

chemin_famd <- file.path("outputs", "models", "04_resultat_famd.rds")

if (!file.exists(chemin_famd)) {
  source(file.path("R", "04_famd.R"))
}

res_famd <- readRDS(chemin_famd)
donnees <- readRDS(file.path("data", "processed", "dropout_clean.rds"))

# ------------------------------------------------------------
# Coordonnees FAMD utilisees pour le clustering
# ------------------------------------------------------------

# On conserve les 5 premiers axes lorsque disponibles.
# Ce choix peut etre ajuste apres lecture de l'inertie cumulee.
nb_axes <- min(5, ncol(res_famd$ind$coord))
coord <- as.data.frame(res_famd$ind$coord[, seq_len(nb_axes), drop = FALSE])

# Standardisation de securite : les axes FAMD sont deja comparables,
# mais cette etape garde le pipeline stable pour le k-means.
coord_scaled <- scale(coord)
dist_coord <- dist(coord_scaled)

# ------------------------------------------------------------
# Evaluation de k : coude et silhouette pour k = 2 a 6
# ------------------------------------------------------------

set.seed(123)
k_possibles <- 2:6

resultats_kmeans <- purrr::map(k_possibles, function(k) {
  kmeans(coord_scaled, centers = k, nstart = 50)
})

table_coude <- tibble::tibble(
  k = k_possibles,
  inertie_intra = purrr::map_dbl(resultats_kmeans, "tot.withinss")
)

readr::write_csv(table_coude, file.path("outputs", "tables", "05_kmeans_methode_coude.csv"))

p_coude <- ggplot(table_coude, aes(x = k, y = inertie_intra)) +
  geom_line() +
  geom_point(size = 2) +
  scale_x_continuous(breaks = k_possibles) +
  labs(
    title = "Choix du nombre de clusters - methode du coude",
    x = "Nombre de clusters k",
    y = "Inertie intra-classe totale"
  )

ggsave(file.path("outputs", "figures", "05_methode_coude.png"), p_coude, width = 7, height = 5, dpi = 300)

table_silhouette <- tibble::tibble(
  k = k_possibles,
  silhouette_moyenne = purrr::map_dbl(resultats_kmeans, function(km) {
    mean(cluster::silhouette(km$cluster, dist_coord)[, "sil_width"])
  })
)

readr::write_csv(table_silhouette, file.path("outputs", "tables", "05_kmeans_silhouette.csv"))

p_silhouette <- ggplot(table_silhouette, aes(x = k, y = silhouette_moyenne)) +
  geom_line() +
  geom_point(size = 2) +
  scale_x_continuous(breaks = k_possibles) +
  labs(
    title = "Choix du nombre de clusters - silhouette moyenne",
    x = "Nombre de clusters k",
    y = "Silhouette moyenne"
  )

ggsave(file.path("outputs", "figures", "05_silhouette_moyenne.png"), p_silhouette, width = 7, height = 5, dpi = 300)

# Recommandation technique initiale : k maximisant la silhouette moyenne.
# L'equipe peut retenir un autre k si le coude et l'interpretabilite le justifient.
k_recommande <- table_silhouette |>
  arrange(desc(silhouette_moyenne), k) |>
  slice(1) |>
  pull(k)

table_k_recommande <- tibble::tibble(
  k_recommande = k_recommande,
  critere = "silhouette_moyenne_maximale",
  commentaire = "Recommendation technique a discuter avec le coude et l'interpretabilite des profils."
)

readr::write_csv(table_k_recommande, file.path("outputs", "tables", "05_k_recommande.csv"))

res_kmeans <- resultats_kmeans[[which(k_possibles == k_recommande)]]
saveRDS(res_kmeans, file.path("outputs", "models", "05_kmeans.rds"))

# ------------------------------------------------------------
# CAH avec le meme k recommande
# ------------------------------------------------------------

res_hclust <- hclust(dist_coord, method = "ward.D2")
clusters_cah <- cutree(res_hclust, k = k_recommande)

saveRDS(res_hclust, file.path("outputs", "models", "05_cah.rds"))

png(file.path("outputs", "figures", "05_dendrogramme_cah.png"), width = 1200, height = 800, res = 150)
plot(res_hclust, labels = FALSE, hang = -1, main = "CAH - methode de Ward", xlab = "", sub = "")
rect.hclust(res_hclust, k = k_recommande, border = 2:(k_recommande + 1))
dev.off()

# ------------------------------------------------------------
# Table individuelle des clusters
# ------------------------------------------------------------

clusters_individus <- tibble::tibble(
  id_individu = seq_len(nrow(coord_scaled)),
  cluster_kmeans = factor(res_kmeans$cluster),
  cluster_cah = factor(clusters_cah),
  target = donnees$target
) |>
  bind_cols(as.data.frame(coord))

readr::write_csv(clusters_individus, file.path("outputs", "tables", "05_clusters_individus.csv"))

p_clusters <- clusters_individus |>
  ggplot(aes(x = Dim.1, y = Dim.2, color = cluster_kmeans, shape = target)) +
  geom_point(alpha = 0.7) +
  labs(
    title = paste("K-means sur coordonnees FAMD - k =", k_recommande),
    x = "Dimension 1",
    y = "Dimension 2",
    color = "Cluster",
    shape = "Target"
  )

ggsave(file.path("outputs", "figures", "05_clusters_kmeans_famd.png"), p_clusters, width = 8, height = 6, dpi = 300)

# ------------------------------------------------------------
# Profils de clusters pour interpretation
# ------------------------------------------------------------

variables_academiques_importantes <- c(
  "admission_grade",
  "curricular_units_1st_sem_approved",
  "curricular_units_2nd_sem_approved",
  "curricular_units_1st_sem_grade",
  "curricular_units_2nd_sem_grade"
)

variables_binaires_importantes <- c(
  "gender",
  "displaced",
  "scholarship_holder",
  "debtor",
  "tuition_fees_up_to_date",
  "international"
)

variables_academiques_importantes <- intersect(variables_academiques_importantes, names(donnees))
variables_binaires_importantes <- intersect(variables_binaires_importantes, names(donnees))

donnees_clusters <- donnees |>
  mutate(id_individu = row_number()) |>
  bind_cols(cluster_kmeans = factor(res_kmeans$cluster), cluster_cah = factor(clusters_cah))

profils_clusters <- donnees_clusters |>
  group_by(cluster_kmeans) |>
  summarise(
    effectif = n(),
    proportion_dropout = mean(target == "Dropout"),
    proportion_enrolled = mean(target == "Enrolled"),
    proportion_graduate = mean(target == "Graduate"),
    across(
      all_of(variables_academiques_importantes),
      ~ mean(.x, na.rm = TRUE),
      .names = "{.col}_moyenne"
    ),
    .groups = "drop"
  ) |>
  mutate(across(starts_with("proportion_"), ~ round(100 * .x, 2)))

readr::write_csv(profils_clusters, file.path("outputs", "tables", "05_profils_clusters_kmeans.csv"))

# Tableau final interprete pour le rapport et la soutenance.
# Les indicateurs quantitatifs viennent du profil calcule ci-dessus ;
# les libelles facilitent la lecture sans modifier les calculs de clustering.
interpretation_clusters <- tibble::tribble(
  ~cluster_kmeans, ~nom_profil, ~interpretation_synthetique, ~niveau_risque,
  "1", "Profil fragile a risque academique", "Petit groupe avec forte proportion de Dropout et faibles performances academiques.", "Eleve",
  "2", "Profil performant a forte reussite", "Groupe avec forte proportion de Graduate, note d'admission elevee et bonnes performances academiques.", "Faible",
  "3", "Profil stable majoritaire", "Groupe majoritaire avec forte proportion de Graduate et situation globale stable.", "Faible",
  "4", "Profil critique de decrochage", "Groupe avec tres forte proportion de Dropout, tres faibles unites approuvees et notes tres faibles.", "Tres eleve",
  "5", "Profil intermediaire en transition", "Groupe intermediaire combinant reussite, inscription en cours et risque de Dropout non negligeable.", "Modere",
  "6", "Profil a risque eleve", "Groupe avec forte proportion de Dropout et profil academique a surveiller.", "Eleve"
)

profils_clusters_interpretes <- profils_clusters |>
  mutate(cluster_kmeans = as.character(cluster_kmeans)) |>
  left_join(interpretation_clusters, by = "cluster_kmeans") |>
  select(
    cluster_kmeans,
    nom_profil,
    effectif,
    proportion_dropout,
    proportion_enrolled,
    proportion_graduate,
    interpretation_synthetique,
    niveau_risque
  )

readr::write_csv(
  profils_clusters_interpretes,
  file.path("outputs", "tables", "05_profils_clusters_interpretes.csv")
)

repartition_binaires_clusters <- donnees_clusters |>
  select(cluster_kmeans, all_of(variables_binaires_importantes)) |>
  tidyr::pivot_longer(
    cols = -cluster_kmeans,
    names_to = "variable",
    values_to = "modalite"
  ) |>
  count(cluster_kmeans, variable, modalite, name = "effectif") |>
  group_by(cluster_kmeans, variable) |>
  mutate(
    total_variable_cluster = sum(effectif),
    proportion = effectif / total_variable_cluster,
    pourcentage = round(100 * proportion, 2)
  ) |>
  ungroup()

readr::write_csv(repartition_binaires_clusters, file.path("outputs", "tables", "05_repartition_binaires_clusters.csv"))

croisement_cluster_target <- donnees_clusters |>
  count(cluster_kmeans, target, name = "effectif") |>
  group_by(cluster_kmeans) |>
  mutate(
    total_cluster = sum(effectif),
    proportion = effectif / total_cluster,
    pourcentage = round(100 * proportion, 2)
  ) |>
  ungroup()

readr::write_csv(croisement_cluster_target, file.path("outputs", "tables", "05_croisement_cluster_target.csv"))

# Figure synthetique des proportions de Target dans chaque cluster.
p_cluster_target <- ggplot(croisement_cluster_target, aes(x = cluster_kmeans, y = proportion, fill = target)) +
  geom_col() +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Composition des clusters selon Target",
    x = "Cluster k-means",
    y = "Proportion dans le cluster",
    fill = "Target"
  )

ggsave(file.path("outputs", "figures", "05_composition_clusters_target.png"), p_cluster_target, width = 7, height = 5, dpi = 300)

message("Clustering termine. k recommande techniquement = ", k_recommande, ". Interpretation finale a discuter par l'equipe.")
