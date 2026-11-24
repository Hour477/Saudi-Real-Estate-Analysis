


CREATE DATABASE SaudiRealEstate;

USE SaudiRealEstate;

SELECT TOP 10 * FROM stg_sales_2026_q2;

SELECT COUNT(*) AS total_rows FROM stg_sales_2026_q2;


SELECT
  SUM(CASE WHEN region IS NULL OR region = '' THEN 1 ELSE 0 END) AS null_region,
  SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS null_city,
  SUM(CASE WHEN price IS NULL OR price = '' THEN 1 ELSE 0 END) AS null_price,
  SUM(CASE WHEN area IS NULL OR area = '' THEN 1 ELSE 0 END) AS null_area
FROM stg_sales_2026_q2;

--åá Ýíå ÕÝÞÇÊ ãßáÑÑÉ
SELECT reference_no, COUNT(*) AS times
FROM stg_sales_2026_q2
GROUP BY reference_no
HAVING COUNT(*) > 1;
-- æÔ ÇäæÇÚ ÇáÚÞÇÑ ÇáãæÌæÏÉ
SELECT property_class, COUNT(*) AS deals
FROM stg_sales_2026_q2
GROUP BY property_class;

SELECT
  MIN(TRY_CAST(REPLACE(price, ',', '') AS DECIMAL(15,2))) AS min_price,
  MAX(TRY_CAST(REPLACE(price, ',', '') AS DECIMAL(15,2))) AS max_price,
  MIN(TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2))) AS min_area,
  MAX(TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2))) AS max_area,
  SUM(CASE WHEN TRY_CAST(REPLACE(price, ',', '') AS DECIMAL(15,2)) IS NULL THEN 1 ELSE 0 END) AS bad_price
FROM stg_sales_2026_q2;

SELECT TOP 10 region, city_district, property_class, price, area
FROM stg_sales_2026_q2
ORDER BY TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2)) ASC;

SELECT TOP 10 region, city_district, property_class, price, area
FROM stg_sales_2026_q2
ORDER BY TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2)) desc;

SELECT COUNT(*) AS tiny_deals
FROM stg_sales_2026_q2
WHERE TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2)) < 20;

CREATE TABLE sales_clean (
    reference_no    BIGINT PRIMARY KEY,
    region          NVARCHAR(100),
    city            NVARCHAR(100),
    district        NVARCHAR(150),
    deal_date       DATE,
    deal_date_hijri NVARCHAR(20),
    property_class  NVARCHAR(20),
    property_count  INT,
    price           DECIMAL(15,2),
    area            DECIMAL(15,2),
    is_tiny_area    BIT
);

INSERT INTO sales_clean
SELECT
    TRY_CAST(reference_no AS BIGINT),
    LTRIM(RTRIM(region)),
    LTRIM(RTRIM(city)),
    LTRIM(RTRIM(SUBSTRING(city_district, CHARINDEX('/', city_district) + 1, 150))),
    TRY_CONVERT(DATE, deal_date, 111),
    deal_date_hijri,
    LTRIM(RTRIM(property_class)),
    TRY_CAST(property_count AS INT),
    TRY_CAST(REPLACE(price, ',', '') AS DECIMAL(15,2)),
    TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2)),
    CASE WHEN TRY_CAST(REPLACE(area, ',', '') AS DECIMAL(15,2)) < 20 THEN 1 ELSE 0 END
FROM stg_sales_2026_q2;

SELECT TOP 10 * FROM sales_clean;
SELECT COUNT(*) FROM sales_clean;

SELECT
  SUM(CASE WHEN deal_date IS NULL THEN 1 ELSE 0 END) AS bad_date,
  SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS bad_price,
  SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END) AS bad_area,
  SUM(CASE WHEN property_count IS NULL THEN 1 ELSE 0 END) AS bad_count
FROM sales_clean;