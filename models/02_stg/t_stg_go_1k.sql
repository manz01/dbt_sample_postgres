/*------------------------------------------------------------------------------
Program:        t_stg_go_1k.sql
Project:        dbt_sample_postgres
Description:    Staging model for GO Sales products transactions
                 with raw data from source
Input(s):       raw.t_raw_go_1k
Output(s):      stg.t_stg_go_1k
Author:         Manzar Ahmed
First Created:  Aug 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-08-06  Manzar Ahmed           v0.01/Initial version
------------------------------------------------------------------------------*/

select
    retailer_code,
    product_number,
    TO_DATE(transaction_date, 'DD/MM/YYYY') as transaction_date,
    quantity

from {{ ref('t_raw_go_1k') }}
