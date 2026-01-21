-- View dimension and fact tables
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;

-- Explore available tables
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Inspect customer table columns
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

-- Inspect product table columns
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_products';

-- Inspect sales table columns
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_sales';

-- Explore customer countries
SELECT DISTINCT country
FROM gold.dim_customers;

-- Explore product attributes
SELECT DISTINCT product_name FROM gold.dim_products;
SELECT DISTINCT category FROM gold.dim_products;
SELECT DISTINCT maintenance FROM gold.dim_products;
SELECT DISTINCT product_line FROM gold.dim_products;
SELECT DISTINCT subcategory FROM gold.dim_products;

-- Product hierarchy overview
SELECT DISTINCT category, subcategory, product_line, product_name
FROM gold.dim_products
ORDER BY 1,2,3,4;

-- Sales date range
SELECT 
    MIN(order_date) AS FirstOrderDate,
    MAX(order_date) AS LastOrderDate,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS TimeBetweenFirstLast
FROM gold.fact_sales;

-- Youngest and oldest customers
SELECT 
    MIN(birthdate) AS OldestDOB,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS OldestCustomer,
    MAX(birthdate) AS YoungestDOB,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS YoungestCustomer
FROM gold.dim_customers;

-- Total sales value
SELECT SUM(sales_amount) AS TotalSales
FROM gold.fact_sales;

-- Total quantity sold
SELECT SUM(quantity) AS TotalItemsSold
FROM gold.fact_sales;

-- Total distinct orders
SELECT COUNT(DISTINCT order_number) AS TotalOrders
FROM gold.fact_sales;

-- Total products available
SELECT COUNT(*) AS TotalProducts
FROM gold.dim_products;

-- Total products ordered
SELECT COUNT(DISTINCT product_key) AS TotalProductsOrdered
FROM gold.fact_sales;

-- Store product order counts in temp table
DROP TABLE IF EXISTS #TEMP_DATABASE1;

CREATE TABLE #TEMP_DATABASE1 (
    product_key INT,
    orders INT
);

INSERT INTO #TEMP_DATABASE1
SELECT product_key, COUNT(*) AS orders
FROM gold.fact_sales
GROUP BY product_key;

SELECT * FROM #TEMP_DATABASE1;

