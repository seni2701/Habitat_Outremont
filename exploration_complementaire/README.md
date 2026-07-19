# Exploration complémentaire

Les résultats obtenus en R avec d'autres outils de mon stack
technique habituel, et pour montrer comment j'aborde la reproductibilité et le
contrôle qualité inter-outils dans mon travail courant (EcoSpatial, CARTHAB et UTI de Montréal).

## Contenu

| Dossier | Outil | Ce qui est vérifié |
|---|---|---|
| `sql_duckdb/` | Python + DuckDB (SQL) | Recalcul des indicateurs de contrôle qualité et de composition par genre directement en SQL sur le CSV nettoyé, pour confirmer l'absence d'erreur d'agrégation côté `dplyr` |
| `julia/` | Julia (DataFrames.jl) | Relecture indépendante du fichier nettoyé et recalcul des mêmes indicateurs de contrôle qualité, avec un environnement Docker figé (`Project.toml` / `Manifest.toml`) |
| `qgis/` | QGIS | Vérification visuelle de la cohérence spatiale (question 7 du brief : NAD83 / MTM zone 8) par superposition de la couche exportée avec les limites de l'arrondissement d'Outremont |

Chaque sous-dossier part du fichier `outputs/arbres_nettoyes.csv` produit par le
script R — il n'y a pas de nouvelle collecte ou de nouveau nettoyage de données ici,
seulement une revalidation des résultats déjà obtenus.
