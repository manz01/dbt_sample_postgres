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
  * Program:        t_stg_go_daily_sales.sql
  * Project:        dbt_sample_postgres
  * Description:    Staging model for GO Sales products daily sales
  * Author:         Manzar Ahmed
  * First Created:  Aug 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-08-06  Manzar Ahmed           v0.01/Initial version
  ************************************************************************
*/

select
    retailer_code,
    product_number,
    order_method_code,
    TO_DATE(transaction_date, 'DD/MM/YYYY')  as transaction_date,
    quantity,
    unit_price,
    unit_sale_price

from {{ ref('t_raw_go_daily_sales') }}



