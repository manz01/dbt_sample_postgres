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
  * Program:        t_fct_sales.sql
  * Project:        dbt_sample_postgres
  * Description:    Fact table for GO Sales with surrogate keys from 
  *                 dimensions
  * Author:         Manzar Ahmed
  * First Created:  Jun 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-06-11  Manzar Ahmed           v0.01/Initial version
  * 2025-08-07  Manzar Ahmed           v0.02/change to postgres endpoint  
  ************************************************************************
*/
{{ config(
    materialized='scd1',
    schema = 'det',
    surrogate_key = 'fct_sales_sk',
    unique_key = ['dim_retailer_sk', 'dim_product_sk', 'dim_order_method_sk', 'transaction_date'],
    scd_hash_col = 'fact_hash'
) }}

with stg_fct_sales as (
    select
        r.dim_retailer_sk,
        p.dim_product_sk,
        m.dim_order_method_sk,
        b.transaction_date,
        b.quantity,
        b.unit_price,
        b.unit_sale_price

    from {{ ref('t_stg_go_daily_sales') }} as b
    left join {{ ref('t_dim_retailers') }} as r
        on b.retailer_code = r.retailer_code
        and r.is_current = true
    left join {{ ref('t_dim_products') }} as p
        on b.product_number = p.product_number
        and p.is_current = true
    left join {{ ref('t_dim_order_methods') }} as m
        on b.order_method_code = m.order_method_code
)
select 
    *,
    {{ generate_hash([
        'dim_retailer_sk',        
        'dim_product_sk',
        'dim_order_method_sk',
        'transaction_date',
        'quantity',
        'cast(unit_price as numeric(19,2))',
        'cast(unit_sale_price as numeric(19,2))'
    ]) }}::bytea as fact_hash
from stg_fct_sales    