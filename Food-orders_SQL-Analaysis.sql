-- Data exploration and Analysis using Self Joins, Aggregrate Functions, Common Table Expressions, Subquery, Window Functions, Temporary tables.

#view imported tables
SELECT * FROM food_orders;
SELECT * FROM customer_details;

#rename columns 
ALTER TABLE food_orders
CHANGE `Order ID` order_id INT,
CHANGE `Customer ID` customer_id TEXT,
CHANGE `Restaurant ID` restaurant_id TEXT,
CHANGE `Order Date and Time` order_datetime DATETIME,
CHANGE `Delivery Date and Time` delivery_datetime DATETIME,
CHANGE `Order Value` order_value INT,
CHANGE `Delivery Fee` delivery_fee INT,
CHANGE `Payment Method` payment_method TEXT,
CHANGE `Discounts and Offers` discounts_offers TEXT,
CHANGE `Commission Fee` commission_fee INT,
CHANGE `Payment Processing Fee` payment_processing_fee INT,
CHANGE `Refunds/Chargebacks` refunds_chargebacks INT;

SELECT * FROM food_orders;

ALTER TABLE customer_details
CHANGE `Customer ID` customer_id TEXT,
CHANGE `First Name` first_name TEXT,
CHANGE `Last Name` last_name TEXT,
CHANGE `Zip Code`  zip_code TEXT;

SELECT * FROM customer_details;

#To extract numbers from string

DELIMITER $$

CREATE FUNCTION UDF_ExtractNumbers(input_string VARCHAR(255))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE output_value INT DEFAULT 0;
    DECLARE current_char CHAR(1);
    DECLARE i INT DEFAULT 1;

    WHILE i <= LENGTH(input_string) DO
        SET current_char = SUBSTRING(input_string, i, 1);
        IF current_char BETWEEN '0' AND '9' THEN
            SET output_value = output_value * 10 + CAST(current_char AS UNSIGNED);
        END IF;
        SET i = i + 1;
    END WHILE;

    RETURN output_value;
END$$

DELIMITER ;

#Basic Select & Filtering: All orders placed in February 2024 along with their order values and payment methods.

SELECT 
    order_id, order_value, payment_method
FROM
    food_orders
WHERE
    DATE(order_datetime) = '2024-02-01'
ORDER BY order_id;

#Aggregate Functions + CTE: 
-- Total revenue generated from all orders for each order

WITH discountpercentage AS (
    SELECT 
        order_id, 
        UDF_ExtractNumbers(discounts_offers) AS discounts,
        order_value
    FROM 
        food_orders
),
Discount AS (
    SELECT 
        order_id,
        order_value, 
        (order_value * (discounts / 100)) AS discountperorder
    FROM 
        discountpercentage
)
SELECT 
    f.order_id, 
    (f.order_value + f.commission_fee + f.delivery_fee - d.discountperorder - f.refunds_chargebacks) AS totalrevenue
FROM 
    food_orders f
JOIN 
    Discount d 
ON 
    f.order_id = d.order_id
ORDER BY 
    f.order_id;

#More Aggregate Functions: Average `Order Value` and `Delivery Fee` for each `Payment Method`. 

SELECT 
    payment_method,
    AVG(order_value) AS avg_order,
    AVG(delivery_fee) AS avg_deliveryfee
FROM
    food_orders
GROUP BY payment_method
ORDER BY 2 , 3;

#Self Join: All customers who placed more than one order at the same restaurant.

SELECT 
    f.customer_id
FROM
    food_orders f
        JOIN
    food_orders fs ON f.customer_id = fs.customer_id
        AND f.restaurant_id = fs.restaurant_id
WHERE
    f.order_id != fs.order_id;

SELECT restaurant_id, 
COUNT(DISTINCT customer_id) as restaurant_customers
FROM food_orders
GROUP BY restaurant_id
ORDER BY 2;

#Common Table Expressions (CTE):
-- Total `Order Value` for each customer. Filter to find customers whose total order value exceeds 3000.

WITH total_order AS
(SELECT customer_id, SUM(order_value) AS total_value 
FROM food_orders 
GROUP BY customer_id)
SELECT customer_id 
FROM total_order 
WHERE total_value > 3000;

#Window Functions(Running Total): 
-- Cumulative total of `Order Value` over time (by `Order Date and Time`), along with each order and their date.

