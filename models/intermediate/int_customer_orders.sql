WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
revenues AS (
    SELECT * FROM {{ ref('int_order_revenues') }}
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
orders_enriched AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        COALESCE(r.total_revenue, 0) AS order_revenue,
        COALESCE(r.total_items, 0)   AS order_items
    FROM orders AS o
    LEFT JOIN revenues AS r
        ON o.order_id = r.order_id
    WHERE o.order_date IS NOT NULL
      AND o.customer_id IN (
          SELECT customer_id FROM customers
      )
),
customer_aggregates AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        MIN(order_date)          AS first_order_date,
        MAX(order_date)          AS last_order_date,
        SUM(order_revenue)       AS total_revenue
    FROM orders_enriched
    GROUP BY customer_id
)
SELECT * FROM customer_aggregates