-- Most ordered product (temp table method)
SELECT product_key
FROM #TEMP_DATABASE1
WHERE orders = (SELECT MAX(orders) FROM #TEMP_DATABASE1);

-- Most ordered product (window function method)
SELECT product_key, CountOfProducts
FROM (
    SELECT 
        product_key,
        COUNT(*) AS CountOfProducts,
        MAX(COUNT(*)) OVER () AS MaxCount
    FROM gold.fact_sales
    GROUP BY product_key
) t
WHERE CountOfProducts = MaxCount;

-- Total customers
SELECT COUNT(*) AS TotalCustomers
FROM gold.dim_customers;

-- Customers who placed orders
SELECT COUNT(DISTINCT customer_key) AS TotalCustomersOrdered
FROM gold.fact_sales;

-- Customer with highest number of orders
SELECT customer_key, TotalOrdersByCustomer
FROM (
    SELECT 
        customer_key,
        COUNT(*) AS TotalOrdersByCustomer,
        MAX(COUNT(*)) OVER () AS MaxOrders
    FROM gold.fact_sales
    GROUP BY customer_key
) c
WHERE TotalOrdersByCustomer = MaxOrders;

-- Average sales amount
SELECT AVG(sales_amount) AS AverageSalesAmount
FROM gold.fact_sales;

-- Most expensive product
SELECT product_key, product_id, product_name, cost
FROM gold.dim_products
WHERE cost = (SELECT MAX(cost) FROM gold.dim_products);

-- Cheapest product
SELECT product_key, product_id, product_name, cost
FROM gold.dim_products
WHERE cost = (SELECT MIN(cost) FROM gold.dim_products);

-- Products grouped by maintenance requirement
SELECT maintenance, COUNT(*) AS Count
FROM gold.dim_products
GROUP BY maintenance;

-- KPI report output
SELECT 'TotalSales' AS measure_name, SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'TotalItemsSold', SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT 'TotalOrders', COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT 'TotalProducts', COUNT(*)
FROM gold.dim_products
UNION ALL
SELECT 'TotalProductsOrdered', COUNT(DISTINCT product_key)
FROM gold.fact_sales
UNION ALL
SELECT 'TotalCustomers', COUNT(*)
FROM gold.dim_customers
UNION ALL
SELECT 'TotalCustomersOrdered', COUNT(DISTINCT customer_key)
FROM gold.fact_sales
UNION ALL
SELECT 'AverageSalesAmount', AVG(sales_amount)
FROM gold.fact_sales;

-- Customers per country
SELECT country, COUNT(*) AS TotalCustomers
FROM gold.dim_customers
GROUP BY country
ORDER BY TotalCustomers DESC;

-- Customers per gender
SELECT gender, COUNT(*) AS TotalCustomers
FROM gold.dim_customers
GROUP BY gender
ORDER BY TotalCustomers DESC;

-- Products per category
SELECT category, COUNT(*) AS TotalProducts
FROM gold.dim_products
GROUP BY category
ORDER BY TotalProducts DESC;

-- Average product cost by category
SELECT category, AVG(cost) AS AvgCost
FROM gold.dim_products
GROUP BY category
ORDER BY AvgCost DESC;

-- Revenue per category (subquery method)
SELECT category, SUM(S.TotalSales) AS TotalSales
FROM gold.dim_products prod
JOIN (
    SELECT product_key, SUM(sales_amount) AS TotalSales
    FROM gold.fact_sales
    GROUP BY product_key
) S
ON prod.product_key = S.product_key
GROUP BY category;

-- Revenue per category (optimized)
SELECT prod.category, SUM(sale.sales_amount) AS TotalSales
FROM gold.fact_sales sale
JOIN gold.dim_products prod
ON sale.product_key = prod.product_key
GROUP BY prod.category
ORDER BY TotalSales DESC;

-- Revenue per customer
SELECT sale.customer_key, SUM(sales_amount) AS TotalRevenue
FROM gold.fact_sales sale
GROUP BY sale.customer_key
ORDER BY TotalRevenue DESC;

-- Items sold by country
SELECT cust.country, COUNT(*) AS ItemsSold
FROM gold.fact_sales sales
JOIN gold.dim_customers cust
ON sales.customer_key = cust.customer_key
GROUP BY cust.country
ORDER BY ItemsSold DESC;

-- Top 5 products by revenue
SELECT TOP 5
    fs.product_key,
    p.product_name,
    SUM(fs.sales_amount) AS Revenue
FROM gold.fact_sales fs
JOIN gold.dim_products p
ON fs.product_key = p.product_key
GROUP BY fs.product_key, p.product_name
ORDER BY Revenue DESC;

-- Top 5 products using ranking
SELECT *
FROM (
    SELECT 
        p.product_name,
        SUM(s.sales_amount) AS Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) DESC) AS Rank
    FROM gold.fact_sales s
    JOIN gold.dim_products p
    ON s.product_key = p.product_key
    GROUP BY p.product_name
) t
WHERE Rank <= 5;

-- Products ordered by revenue
SELECT TOP 5
    fs.product_key,
    p.product_name,
    SUM(fs.sales_amount) AS Revenue
FROM gold.fact_sales fs
JOIN gold.dim_products p
ON fs.product_key = p.product_key
GROUP BY fs.product_key, p.product_name
ORDER BY Revenue;

-- 3rd ranked subcategory by revenue
SELECT *
FROM (
    SELECT 
        prod.subcategory,
        SUM(sales_amount) AS Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS Rank
    FROM gold.fact_sales sales
    JOIN gold.dim_products prod
    ON sales.product_key = prod.product_key
    GROUP BY prod.subcategory
) t
WHERE Rank = 3;

-- Top 10 customers by revenue
SELECT *
FROM (
    SELECT 
        cust.customer_id,
        cust.first_name,
        cust.last_name,
        SUM(sales_amount) AS Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS Rank
    FROM gold.fact_sales sales
    JOIN gold.dim_customers cust
    ON sales.customer_key = cust.customer_key
    GROUP BY cust.customer_id, cust.first_name, cust.last_name
) t
WHERE Rank <= 10;

-- Customers with fewest orders
SELECT *
FROM (
    SELECT 
        cust.customer_key,
        cust.first_name,
        cust.last_name,
        COUNT(DISTINCT order_number) AS OrdersPlaced,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_number)) AS Rank
    FROM gold.fact_sales sales
    LEFT JOIN gold.dim_customers cust
    ON sales.customer_key = cust.customer_key
    GROUP BY cust.customer_key, cust.first_name, cust.last_name
) t
WHERE Rank <= 3;
