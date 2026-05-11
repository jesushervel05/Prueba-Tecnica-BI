WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),
cleaned AS (
    SELECT
        product_id,
        TRIM(name) AS product_name,
        SAFE_CAST(price AS NUMERIC) AS price,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM source
    WHERE product_id IS NOT NULL
      AND SAFE_CAST(price AS NUMERIC) > 0
)
SELECT * FROM cleaned