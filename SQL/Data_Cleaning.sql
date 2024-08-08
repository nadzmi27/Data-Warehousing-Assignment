--Problem 1
--There are duplicated values in the customer table.
SELECT
    *
FROM
    customer
WHERE
    customer_id IN (
        SELECT
            customer_id
        FROM
            customer
        GROUP BY
            customer_id
        HAVING
            COUNT(*) > 1
    );

--Solution Problem 1
CREATE TABLE customer_clean
    AS
        SELECT DISTINCT
            *
        FROM
            customer
        ORDER BY
            customer_id;

--Problem 2
--There is a relationship problem between HIRE table and EQUIPMENT, STAFF, CUSTOMER tables where there are some equipment_id, staff_id, and customer_id in Hire table
--which not listed in those tables
-- Relationship error between Hire-Equipment
SELECT
    *
FROM
    hire
WHERE
    equipment_id NOT IN (
        SELECT
            equipment_id
        FROM
            equipment
    );

-- Relationship error between Hire-Customer
SELECT
    *
FROM
    hire
WHERE
    customer_id NOT IN (
        SELECT
            customer_id
        FROM
            customer
    );

-- Relationship error between Hire-Staff
SELECT
    *
FROM
    hire
WHERE
    staff_id NOT IN (
        SELECT
            staff_id
        FROM
            staff
    );

--Solution Problem 2
DELETE FROM hire
WHERE
    equipment_id NOT IN (
        SELECT
            equipment_id
        FROM
            equipment
    );

DELETE FROM hire
WHERE
    customer_id NOT IN (
        SELECT
            customer_id
        FROM
            customer
    );

DELETE FROM hire
WHERE
    staff_id NOT IN (
        SELECT
            staff_id
        FROM
            staff
    );

--Problem 3
--There are inconsistent values where the end date is not after the start date in HIRE table
SELECT
    *
FROM
    hire
WHERE
    end_date < start_date;

--Solution Problem 3
DELETE FROM hire
WHERE
    end_date < start_date;

--Problem 4
--The end_date for year component is greater than December 2020 in HIRE table
SELECT
    *
FROM
    hire
WHERE
    to_char(end_date, 'YYYY') > 2020;

--Solution Problem 4
DELETE FROM hire
WHERE
    to_char(end_date, 'YYYY') > 2020;

--Problem 5
--There is a null value in CATEGORY table
SELECT
    *
FROM
    category
WHERE
    category_description = 'null';
    
--Solution Problem 5
DELETE FROM category
WHERE
    category_description = 'null'; 

--Problem 6
--There is negative value in quantity attribute in SALES table
SELECT
    *
FROM
    sales
WHERE
    quantity < 0;

--Solution Problem 6
DELETE FROM sales
WHERE
    quantity < 0;
    
--Problem 7
--There are wrong calculation on total_hire_price in HIRE table
SELECT
    *
FROM
    hire
WHERE
        start_date != end_date
    AND total_hire_price != ( end_date - start_date ) * quantity * unit_hire_price;
    
--Solution Problem 7
UPDATE hire
SET
    total_hire_price = ( end_date - start_date ) * quantity * unit_hire_price
WHERE
        start_date != end_date
    AND total_hire_price != ( end_date - start_date ) * quantity * unit_hire_price;

--Problem 8
--There are negative values in total_hire price in HIRE table
SELECT
    *
FROM
    hire
WHERE
    total_hire_price < 0;

--Solution Problem 8
DELETE FROM hire
WHERE
    total_hire_price < 0;

--Problem 9
--Relationship problem between equipment table and category table
SELECT
    *
FROM
    equipment
WHERE
    category_id NOT IN (
        SELECT
            category_id
        FROM
            category
    );

--Solution Problem 9
DELETE FROM equipment
WHERE
    category_id NOT IN (
        SELECT
            category_id
        FROM
            category
    );