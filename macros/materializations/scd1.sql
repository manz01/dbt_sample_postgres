{% materialization scd1, default %}

  {#---------------------------#
   # Config & relations
   #---------------------------#}
  {% set temp_relation         = make_temp_relation(this) %}

  {% set unique_key            = config.get('unique_key') %}
  {% set surrogate_key         = config.get('surrogate_key') %}
  {% set scd_hash_col          = config.get('scd_hash_col', 'scd_hash') %}
  {% set create_ts_col         = config.get('create_ts_col', 'create_ts') %}
  {% set update_ts_col         = config.get('update_ts_col', 'update_ts') %}
  {% set skip_surrogate_insert = config.get('skip_surrogate_on_insert', true) %}

  {% if unique_key is none %}
    {{ exceptions.raise_compiler_error("Missing required config: unique_key") }}
  {% endif %}
  {% if unique_key is string %}
    {% set unique_key = [unique_key] %}
  {% endif %}

  {#---------------------------#
   # Timestamp helper
   #---------------------------#}
  {% set datetime = modules.datetime %}
  {% set fmt = '%Y-%m-%d %H:%M:%S' %}
  {% set now_ts = datetime.datetime.now().replace(microsecond=0).strftime(fmt) %}

  {#---------------------------#
   # Build temp table from model SQL
   #---------------------------#}

  {% call statement('create_temp', fetch_result=False) %}
    {{ create_table_as(False, temp_relation, sql) }}
  {% endcall %}

  {#---------------------------#
   # Target existence
   #---------------------------#}
  {% set existing = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) %}
  {% if existing is none %}
    {% call statement('drop_temp_guard', fetch_result=False) %}
      drop table if exists {{ temp_relation }};
    {% endcall %}
    {{ exceptions.raise_compiler_error("SCD1 requires an existing target table: " ~ this ~ ". Create it first (including admin columns).") }}
  {% endif %}

  {% if should_full_refresh() %}
    {{ log("Note: --full-refresh ignored. SCD1 performs UPDATE + INSERT only.", info=True) }}
  {% endif %}

  {#---------------------------#
   # Introspect columns
   #---------------------------#}
  {% set tgt_cols         = adapter.get_columns_in_relation(this) %}
  {% set tgt_names        = tgt_cols | map(attribute='name') | list %}
  {% set tgt_names_lower  = tgt_cols | map(attribute='name') | map('lower') | list %}

  {% set src_cols         = adapter.get_columns_in_relation(temp_relation) %}
  {% set src_names        = src_cols | map(attribute='name') | list %}
  {% set src_names_lower  = src_cols | map(attribute='name') | map('lower') | list %}

  {# required columns in target #}
  {% set required_in_target = [create_ts_col, update_ts_col, scd_hash_col] %}
  {% for col in required_in_target %}
    {% if col | lower not in tgt_names_lower %}
      {% call statement('drop_temp_guard_missing_tgt', fetch_result=False) %}
        drop table if exists {{ temp_relation }};
      {% endcall %}
      {{ exceptions.raise_compiler_error("Target " ~ this ~ " is missing required column '" ~ col ~ "'.") }}
    {% endif %}
  {% endfor %}

  {# unique keys in both sides #}
  {% for k in unique_key %}
    {% if k | lower not in src_names_lower %}
      {% call statement('drop_temp_guard_missing_src_key', fetch_result=False) %}
        drop table if exists {{ temp_relation }};
      {% endcall %}
      {{ exceptions.raise_compiler_error("Temp (source) is missing unique_key column '" ~ k ~ "'.") }}
    {% endif %}
    {% if k | lower not in tgt_names_lower %}
      {% call statement('drop_temp_guard_missing_tgt_key', fetch_result=False) %}
        drop table if exists {{ temp_relation }};
      {% endcall %}
      {{ exceptions.raise_compiler_error("Target is missing unique_key column '" ~ k ~ "'.") }}
    {% endif %}
  {% endfor %}

  {# ensure scd_hash exists in source #}
  {% if scd_hash_col | lower not in src_names_lower %}
    {% call statement('drop_temp_guard_missing_src_hash', fetch_result=False) %}
      drop table if exists {{ temp_relation }};
    {% endcall %}
    {{ exceptions.raise_compiler_error("Temp (source) is missing scd hash column '" ~ scd_hash_col ~ "'.") }}
  {% endif %}

  {#---------------------------#
   # Plan SET (update) and INSERT cols
   #---------------------------#}
  {% set do_not_set = unique_key + [create_ts_col, update_ts_col] %}
  {% if surrogate_key and skip_surrogate_insert %}
    {% set do_not_set = do_not_set + [surrogate_key] %}
  {% endif %}

  {% set updatable_cols = [] %}
  {% for c in src_names %}
    {% if c in tgt_names and c | lower not in (do_not_set | map('lower') | list) %}
      {% do updatable_cols.append(c) %}
    {% endif %}
  {% endfor %}

  {% set insert_cols = [] %}
  {% for c in src_names %}
    {% if c in tgt_names and (not (surrogate_key and skip_surrogate_insert and c | lower == surrogate_key | lower)) %}
      {% do insert_cols.append(c) %}
    {% endif %}
  {% endfor %}
  {% set insert_cols = insert_cols + [create_ts_col, update_ts_col] %}

  {# Quote helpers #}
  {% set updates = [] %}
  {% for c in updatable_cols %}
    {% do updates.append('"' ~ c ~ '" = s."' ~ c ~ '"') %}
  {% endfor %}
  {% set updates_csv = updates | join(',\n         ') %}

  {% set insert_cols_quoted = [] %}
  {% for c in insert_cols %}
    {% do insert_cols_quoted.append('"' ~ c ~ '"') %}
  {% endfor %}
  {% set insert_cols_csv = insert_cols_quoted | join(', ') %}

  {% set insert_vals = [] %}
  {% for c in insert_cols %}
    {% if c == create_ts_col %}
      {% do insert_vals.append("'" ~ now_ts ~ "'::timestamp") %}
    {% elif c == update_ts_col %}
      {% do insert_vals.append("'1900-01-01 00:00:00'::timestamp") %}
    {% else %}
      {% do insert_vals.append('s."' ~ c ~ '"') %}
    {% endif %}
  {% endfor %}
  {% set insert_vals_csv = insert_vals | join(', ') %}

  {% set eqs = [] %}
  {% for k in unique_key %}
    {% do eqs.append('t."' ~ k ~ '" = s."' ~ k ~ '"') %}
  {% endfor %}
  {% set join_on = eqs | join(' and ') %}
  {% set first_key = unique_key[0] %}

  {{ log('SCD1 join_on: ' ~ join_on, info=True) }}

  {# Null-safe change predicate: always require scd_hash to differ #}
  {% set change_predicate -%}
    {%- if target.type in ['postgres', 'redshift', 'duckdb'] -%}
      t."{{ scd_hash_col }}" is distinct from s."{{ scd_hash_col }}"
    {%- else -%}
      coalesce(t."{{ scd_hash_col }}",'') <> coalesce(s."{{ scd_hash_col }}",'')
    {%- endif -%}
  {%- endset %}

  {#---------------------------#
   # Close off changed current rows
   #---------------------------#}
  {% call statement('close_out', fetch_result=True) %}
  
  select count(0)
      from {{ temp_relation }} as s, {{ this }} as t
     where {{ join_on }}
       and ( {{ change_predicate }} );   
  {% endcall %}

  {% set res = load_result('close_out') %}
  {% set updated = (res.table.rows[0][0] if res and res.table and res.table.rows else 0) %}


  {#---------------------------#
   # Insert rows
   #---------------------------#}
  {% call statement('insert_rows', fetch_result=True) %}
  
    select count(0) 
    from {{ temp_relation }} s
    left join {{ this }} t
        on {{ join_on }}
     where t."{{ first_key }}" is null;
  {% endcall %}

  {% set res = load_result('insert_rows') %}
  {% set inserted = (res.table.rows[0][0] if res and res.table and res.table.rows else 0) %}  

  {#---------------------------#
   # DML
   #---------------------------#}
  {% call statement('main', fetch_result=False) %}
  begin;

    /* 1) UPDATE existing rows — only when scd_hash changed */
    update {{ this }} as t
       set
         {{ updates_csv }},
         "{{ update_ts_col }}" = '{{ now_ts }}'::timestamp
      from {{ temp_relation }} as s
     where {{ join_on }}
       and ( {{ change_predicate }} );

    /* 2) INSERT new rows */
    insert into {{ this }} ( {{ insert_cols_csv }} )
    select {{ insert_vals_csv }}
      from {{ temp_relation }} s
 left join {{ this }} t
        on {{ join_on }}
     where t."{{ first_key }}" is null
     order by s."{{ first_key }}";

  commit;
  {% endcall %}

 {{ log('NOTE: Updated ' ~ updated ~ ' row(s) into ' ~ this, info=True) }}

 {{ log('NOTE: Inserted ' ~ inserted ~ ' row(s) into ' ~ this, info=True) }}

  {#---------------------------#
   # Cleanup temp
   #---------------------------#}
  {% call statement('drop_temp', fetch_result=False) %}
    drop table if exists {{ temp_relation }};
  {% endcall %}

  {{ return({'relations': [this]}) }}

{% endmaterialization %}
