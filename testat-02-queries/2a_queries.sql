/*
1. Wieviele Produkte jeden Typs (Buch, Musik-CD, DVD) sind in der Datenbank erfasst?
Hinweis: Geben Sie das Ergebnis in einer 3-spaltigen Relation aus.

Verwendet die SUM-Funktion in Verbindung mit CASE-Ausdrücken, um die Anzahl der
Produkte zu berechnen, die jeweils zur Produktgruppe 'Book', 'Music' und 'DVD' gehören.
*/

SELECT SUM(CASE WHEN pgroup = 'Book' THEN 1 ELSE 0 END)  AS "Anzahl Bücher",
       SUM(CASE WHEN pgroup = 'Music' THEN 1 ELSE 0 END) AS "Anzahl Musik-CDs",
       SUM(CASE WHEN pgroup = 'DVD' THEN 1 ELSE 0 END)   AS "Anzahl DVDs"
FROM Product;


/*
2. Nennen Sie die 5 besten Produkte jedes Typs (Buch, Musik-CD, DVD) sortiert nach dem durchschnittlichem Rating.
Hinweis: Geben Sie das Ergebnis in einer einzigen Relation mit den Attributen Typ, ProduktNr, Rating aus.

Dieses SQL-Statement definiert eine Common Table Expression (CTE) namens Best_Products,
die die besten Produkte in jeder Produktgruppe basierend auf den durchschnittlichen Bewertungen ermittelt.
Zunächst wird für jedes Produkt die durchschnittliche Bewertung berechnet.

Anschließend werden die Produkte nach ihren Produktgruppen (pgroup) partitioniert und innerhalb
jeder Gruppe nach der durchschnittlichen Bewertung absteigend sortiert.

Die Reihenfolge der Produkte innerhalb jeder Gruppe wird mit ROW_NUMBER nummeriert.
*/

WITH Best_Products AS (SELECT pgroup             AS Typ,
                              Product.product_id AS ProduktNr,
                              average_rating     AS Rating,
                              ROW_NUMBER() OVER (
                                  PARTITION BY pgroup
                                  ORDER BY average_rating DESC
                                  )              AS Reihenfolge
                       FROM Product
                       WHERE average_rating IS NOT NULL)

SELECT Typ, ProduktNr, Rating
FROM Best_Products
WHERE Reihenfolge <= 5
ORDER BY Typ, Reihenfolge;

/*
3. Für welche Produkte gibt es im Moment kein Angebot?

Dieses SQL-Statement selektiert eindeutige Produkt-IDs aus der Tabelle "Offer"
und benennt die Spalte in "Produkte ohne Angebot" um.
Es filtert die Ergebnisse, um nur diejenigen Produkt-IDs einzuschließen,
bei denen der Preis (price) NULL ist, was bedeutet, dass kein Angebot für diese Produkte vorliegt.
*/

SELECT DISTINCT of.product_id
FROM offer of
WHERE NOT EXISTS (
    -- Unterabfrage
    SELECT 1
    FROM offer of2
    WHERE of.product_id = of2.product_id
      AND of2.price IS NOT NULL);

/*
4. Für welche Produkte ist das teuerste Angebot mehr als doppelt so teuer wie das preiswerteste?

Das Statement verwendet zwei Unterabfragen:
1. Um den maximalen Preis für jede Produkt-ID zu ermitteln, wobei der Preis nicht NULL ist.
2. Um den minimalen Preis für jede Produkt-ID zu ermitteln, wobei der Preis nicht NULL ist.
Die Hauptabfrage wählt Produkt-IDs aus, bei denen das Maximum des Preises mehr als das Doppelte des Minimums beträgt.
*/
SELECT product_id
FROM Offer AS o
WHERE (SELECT MAX(price) FROM Offer WHERE product_id = o.product_id AND price IS NOT NULL) >
      2 * (SELECT MIN(price) FROM Offer WHERE product_id = o.product_id AND price IS NOT NULL);

/*
5. Welche Produkte haben sowohl mindestens eine sehr schlechte (Punktzahl: 1) als auch mindestens eine sehr gute (Punktzahl: 5) Bewertung?

Dieses SQL-Statement selektiert Produkt-IDs aus einer Unterabfrage,
die die Bewertungen der Produkte aus der Tabelle "Review" enthält.
Es gruppiert die Ergebnisse nach Produkt-IDs und filtert die Gruppen, um nur diejenigen
einzuschließen, die sowohl Bewertungen von 1 als auch von 5 enthalten.
Dazu wird die HAVING-Klausel verwendet, um sicherzustellen, dass es mindestens eine Bewertung
von 1 und mindestens eine Bewertung von 5 für jedes ausgewählte Produkt gibt.
*/
SELECT product_id
FROM (SELECT product_id, rating
      FROM Review) AS reviews
