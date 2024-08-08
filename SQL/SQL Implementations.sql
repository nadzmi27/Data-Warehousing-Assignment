-- SQL IMPLEMENTATIONS VERSION 1 --

--------------------------------------------------
-- Create Dimension Tables
--------------------------------------------------


-- CompanyBranchDIM_V1
CREATE SEQUENCE branch_id_seq START WITH 1 INCREMENT BY 1 MAXVALUE 15 NOCYCLE;

CREATE TABLE companybranchdim_v1
    AS
        SELECT
            branch_id_seq.NEXTVAL AS branchid,
            branch_desc
        FROM
            (
                SELECT DISTINCT
                    company_branch AS branch_desc
                FROM
                    staff
                ORDER BY
                    company_branch
            ) ordered_branches;


-- TimeDIM_V1
CREATE TABLE timedim_v1
    AS
        SELECT DISTINCT
            to_char(d, 'yyyymm') AS timeid,
            to_char(d, 'yyyy')   AS year,
            to_char(d, 'MONTH')  AS month
        FROM
            (
                SELECT
                    start_date AS d
                FROM
                    hire
                UNION
                SELECT
                    sales_date AS d
                FROM
                    sales
            )
        ORDER BY
            year,
            to_char(TO_DATE(month, 'MONTH'),
                    'MM');


-- SeasonDIM_V1
CREATE TABLE seasondim_v1 (
    seasonid         CHAR(1),
    season_desc      VARCHAR2(20),
    season_startdate VARCHAR2(10),
    season_enddate   VARCHAR2(10)
);

-- Summer Dec-Feb
INSERT INTO seasondim_v1 VALUES (
    1,
    'Summer',
    '01-DEC',
    '29-FEB'
);
    
-- Autumn Feb-May
INSERT INTO seasondim_v1 VALUES (
    2,
    'Autumn',
    '01-MAR',
    '31-MAY'
);
    
-- Winter Jun-Aug
INSERT INTO seasondim_v1 VALUES (
    3,
    'Winter',
    '01-JUN',
    '31-AUG'
);
    
-- Spring Sep-Nov
INSERT INTO seasondim_v1 VALUES (
    4,
    'Spring',
    '01-SEP',
    '30-NOV'
);


-- CategoryDIM_V1
CREATE TABLE categorydim_v1
    AS
        SELECT
            category_id          AS categoryid,
            category_description AS category_desc
        FROM
            category;


-- CustomerTypeDIM_V1
CREATE TABLE customertypedim_v1
    AS
        SELECT
            customer_type_id AS customertypeid,
            description      AS customertype_desc
        FROM
            customer_type;


-- PriceScaleDIM_V1
CREATE TABLE pricescaledim_v1 (
    scaleid          VARCHAR2(10),
    scale_desc       VARCHAR2(50),
    scale_lowerbound NUMBER(10),
    scale_upperbound NUMBER(10)
);

INSERT INTO pricescaledim_v1 VALUES (
    1,
    'LOW',
    0,
    4999
);

INSERT INTO pricescaledim_v1 VALUES (
    2,
    'MEDIUM',
    5000,
    10000
);

INSERT INTO pricescaledim_v1 VALUES (
    3,
    'HIGH',
    10001,
    power(10, 10) - 1
);


--------------------------------------------------
-- Create Fact Tables
--------------------------------------------------


-- HireFact_V1
CREATE TABLE hirefact_v1
    AS
        SELECT
            to_char(hi.start_date, 'YYYYMM') AS timeid,
            CASE
                WHEN to_char(hi.start_date, 'MM') IN ( '12', '01', '02' ) THEN
                    1
                WHEN to_char(hi.start_date, 'MM') BETWEEN '03' AND '05' THEN
                    2
                WHEN to_char(hi.start_date, 'MM') BETWEEN '06' AND '08' THEN
                    3
                WHEN to_char(hi.start_date, 'MM') BETWEEN '09' AND '11' THEN
                    4
            END                              AS seasonid,
            eq.category_id                   AS categoryid,
            ct.customer_type_id              AS customertypeid,
            cb.branchid,
            SUM(hi.total_hire_price)         AS totalhirerevenue,
            COUNT(*)                         AS num_of_hired_transaction,
            SUM(hi.quantity)                 AS num_of_hired_equip
        FROM
                 hire hi
            JOIN equipment           eq ON eq.equipment_id = hi.equipment_id
            JOIN customer_clean      ct ON ct.customer_id = hi.customer_id
            JOIN staff               st ON st.staff_id = hi.staff_id
            JOIN companybranchdim_v1 cb ON cb.branch_desc = st.company_branch
        GROUP BY
            to_char(hi.start_date, 'YYYYMM'),
            CASE
                    WHEN to_char(hi.start_date, 'MM') IN ( '12', '01', '02' ) THEN
                        1
                    WHEN to_char(hi.start_date, 'MM') BETWEEN '03' AND '05' THEN
                        2
                    WHEN to_char(hi.start_date, 'MM') BETWEEN '06' AND '08' THEN
                        3
                    WHEN to_char(hi.start_date, 'MM') BETWEEN '09' AND '11' THEN
                        4
            END,
            eq.category_id,
            ct.customer_type_id,
            cb.branchid;


