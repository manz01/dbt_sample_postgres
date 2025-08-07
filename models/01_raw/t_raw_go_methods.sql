/*------------------------------------------------------------------------------
Program:        t_raw_go_methods.sql
Project:        dbt_sample_postgres
Description:    Raw data model for go methods
Input(s):       /warehouse/rawdata/go_sales/go_methods.csv
Output(s):      raw.t_raw_go_methods
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
    csv_path = '/warehouse/rawdata/gosales/go_methods.csv',
    columns = '
        order_method_code BIGINT,
        order_method_type TEXT
    '
) }}

