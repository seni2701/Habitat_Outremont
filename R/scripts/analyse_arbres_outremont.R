# =====================================================================
# ARBRES PUBLICS D'OUTREMONT
# Importation, nettoyage, contrôle qualité, statistiques, graphiques,
# spatialisation et exports.
#
# Ce script est conçu pour être exécuté depuis la racine du dossier
# `R/` (via `Rscript analyse_arbres_outremont.R` ou en
# ouvrant le projet dans RStudio). Aucun chemin absolu n'est requis.
# =====================================================================

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  stringsAsFactors = FALSE
)

dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)

packages_requis <- c(
  "dplyr", "readr", "tibble", "stringr", "lubridate",
  "janitor", "forcats", "ggplot2", "scales", "sf"
)

packages_manquants <- packages_requis[
  !vapply(
    packages_requis,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
]

if (length(packages_manquants) > 0) {
  stop(
    "Packages manquants : ",
    paste(packages_manquants, collapse = ", ")
  )
}

url_csv <- paste0(
  "https://donnees.montreal.ca/dataset/",
  "b89fd27d-4b49-461b-8e54-fa2b34a628c4/",
  "resource/05f06958-fa34-4c74-be23-2573074bfd6e/",
  "download/inventaire_arbre_outremont_2026-01-12.csv"
)

fichier_csv <- "data/arbres_outremont.csv"

if (!file.exists(fichier_csv)) {
  utils::download.file(
    url = url_csv,
    destfile = fichier_csv,
    mode = "wb"
  )
}

arbres_bruts <- readr::read_csv(
  fichier_csv,
  locale = readr::locale(encoding = "UTF-8"),
  na = c("", "NA", "N/A", "NULL"),
  show_col_types = FALSE,
  progress = TRUE,
  name_repair = "unique"
) |>
  janitor::clean_names()

premiere_colonne_existante <- function(data, candidats, libelle) {
  trouvees <- candidats[candidats %in% names(data)]

  if (length(trouvees) == 0) {
    stop("Colonne introuvable pour : ", libelle)
  }

  trouvees[[1]]
}

col_id <- premiere_colonne_existante(
  arbres_bruts,
  c("emp_no", "id_arbre", "id"),
  "identifiant"
)

col_arrondissement <- premiere_colonne_existante(
  arbres_bruts,
  c("arrond_nom", "arrondissement", "arrond"),
  "arrondissement"
)

col_rue <- premiere_colonne_existante(
  arbres_bruts,
  c("rue", "nom_rue"),
  "rue"
)

col_emplacement <- premiere_colonne_existante(
  arbres_bruts,
  c("emplacement", "localisation"),
  "emplacement"
)

col_espece <- premiere_colonne_existante(
  arbres_bruts,
  c("essence_latin", "espece_latin", "nom_latin"),
  "espèce latine"
)

col_dhp <- premiere_colonne_existante(
  arbres_bruts,
  c("dhp", "dhp_cm", "diametre"),
  "DHP"
)

col_x <- premiere_colonne_existante(
  arbres_bruts,
  c("coord_x_9", "coord_x", "coord_x_32", "x"),
  "coordonnée X"
)

col_y <- premiere_colonne_existante(
  arbres_bruts,
  c("coord_y_10", "coord_y", "coord_y_33", "y"),
  "coordonnée Y"
)

col_date <- premiere_colonne_existante(
  arbres_bruts,
  c("date_releve", "date_inventaire", "date"),
  "date du relevé"
)

id_original <- arbres_bruts[[col_id]]
arrondissement_original <- arbres_bruts[[col_arrondissement]]
rue_originale <- arbres_bruts[[col_rue]]
emplacement_original <- arbres_bruts[[col_emplacement]]
espece_originale <- arbres_bruts[[col_espece]]
dhp_original <- suppressWarnings(as.numeric(arbres_bruts[[col_dhp]]))
x_original <- suppressWarnings(as.numeric(arbres_bruts[[col_x]]))
y_original <- suppressWarnings(as.numeric(arbres_bruts[[col_y]]))
date_originale <- as.character(arbres_bruts[[col_date]])

# Les données municipales encodent parfois le DHP et les coordonnées avec
# un facteur d'échelle différent selon les exports. On détecte ce facteur
# à partir de la médiane plutôt que de le supposer fixe.
facteur_dhp <- if (stats::median(dhp_original, na.rm = TRUE) > 300) 100 else 1
facteur_x <- if (stats::median(x_original, na.rm = TRUE) > 1000000) 100 else 1
facteur_y <- if (stats::median(y_original, na.rm = TRUE) > 10000000) 100 else 1

arbres <- tibble::tibble(
  id_arbre = paste0(
    "OUT_",
    stringr::str_pad(
      as.character(id_original),
      width = 7,
      side = "left",
      pad = "0"
    )
  ),
  arrondissement = stringr::str_squish(as.character(arrondissement_original)),
  rue = stringr::str_squish(as.character(rue_originale)),
  emplacement = stringr::str_squish(as.character(emplacement_original)),
  espece_latin = stringr::str_squish(as.character(espece_originale)),
  dhp_cm = dhp_original / facteur_dhp,
  x = x_original / facteur_x,
  y = y_original / facteur_y,
  date_releve = lubridate::ymd(
    stringr::str_replace_all(date_originale, "\\.", "-"),
    quiet = TRUE
  )
) |>
  dplyr::mutate(
    dplyr::across(
      c(arrondissement, rue, emplacement, espece_latin),
      ~ dplyr::na_if(.x, "")
    ),
    genre = stringr::word(espece_latin, 1),
    annee_releve = lubridate::year(date_releve),
    classe_dhp = cut(
      dhp_cm,
      breaks = c(-Inf, 10, 30, 60, Inf),
      labels = c(
        "Moins de 10 cm",
        "10 à moins de 30 cm",
        "30 à moins de 60 cm",
        "60 cm et plus"
      ),
      right = FALSE
    )
  )

# --- Contrôle qualité --------------------------------------------------
# On documente les anomalies avant de les exclure des statistiques,
# plutôt que de les supprimer silencieusement.

qa <- tibble::tibble(
  indicateur = c(
    "Lignes totales",
    "Espèces manquantes",
    "DHP manquants",
    "DHP non positifs",
    "DHP supérieurs à 120 cm",
    "Coordonnées manquantes",
    "Identifiants dupliqués",
    "Dates manquantes"
  ),
  nombre = c(
    nrow(arbres),
    sum(is.na(arbres$espece_latin)),
    sum(is.na(arbres$dhp_cm)),
    sum(arbres$dhp_cm <= 0, na.rm = TRUE),
    sum(arbres$dhp_cm > 120, na.rm = TRUE),
    sum(is.na(arbres$x) | is.na(arbres$y)),
    sum(duplicated(arbres$id_arbre)),
    sum(is.na(arbres$date_releve))
  )
) |>
  dplyr::mutate(
    proportion_pct = round(100 * nombre / nrow(arbres), 2)
  )

arbres <- arbres |>
  dplyr::mutate(
    anomalie = (
      is.na(espece_latin) |
      is.na(dhp_cm) |
      dhp_cm <= 0 |
      dhp_cm > 120 |
      is.na(x) |
      is.na(y) |
      is.na(date_releve)
    )
  )

# --- Composition -------------------------------------------------------
# Le dénominateur des proportions est le nombre d'arbres avec une espèce
# renseignée, pas le nombre total de lignes.

composition <- arbres |>
  dplyr::filter(!is.na(espece_latin)) |>
  dplyr::count(espece_latin, sort = TRUE, name = "nb_arbres") |>
  dplyr::mutate(
    proportion = nb_arbres / sum(nb_arbres),
    proportion_pct = round(100 * proportion, 2)
  )

composition_genre <- arbres |>
  dplyr::filter(!is.na(genre)) |>
  dplyr::count(genre, sort = TRUE, name = "nb_arbres") |>
  dplyr::mutate(
    proportion = nb_arbres / sum(nb_arbres),
    proportion_pct = round(100 * proportion, 2)
  )

p <- composition$proportion

diversite <- tibble::tibble(
  indice = c("Shannon", "Simpson"),
  valeur = c(
    -sum(p * log(p), na.rm = TRUE),
    1 - sum(p^2, na.rm = TRUE)
  )
)

indicateurs <- arbres |>
  dplyr::summarise(
    nb_arbres = dplyr::n(),
    nb_arbres_avec_espece = sum(!is.na(espece_latin)),
    nb_especes = dplyr::n_distinct(espece_latin, na.rm = TRUE),
    nb_genres = dplyr::n_distinct(genre, na.rm = TRUE),
    dhp_moyen_cm = mean(dhp_cm, na.rm = TRUE),
    dhp_median_cm = stats::median(dhp_cm, na.rm = TRUE),
    proportion_acer_pct = round(100 * mean(genre == "ACER", na.rm = TRUE), 2)
  )

# DHP moyen par espèce, restreint aux espèces avec au moins 20 mesures
# valides (question 5 du brief).
dhp_par_espece <- arbres |>
  dplyr::filter(
    !is.na(espece_latin),
    !is.na(dhp_cm),
    dhp_cm > 0
  ) |>
  dplyr::group_by(espece_latin) |>
  dplyr::summarise(
    nb_mesures = dplyr::n(),
    dhp_moyen_cm = mean(dhp_cm),
    dhp_median_cm = stats::median(dhp_cm),
    ecart_type_cm = stats::sd(dhp_cm),
    .groups = "drop"
  ) |>
  dplyr::filter(nb_mesures >= 20) |>
  dplyr::arrange(dplyr::desc(dhp_moyen_cm))

# --- Graphiques ---------------------------------------------------------

graphique_genres <- composition_genre |>
  dplyr::slice_head(n = 10) |>
  dplyr::mutate(genre = forcats::fct_reorder(genre, proportion_pct)) |>
  ggplot2::ggplot(ggplot2::aes(x = proportion_pct, y = genre)) +
  ggplot2::geom_col() +
  ggplot2::labs(
    title = "Composition du patrimoine arboré par genre",
    subtitle = "Dix genres les plus représentés",
    x = "Proportion des arbres (%)",
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "outputs/composition_genres_top10.png",
  graphique_genres,
  width = 9, height = 6, dpi = 300
)

graphique_dhp <- dhp_par_espece |>
  dplyr::slice_head(n = 10) |>
  dplyr::mutate(
    espece_latin = forcats::fct_reorder(espece_latin, dhp_moyen_cm)
  ) |>
  ggplot2::ggplot(ggplot2::aes(x = dhp_moyen_cm, y = espece_latin)) +
  ggplot2::geom_col() +
  ggplot2::labs(
    title = "DHP moyen des dix espèces dominantes en diamètre",
    subtitle = "Espèces comptant au moins 20 mesures",
    x = "DHP moyen (cm)",
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "outputs/dhp_moyen_top10.png",
  graphique_dhp,
  width = 9, height = 6, dpi = 300
)

graphique_classes_dhp <- arbres |>
  dplyr::filter(!is.na(classe_dhp)) |>
  dplyr::count(classe_dhp, .drop = FALSE, name = "nb_arbres") |>
  ggplot2::ggplot(ggplot2::aes(x = classe_dhp, y = nb_arbres)) +
  ggplot2::geom_col() +
  ggplot2::labs(
    title = "Répartition des arbres par classe de DHP",
    x = NULL,
    y = "Nombre d'arbres"
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))

