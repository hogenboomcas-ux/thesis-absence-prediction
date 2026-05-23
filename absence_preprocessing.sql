/*
Onderstaande query is gerund door een ontwikkelaar vanuit de zorgorganisatie om de brondata op te halen. De query is gebaseerd op de reeds bestaande 
inrichting van het business intelligence platform van de zorgorganisatie. 
 
Het resultaat van deze query is als .CSV opgeleverd ten behoeve van het onderzoek. 
*/

WITH Contracts AS (
    SELECT
        Kp.OPK_D_Kostenplaats AS Team_ID,
        K.Jaar,
        K.Maandkey,
        SUM(Dv.FTE_Ziek) AS Totaal_FTE_Ziek,
        SUM(Dv.FTE_Toewijzing) AS Totaal_FTE_Toegewezen,
        ISNULL(SUM(Dv.FTE_Ziek), 0) / NULLIF(SUM(Dv.FTE_Toewijzing), 0) AS Verzuimpercentage
        COUNT(DISTINCT Dv.FK_D_Medewerker) AS Teamomvang, 
        AVG(DATEDIFF(YEAR, P.Geboorte_datum, K.Datum)) AS Gem_Leeftijd,
        CAST(COUNT(DISTINCT CASE 
            WHEN P.Geslacht = 'V' 
            THEN Dv.FK_D_Medewerker END) AS FLOAT)
            / NULLIF(COUNT(DISTINCT Dv.FK_D_Medewerker), 0) AS Aandeel_Vrouw,
        AVG(Dvb.UrenPerWeek) AS Gem_Contracturen_Week,
        CAST(COUNT(DISTINCT CASE 
            WHEN Dvb.SoortContract = 'Onbepaalde tijd' 
            THEN Dv.FK_D_Medewerker END) AS FLOAT)
            / NULLIF(COUNT(DISTINCT Dv.FK_D_Medewerker), 0) AS Aandeel_Vast_Contract

    FROM [SchemaName].F_Dienstverband AS Dv
    LEFT JOIN [SchemaName].D_Kalender        AS K   ON Dv.FK_D_Kalender      = K.PK_D_Kalender
    LEFT JOIN [SchemaName].D_Kostenplaats    AS Kp  ON Dv.FK_D_Kostenplaats  = Kp.PK_D_Kostenplaats
    LEFT JOIN [SchemaName].D_Dienstverband   AS Dvb ON Dv.FK_D_Dienstverband = Dvb.PK_D_Dienstverband
    LEFT JOIN [SchemaName].D_Medewerker      AS Mw  ON Dv.FK_D_Medewerker    = Mw.PK_D_Medewerker
    LEFT JOIN [SourceTable].Persoon          AS P   ON CAST(P.Persoonsnummer AS NVARCHAR) = Mw.OPK_D_Medewerker
    LEFT JOIN [SchemaName].D_Functie AS F ON F.PK_D_Functie = Dv.FK_D_Functie
    WHERE K.Jaar >= 2022
        AND Dv.FK_D_Medewerker != -1
        AND K.Maandkey <= '202604'
        AND Kp.KostenplaatsNiveau1 IN (**confidential**)

    GROUP BY Kp.OPK_D_Kostenplaats, K.Jaar, K.Maandkey
    HAVING SUM(Dv.FTE_Toewijzing) >= 110
),

overtime AS (
    SELECT
        LEFT(O.Personeelsnummer, CHARINDEX('/', O.Personeelsnummer) - 1) AS Medewerker_ID,
        K.Jaar,
        K.Maandkey,
        OPK_D_Kostenplaats AS Team_ID,
        SUM(CAST(REPLACE(O.Uren, ',', '.') AS FLOAT)) AS Overwerk_Uren

    FROM [SourceTable].[overtime] AS O
    INNER JOIN [SchemaName].D_Kalender AS K ON K.Datum = O.Datum
    LEFT JOIN [SchemaName].D_Rooster AS R ON COALESCE(NULLIF(O.[Rooster inzet], ''), O.[Rooster medewerker]) = R.Rooster
    LEFT JOIN [SchemaName].D_Kostenplaats AS Kp ON Kp.OPK_D_Kostenplaats = CAST(R.KostenplaatsCode AS VARCHAR(4000))
    WHERE O.Status = 'geaccepteerd'
        AND K.Jaar >= 2022
        AND K.Maandkey <= '202604'
        AND O.Personeelsnummer IS NOT NULL
        AND O.[Rooster inzet] IS NOT NULL

    GROUP BY 
        K.Jaar, K.Maandkey,
        OPK_D_Kostenplaats,
        LEFT(O.Personeelsnummer, CHARINDEX('/', O.Personeelsnummer) - 1)
),

Overwerk_Team AS(
    SELECT
        Team_ID,
        Jaar,
        Maandkey,
        SUM(Overwerk_Uren) AS Totaal_Overwerk_Uren,
        COUNT(DISTINCT Medewerker_ID) AS Medewerkers_Met_Overwerk,
        AVG(Overwerk_Uren) AS Gem_Overwerk_Per_Medewerker
    FROM overtime
    GROUP BY Team_ID, Jaar, Maandkey
)

SELECT
    A.Team_ID,
    A.Jaar,
    A.Maandkey,
    ISNULL(A.Totaal_FTE_Ziek, 0) AS Totaal_FTE_Ziek,
    A.Totaal_FTE_Toegewezen,
    A.Verzuimpercentage,
    A.Teamomvang,
    A.Gem_Leeftijd,
    A.Aandeel_Vrouw,
    ISNULL(O.Medewerkers_Met_Overwerk, 0) AS Medewerkers_Met_Overwerk, 
    A.Gem_Contracturen_Week,
    A.Aandeel_Vast_Contract,
    ISNULL(O.Totaal_Overwerk_Uren, 0) AS Totaal_Overwerk_Uren,
    ISNULL(O.Gem_Overwerk_Per_Medewerker, 0) AS Gem_Overwerk_Per_Medewerker

FROM Contracts AS A
LEFT JOIN Overwerk_Team AS O
    ON  CAST(A.Team_ID AS VARCHAR) = CAST(O.Team_ID AS VARCHAR)
    AND A.Jaar     = O.Jaar
    AND A.Maandkey = O.Maandkey

WHERE A.Team_ID NOT IN (**confidential**))
ORDER BY A.Team_ID, A.Jaar, A.Maandkey
