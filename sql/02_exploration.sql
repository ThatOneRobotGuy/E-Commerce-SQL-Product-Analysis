/*
Questions:
* How many orders exist?
* How many unique customers?
* What is the average order value?
*/

-- How many orders exist?
SELECT COUNT(*) FROM orders;

-- How many unique customers?
SELECT COUNT(DISTINCT customer_unique_id) 
FROM customers;

-- What is the average order value
SELECT AVG(order_value) as avg_order_value
FROM (
    SELECT SUM(payment_value) as order_value
    FROM order_payments
    GROUP BY order_id
);

-- Customers with the most orders
SELECT customer_unique_id, COUNT(*) as number_of_orders
FROM customers
GROUP BY customer_unique_id
ORDER BY number_of_orders DESC;

-- Most popular cities
SELECT geolocation_city, COUNT(*) as number_of_orders
from geolocation
GROUP BY geolocation_city
ORDER BY number_of_orders DESC;

-- Most popular states
SELECT geolocation_state, COUNT(*) as number_of_orders
from geolocation
GROUP BY geolocation_state
ORDER BY number_of_orders DESC;

-- State with the most sellers
SELECT seller_state, COUNT(*) as number_of_sellers
FROM sellers
GROUP BY seller_state
ORDER BY number_of_sellers DESC;

-- Average review
SELECT AVG(review_score) from order_reviews;