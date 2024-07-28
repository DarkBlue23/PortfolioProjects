--import data

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- If your CSV file has a header row

-- creating a table that holds raw data
CREATE TABLE netflix LIKE netflix_raw;
INSERT INTO netflix
SELECT * FROM netflix_raw;


truncate table netflix;

Select *
From netflix


-- renamed the table

-- ALTER TABLE netflix1 RENAME TO netflix;


-- checking the table for duplicates using show_id
SELECT show_id, COUNT(*)                                                                                                                                                                            
FROM netflix_raw 
GROUP BY show_id                                                                                                                                                                                            
ORDER BY show_id DESC;


-- Checking the data for issues
SELECT DISTINCT director
FROM netflix
WHERE director IS NULL OR TRIM(director) = '';

SELECT director, LENGTH(director) AS length
FROM netflix
WHERE director IS NOT NULL;

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN director IS NOT NULL AND TRIM(director) != '' THEN 1 ELSE 0 END) AS non_empty_directors
FROM netflix;

-- Checking for null (and empty) fields
SELECT 
    SUM(CASE WHEN show_id IS NULL OR TRIM(show_id) = '' THEN 1 ELSE 0 END) AS showid_nulls,
    SUM(CASE WHEN type IS NULL OR TRIM(type) = '' THEN 1 ELSE 0 END) AS type_nulls,
    SUM(CASE WHEN title IS NULL OR TRIM(title) = '' THEN 1 ELSE 0 END) AS title_nulls,
    SUM(CASE WHEN director IS NULL OR TRIM(director) = '' THEN 1 ELSE 0 END) AS director_nulls,
    SUM(CASE WHEN cast IS NULL OR TRIM(cast) = '' THEN 1 ELSE 0 END) AS cast_nulls,  -- corrected column name
    SUM(CASE WHEN country IS NULL OR TRIM(country) = '' THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN date_added IS NULL OR TRIM(date_added) = '' THEN 1 ELSE 0 END) AS date_added_nulls,
    SUM(CASE WHEN release_year IS NULL OR TRIM(release_year) = '' THEN 1 ELSE 0 END) AS release_year_nulls,
    SUM(CASE WHEN rating IS NULL OR TRIM(rating) = '' THEN 1 ELSE 0 END) AS rating_nulls,
    SUM(CASE WHEN duration IS NULL OR TRIM(duration) = '' THEN 1 ELSE 0 END) AS duration_nulls,
    SUM(CASE WHEN listed_in IS NULL OR TRIM(listed_in) = '' THEN 1 ELSE 0 END) AS listed_in_nulls,
    SUM(CASE WHEN description IS NULL OR TRIM(description) = '' THEN 1 ELSE 0 END) AS description_nulls
FROM netflix;

-- -- writing down for easier access
-- director_nulls = 2634
-- movie_cast_nulls = 825
-- country_nulls = 831
-- date_added_nulls = 10
-- rating_nulls = 4
-- duration_nulls = 3  

-- trying to find combinations of directors and cast
WITH cte AS (
    SELECT title, director, cast, CONCAT(director, '---', cast) AS director_cast 
    FROM netflix
)
SELECT director, director_cast, COUNT(*) AS count
FROM cte
GROUP BY director, director_cast
HAVING COUNT(*) > 1
ORDER BY count DESC;

UPDATE netflix 
SET director =  'Rajiv Chilaka'
WHERE TRIM(cast) LIKE 'Vatsal Dubey%'

SELECT * 
FROM netflix 
WHERE cast LIKE 'Vatsal Dubey%';

CREATE TEMPORARY TABLE temp_director_mapping AS
SELECT DISTINCT
    TRIM(cast) AS cast_pattern,
    director AS director_name
FROM netflix
WHERE director IS NOT NULL
AND cast IS NOT NULL
AND director <> '';

SELECT * FROM temp_director_mapping;

ALTER TABLE temp_director_mapping ADD COLUMN first_name VARCHAR(255);
UPDATE temp_director_mapping
SET first_name = TRIM(SUBSTRING_INDEX(cast_pattern, ',', 1));

DELIMITER //

