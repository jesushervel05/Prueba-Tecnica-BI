WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),
products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
items_with_price AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.quantity,
        p.price,
        (oi.quantity * p.price) AS line_revenue
    FROM order_items AS oi
    INNER JOIN products AS p
        ON oi.product_id = p.product_id
),
order_totals AS (
    SELECT
        order_id,
        COUNT(*)          AS total_items,
        SUM(quantity)     AS total_units,
        SUM(line_revenue) AS total_revenue
    FROM items_with_price
    GROUP BY order_id
)
SELECT * FROM order_totals