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
  * Program:        t_dim_retailers.sql
  * Project:        dbt_sample_postgres
  * Description:    SCD2 dimension model for GO Sales retailers with 
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
  *                                    duplicating this  literal 5 times 
  *                                    (plsql:S1192)
  * 2025-08-07  Manzar Ahmed           v0.04/change to postgres endpoint   
  ************************************************************************
*/
{{ config(
    materialized = 'scd2',
    schema = 'det',
    surrogate_key = 'dim_retailer_sk',
    unique_key = 'retailer_code'
) }}

select  
    retailer_code,
    retailer_name,
    retailer_type,
    country,
    {{ generate_hash([
        'retailer_code',
        'retailer_name',
        'retailer_type',
        'country',
    ]) }} as scd2_hash

from {{ ref('t_stg_go_retailers') }}

