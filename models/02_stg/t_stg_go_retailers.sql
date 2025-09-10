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
  * Path:           models/02_stg
  * Program:        t_stg_go_retailers.sql
  * Project:        dbt_sample_postgres
  * Description:    Staging model for GO Sales retailers
  * Author:         Manzar Ahmed
  * First Created:  Jun 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-06-11  Manzar Ahmed           v0.01/Initial version
  * 2025-08-07  Manzar Ahmed           v0.02/added row_number() for 
  *                                    deduplication
  ************************************************************************
*/
with ranked as
(
    select
        retailer_code,
        retailer_name,
        retailer_type,
        country,
        row_number() over (
        partition by 
            retailer_code,
            retailer_name,
            retailer_type,
            country
        order by
            retailer_code desc
        ) as rn
    from {{ ref('t_raw_go_retailers') }}
)
select 
    retailer_code,
    retailer_name,
    retailer_type,
    country 
from ranked
where rn = 1