SELECT order_id, 
SUM(order_value) OVER(ORDER BY order_datetime ASC) AS cumulative_value, 
DATE(order_datetime) AS order_date
FROM food_orders;

#Subquery: Restaurants that earned more than the average commission fee. Return `Restaurant ID` and total commission fee earned.

SELECT 
    restaurant_id, SUM(commission_fee) AS total_cf
FROM
    food_orders
GROUP BY restaurant_id
HAVING SUM(commission_fee) > (SELECT 
        AVG(commission_fee)
    FROM
        food_orders)
ORDER BY restaurant_id;

#Advanced `SELECT` with CASE
-- Categorize each order based on `Order Value`: ‘Low’ for values below 1000, ‘Medium’ for values between 1000 and 2000, and ‘High’ for values above 2000.

SELECT 
    order_id,
    CASE
        WHEN order_value < 1000 THEN 'Low'
        WHEN order_value BETWEEN 1000 AND 2000 THEN 'Medium'
        WHEN order_value > 2000 THEN 'High'
    END AS value_category
FROM
    food_orders
ORDER BY order_id; 

#Joins and Filtering
-- Customers and their total number of orders, total order value, along with their details. Only customers who have placed more than 1 order.

SELECT 
    f.customer_id,
    c.first_name,
    c.last_name,
    COUNT(f.order_id) AS total_orders,
    SUM(f.order_value) AS total_value
FROM
    food_orders f
        JOIN
    customer_details c ON f.customer_id = c.customer_id
GROUP BY 1 , 2 , 3
HAVING COUNT(f.order_id) > 1
ORDER BY 5;

#More Aggregation
-- Restaurants that have processed more than 10 orders and have a total commission fee collected greater than 1000.

SELECT restaurant_id
FROM food_orders
GROUP BY restaurant_id
HAVING COUNT(order_id) > 10 AND SUM(commission_fee) > 1000
ORDER BY 1;

#Date Functions: Average delivery time for all orders for each restaurant. Format result in hours.

SELECT 
    restaurant_id,
    AVG(TIMESTAMPDIFF(HOUR, order_datetime, delivery_datetime)) AS avghours_for_delivery
FROM
    food_orders
GROUP BY restaurant_id
ORDER BY restaurant_id;

#Window Functions + CTE: Rank restaurants based on their total revenue. Return Top 10.

WITH discountpercentage AS (
    SELECT 
        UDF_ExtractNumbers(discounts_offers) AS discounts,
        order_value
    FROM 
        food_orders
),
Discount AS (
    SELECT 
        order_value, 
        (order_value * (discounts / 100)) AS discountperorder
    FROM 
        discountpercentage
),
total_revenue AS (
    SELECT 
        f.restaurant_id, 
        SUM(f.order_value + f.commission_fee + f.delivery_fee - d.discountperorder - f.refunds_chargebacks) AS totalrevenue
    FROM 
        food_orders f
    JOIN 
        Discount d 
    ON 
        f.order_value = d.order_value
    GROUP BY 
        f.restaurant_id
)
SELECT 
    restaurant_id,
    totalrevenue,
    RANK() OVER (ORDER BY totalrevenue DESC) AS ranking
FROM 
    total_revenue
ORDER BY 
    ranking
LIMIT 10;

#Temporary Table: 
-- A table that holds the total number of orders and total revenue generated by each restaurant. Find the top 5 restaurants by revenue from table.

CREATE TEMPORARY TABLE total_for_restaurant AS
WITH discountpercentage AS (
    SELECT 
        order_id,
        UDF_ExtractNumbers(discounts_offers) AS discounts,
        order_value
    FROM 
        food_orders
),
Discount AS (
    SELECT 
        order_id,
        order_value, 
        (order_value * (discounts / 100)) AS discountperorder
    FROM 
        discountpercentage
)
SELECT 
    f.restaurant_id, 
    COUNT(f.order_id) AS totalorder,
    SUM(f.order_value + f.commission_fee + f.delivery_fee - d.discountperorder - f.refunds_chargebacks) AS totalrevenue
FROM 
    food_orders f
JOIN 
    Discount d 
ON 
    f.order_id = d.order_id
GROUP BY 
    f.restaurant_id;

SELECT 
    restaurant_id, 
    totalrevenue
FROM 
    total_for_restaurant
ORDER BY 
    totalrevenue DESC
LIMIT 5;

