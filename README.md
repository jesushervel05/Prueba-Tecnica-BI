Prueba Tecnica BI — Pipeline dbt + BigQuery + Airflow
Autor: Jesus Hernandez Velasquez
Fecha: Mayo 2026
Repositorio: https://github.com/jesushervel05/Prueba-Tecnica-BI

Descripcion del proyecto
Pipeline de transformacion de datos para una empresa de e-commerce. Toma datos crudos con problemas de calidad desde BigQuery y los transforma en tablas limpias y confiables listas para analisis, usando dbt como herramienta principal de transformacion.

Arquitectura
BigQuery (raw)
    |
    v
staging/        <- limpieza 1:1 de tablas raw (vistas)
    |
    v
intermediate/   <- logica de negocio y joins (tablas)
    |
    v
marts/          <- tablas finales para consumo (tablas)

Estructura del proyecto
ecommerce_dbt/
├── dbt_project.yml
├── README.md
├── models/
│   ├── staging/
│   │   ├── sources.yml
│   │   ├── schema.yml
│   │   ├── stg_orders.sql
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   └── stg_order_items.sql
│   ├── intermediate/
│   │   ├── int_order_revenues.sql
│   │   └── int_customer_orders.sql
│   └── marts/
│       ├── schema.yml
│       ├── mart_orders_summary.sql
│       └── mart_customer_ltv.sql
├── macros/
│   ├── normalize_text.sql
│   ├── customer_segment.sql
│   └── date_filter.sql
├── tests/
│   └── assert_no_negative_revenue.sql
└── airflow/
    └── ecommerce_dbt_dag.py

Prerequisitos

