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
  * Path:           models/01_raw
  * Program:        t_raw_go_daily_sales.sql
  * Project:        dbt_sample_postgres
  * Description:    Raw data model for go daily sales
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

{{ config(
    materialized = 'copy_to_postgres',
    csv_path = '/warehouse/rawdata/gosales/go_daily_sales.csv',
    columns = '
        retailer_code BIGINT,
        product_number BIGINT,
        order_method_code BIGINT,
        transaction_date TEXT,
        quantity INTEGER,
        unit_price DOUBLE PRECISION,
        unit_sale_price DOUBLE PRECISION
    '
) }}