-- SalesFact_V1
CREATE TABLE salesfact_v1
    AS
        SELECT
            to_char(sl.sales_date, 'yyyymm') AS timeid,
            CASE
                WHEN to_char(sl.sales_date, 'mm') IN ( 12, 01, 02 ) THEN
                    1
                WHEN to_char(sl.sales_date, 'mm') BETWEEN 03 AND 05 THEN
                    2
                WHEN to_char(sl.sales_date, 'mm') BETWEEN 06 AND 08 THEN
                    3
                WHEN to_char(sl.sales_date, 'mm') BETWEEN 09 AND 11 THEN
                    4
            END                              AS seasonid,
            eq.category_id                   AS categoryid,
            ct.customer_type_id              AS customertypeid,
            cb.branchid,
            CASE
                WHEN sl.total_sales_price < 5000  THEN
                    1
                WHEN sl.total_sales_price > 10000 THEN
                    3
                ELSE
                    2
            END                              AS scaleid,
            SUM(sl.total_sales_price)        AS totalsalesrevenue,
            COUNT(*)                         AS num_of_sold_transaction,
            SUM(sl.quantity)                 AS num_of_sold_equip
        FROM
                 sales sl
            JOIN equipment           eq ON eq.equipment_id = sl.equipment_id
            JOIN customer_clean      ct ON ct.customer_id = sl.customer_id
            JOIN staff               st ON st.staff_id = sl.staff_id
            JOIN companybranchdim_v1 cb ON cb.branch_desc = st.company_branch
        GROUP BY
                CASE
                    WHEN sl.total_sales_price < 5000  THEN
                        1
                    WHEN sl.total_sales_price > 10000 THEN
                        3
                    ELSE
                        2
                END,
                to_char(sl.sales_date, 'yyyymm'),
                CASE
                    WHEN to_char(sl.sales_date, 'mm') IN ( 12, 01, 02 ) THEN
                        1
                    WHEN to_char(sl.sales_date, 'mm') BETWEEN 03 AND 05 THEN
                        2
                    WHEN to_char(sl.sales_date, 'mm') BETWEEN 06 AND 08 THEN
                        3
                    WHEN to_char(sl.sales_date, 'mm') BETWEEN 09 AND 11 THEN
                        4
                END,
                eq.category_id,
                ct.customer_type_id,
                cb.branchid;


-- SQL IMPLEMENTATIONS VERSION 2 --

--------------------------------------------------
-- Create Dimension Tables
--------------------------------------------------


-- StaffDIM_V2
CREATE TABLE staffdim_v2
    AS
        SELECT
            *
        FROM
            staff;


--EquipmentDIM_V2
CREATE TABLE equipmentdim_v2
    AS
        SELECT
            *
        FROM
            equipment;

--CustomerDIM_V2
CREATE TABLE customerdim_v2
    AS
        SELECT
            *
        FROM
            customer_clean;


--HireDIM_V2
CREATE TABLE hiredim_v2
    AS
        SELECT
            hire_id,
            start_date,
            end_date,
            quantity,
            unit_hire_price,
            total_hire_price
        FROM
            hire;


--SalesDIM_V2
CREATE TABLE salesdim_v2
    AS
        SELECT
            sales_id,
            sales_date,
            quantity,
            unit_sales_price,
            total_sales_price
        FROM
            sales;


--------------------------------------------------
-- Create Fact Tables
--------------------------------------------------


-- HiringFact_V2
CREATE TABLE hiringfact_v2
    AS
        SELECT
            st.staff_id,
            eq.equipment_id,
            hi.hire_id,
            cc.customer_id,
            SUM(hi.total_hire_price) AS totalhirerevenue
        FROM
                 hire hi
            JOIN staff          st ON st.staff_id = hi.staff_id
            JOIN equipment      eq ON eq.equipment_id = hi.equipment_id
            JOIN customer_clean cc ON cc.customer_id = hi.customer_id
        GROUP BY
            st.staff_id,
            eq.equipment_id,
            hi.hire_id,
            cc.customer_id;


--SellingFact_V2
CREATE TABLE sellingfact_v2
    AS
        SELECT
            st.staff_id,
            eq.equipment_id,
            sl.sales_id,
            cc.customer_id,
            SUM(sl.total_sales_price) AS totalsalesrevenue
        FROM
                 sales sl
            JOIN staff          st ON st.staff_id = sl.staff_id
            JOIN equipment      eq ON eq.equipment_id = sl.equipment_id
            JOIN customer_clean cc ON cc.customer_id = sl.customer_id
        GROUP BY
            st.staff_id,
            eq.equipment_id,
            sl.sales_id,
            cc.customer_id;