WHERE reviews.rating = 1
   OR reviews.rating = 5
GROUP BY reviews.product_id
HAVING COUNT(CASE WHEN reviews.rating = 1 THEN reviews.product_id END) > 0
   AND COUNT(CASE WHEN reviews.rating = 5 THEN reviews.product_id END) > 0;

/*
6. Für wieviele Produkte gibt es gar keine Rezension?

Dieses SQL-Statement zählt die Anzahl der Produkte ohne Rezensionen.
Es verwendet eine Unterabfrage, um zu überprüfen, ob es für jedes Produkt in der Tabelle "Product" keine entsprechende Rezension gibt.
Wenn für ein Produkt keine Rezension existiert, wird es in die Zählung einbezogen.
Das Ergebnis wird als "Anzahl Produkte ohne Rezension" zurückgegeben.
*/
SELECT COUNT(product_id) AS "Anzahl Produkte ohne Rezension"
FROM Product AS p
WHERE NOT EXISTS (SELECT 1
                  FROM Review AS r
                  WHERE r.product_id = p.product_id);


/*
7. Nennen Sie alle Rezensenten, die mindestens 10 Rezensionen geschrieben haben (Annahme: Ohne Gast).

Dieses SQL-Statement wählt die Kunden-ID (customer_id) und zählt die Anzahl der Rezensionen für jeden Kunden aus der Tabelle "Review".
Es gruppiert die Ergebnisse nach Kunden-ID.
Dann werden alle Kunden herausgefilter deren id nicht 'guest' entspricht und meht als 10 Rezensionen geschrieben haben.
*/

SELECT customer_id AS "Kunde", COUNT(customer_id) AS "Anzahl Rezensionen"
FROM Review
GROUP BY customer_id
HAVING COUNT(review_id) >= 10
   AND customer_id != 'guest';

/*
8. Geben Sie eine duplikatfreie und alphabetisch sortierte Liste der Namen aller Buchautoren an, die auch an DVDs oder Musik-CDs beteiligt sind.

Dieses SQL-Statement wählt die Namen von Personen aus der Tabelle "person" aus, die in den Tabellen "book_person", "dvd_person" und "cd_person" vorkommen.
Es überprüft, ob die person_id einer Person in allen drei Tabellen vorhanden ist.
Dann werden die Ergebnisse nach Namen sortiert.
*/
SELECT name
FROM person
WHERE person_id IN (SELECT person_id FROM book_person)
  AND (person_id IN (SELECT person_id FROM dvd_person) OR person_id IN (SELECT person_id FROM cd_person))
ORDER BY name;

/*
9. Wie hoch ist die durchschnittliche Anzahl von Liedern einer Musik-CD?

Dieses SQL-Statement berechnet die durchschnittliche Anzahl von Liedern pro CD.
Zuerst wird in einer Unterabfrage die Anzahl der Lieder für jede CD gezählt und als "num_songs" gruppiert nach "cd_id" berechnet.
Dann wird in der äußeren Abfrage der Durchschnitt dieser Liedanzahlen berechnet und auf die nächste ganze Zahl gerundet.
Das Ergebnis wird als "durchschnittliche_anzahl_lieder" zurückgegeben.
*/

SELECT ROUND(AVG(num_songs), 0) AS durchschnittliche_anzahl_lieder
FROM (SELECT cd_id, COUNT(*) AS num_songs
      FROM Title
      GROUP BY cd_id) AS song_count;

/*
10. Für welche Produkte gibt es ähnliche Produkte in einer anderen Hauptkategorie?
Hinweis: Eine Hauptkategorie ist eine Produktkategorie ohne Oberkategorie. Erstellen Sie eine rekursive Anfrage, die zu jedem Produkt dessen Hauptkategorie bestimmt.
*/

-- Zuerst definieren wir eine rekursive CTE (Common Table Expression), um die Hierarchie der Kategorien zu erstellen.
-- Die CTE "category_hierarchy" dient dazu, die Kategorien und ihre Unterkategorien in einer hierarchischen Struktur zu organisieren.
-- Sie besteht aus zwei Teilen: der Basisabfrage und der rekursiven Abfrage.
WITH RECURSIVE category_hierarchy AS (
    -- Basisabfrage: Wir beginnen mit den Hauptkategorien, die keine Elternkategorie haben.
    SELECT category.category_id, category.parent_category, category.category_id AS root_category_id
    FROM category
    WHERE category.parent_category IS NULL

    UNION ALL

    -- Rekursive Abfrage: Hier fügen wir Unterkategorien hinzu, indem wir die Kategorien mit ihren Elternkategorien verknüpfen.
    SELECT category.category_id, category.parent_category, category_hierarchy.root_category_id
    FROM category
             INNER JOIN category_hierarchy ON category.parent_category = category_hierarchy.category_id)