ggplot2::ggsave(
  "outputs/classes_dhp.png",
  graphique_classes_dhp,
  width = 9, height = 6, dpi = 300
)

# --- Spatialisation ------------------------------------------------------
# Les coordonnées sources sont en NAD83 / MTM zone 8 (EPSG:32188), le
# système utilisé par la Ville de Montréal pour ses inventaires urbains.
# On reprojette en WGS84 (EPSG:4326) pour l'export et la carte interactive.

arbres_spatiaux <- arbres |>
  dplyr::filter(!is.na(x), !is.na(y)) |>
  sf::st_as_sf(coords = c("x", "y"), crs = 32188, remove = FALSE)

arbres_wgs84 <- arbres_spatiaux |>
  sf::st_transform(4326)

# --- Exports -------------------------------------------------------------

readr::write_csv(arbres, "outputs/arbres_nettoyes.csv", na = "NA")
readr::write_csv(qa, "outputs/controle_qualite.csv")
readr::write_csv(composition, "outputs/composition_especes.csv")
readr::write_csv(composition_genre, "outputs/composition_genres.csv")
readr::write_csv(diversite, "outputs/indices_diversite.csv")
readr::write_csv(indicateurs, "outputs/indicateurs_globaux.csv")
readr::write_csv(dhp_par_espece, "outputs/dhp_par_espece.csv")

sf::st_write(
  arbres_wgs84,
  "outputs/arbres_outremont.gpkg",
  layer = "arbres",
  delete_dsn = TRUE,
  quiet = TRUE
)

cat("\n============================================================\n")
cat("TRAITEMENT TERMINÉ\n")
cat("============================================================\n")
cat("Arbres importés    :", nrow(arbres), "\n")
cat("Arbres spatialisés :", nrow(arbres_wgs84), "\n")
cat("Espèces            :", dplyr::n_distinct(arbres$espece_latin, na.rm = TRUE), "\n")
cat("Genres             :", dplyr::n_distinct(arbres$genre, na.rm = TRUE), "\n")
cat("DHP moyen          :", round(mean(arbres$dhp_cm, na.rm = TRUE), 1), "cm\n")
cat("Genre dominant     :", composition_genre$genre[[1]],
    "(", composition_genre$proportion_pct[[1]], "%)\n")
cat("============================================================\n")

print(qa)
print(utils::head(composition, 10))
print(utils::head(composition_genre, 10))
print(diversite)
print(utils::head(dhp_par_espece, 10))
print(list.files("outputs"))