Cuenta en Google Cloud Platform con BigQuery habilitado
Cuenta en dbt Cloud (https://cloud.getdbt.com) — plan gratuito funciona
Python 3.9+ (solo si corres dbt localmente)
Apache Airflow 2.x (para el DAG)


Configuracion paso a paso
1. Crear el proyecto en Google Cloud

Ve a https://console.cloud.google.com
Crea un proyecto nuevo sin organizacion
Activa BigQuery
Crea el dataset raw

2. Cargar los datos de prueba
En BigQuery, ejecuta este script:
sqlCREATE OR REPLACE TABLE `raw.orders` AS
SELECT * FROM UNNEST([
  STRUCT('O001' AS order_id, 'C01' AS customer_id, '2024-01-15' AS order_date, 'completed' AS status),
  STRUCT('O002', 'C02', '2024-01-16', 'COMPLETED'),
  STRUCT('O002', 'C02', '2024-01-16', 'COMPLETED'),
  STRUCT('O003', 'C03', NULL, 'pending'),
  STRUCT('O004', 'C01', '2024-02-01', 'cancelled'),
  STRUCT('O005', 'C99', '2024-02-10', 'completed')
]);

CREATE OR REPLACE TABLE `raw.customers` AS
SELECT * FROM UNNEST([
  STRUCT('C01' AS customer_id, 'Ana Garcia' AS name, 'ana@email.com' AS email),
  STRUCT('C02', 'Carlos Lopez', 'carlos@email.com'),
  STRUCT('C03', NULL, 'sin_nombre@email.com')
]);

CREATE OR REPLACE TABLE `raw.products` AS
SELECT * FROM UNNEST([
  STRUCT('P01' AS product_id, 'Laptop' AS name, 1200.00 AS price),
  STRUCT('P02', 'Mouse', 25.00),
  STRUCT('P03', 'Teclado', 75.00)
]);

CREATE OR REPLACE TABLE `raw.order_items` AS
SELECT * FROM UNNEST([
  STRUCT('O001' AS order_id, 'P01' AS product_id, 1 AS quantity),
  STRUCT('O001', 'P02', 2),
  STRUCT('O002', 'P03', 3),
  STRUCT('O004', 'P99', 1),
  STRUCT('O005', 'P01', -1)
]);
3. Configurar dbt Cloud

Crea cuenta en https://cloud.getdbt.com
Crea un proyecto nuevo llamado ecommerce_dbt
Conecta BigQuery usando una cuenta de servicio JSON
Asegurate de que la cuenta de servicio tenga rol BigQuery Admin
Configura el dataset de desarrollo como dbt_dev
Conecta este repositorio de GitHub

4. Dar permisos a la cuenta de servicio
En BigQuery ejecuta:
sqlGRANT `roles/bigquery.admin`
ON SCHEMA `tu-proyecto`.raw
TO "serviceAccount:tu-cuenta@tu-proyecto.iam.gserviceaccount.com";

Correr el proyecto
Una vez configurado en dbt Cloud, desde el IDE ejecuta:
bash# Correr todos los modelos en orden
dbt run

# Correr solo staging
dbt run --select staging

# Correr solo intermediate
dbt run --select intermediate

# Correr solo marts
dbt run --select marts

# Ejecutar todos los tests
dbt test

# Verificar frescura de datos raw
dbt source freshness

# Generar documentacion y lineage graph
dbt docs generate
El orden correcto para la primera ejecucion es:
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

Modelos
Staging (limpieza)
ModeloTabla rawLimpieza aplicadastg_ordersraw.ordersElimina duplicados, normaliza status, castea fechasstg_customersraw.customersReemplaza nombres nulos, normaliza emailstg_productsraw.productsFiltra precios invalidos, castea a NUMERICstg_order_itemsraw.order_itemsFiltra cantidades negativas, genera surrogate key
Intermediate (logica de negocio)
ModeloDescripcionint_order_revenuesJOIN entre items y productos, calcula revenue por ordenint_customer_ordersAgrega ordenes por cliente, filtra clientes y productos inexistentes
Marts (tablas finales)
ModeloDescripcionmart_orders_summaryUna fila por orden con order_id, customer_id, order_date, total_items, total_revenue, order_statusmart_customer_ltvUna fila por cliente con LTV acumulado y segmento VIP/Regular/Nuevo

Tests de calidad
El proyecto incluye mas de 28 tests:

unique y not_null en todas las primary keys
not_null en columnas criticas
accepted_values en order_status y customer_segment
relationships entre tablas (foreign keys)
Test singular: assert_no_negative_revenue.sql — ninguna orden puede tener revenue <= 0


Macros
MacroUsonormalize_text(col)Aplica LOWER(TRIM()) para normalizar textocustomer_segment(revenue, orders)Calcula segmento VIP/Regular/Nuevodate_filter(col, start, end)Filtro de fechas con parametros opcionales

DAG de Airflow
El archivo airflow/ecommerce_dbt_dag.py orquesta el pipeline:
run_staging >> test_staging >> run_marts >> test_marts

Corre todos los dias a las 2:00 AM
Si test_staging falla, el pipeline se detiene automaticamente
1 reintento por tarea con 5 minutos de espera
Alerta por email si cualquier tarea falla

Para instalarlo copiar el archivo a la carpeta /dags/ de tu instalacion de Airflow.

Respuesta teorica — Tablas grandes en BigQuery (+500M filas)
Para manejar tablas con mas de 500 millones de filas aplicaria dos estrategias:

Incremental + particionamiento: Configurar materialized='incremental' con is_incremental() para procesar solo filas nuevas en cada corrida. Combinado con partition_by: {field: 'order_date', data_type: 'date'} para escanear solo las particiones del periodo relevante, reduciendo costo y latencia.
Clustering: Agregar cluster_by: ['customer_id', 'order_status'] para que BigQuery ordene fisicamente los datos dentro de cada particion, acelerando los filtros y GROUP BY frecuentes del pipeline.


Problemas conocidos
Los siguientes tests fallan intencionalmente porque detectan datos sucios del enunciado:

relationships_stg_order_items_product_id_ref_stg_products — O004 tiene product_id=P99 que no existe
assert_no_negative_revenue — ordenes con revenue=0 por producto inexistente

Esto demuestra que el sistema de calidad funciona correctamente.
