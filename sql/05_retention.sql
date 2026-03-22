-- How many days does it usually take to make a second purchase?

WITH customer_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_purchase_timestamp AS order_day
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
),
ranked_purchases AS (
    SELECT
        customer_unique_id,
        order_day,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_day
        ) AS order_rank
    FROM customer_activity
),

first_and_second_purchases AS (
    SELECT 
        *,
        MAX(order_rank) OVER (PARTITION BY customer_unique_id) as total_orders
    FROM ranked_purchases
    WHERE order_rank <= 2
    ORDER BY customer_unique_id, order_rank
),

filtered_purchases AS (
    SELECT
        customer_unique_id, 
        order_day,
        order_rank
    FROM first_and_second_purchases
    WHERE total_orders = 2
),

purchases_with_delays AS (
    SELECT
        customer_unique_id,
        order_day,
        order_rank,
        order_day - LAG(order_day) OVER(PARTITION BY customer_unique_id) as delay
    FROM filtered_purchases
)

SELECT
    AVG(delay) as avg_time_since_first_purchase
FROM purchases_with_delays
WHERE delay IS NOT NULL

-- Insights:
-- If a second purchase is made, it usually takes approximately three months


-- Question: How do retention rates differ by first purchase month?

WITH customer_cohort AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_purchase_timestamp AS order_day
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
),
ranked_purchases AS (
    SELECT
        customer_unique_id,
        order_day,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_day
        ) AS order_rank
    FROM customer_activity
),

first_and_second_purchases AS (
    SELECT 
        *,
        CASE WHEN MAX(order_rank) OVER (PARTITION BY rp.customer_unique_id) > 1 THEN 1 ELSE 0 END as is_retained
    FROM ranked_purchases rp
    JOIN customer_cohort cc ON cc.customer_unique_id = rp.customer_unique_id
    WHERE order_rank <= 2
    ORDER BY rp.customer_unique_id, order_rank
),

-- How many people in each cohort
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohort
    GROUP BY cohort_month
)

SELECT
    fsp.cohort_month,
    ROUND(AVG(is_retained) * 100.0, 2) as retain_percentage,
    cohort_size
FROM first_and_second_purchases fsp
JOIN cohort_size cs ON cs.cohort_month = fsp.cohort_month
WHERE order_rank = 1
GROUP BY fsp.cohort_month, cohort_size
ORDER BY fsp.cohort_month