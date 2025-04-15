# SQL Project

#Request 1
SELECT DISTINCT(market) 
FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";

#Request 2
WITH cte1 AS(
	SELECT COUNT(DISTINCT(product_code)) AS unique_products_2020
	FROM fact_sales_monthly
	WHERE fiscal_year = 2020),

cte2 AS(
	SELECT COUNT(DISTINCT(product_code)) AS unique_products_2021
	FROM fact_sales_monthly
	WHERE fiscal_year = 2021
)

SELECT 
	unique_products_2020, unique_products_2021,
    ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM cte1, cte2;

#Request 3
SELECT segment, COUNT(product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count;

#Request 4
WITH pc1 AS(
	SELECT segment, COUNT(DISTINCT(product_code)) AS product_count_2020
	FROM dim_product
    JOIN fact_sales_monthly
    USING (product_code)
	WHERE fiscal_year = 2020
    GROUP BY segment),

pc2 AS(
	SELECT segment, COUNT(DISTINCT(product_code)) AS product_count_2021
	FROM dim_product
    JOIN fact_sales_monthly
    USING (product_code)
	WHERE fiscal_year = 2021
    GROUP BY segment
)

SELECT 
	segment, product_count_2020, product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM pc1
JOIN pc2
USING (segment)
ORDER BY difference DESC;

#Request 5
WITH cte1 AS(
	SELECT product_code, product, manufacturing_cost
	FROM dim_product p
	JOIN fact_manufacturing_cost m
	USING (product_code)
	GROUP BY product_code, product
	ORDER BY manufacturing_cost DESC
)

SELECT * 
FROM cte1
WHERE manufacturing_cost IN ((SELECT MAX(manufacturing_cost) FROM cte1), 
							(SELECT MIN(manufacturing_cost) FROM cte1));
                            
#Request 6
SELECT customer_code, customer, 
	ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer
JOIN fact_pre_invoice_deductions
USING (customer_code)
WHERE fiscal_year = 2021 AND market = "India"
GROUP BY customer_code, customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

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
SELECT channel, gross_sales_mln, gross_sales_mln*100/SUM(gross_sales_mln) OVER() AS percentage
FROM cte1
ORDER BY percentage DESC;

#Request 10
WITH cte1 AS(
	SELECT division, product_code, product, 
		   SUM(sold_quantity) AS total_sold_quantity,
           RANK() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rank_order
	FROM fact_sales_monthly
	JOIN dim_product
	USING (product_code)
	WHERE fiscal_year = 2021
	GROUP BY product_code, product
)
SELECT *	
FROM cte1
WHERE rank_order <=3;