/*------------------------------------------------------------------------------
Program:        t_raw_go_products.sql
Project:        dbt_sample_postgres
Description:    Raw data model for go products
Input(s):       /warehouse/rawdata/go_sales/go_products.csv
Output(s):      raw.t_raw_go_products
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
    csv_path = '/warehouse/rawdata/gosales/go_products.csv',
    columns = '
        product_number BIGINT,
        product_line TEXT,
        product_type TEXT,
        product TEXT,
        product_brand TEXT,
        product_color TEXT,
        unit_cost DOUBLE PRECISION,
        unit_price DOUBLE PRECISION
    '
) }}
