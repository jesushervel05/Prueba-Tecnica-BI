SELECT
    order_id,
    total_revenue
FROM {{ ref('mart_orders_summary') }}
WHERE total_revenue <= 0