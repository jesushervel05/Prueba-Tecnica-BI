WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id ORDER BY order_id
        ) AS row_num
    FROM source
    WHERE order_id IS NOT NULL
),
cleaned AS (
    SELECT
        order_id,
        customer_id,
        SAFE_CAST(order_date AS DATE) AS order_date,
        LOWER(TRIM(status)) AS order_status,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM deduplicated
    WHERE row_num = 1
)
SELECT * FROM cleaned