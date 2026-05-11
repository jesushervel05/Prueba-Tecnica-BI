WITH source AS (
    SELECT * FROM {{ source('raw', 'order_items') }}
),
cleaned AS (
    SELECT
        TO_HEX(MD5(CONCAT(
            COALESCE(order_id, ''), '_',
            COALESCE(product_id, '')
        ))) AS order_item_id,
        order_id,
        product_id,
        quantity,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM source
    WHERE order_id IS NOT NULL
      AND product_id IS NOT NULL
      AND quantity > 0
)
SELECT * FROM cleaned