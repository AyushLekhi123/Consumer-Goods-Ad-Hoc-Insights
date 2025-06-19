# SQL Project

#Request 1
SELECT DISTINCT(market) 
FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";

#Request 2
WITH cte AS (
  SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
  FROM fact_sales_monthly
)

SELECT 
  unique_products_2020,
  unique_products_2021,
  CONCAT(ROUND((unique_products_2021 - unique_products_2020) * 100.0 / 
	NULLIF(unique_products_2020, 0),2), "%") AS percentage_chg
FROM cte;

#Request 3
SELECT segment, COUNT(product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count;

#Request 4
WITH cte AS (
  SELECT 
    segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS product_count_2021
  FROM dim_product
  JOIN fact_sales_monthly 
  USING (product_code)
  WHERE fiscal_year IN (2020, 2021)
  GROUP BY segment
)

SELECT 
  segment, product_count_2020, product_count_2021,
  (product_count_2021 - product_count_2020) AS difference
FROM cte
ORDER BY difference DESC;

#Request 5
WITH cte1 AS(
	SELECT product_code, product, manufacturing_cost
	FROM dim_product
	JOIN fact_manufacturing_cost
	USING (product_code)
	ORDER BY manufacturing_cost DESC
)

SELECT * 
FROM cte1
WHERE manufacturing_cost IN ((SELECT MAX(manufacturing_cost) FROM cte1), 
							(SELECT MIN(manufacturing_cost) FROM cte1));
                            
#Request 6
WITH cte AS(
	SELECT customer_code, customer, 
		ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
	FROM dim_customer
	JOIN fact_pre_invoice_deductions
	USING (customer_code)
	WHERE fiscal_year = 2021 AND market = "India"
	GROUP BY customer_code, customer
)

SELECT customer_code, customer, average_discount_percentage
FROM (
		SELECT *,
			ROW_NUMBER() OVER(ORDER BY average_discount_percentage DESC) AS rnk
		FROM cte
	) t1
WHERE rnk <= 5;

#Request 7
SELECT MONTHNAME(date) AS month, fiscal_year AS year,
	ROUND(SUM((gross_price*sold_quantity))/1000000,2) AS gross_sales_amount
FROM fact_sales_monthly
JOIN dim_customer
USING (customer_code)
JOIN fact_gross_price
USING (product_code, fiscal_year)
WHERE customer = "Atliq Exclusive"
GROUP BY month, year
ORDER BY gross_sales_amount DESC;

#Request 8
WITH cte1 AS(
	SELECT 
		date,
		CASE
			WHEN MONTH(date) IN (9,10,11) THEN "Q1"
			WHEN MONTH(date) IN (12,1,2) THEN "Q2"
			WHEN MONTH(date) IN (3,4,5) THEN "Q3"
			ELSE "Q4"
		END AS quarter,
		sold_quantity
	FROM fact_sales_monthly
	WHERE fiscal_year = 2020
)

SELECT quarter, SUM(sold_quantity) AS total_sold_quantity
FROM cte1
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

#Request 9
WITH cte1 AS(
	SELECT channel, ROUND(SUM(gross_price*sold_quantity)/1000000,2) AS gross_sales_mln
	FROM fact_sales_monthly
	JOIN dim_customer
	USING (customer_code)
	JOIN fact_gross_price
	USING (fiscal_year, product_code)
	WHERE fiscal_year = 2021
	GROUP BY channel
)
SELECT channel, gross_sales_mln, CONCAT(ROUND(percentage, 2), "%") AS percentage
FROM (
		SELECT channel, gross_sales_mln, gross_sales_mln*100/SUM(gross_sales_mln) OVER() AS percentage
        FROM cte1
) t1
ORDER BY percentage DESC;

#Request 10
WITH cte1 AS(
	SELECT division, product_code, product, 
		   SUM(sold_quantity) AS total_sold_quantity
	FROM fact_sales_monthly
	JOIN dim_product
	USING (product_code)
	WHERE fiscal_year = 2021
	GROUP BY division, product_code, product
)
SELECT *
FROM(
		SELECT *,
		ROW_NUMBER() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order	
        FROM cte1
    ) t1
WHERE rank_order <=3;