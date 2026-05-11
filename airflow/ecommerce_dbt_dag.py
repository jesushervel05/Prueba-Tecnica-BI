"""
DAG: ecommerce_dbt_pipeline
Corre diariamente a las 2:00 AM
Flujo: run_staging >> test_staging >> run_marts >> test_marts
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "bi_team",
    "depends_on_past": False,
    "email": ["jesus.hervel05@gmail.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR  = "/opt/airflow/dbt/ecommerce_dbt"
DBT_PROFILES_DIR = "/opt/airflow/dbt/profiles"

with DAG(
    dag_id="ecommerce_dbt_pipeline",
    description="Pipeline dbt ecommerce: staging -> tests -> marts -> tests",
    default_args=default_args,
    schedule_interval="0 2 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["dbt", "ecommerce", "bi"],
) as dag:

    run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --select staging "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--target prod"
        ),
    )

    test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt test --select staging "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--target prod"
        ),
    )

    run_marts = BashOperator(
        task_id="dbt_run_marts",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --select marts "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--target prod"
        ),
    )

    test_marts = BashOperator(
        task_id="dbt_test_marts",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt test --select marts "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--target prod"
        ),
    )

    run_staging >> test_staging >> run_marts >> test_marts
