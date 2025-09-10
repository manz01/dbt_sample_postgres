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
  * Program:        t_stg_go_products.sql
  * Project:        dbt_sample_postgres
  * Description:    Staging model for GO Sales products
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
        product_number,
        product_line,
        product_type,
        product,
        product_brand,
        product_color,
        unit_cost,
        unit_price,
        row_number() over (
        partition by 
            product_number,
            product_line,
            product_type,
            product,
            product_brand,
            product_color
        order by
            product_number desc
        ) as rn
    from {{ ref('t_raw_go_products') }}
)

select 
    product_number,
    product_line,
    product_type,
    product,
    product_brand,
    product_color,
    unit_cost,
    unit_price
from ranked
where rn = 1
