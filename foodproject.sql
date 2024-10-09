#view imported table 
SELECT * FROM food_orders;

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

#Basic Select & Filtering: All orders placed in February 2024 along with their order values and payment methods.

SELECT order_id, order_value, payment_method
FROM food_orders
WHERE DATE(order_datetime) = '2024-02-01'
ORDER BY order_id;

#Aggregate Functions: 
#Total revenue generated from all orders, including the sum of `Order Value` and `Delivery Fee` for each order


#More Aggregate Functions: Average `Order Value` and `Delivery Fee` for each `Payment Method`. 

SELECT payment_method, AVG(order_value) as avg_order, AVG(delivery_fee) as avg_deliveryfee
FROM food_orders
GROUP BY payment_method
ORDER BY 2, 3;

#Self Join: All customers who placed more than one order at the same restaurant.

SELECT f.customer_id 
FROM food_orders f
JOIN food_orders fs 
  ON f.customer_id = fs.customer_id 
  AND f.restaurant_id = fs.restaurant_id
WHERE f.order_id != fs.order_id;

SELECT restaurant_id, 
COUNT(DISTINCT customer_id) as restaurant_customers
FROM food_orders
GROUP BY restaurant_id
ORDER BY 2;

#Common Table Expressions (CTE):
#Total `Order Value` for each customer. Filter to find customers whose total order value exceeds 3000.

WITH total_order AS
(SELECT customer_id, SUM(order_value) AS total_value 
FROM food_orders 
GROUP BY customer_id)
SELECT customer_id 
FROM total_order 
WHERE total_value > 3000;

#Window Functions(Running Total): 
#Cumulative total of `Order Value` over time (by `Order Date and Time`), along with each order and their date.

SELECT order_id, 
SUM(order_value) OVER(ORDER BY order_datetime ASC) AS cumulative_value, 
DATE(order_datetime) AS order_date
FROM food_orders;




