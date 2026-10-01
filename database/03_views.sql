SET search_path TO ecommerce, public;


-- =========================================================
-- 1. MONTHLY REVENUE
-- =========================================================

CREATE OR REPLACE VIEW vw_monthly_revenue AS

WITH monthly_orders AS (
    SELECT
        date_trunc('month', order_date)::date AS month,
        COUNT(*) FILTER (
            WHERE order_status = 'COMPLETED'
        ) AS completed_orders,
        COUNT(DISTINCT customer_id) FILTER (
            WHERE order_status = 'COMPLETED'
        ) AS active_customers,
        ROUND(
            SUM(total_amount) FILTER (
                WHERE order_status = 'COMPLETED'
            ),
            2
        ) AS gross_revenue
    FROM orders
    GROUP BY 1
),

monthly_refunds AS (
    SELECT
        date_trunc('month', return_date)::date AS month,
        ROUND(
            SUM(refund_amount) FILTER (
                WHERE return_status = 'REFUNDED'
            ),
            2
        ) AS refunds
    FROM returns
    GROUP BY 1
)

SELECT
    mo.month,
    mo.completed_orders,
    mo.active_customers,
    mo.gross_revenue,
    COALESCE(mr.refunds, 0) AS refunds,
    ROUND(
        mo.gross_revenue - COALESCE(mr.refunds, 0),
        2
    ) AS net_revenue
FROM monthly_orders mo
LEFT JOIN monthly_refunds mr
    ON mr.month = mo.month
ORDER BY mo.month;


-- =========================================================
-- 2. CUSTOMER 360
-- =========================================================

CREATE OR REPLACE VIEW vw_customer_360 AS

WITH base AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.city,
        c.signup_date,

        COUNT(o.order_id) FILTER (
            WHERE o.order_status = 'COMPLETED'
        ) AS orders_count,

        COALESCE(
            SUM(o.total_amount) FILTER (
                WHERE o.order_status = 'COMPLETED'
            ),
            0
        ) AS revenue,

        MAX(o.order_date) FILTER (
            WHERE o.order_status = 'COMPLETED'
        ) AS last_order

    FROM customers c

    LEFT JOIN orders o
        ON o.customer_id = c.customer_id

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city,
        c.signup_date
)

SELECT
    *,
    CASE
        WHEN last_order IS NULL THEN NULL
        ELSE CURRENT_DATE - last_order::date
    END AS days_since_purchase,

    CASE
        WHEN revenue >= 50000
             AND orders_count >= 8
            THEN 'VIP'

        WHEN orders_count >= 5
            THEN 'LOYAL'

        WHEN last_order IS NULL
            THEN 'NEVER_PURCHASED'

        WHEN CURRENT_DATE - last_order::date > 180
            THEN 'AT_RISK'

        ELSE 'REGULAR'
    END AS customer_segment

FROM base;


-- =========================================================
-- 3. PRODUCT PERFORMANCE
-- =========================================================

CREATE OR REPLACE VIEW vw_product_performance AS

WITH sales AS (
    SELECT
        oi.product_id,

        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount / 100.0)
            ) FILTER (
                WHERE o.order_status = 'COMPLETED'
            ),
            2
        ) AS revenue,

        SUM(oi.quantity) FILTER (
            WHERE o.order_status = 'COMPLETED'
        ) AS units_sold,

        ROUND(
            SUM(
                oi.quantity
                * (
                    oi.unit_price
                    * (1 - oi.discount / 100.0)
                    - p.cost
                )
            ) FILTER (
                WHERE o.order_status = 'COMPLETED'
            ),
            2
        ) AS estimated_profit

    FROM order_items oi

    JOIN orders o
        ON o.order_id = oi.order_id

    JOIN products p
        ON p.product_id = oi.product_id

    GROUP BY oi.product_id
),

ratings AS (
    SELECT
        product_id,
        ROUND(AVG(rating)::numeric, 2) AS avg_rating,
        COUNT(*) AS review_count

    FROM reviews

    GROUP BY product_id
),

returns_by_product AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT r.return_id) AS return_count

    FROM order_items oi

    JOIN returns r
        ON r.order_item_id = oi.order_item_id

    GROUP BY oi.product_id
)

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    COALESCE(s.revenue, 0) AS revenue,
    COALESCE(s.units_sold, 0) AS units_sold,
    COALESCE(s.estimated_profit, 0) AS estimated_profit,

    r.avg_rating,
    COALESCE(r.review_count, 0) AS review_count,

    COALESCE(rb.return_count, 0) AS return_count

FROM products p

JOIN categories c
    ON c.category_id = p.category_id

LEFT JOIN sales s
    ON s.product_id = p.product_id

LEFT JOIN ratings r
    ON r.product_id = p.product_id

LEFT JOIN returns_by_product rb
    ON rb.product_id = p.product_id;


-- =========================================================
-- 4. RFM CUSTOMER SEGMENTATION
-- =========================================================

CREATE OR REPLACE VIEW vw_rfm_customer AS

WITH x AS (
    SELECT
        customer_id,

        CURRENT_DATE - MAX(order_date)::date
            AS recency_days,

        COUNT(*) AS frequency,

        ROUND(SUM(total_amount), 2)
            AS monetary

    FROM orders

    WHERE order_status = 'COMPLETED'

    GROUP BY customer_id
),

scored AS (
    SELECT
        *,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM x
)

SELECT
    *,

    r_score + f_score + m_score
        AS rfm_score,

    CASE
        WHEN r_score + f_score + m_score >= 13
            THEN 'HIGH_VALUE'

        WHEN r_score + f_score + m_score >= 9
            THEN 'LOYAL'

        WHEN r_score + f_score + m_score >= 6
            THEN 'PROMISING'

        ELSE 'AT_RISK'
    END AS segment

FROM scored;