

-- Q1: total deals, total value and avg price
SELECT COUNT(*) AS total_deals,
       SUM(price) AS total_value,
       AVG(price) AS avg_price
FROM fact_sales;

-- Q2: deals by region + % of total
SELECT r.region_name,
       COUNT(*) AS deals,
       SUM(f.price) AS total_value,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS pct_of_deals
FROM fact_sales f
JOIN dim_city c   ON f.city_id = c.city_id
JOIN dim_region r ON c.region_id = r.region_id
GROUP BY r.region_name
ORDER BY deals DESC;

-- Q3: top 10 cities by price per m2 (residential)
-- removed tiny areas and cities with less than 50 deals
WITH city_stats AS (
    SELECT c.city_name,
           COUNT(*) AS deals,
           SUM(f.price) / SUM(f.area) AS price_per_sqm
    FROM fact_sales f
    JOIN dim_city c           ON f.city_id = c.city_id
    JOIN dim_property_class p ON f.class_id = p.class_id
    WHERE f.is_tiny_area = 0 AND p.class_name = '”ﬂ‰Ì'
    GROUP BY c.city_name
)
SELECT TOP 10 city_name, deals,
       CAST(price_per_sqm AS DECIMAL(10,0)) AS price_per_sqm
FROM city_stats
WHERE deals >= 50
ORDER BY price_per_sqm DESC;

-- Q4: top 3 districts in Riyadh, Jeddah, Dammam
WITH district_stats AS (
    SELECT c.city_name, f.district,
           COUNT(*) AS deals,
           SUM(f.price) / SUM(f.area) AS price_per_sqm
    FROM fact_sales f
    JOIN dim_city c           ON f.city_id = c.city_id
    JOIN dim_property_class p ON f.class_id = p.class_id
    WHERE f.is_tiny_area = 0
      AND p.class_name = '”ﬂ‰Ì'
      AND f.district <> '√Œ—Ï'
    GROUP BY c.city_name, f.district
     HAVING COUNT(*) >= 10
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY city_name ORDER BY price_per_sqm DESC) AS rnk
    FROM district_stats
)
SELECT city_name, district, deals,
       CAST(price_per_sqm AS DECIMAL(10,0)) AS price_per_sqm, rnk
FROM ranked
WHERE rnk <= 3 AND city_name IN ('«·—Ì«÷', 'ÃœÂ', '«·œ„«„')
ORDER BY city_name, rnk;
-- Q5: monthly deals and change from last month
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(deal_date), MONTH(deal_date), 1) AS month_start,
           COUNT(*) AS deals,
           SUM(price) AS total_value
    FROM fact_sales
    GROUP BY DATEFROMPARTS(YEAR(deal_date), MONTH(deal_date), 1)
)
SELECT month_start, deals,
       LAG(deals) OVER (ORDER BY month_start) AS prev_month_deals,
       CAST(100.0 * (deals - LAG(deals) OVER (ORDER BY month_start))
            / LAG(deals) OVER (ORDER BY month_start) AS DECIMAL(6,2)) AS pct_change
FROM monthly
ORDER BY month_start;

-- Q6: residential vs commercial vs agricultural
SELECT p.class_name,
       COUNT(*) AS deals,
       AVG(f.price) AS avg_price,
       CAST(SUM(f.price) / SUM(f.area) AS DECIMAL(10,0)) AS price_per_sqm
FROM fact_sales f
JOIN dim_property_class p ON f.class_id = p.class_id
WHERE f.is_tiny_area = 0
GROUP BY p.class_name;
 