-- Nachdem wir die Hierarchie der Kategorien definiert haben,
-- führen wir die Hauptabfrage aus, um ähnliche Produkte in verschiedenen Hauptkategorien zu finden.
SELECT DISTINCT product_similars.product_id
FROM product_similars

         JOIN product_category AS jpc1 ON product_similars.product_id = jpc1.product_id
         JOIN product_category AS jpc2 ON product_similars.similar_product = jpc2.product_id

         JOIN category_hierarchy AS ch1 ON jpc1.category_id = ch1.category_id
         JOIN category_hierarchy AS ch2 ON jpc2.category_id = ch2.category_id
-- Wir verknüpfen die Tabelle "product_similars", um ähnliche Produkte zu finden.
-- Dann verknüpfen wir die Tabelle "product_category", um die Kategorien der Produkte zu erhalten.
-- Wir verwenden die rekursive CTE "category_hierarchy", um die Hierarchie der Kategorien abzubilden.

-- Schließlich fügen wir eine Bedingung hinzu, um sicherzustellen, dass die ähnlichen Produkte in verschiedenen Hauptkategorien liegen.
WHERE ch1.root_category_id != ch2.root_category_id;

/*
11. Welche Produkte werden in allen Filialen angeboten? Hinweis: Ihre Query muss so formuliert werden, dass sie für eine beliebige Anzahl von Filialen funktioniert.
Hinweis: Beachten Sie, dass ein Produkt mehrfach von einer Filiale angeboten werden kann (z.B. neu und gebraucht).
 */

SELECT o.product_id -- Wähle die Produkt-IDs aus
FROM Offer o -- Aus der Tabelle "Offer"
GROUP BY o.product_id -- Gruppiere die Angebote nach Produkt
HAVING COUNT(DISTINCT o.shop_id) = (SELECT COUNT(*) FROM Shop);
-- Filtere die Produkte, die in allen Filialen angeboten werden

/*
 12. In wieviel Prozent der Fälle der Frage 11 gibt es in Leipzig das preiswerteste Angebot?
 */

-- Diese Abfrage ermittelt, in wie vielen Prozent der Fälle das preiswerteste Angebot für Produkte,
-- die in allen Filialen angeboten werden, in Leipzig verfügbar ist.

-- 1. CTE: matching_products_cte
-- Diese CTE identifiziert die Produkte, die in allen Filialen angeboten werden.
WITH matching_products_cte AS (SELECT o.product_id
                               FROM Offer o
                               GROUP BY o.product_id
                               HAVING COUNT(DISTINCT o.shop_id) = (SELECT COUNT(*) FROM Shop)),

-- 2. CTE: cheapest_prices_cte
-- Diese CTE findet das preiswerteste Angebot für jedes Produkt aus der vorherigen CTE.
-- Sie enthält die Produkt-ID, die Shop-ID und den Preis des günstigsten Angebots.
     cheapest_prices_cte AS (SELECT offer.product_id, offer.shop_id, offer.price
                             FROM offer
                                      INNER JOIN (SELECT product_id, MIN(price) AS min_price
                                                  FROM offer
                                                  WHERE offer.product_id IN (SELECT product_id FROM matching_products_cte)
                                                  GROUP BY product_id
                                                  ) AS min_prices
                                                 ON offer.product_id = min_prices.product_id
                                                     AND offer.price = min_prices.min_price),

-- 3. CTE: leipzig_count_cte
-- Diese CTE zählt, wie viele der preiswertesten Angebote in Leipzig verfügbar sind.
-- Die Shop-ID für Leipzig ist 2.
     leipzig_count_cte AS (SELECT COUNT(*) AS leipzig_count
                           FROM cheapest_prices_cte
                           WHERE shop_id = 2),

-- 4. CTE: total_count_cte
-- Diese CTE zählt die Gesamtzahl der preiswertesten Angebote für die identifizierten Produkte.
     total_count_cte AS (SELECT COUNT(*) AS total_count
                         FROM cheapest_prices_cte)

-- Hauptabfrage: Berechnung des Prozentsatzes der Fälle, in denen das preiswerteste Angebot in Leipzig verfügbar ist.
SELECT ROUND((leipzig_count_cte.leipzig_count * 100.0 / total_count_cte.total_count), 2) AS leipzig_cheapest_percentage
FROM leipzig_count_cte,
     total_count_cte;

