using CSV
using DataFrames
using Statistics

chemin = joinpath(
    @__DIR__,
    "outputs",
    "arbres_nettoyes.csv"
)

arbres = CSV.read(
    chemin,
    DataFrame;
    missingstring = "NA"
)

println("Dimensions : ", size(arbres))
println("Colonnes : ", names(arbres))
println(first(arbres, 5))
println(eltype.(eachcol(arbres)))

qa = DataFrame(
    indicateur = [
        "Lignes totales",
        "Espèces manquantes",
        "DHP manquants",
        "DHP supérieurs à 120 cm",
        "Coordonnées manquantes"
    ],

    nombre = [
        nrow(arbres),

        count(ismissing, arbres.espece_latin),

        count(ismissing, arbres.dhp_cm),

        count(
            valeur -> !ismissing(valeur) && valeur > 120,
            arbres.dhp_cm
        ),

        count(
            i -> ismissing(arbres.x[i]) ||
                 ismissing(arbres.y[i]),
            1:nrow(arbres)
        )
    ]
)

println(qa)