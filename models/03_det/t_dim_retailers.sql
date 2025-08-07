/*------------------------------------------------------------------------------
Program:        t_det_go_retailers
Project:        dbt_sample_postgres
Description:    SCD2 dimension model for GO Sales retailers
Input(s):       stg.t_stg_go_retailers
Output(s):      det.t_det_go_retailers
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-06-23  Manzar Ahmed           v0.02/Utilising SCD2 vars for start and end 
                                   timestamps
2025-06-23  Manzar Ahmed           v0.03/SonarQube issues fixed:  
                                   Define a constant instead of duplicating this 
                                   literal 5 times (plsql:S1192)
2025-08-07  Manzar Ahmed           v0.02/change to postgres endpoint                                                                   
------------------------------------------------------------------------------*/

{{ config(
    materialized = 'incremental',
    schema = 'det',
    unique_key = 'retailer_code',
    pre_hook = ["create sequence if not exists seq_dim_retailer_sk start 1 increment 1"]
) }}

{% set vars = get_scd2_vars() %}
{% set start_ts = "('" ~ vars.start_ts ~ "')::timestamp" %}
{% set end_ts = "('" ~ vars.end_ts ~ "')::timestamp" %}
{% set high_date_ts = "('" ~ vars.high_date ~ "')::timestamp" %}

with current_data as (
    select  retailer_code,
            retailer_name,
            type,
            country,
            md5(
                coalesce(retailer_name, '') || '|' ||
                coalesce(type, '') || '|' ||
                coalesce(country, '')
                ) as scd2_hash
    from    {{ ref('t_stg_go_retailers') }}
)

{% if is_incremental() %},

existing_records as (
    select      retailer_code,
                retailer_name,
                type,
                country,
                scd2_hash,
                start_ts,
                end_ts
    from        {{ this }}
    where       end_ts = {{ high_date_ts }}
),

ordered_changes as (
    select      c.retailer_code,
                c.retailer_name,
                c.type,
                c.country,
                c.scd2_hash
    from        current_data c
    left join   existing_records e
    on          c.retailer_code = e.retailer_code
    where       e.retailer_code is null
    or          c.scd2_hash != e.scd2_hash
    order by    c.retailer_code
),

changes as (
    select  nextval('seq_dim_retailer_sk') as dim_retailer_sk,
            oc.retailer_code,
            oc.retailer_name,
            oc.type,
            oc.country,
            oc.scd2_hash,
            {{ start_ts }} start_ts,
            {{ high_date_ts }} as end_ts
    from    ordered_changes oc
),

updates as (
    select  e.dim_retailer_sk,
            e.retailer_code,
            e.retailer_name,
            e.type,
            e.country,
            e.scd2_hash,
            e.start_ts,
            ('{{ end_ts }}')::timestamp  as end_ts
    from    existing_records e
    join    changes c
    on      e.retailer_code = c.retailer_code
    where   e.end_ts = {{ high_date_ts }}
),

unchanged_history as (
    select *
    from {{ this }}
    where end_ts != {{ high_date_ts }}
)

select * from changes
union all
select * from updates
union all
select * from unchanged_history

{% else %}

select      nextval('seq_dim_retailer_sk') as dim_retailer_sk,
            retailer_code,
            retailer_name,
            type,
            country,
            scd2_hash,
            {{ start_ts }}  as start_ts,
            {{ high_date_ts }}as end_ts
from        current_data
order by    retailer_code

{% endif %}