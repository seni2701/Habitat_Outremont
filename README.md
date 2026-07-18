# Cas technique Habitat — Patrimoine arboré public d'Outremont

Dépôt réalisé en réponse au cas technique proposé par Habitat (analyse de la
composition des arbres publics de l'arrondissement d'Outremont, données de la
Ville de Montréal).

## Structure du dépôt

```
.
├── cas_technique_R/            # LE LIVRABLE OFFICIEL — répond strictement au mandat, en R
├── exploration_complementaire/ # Démarche personnelle hors mandat — SQL/DuckDB, Julia, QGIS
├── presentation_orale/         # Notes pour la présentation orale de 3 minutes
└── README.md                   # Ce fichier
```

### Pourquoi cette séparation

Le mandat demandait explicitement une **analyse reproductible en R**, réalisable
en 60 à 90 minutes, évaluée notamment sur la maîtrise de R et du package `sf`
(20 % de la pondération). Le dossier `cas_technique_R/` répond exactement à ça,
sans rien d'autre.

Le dossier `exploration_complementaire/` documente un travail que j'ai fait de
mon propre chef, en dehors du temps du test, pour revalider les résultats avec
d'autres outils de mon stack habituel (SQL/DuckDB, Julia, QGIS). Ce n'est pas
une deuxième version du livrable — c'est une pratique que j'applique aussi dans
mes projets réels (EcoSpatial, CARTHAB) : ne jamais faire confiance à un seul
langage ou une seule librairie pour un résultat qui doit être fiable, et
vérifier la cohérence spatiale visuellement plutôt que de la supposer.

Je préfère cette séparation à un dépôt qui mélangerait tout : ça montre ma
polyvalence réelle sans brouiller ce que le cas technique doit démontrer.

## Pour commencer

1. **Livrable du cas technique** : voir `cas_technique_R/README.md`
2. **Exploration complémentaire** : voir `exploration_complementaire/README.md`
3. **Présentation orale** : voir `presentation_orale/notes_3_minutes.md`

## Stack utilisé

| Composant | Rôle |
|---|---|
| R (`dplyr`, `readr`, `janitor`, `sf`, `ggplot2`, `forcats`) | Analyse principale demandée par le mandat |
| Shiny + leaflet | Prototype de tableau de bord interactif |
| Python + DuckDB (SQL) | Revalidation indépendante des indicateurs |
| Julia (DataFrames.jl) | Revalidation indépendante, environnement Docker figé |
| QGIS | Vérification visuelle de la cohérence spatiale |
| Docker | Reproductibilité de l'environnement R et Julia |

## À compléter avant l'envoi

- [ ] Ajouter le projet QGIS réel dans `exploration_complementaire/qgis/`
      (actuellement un placeholder — voir le README de ce dossier)
- [ ] Vérifier que `data/arbres_outremont.csv` correspond bien à l'export final
      utilisé (date dans le nom de fichier : 2026-01-12)
- [ ] Relire `presentation_orale/notes_3_minutes.md` et la reformuler avec tes
      propres mots avant l'oral — ce sont des notes de structure, pas un texte
      à lire
