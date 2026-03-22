-- Which products are generating us the most revenue?
SELECT
    oi.product_id,
    SUM(op.payment_value) as total_revenue,
    SUM(op.payment_value) * 100.0 / SUM(SUM(op.payment_value)) OVER () as percentage_of_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN order_payments op ON op.order_id = o.order_id
GROUP BY oi.product_id
ORDER BY total_revenue DESC;
-- Insights:
-- We find that no product clearly dominates as a proportion of revenue

-- Which categories are generating us the most revenue?
WITH category_values_portuguese AS (
    SELECT
        p.product_category_name,
        SUM(op.payment_value) as total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON o.order_id = oi.order_id
    JOIN order_payments op ON op.order_id = o.order_id
    GROUP BY p.product_category_name
    ORDER BY total_revenue DESC
)

SELECT
    tr.product_category_name_english,
    total_revenue,
    total_revenue * 100.00 / SUM(total_revenue) OVER () as percentage_of_revenue
FROM category_values_portuguese port
JOIN product_category_name_translation tr ON port.product_category_name = tr.product_category_name
ORDER BY total_revenue DESC

-- Insights:
-- We find that no one category clearly dominates as a proportion of revenue
-- A very diverse income stream

-- Which categories are generating us the most revenue?
WITH category_values_portuguese AS (
    SELECT
        p.product_category_name,
        AVG(ore.review_score) as avg_review,
        COUNT(*) num_orders
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON o.order_id = oi.order_id
    JOIN order_reviews ore ON ore.order_id = o.order_id
    GROUP BY p.product_category_name
    ORDER BY avg_review
)

SELECT
    tr.product_category_name_english,
    avg_review,
    num_orders
FROM category_values_portuguese port
JOIN product_category_name_translation tr ON port.product_category_name = tr.product_category_name
ORDER BY avg_review

-- Insights:
-- Given the large sample size and therefore high interest, we could do a lot to improve our 
-- office furniture offerings as it performs noticeably worse than our other high interest categories