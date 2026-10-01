SET search_path TO ecommerce, public;

-- 01. Executive KPI
SELECT
    ROUND(SUM(total_amount) FILTER (WHERE order_status='COMPLETED'),2) AS gross_revenue,
    COUNT(*) FILTER (WHERE order_status='COMPLETED') AS completed_orders,
    COUNT(DISTINCT customer_id) FILTER (WHERE order_status='COMPLETED') AS purchasing_customers,
    ROUND(AVG(total_amount) FILTER (WHERE order_status='COMPLETED'),2) AS average_order_value
FROM orders;

-- 02. Month-over-month revenue growth
WITH m AS (
    SELECT date_trunc('month',order_date)::date month,
           SUM(total_amount) revenue
    FROM orders
    WHERE order_status='COMPLETED'
    GROUP BY 1
)
SELECT month, ROUND(revenue,2),
       ROUND(100*(revenue-LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month),0),2) AS mom_growth_pct
FROM m ORDER BY month;

-- 03. Top 10 customers
SELECT customer_id,
       COUNT(*) orders,
       ROUND(SUM(total_amount),2) revenue,
       DENSE_RANK() OVER (ORDER BY SUM(total_amount) DESC) revenue_rank
FROM orders
WHERE order_status='COMPLETED'
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 10;

-- 04. Top products by revenue
SELECT * FROM vw_product_performance
ORDER BY revenue DESC NULLS LAST
LIMIT 10;

-- 05. Customer RFM segmentation
SELECT segment, COUNT(*) customers,
       ROUND(AVG(monetary),2) avg_customer_value
FROM vw_rfm_customer
GROUP BY segment
ORDER BY avg_customer_value DESC;

-- 06. Return rate by category
SELECT c.category_name,
       COUNT(DISTINCT oi.order_item_id) sold_items,
       COUNT(DISTINCT r.return_id) returned_items,
       ROUND(100.0*COUNT(DISTINCT r.return_id)
             / NULLIF(COUNT(DISTINCT oi.order_item_id),0),2) return_rate_pct
FROM categories c
JOIN products p ON p.category_id=c.category_id
JOIN order_items oi ON oi.product_id=p.product_id
JOIN orders o ON o.order_id=oi.order_id AND o.order_status='COMPLETED'
LEFT JOIN returns r ON r.order_item_id=oi.order_item_id
GROUP BY c.category_name
ORDER BY return_rate_pct DESC;

-- 07. Payment method mix
SELECT payment_method,
       COUNT(*) transactions,
       ROUND(SUM(amount),2) amount,
       ROUND(100.0*SUM(amount)/SUM(SUM(amount)) OVER (),2) pct_of_amount
FROM payments
WHERE payment_status='SUCCESS'
GROUP BY payment_method
ORDER BY amount DESC;

-- 08. Running revenue
SELECT month, revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month),2) running_revenue
FROM (
    SELECT date_trunc('month',order_date)::date month,
           SUM(total_amount) revenue
    FROM orders
    WHERE order_status='COMPLETED'
    GROUP BY 1
) m;

-- 09. High-value products with elevated returns
SELECT *
FROM vw_product_performance
WHERE revenue > 10000 AND return_count >= 3
ORDER BY return_count DESC, revenue DESC;

-- 10. Data-quality checks
SELECT 'Orders with negative/zero totals' check_name, COUNT(*) bad_rows
FROM orders WHERE total_amount < 0
UNION ALL
SELECT 'Products where price < cost', COUNT(*)
FROM products WHERE price < cost
UNION ALL
SELECT 'Orphan order items', COUNT(*)
FROM order_items oi LEFT JOIN orders o ON o.order_id=oi.order_id
WHERE o.order_id IS NULL;
