-- Coffee Shop - Data Analysis Project

use coffee_shop;

select * from city;
select * from products;
select * from customers;
select * from sales;

-- Key Questions

-- 1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
	city_name,
    round((population * 0.25)/1000000,2) as coffee_consumers_in_millions,
    city_rank
from city
order by population desc;

-- 2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select 
	SUM(total) as total_revenue
from sales
where 
YEAR(sale_date) = 2023 AND
QUARTER(sale_date) = 4;


select
	ci.city_name,
    SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
WHERE 
	YEAR(s.sale_date) = 2023
    AND 
    QUARTER(s.sale_date) = 4
GROUP BY 1
ORDER BY 2;

-- 3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

select 
	p.product_name,
    COUNT(s.sale_id) as Unit_sold 
FROM products as p
JOIN sales as s
ON p.product_id = s.product_id
GROUP BY product_name
ORDER BY Unit_sold DESC;

-- 4. Average Sales Amount per City
--  What is the average sales amount per customer in each city?

-- city and their tot sales 
-- no. of customers in each city
select
	ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as total_customers,
    ROUND(SUM(s.total)/ COUNT(DISTINCT s.customer_id),2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY avg_sale_per_customer DESC;

--  5. City Population and Coffee Consumers
--  Provide a list of cities along with their populations and estimated coffee consumers.
--  Return city_name, total current cx, estimated coffee consumers (25%)

SELECT 
    ci.city_name,
    ci.population,
    ROUND((ci.population * 0.25) / 100000 ,2)AS coffee_consumers_lakhs,
    COUNT(DISTINCT c.customer_id) AS Unique_CX
    
FROM 
    city as ci
    LEFT JOIN customers as c ON
    c.city_id = ci.city_id
        GROUP BY ci.city_id,city_name, population
    ORDER BY 3 DESC;

-- 6.  Top Selling Products by City
--  What are the top 3 selling products in each city based on sales volume?    

SELECT * 
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rnk
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS t1
WHERE rnk <= 3;

-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
    
SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

--  Q.8  Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name, estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / NULLIF(ct.total_cx, 0), 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;

-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, year, month
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;

-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

-- City Revenue and Rent Analysis

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / NULLIF(ct.total_cx,0),
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;





