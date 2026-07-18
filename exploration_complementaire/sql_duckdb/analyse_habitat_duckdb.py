from pathlib import Path

import duckdb


PROJET = Path(__file__).resolve().parent
CSV_ARBRES = PROJET / "outputs" / "arbres_nettoyes.csv"
BASE_DUCKDB = PROJET / "habitat.duckdb"

if not CSV_ARBRES.exists():
    raise FileNotFoundError(f"Fichier absent : {CSV_ARBRES}")

connexion = duckdb.connect(str(BASE_DUCKDB))

chemin_csv = CSV_ARBRES.as_posix()

connexion.execute(
    f"""
    CREATE OR REPLACE TABLE arbres AS
    SELECT *
    FROM read_csv(
        '{chemin_csv}',
        header = TRUE,
        nullstr = ['NA', '']
    );
    """
)

print("\nDIMENSIONS")
print(
    connexion.execute(
        """
        SELECT
            COUNT(*) AS nb_lignes,
            COUNT(*) - COUNT(DISTINCT id_arbre)
                AS identifiants_dupliques
        FROM arbres;
        """
    ).fetchdf()
)

print("\nCONTRÔLE QUALITÉ")
qa = connexion.execute(
    """
    SELECT
        COUNT(*) AS lignes_totales,

        COUNT(*) FILTER (
            WHERE espece_latin IS NULL
        ) AS especes_manquantes,

        COUNT(*) FILTER (
            WHERE dhp_cm IS NULL
        ) AS dhp_manquants,

        COUNT(*) FILTER (
            WHERE dhp_cm > 120
        ) AS dhp_superieurs_120,

        COUNT(*) FILTER (
            WHERE x IS NULL OR y IS NULL
        ) AS coordonnees_manquantes

    FROM arbres;
    """
).fetchdf()

print(qa.to_string(index=False))

print("\nDIX PRINCIPAUX GENRES")
composition = connexion.execute(
    """
    SELECT
        genre,
        COUNT(*) AS nb_arbres,

        ROUND(
            100.0 * COUNT(*) /
            SUM(COUNT(*)) OVER (),
            2
        ) AS proportion_pct

    FROM arbres
    WHERE genre IS NOT NULL

    GROUP BY genre
    ORDER BY nb_arbres DESC
    LIMIT 10;
    """
).fetchdf()

print(composition.to_string(index=False))

connexion.close()

print("\nTraitement DuckDB terminé.")