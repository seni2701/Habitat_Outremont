# Composition des arbres publics d'Outremont

Le dossier `exploration_complementaire/` à la racine du dépôt contient un travail
distinct, fait de ma propre initiative en dehors du temps du test, pour
approfondir la validation des résultats. Il est clairement séparé pour ne pas
brouiller ce que ce livrable doit démontrer.

## Contenu

```
cas_technique_R/
├── analyse_arbres_outremont.R   # Script principal : import, nettoyage, QC, stats, graphiques, sf
├── app.R                         # Prototype de tableau de bord interactif (Shiny + leaflet)
├── data/
│   └── arbres_outremont.csv      # Inventaire des arbres publics d'Outremont (Ville de Montréal)
├── outputs/                      # Résultats générés par analyse_arbres_outremont.R
└── Dockerfile                    # Environnement R reproductible (rocker/geospatial)
```

## Exécution

**Localement :**

```r
# Depuis ce dossier, avec les packages listés en tête de script installés
Rscript analyse_arbres_outremont.R
```

**Avec Docker (reproductibilité garantie) :**

```bash
docker build -t cas-habitat-outremont .
docker run --rm -v "$(pwd)/outputs:/projet/outputs" cas-habitat-outremont
```

**Tableau de bord :**

```r
shiny::runApp("app.R")
```

## Méthode (résumé)

1. **Import** : lecture du CSV avec détection de l'encodage et des types de colonnes réels
   (les noms de colonnes de l'export municipal varient selon les versions, donc le script
   cherche parmi plusieurs alias plutôt que de supposer un nom fixe).
2. **Nettoyage** : nettoyage des chaînes (espaces, casse), détection automatique d'un facteur
   d'échelle sur le DHP et les coordonnées (certains exports municipaux encodent ces valeurs
   ×100), extraction du genre à partir du nom latin, classes de DHP.
3. **Contrôle qualité** : les anomalies (espèce manquante, DHP invalide ou manquant,
   coordonnées manquantes, identifiant dupliqué, date manquante) sont **comptées et
   documentées**, pas supprimées silencieusement. Une colonne `anomalie` reste disponible
   pour audit.
4. **Indicateurs** : les proportions d'espèces sont calculées sur le nombre d'arbres
   *avec une espèce renseignée*, pas sur le total de lignes — le dénominateur est explicite.
5. **Spatialisation** : les coordonnées sources sont en NAD83 / MTM zone 8 (EPSG:32188,
   système standard des inventaires urbains de la Ville de Montréal); reprojection en
   WGS84 (EPSG:4326) pour l'export `.gpkg` et la carte interactive.

## Réponses aux questions du brief

*(chiffres produits par `outputs/*.csv`, exécution du script en date du dépôt)*

| # | Question | Réponse |
|---|---|---|
| 1 | Arbres utilisables | 7 688 lignes au total; 7 683 avec une espèce renseignée |
| 2 | Espèces distinctes | 148 espèces, 48 genres |
| 3 | Dix espèces les plus fréquentes | voir `outputs/composition_especes.csv` — dominées par *Acer platanoides* (22,8 %) et *Acer saccharinum* (13,6 %) |
| 4 | Part des trois espèces dominantes | *Acer platanoides*, *Acer saccharinum* et *Fraxinus pennsylvanica* représentent ensemble environ 40 % du patrimoine |
| 5 | DHP moyen le plus élevé (≥ 20 obs.) | *Acer saccharinum* (61,2 cm), suivi d'*Acer platanoides* (50,0 cm) et *Tilia cordata* (47,5 cm) |
| 6 | Proportions d'anomalies | essence manquante 0,07 %; DHP manquant 0 %; DHP > 120 cm 0,08 %; coordonnées manquantes 0,05 %; identifiants dupliqués 0 % |
| 7 | Cohérence NAD83 / MTM zone 8 | les coordonnées sources sont cohérentes avec l'emprise attendue pour Outremont en EPSG:32188; la reprojection en WGS84 ne produit pas de points hors de l'arrondissement |
| 8 | Indicateurs utiles au tableau de bord | nombre d'arbres, richesse spécifique, indice de diversité de Shannon, top 10 espèces/genres, DHP moyen par espèce, carte de répartition, taux d'anomalies |

Indices de diversité : Shannon = 3,52, Simpson = 0,919 — une diversité spécifique
relativement élevée, bien que dominée par le genre *Acer* (48,6 % des arbres), ce qui
mérite d'être signalé dans l'interprétation (vulnérabilité si un ravageur ciblait ce genre).

## Limites de l'inventaire

Comme signalé dans le brief : les données municipales peuvent contenir des localisations
imprécises ou désuètes, et certains arbres de parc peuvent être absents de l'inventaire.
Les indicateurs ci-dessus portent sur les arbres **inventoriés**, pas sur le patrimoine réel,
qui peut être légèrement plus large ou différemment distribué.
