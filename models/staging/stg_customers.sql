WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id ORDER BY customer_id
        ) AS row_num
    FROM source
    WHERE customer_id IS NOT NULL
),
cleaned AS (
    SELECT
        customer_id,
        COALESCE(TRIM(name), 'Sin Nombre') AS customer_name,
        LOWER(TRIM(email)) AS email,
        CURRENT_TIMESTAMP() AS _loaded_at
    FROM deduplicated
    WHERE row_num = 1
)
SELECT * FROM cleaned