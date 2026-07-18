# Exploration complémentaire (hors mandat du cas technique)

Ce qui suit est une initiative personnelle, réalisée en dehors du temps du test,
pour valider les résultats obtenus en R avec d'autres outils de mon stack
technique habituel, et pour montrer comment j'aborde la reproductibilité et le
contrôle qualité inter-outils dans mon travail courant (EcoSpatial, CARTHAB).
L'objectif n'est pas de refaire l'analyse en plusieurs langages pour impressionner,
mais de documenter une pratique réelle : vérifier qu'un résultat statistique ne
dépend pas d'un artefact propre à un langage ou une librairie donnée.

## Contenu

| Dossier | Outil | Ce qui est vérifié |
|---|---|---|
| `sql_duckdb/` | Python + DuckDB (SQL) | Recalcul des indicateurs de contrôle qualité et de composition par genre directement en SQL sur le CSV nettoyé, pour confirmer l'absence d'erreur d'agrégation côté `dplyr` |
| `julia/` | Julia (DataFrames.jl) | Relecture indépendante du fichier nettoyé et recalcul des mêmes indicateurs de contrôle qualité, avec un environnement Docker figé (`Project.toml` / `Manifest.toml`) |
| `qgis/` | QGIS | Vérification visuelle de la cohérence spatiale (question 7 du brief : NAD83 / MTM zone 8) par superposition de la couche exportée avec les limites de l'arrondissement d'Outremont |

Chaque sous-dossier part du fichier `outputs/arbres_nettoyes.csv` produit par le
script R — il n'y a pas de nouvelle collecte ou de nouveau nettoyage de données ici,
seulement une revalidation des résultats déjà obtenus.

## Pourquoi le présenter ainsi

Un cas technique évalue une compétence précise dans un cadre précis. Faire
passer un travail exploratoire personnel pour une partie du livrable officiel
fausserait ce que l'évaluateur cherche à mesurer. Le séparer clairement permet
de montrer une polyvalence réelle sans diluer ni maquiller la réponse au mandat.
