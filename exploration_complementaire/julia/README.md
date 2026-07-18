# Revalidation Julia (DataFrames.jl)

Relit `outputs/arbres_nettoyes.csv` de façon indépendante et recalcule les
indicateurs de contrôle qualité (lignes totales, espèces manquantes, DHP
manquants ou invalides, coordonnées manquantes).

## Exécution locale

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. analyse_habitat_julia.jl
```

## Exécution avec Docker (environnement figé)

```bash
docker build -t exploration-julia .
docker run --rm exploration-julia
```

Le `Dockerfile` fige la version de Julia (1.12) et les dépendances via
`Project.toml` / `Manifest.toml`, pour que la revalidation reste reproductible
indépendamment de l'environnement local.
