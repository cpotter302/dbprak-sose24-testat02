-- https://www.postgresql.org/docs/current/plpgsql-trigger.html

/*
2b)
Diese Funktion "calculate_average_ratings_ontrigger" wird als Trigger verwendet,
um den durchschnittlichen Bewertungswert eines Produkts in der Tabelle "Product" zu aktualisieren.
Sie wird bei INSERT, UPDATE und DELETE Operationen aufgerufen.
Bei einem INSERT oder UPDATE wird der durchschnittliche Bewertungswert für das betreffende Produkt basierend auf den Bewertungen in der Tabelle "Review" aktualisiert.
Bei einem DELETE wird der durchschnittliche Bewertungswert des Produkts ebenfalls basierend auf den verbleibenden Bewertungen aktualisiert.
*/

CREATE OR REPLACE FUNCTION calculate_average_ratings_ontrigger()
    RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE Product
        SET average_rating = (SELECT AVG(rating)
                              FROM Review
                              WHERE product_id = NEW.product_id)
        WHERE product_id = NEW.product_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Product
        SET average_rating = (SELECT AVG(rating)
                              FROM Review
                              WHERE product_id = OLD.product_id)
        WHERE product_id = OLD.product_id;
    END IF;
    RETURN NULL;
END ;
$$ LANGUAGE plpgsql;

/*
2b)
Dieser Trigger "update_average_rating_on_insert_or_delete_reviews" wird nach dem Einfügen, Löschen oder Aktualisieren von Rezensionen in der Tabelle "Review" ausgelöst.
Für jede Zeile in der Tabelle "Review" wird die Funktion "calculate_average_ratings_ontrigger()" ausgeführt,
um den durchschnittlichen Bewertungswert der betroffenen Produkte in der Tabelle "Product" zu aktualisieren.
*/

CREATE TRIGGER update_average_rating_on_insert_or_delete_reviews
    AFTER INSERT OR DELETE OR UPDATE
    ON Review
    FOR EACH ROW
EXECUTE FUNCTION calculate_average_ratings_ontrigger();


/*
 2b)
 Testszenario anhand eines Produkts
 */

SELECT product_id, pgroup, average_rating FROM Product WHERE Product.product_id = 'B0002S30NE';

INSERT INTO Review (review_date, customer_id, rating, description, product_id)
VALUES (CURRENT_DATE, 'weisserstier', 1, 'Super geil', 'B0002S30NE') RETURNING review_id;

SELECT product_id, pgroup, average_rating FROM Product WHERE product_id = 'B0002S30NE';

DELETE FROM Review WHERE review_id = '';