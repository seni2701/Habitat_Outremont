FROM julia:1.12-bookworm

WORKDIR /app

COPY Project.toml Manifest.toml ./

RUN julia --project=. -e \
    'using Pkg; Pkg.instantiate(); Pkg.precompile()'

COPY analyse_habitat_julia.jl ./

RUN mkdir -p outputs

COPY outputs/arbres_nettoyes.csv ./outputs/arbres_nettoyes.csv

CMD ["julia", "--project=.", "analyse_habitat_julia.jl"]