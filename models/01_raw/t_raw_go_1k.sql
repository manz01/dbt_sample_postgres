/*------------------------------------------------------------------------------
Program:        t_raw_go_1k.sql
Project:        dbt_sample_postgres
Description:    Raw data model for go sales 1k transactions            
Input(s):       /warehouse/rawdata/go_sales/go_1k.csv
Output(s):      raw.t_raw_go_1k
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
    csv_path = '/warehouse/rawdata/gosales/go_1k.csv',
    columns = '
        retailer_code BIGINT,
        product_number BIGINT,
        transaction_date TEXT,
        quantity INTEGER
    '
) }}

