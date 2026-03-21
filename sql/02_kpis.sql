------------- REVENUE -------------

-- Total Revenue
SELECT SUM(payment_value) as total_revenue
FROM order_payments;
-- Insight:
-- A total of 16 million


-- Monthly Revenue Growth
-- Note: Will use items as opposed to payment because we are not trying to consider delays in payments yet, only whether interest is growing or not
WITH monthly_revenue AS (
    SELECT 
        date_trunc('month',  order_purchase_timestamp) as month,
        sum(oi.price + oi.freight_value) as revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY month
    ORDER BY month
)

SELECT 
    month, 
    revenue,
    (revenue - LAG(revenue) OVER (ORDER by month)) / LAG(revenue) OVER (ORDER by month) * 100 as growth_percent
FROM monthly_revenue
ORDER BY month;

-- Insight:
-- We find that there is a very large variability in revenue with no clear growth trend

------------- CUSTOMERS -------------

-- # of Unique Customers
SELECT COUNT(DISTINCT customer_unique_id) 
FROM customers;
-- Insights:
-- 96096 distinct customers

-- Ratio of new vs returning customers

WITH customers_first_purchase AS (
    SELECT customer_unique_id, MIN(order_purchase_timestamp) AS customers_first_purchase
    FROM orders
    JOIN customers ON customers.customer_id = orders.customer_id
    GROUP BY customer_unique_id
),

customer_purchase_type AS (
    SELECT
        date_trunc('month',  order_purchase_timestamp) as month,
        c.customer_unique_id,
        CASE
            WHEN fp.customers_first_purchase = order_purchase_timestamp THEN 'new'
            ELSE 'returning'
        END as first_or_returning
    FROM orders
    JOIN customers c ON c.customer_id = orders.customer_id
    JOIN customers_first_purchase fp ON fp.customer_unique_id = c.customer_unique_id
)

SELECT 
    month,
    COUNT(CASE WHEN first_or_returning = 'new' THEN 1 END) as new_customer,
    COUNT(CASE WHEN first_or_returning = 'returning' THEN 1 END) as returning_customer,
    ROUND(COUNT(CASE WHEN first_or_returning = 'new' THEN 1 END) * 100.00 / 
        (COUNT(CASE WHEN first_or_returning = 'returning' THEN 1 END) + COUNT(CASE WHEN first_or_returning = 'new' THEN 1 END)), 2)  as rate
FROM customer_purchase_type
GROUP BY month
ORDER BY month;

-- Insights:
-- We find that the rate of new vs old customers is very high, given the fact we have 2 years of data, for a marketplace, 
-- this could indicate that we need to improve retention
-- New vs returning rate hovers at around 96% new


------------- ORDERS -------------

-- Total Orders
SELECT COUNT(*) FROM orders;
-- Insights:
-- 99441 orders

-- Average order value
SELECT AVG(freight_value + price) FROM order_items;
-- Insights:
-- 140.64

------------- RETENTION -------------

-- Repeat Purchase Rate
WITH customer_retention AS (
    SELECT customer_unique_id, 
        CASE
            WHEN COUNT(*) > 1 THEN 1
            ELSE 0
        END as retained
    FROM customers
    GROUP BY customer_unique_id
)
SELECT SUM(retained) * 100.0 / COUNT(*)
FROM customer_retention;
-- Insights:
-- Only 3.11% of all our customers have returned, this seems very low

-- First purchase month cohort Retention

WITH customer_cohort AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_activity AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
),

cohort_data AS (
    SELECT 
        cc.cohort_month,
        ca.order_month,
        EXTRACT(YEAR FROM AGE(ca.order_month, cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(ca.order_month, cc.cohort_month)) AS month_number,
        ca.customer_unique_id
    FROM customer_cohort cc
    JOIN customer_activity ca 
        ON cc.customer_unique_id = ca.customer_unique_id
),

cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM cohort_data
    WHERE month_number = 0
    GROUP BY cohort_month
)

SELECT
    cd.cohort_month,
    cd.month_number,
    COUNT(DISTINCT cd.customer_unique_id) as active_customers,
    ROUND(COUNT(DISTINCT cd.customer_unique_id) * 100.0 / cs.cohort_size, 2) as retention_rate
FROM cohort_data cd
JOIN cohort_size cs ON cs.cohort_month = cd.cohort_month
GROUP BY cd.cohort_month, cd.month_number, cs.cohort_size
ORDER BY cd.cohort_month, cd.month_number;
-- Insights:
-- What we find is that after the first month, the cohort retention drops off drastically
-- Each month after initial purchase, we often see less than 0.5% of our cohort return
-- This seems to indicate that customers are very unlikely to visit monthly, explanation is 
-- likely a combination of the nature of the marketplace, but also poor retention

------------- QUALITY -------------

-- Average review score
SELECT AVG(review_score) from order_reviews;
-- Insights:
-- An average review of 4.09/5

-- Delivery delays
SELECT 
    AVG(AGE(order_delivered_customer_date, order_estimated_delivery_date)),
    MAX(AGE(order_delivered_customer_date, order_estimated_delivery_date)),
    MIN(AGE(order_delivered_customer_date, order_estimated_delivery_date)),
    ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate
FROM orders
-- Insights:
-- We find that on average we delivered 10 days early, with the latest delivery being 6 months late.
-- We find that about 7.87% of deliveries are late