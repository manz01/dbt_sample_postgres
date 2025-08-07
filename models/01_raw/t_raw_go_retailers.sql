/*------------------------------------------------------------------------------
Program:        t_raw_go_retailers.sql
Project:        dbt_sample_postgres
Description:    Raw data model for go products
Input(s):       /warehouse/rawdata/go_sales/go_retailers.csv
Output(s):      raw.t_raw_go_retailers
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
    csv_path = '/warehouse/rawdata/gosales/go_retailers.csv',
    columns = '
        retailer_code BIGINT,
        retailer_name TEXT,
        retailer_type TEXT,  
        country TEXT    
    '
) }}

