# Revalidation SQL (DuckDB)

Recalcule en SQL, sur `outputs/arbres_nettoyes.csv`, les mêmes indicateurs que le
script R : dimensions, contrôle qualité, composition par genre.

## Exécution

```bash
pip install duckdb --break-system-packages
python analyse_habitat_duckdb.py
```

## Ce que ça confirme

- Le nombre de lignes, d'identifiants dupliqués et d'anomalies obtenus via
  `COUNT(*) FILTER (...)` correspondent exactement à `outputs/controle_qualite.csv`.
- Les proportions par genre calculées avec une fonction fenêtre SQL
  (`SUM(...) OVER ()`) correspondent à `outputs/composition_genres.csv`.

Aucune divergence n'a été observée entre les deux implémentations, ce qui
donne un premier niveau de confiance sur l'absence d'erreur d'agrégation.
