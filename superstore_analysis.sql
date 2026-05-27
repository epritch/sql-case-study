-- ============================================================
-- SQL Case Study: Superstore Sales Analysis
-- Author: Evan Pritchard | github.com/epritch
-- Dataset: Tableau Superstore (public domain)
-- Dialect: PostgreSQL / SQL Server compatible
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- TABLE SCHEMA (for reference)
-- ─────────────────────────────────────────────────────────────
--
-- orders (
--   order_id       VARCHAR PRIMARY KEY,
--   order_date     DATE,
--   ship_date      DATE,
--   ship_mode      VARCHAR,
--   customer_id    VARCHAR,
--   customer_name  VARCHAR,
--   segment        VARCHAR,        -- Consumer, Corporate, Home Office
--   region         VARCHAR,
--   state          VARCHAR,
--   city           VARCHAR
-- )
--
-- order_items (
--   item_id        SERIAL PRIMARY KEY,
--   order_id       VARCHAR REFERENCES orders(order_id),
--   product_id     VARCHAR,
--   category       VARCHAR,
--   sub_category   VARCHAR,
--   product_name   VARCHAR,
--   sales          NUMERIC(10,2),
--   quantity       INT,
--   discount       NUMERIC(4,2),
--   profit         NUMERIC(10,2)
-- )


-- ─────────────────────────────────────────────────────────────
-- QUERY 1: Revenue & Profit Summary by Category
-- Simple aggregation — baseline for any BI dashboard
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.category,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    SUM(oi.sales)                       AS total_revenue,
    SUM(oi.profit)                      AS total_profit,
    ROUND(SUM(oi.profit) / NULLIF(SUM(oi.sales), 0) * 100, 2)
                                        AS profit_margin_pct,
    ROUND(AVG(oi.discount) * 100, 1)   AS avg_discount_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY oi.category
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 2: Year-over-Year Revenue Growth (Window Function)
-- Uses LAG() to compare each year to the prior year
-- ─────────────────────────────────────────────────────────────
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date)  AS order_year,
        oi.category,
        ROUND(SUM(oi.sales), 2)          AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY order_year, oi.category
)
SELECT
    order_year,
    category,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY category
        ORDER BY order_year
    )                                           AS prior_year_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY order_year))
        / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY order_year), 0)
        * 100, 1
    )                                           AS yoy_growth_pct
FROM yearly
ORDER BY category, order_year;


-- ─────────────────────────────────────────────────────────────
-- QUERY 3: Top 10 Customers by Lifetime Value
-- CTE + RANK() window function
-- ─────────────────────────────────────────────────────────────
WITH customer_ltv AS (
    SELECT
        o.customer_id,
        o.customer_name,
        o.segment,
        COUNT(DISTINCT o.order_id)          AS total_orders,
        ROUND(SUM(oi.sales), 2)             AS lifetime_revenue,
        ROUND(SUM(oi.profit), 2)            AS lifetime_profit,
        MIN(o.order_date)                   AS first_order_date,
        MAX(o.order_date)                   AS last_order_date,
        MAX(o.order_date) - MIN(o.order_date)
                                            AS days_as_customer
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.customer_name, o.segment
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY lifetime_revenue DESC) AS revenue_rank
    FROM customer_ltv
)
SELECT *
FROM ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


-- ─────────────────────────────────────────────────────────────
-- QUERY 4: Discount vs Profitability Analysis
-- Buckets discounts into bands and compares profit margin
-- ─────────────────────────────────────────────────────────────
WITH discount_bands AS (
    SELECT
        oi.*,
        CASE
            WHEN oi.discount = 0             THEN '0% – No Discount'
            WHEN oi.discount <= 0.10         THEN '1–10%'
            WHEN oi.discount <= 0.20         THEN '11–20%'
            WHEN oi.discount <= 0.30         THEN '21–30%'
            ELSE '31%+'
        END AS discount_band
    FROM order_items oi
)
SELECT
    discount_band,
    COUNT(*)                                        AS line_items,
    ROUND(SUM(sales), 0)                            AS total_sales,
    ROUND(SUM(profit), 0)                           AS total_profit,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_margin_pct,
    ROUND(AVG(discount) * 100, 1)                  AS avg_discount_pct
FROM discount_bands
GROUP BY discount_band
ORDER BY avg_discount_pct;

-- KEY FINDING: Items discounted over 20% consistently produce
-- negative profit margins — a direct driver of profit leakage.


-- ─────────────────────────────────────────────────────────────
-- QUERY 5: Regional Performance Comparison
-- PIVOT-style aggregation for a BI-ready data source
-- ─────────────────────────────────────────────────────────────
SELECT
    o.region,
    COUNT(DISTINCT o.order_id)                      AS orders,
    COUNT(DISTINCT o.customer_id)                   AS unique_customers,
    ROUND(SUM(oi.sales), 0)                         AS revenue,
    ROUND(SUM(oi.profit), 0)                        AS profit,
    ROUND(SUM(oi.profit) / NULLIF(SUM(oi.sales), 0) * 100, 2)
                                                    AS margin_pct,
    ROUND(SUM(oi.sales) / COUNT(DISTINCT o.customer_id), 2)
                                                    AS revenue_per_customer
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.region
ORDER BY revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 6: Rolling 3-Month Revenue (Window Frame)
-- Useful for smoothing seasonal spikes in trend charts
-- ─────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date)   AS month,
        ROUND(SUM(oi.sales), 2)             AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    monthly_revenue,
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3mo_avg
FROM monthly
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- QUERY 7: Customer Retention — Repeat vs One-Time Buyers
-- ─────────────────────────────────────────────────────────────
WITH order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS num_orders
    FROM orders
    GROUP BY customer_id
),
segments AS (
    SELECT
        CASE
            WHEN num_orders = 1 THEN 'One-time buyer'
            WHEN num_orders BETWEEN 2 AND 4 THEN 'Occasional (2–4)'
            WHEN num_orders BETWEEN 5 AND 9 THEN 'Loyal (5–9)'
            ELSE 'Champion (10+)'
        END AS segment,
        COUNT(*) AS customer_count
    FROM order_counts
    GROUP BY segment
)
SELECT
    segment,
    customer_count,
    ROUND(customer_count * 100.0 / SUM(customer_count) OVER (), 1) AS pct_of_customers
FROM segments
ORDER BY customer_count DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 8: Sub-Category Ranked by Profit Within Category
-- DENSE_RANK() partitioned by category
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.category,
    oi.sub_category,
    ROUND(SUM(oi.sales), 0)     AS revenue,
    ROUND(SUM(oi.profit), 0)    AS profit,
    ROUND(SUM(oi.profit) / NULLIF(SUM(oi.sales), 0) * 100, 1) AS margin_pct,
    DENSE_RANK() OVER (
        PARTITION BY oi.category
        ORDER BY SUM(oi.profit) DESC
    )                           AS profit_rank_in_category
FROM order_items oi
GROUP BY oi.category, oi.sub_category
ORDER BY oi.category, profit_rank_in_category;
