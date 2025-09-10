/*
  ************************************************************************
  *               _____          _____       _                           *
  *              / ____|        / ____|     | |                          *
  *             | |  __  ___   | (___   __ _| | ___  ___                 *
  *             | | |_ |/ _ \   \___ \ / _` | |/ _ \/ __|                *
  *             | |__| | (_) |  ____) | (_| | |  __/\__ \                *
  *              \_____|\___/  |_____/ \__,_|_|\___||___/                *
  *                                                                      *
  ************************************************************************
  * Path:           models/03_det
  * Program:        t_dim_products.sql
  * Project:        dbt_sample_postgres
  * Description:    SCD2 dimension model for GO Sales products with 
  *                 surrogate key and change hash
  * Author:         Manzar Ahmed
  * First Created:  Jun 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-06-11  Manzar Ahmed           v0.01/Initial version
  * 2025-06-23  Manzar Ahmed           v0.02/Utilising SCD2 vars for start 
  *                                    and end timestamps
  * 2025-06-23  Manzar Ahmed           v0.03/SonarQube issues fixed:  
  *                                    Define a constant instead of 
  *                                    duplicating this literal 5 times 
  *                                    (plsql:S1192)    
  * 2025-07-07  Manzar Ahmed           v0.04/Added version number, 
  *                                    current_version and prior surrogate
  *                                    key to SCD2
  * 2025-08-07  Manzar Ahmed           v0.05/change to postgres endpoint  
  ************************************************************************
*/
{{ config(
    materialized = 'scd2',
    schema = 'det',
    surrogate_key = 'dim_product_sk',
    unique_key = 'product_number'
) }}

select 
    product_number,
    product_line,
    product_type,
    product,
    product_brand,
    product_color,
    unit_cost,
    unit_price,
    {{ generate_hash([
        'product_number',        
        'product_line',
        'product_type',
        'product',
        'product_brand',
        'product_color',
        'cast(unit_cost as numeric(19,2))',
        'cast(unit_price as numeric(19,2))'
    ]) }}::bytea as scd2_hash

from {{ ref('t_stg_go_products') }}


