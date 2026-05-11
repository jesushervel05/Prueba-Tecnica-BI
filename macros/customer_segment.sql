{% macro customer_segment(revenue_col, orders_col) %}
    CASE
        WHEN {{ orders_col }} < 2      THEN 'Nuevo'
        WHEN {{ revenue_col }} > 5000  THEN 'VIP'
        WHEN {{ revenue_col }} > 500   THEN 'Regular'
        ELSE 'Nuevo'
    END
{% endmacro %}