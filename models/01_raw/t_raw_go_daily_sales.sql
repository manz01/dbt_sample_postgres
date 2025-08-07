/*------------------------------------------------------------------------------
Program:        t_raw_go_daily_sales.sql
Project:        dbt_sample_postgres
Description:    Raw data model for go daily sales
Input(s):       /warehouse/rawdata/go_sales/go_daily_sales.csv
Output(s):      raw.t_raw_go_daily_sales
Author:         Manzar Ahmed
First Created:  Aug 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-08-06  Manzar Ahmed           v0.01/Initial version
------------------------------------------------------------------------------*/
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

