----------  Some deeper analysis on our customers ----------

-- What is the lifetime revenue per customer
WITH customer_lifetime_value AS (
    SELECT
        SUM(payment_value) as lifetime_value
    FROM order_payments
    JOIN orders ON orders.order_id = order_payments.order_id
    JOIN customers ON customers.customer_id = orders.customer_id
    GROUP BY customers.customer_unique_id
)
SELECT
    AVG(lifetime_value) as lifetime_average_value
FROM customer_lifetime_value;

-- Insights:
-- We find that the average customer lifetime value is 166.59


-- What share of revenue comes from the top 10% of customers?
WITH customer_lifetime_value AS (
    SELECT
        customers.customer_unique_id,
        SUM(payment_value) as lifetime_value
    FROM order_payments
    JOIN orders ON orders.order_id = order_payments.order_id
    JOIN customers ON customers.customer_id = orders.customer_id
    GROUP BY customers.customer_unique_id
    ORDER BY lifetime_value DESC
),

customer_decile AS (
    SELECT 
        customer_unique_id,
        lifetime_value,
        SUM(lifetime_value) OVER (ORDER BY lifetime_value DESC) as cumulative_value,
        FLOOR(row_number() OVER () * 10.0 / COUNT(*) OVER ()) * 10 + 10 as decile
    FROM customer_lifetime_value
),

cumulative_deciles AS (
    SELECT
        decile,
        MAX(cumulative_value) as cumulative_value
    FROM customer_decile
    GROUP BY decile
    ORDER BY decile
)

SELECT
    decile,
    cumulative_value - LAG(cumulative_value, 1, 0) OVER () as total_revenue,
    (cumulative_value - LAG(cumulative_value, 1, 0) OVER ()) * 100.0 / 
    MAX(cumulative_value) OVER () as revenue_share
FROM cumulative_deciles;

-- Insights:
-- Our top 10% customers account for 38.5% of all our revenue
-- Our top 20% customers account for 53.8% of all our revenue
-- This shows we have a strong "whale" presence


-- How many customers fall into 1 order, 2–3 orders, and 4+ orders
WITH customer_order_counts AS (
    SELECT customer_unique_id, COUNT(*) as number_of_orders
    FROM customers
    GROUP BY customer_unique_id
    ORDER BY number_of_orders DESC
)

SELECT
    number_of_orders,
    COUNT(*) as number_of_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percent_of_customers
FROM customer_order_counts
GROUP BY number_of_orders
ORDER BY number_of_orders;

-- Insights:
-- We find that almost 97% of customers only order once