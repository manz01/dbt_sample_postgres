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
  * Program:        t_dim_order_methods.sql
  * Project:        dbt_sample_postgres
  * Description:    SCD1 dimension model for GO Sales order methods with 
                    surrogate key and audit columns
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
    surrogate_key = 'dim_order_method_sk',
    unique_key = 'order_method_code'                   
) }}

select
    order_method_code,
    order_method_type,
    {{ generate_hash(['order_method_code', 'order_method_type']) }}::bytea as scd_hash    

from {{ ref('t_stg_go_methods') }}