CREATE PROCEDURE populate_directors()
BEGIN
    -- Create a temporary table to store cast-director mappings
    CREATE TEMPORARY TABLE temp_directors AS
    SELECT DISTINCT
        n1.cast AS cast_member,
        n1.director AS director
    FROM netflix n1
    WHERE n1.director IS NOT NULL;

    -- Debugging - Check content of the temporary table
    SELECT * FROM temp_directors;

    -- Update the director field in the main table
    UPDATE netflix n2
    JOIN temp_directors t 
    ON FIND_IN_SET(t.cast_member, n2.cast) > 0
    SET n2.director = t.director
    WHERE n2.director IS NULL;

    -- Debugging - Check rows that were supposed to be updated
    SELECT * 
    FROM netflix 
    WHERE director IS NULL AND cast IS NOT NULL;

    --  Drop the temporary table
    DROP TEMPORARY TABLE temp_directors;
END //

DELIMITER ;

CALL populate_directors();

UPDATE netflix 
SET country = NULL
WHERE country ='';

-- Populate the country using the director column

DELIMITER //

CREATE PROCEDURE populate_countries()
BEGIN
    -- Temporary table to store director-country mappings
    CREATE TEMPORARY TABLE temp_country_mapping AS
    SELECT DISTINCT
        director,
        country
    FROM netflix
    WHERE country IS NOT NULL;

    SELECT * FROM temp_country_mapping;

    -- Update the country field in the main table
    UPDATE netflix n
    JOIN temp_country_mapping t
    ON n.director = t.director
    SET n.country = t.country
    WHERE n.country IS NULL;

    -- Debugging - Check rows that were updated
    SELECT * 
    FROM netflix 
    WHERE country IS NULL AND director IS NOT NULL;

    -- Step 3: Drop the temporary table
    DROP TEMPORARY TABLE temp_country_mapping;
END //

DELIMITER ;

CALL populate_countries();

-- Changing not found countries to "Not given" to remove nulls
UPDATE netflix 
SET country = 'Not Given'
WHERE country = NULL;

SELECT show_id, date_added
FROM netflix
WHERE date_added IS NULL;

-- Deleting nulls >= 10
DELETE FROM netflix
WHERE date_added IS NULL;

DELETE FROM netflix
WHERE rating IS NULL;

DELETE FROM netflix
WHERE duration IS NULL;


-- Check to confirm the number of rows are the same(NO NULL)

SELECT 
    COUNT(CASE WHEN show_id IS NOT NULL THEN 1 END) AS showid_non_nulls,
    COUNT(CASE WHEN type IS NOT NULL THEN 1 END) AS type_non_nulls,
    COUNT(CASE WHEN title IS NOT NULL THEN 1 END) AS title_non_nulls,
    COUNT(CASE WHEN director IS NOT NULL THEN 1 END) AS director_non_nulls,
    COUNT(CASE WHEN country IS NOT NULL THEN 1 END) AS country_non_nulls,
    COUNT(CASE WHEN date_added IS NOT NULL THEN 1 END) AS date_added_non_nulls,
    COUNT(CASE WHEN release_year IS NOT NULL THEN 1 END) AS release_year_non_nulls,
    COUNT(CASE WHEN rating IS NOT NULL THEN 1 END) AS rating_non_nulls,
    COUNT(CASE WHEN duration IS NOT NULL THEN 1 END) AS duration_non_nulls,
    COUNT(CASE WHEN listed_in IS NOT NULL THEN 1 END) AS listed_in_non_nulls
FROM netflix;


 -- Total number of rows are the same in all columns
 
 -- DROP description and cast because they're not needed

ALTER TABLE netflix
DROP COLUMN cast, 
DROP COLUMN description;


-- Create another column that stores only the first country mentioned
ALTER TABLE netflix
ADD COLUMN first_country VARCHAR(255);


UPDATE netflix
SET country = REPLACE(REPLACE(REPLACE(country, '/', ','), ';', ','), '|', ',');


UPDATE netflix
SET first_country = SUBSTRING_INDEX(country, ',', 1);

SELECT DISTINCT first_country
FROM netflix;

select * from netflix