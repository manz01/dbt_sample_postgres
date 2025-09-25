{% materialization scd2, default %}

  {#---------------------------#
   # Relations & configuration #
   #---------------------------#}
  {% set temp_relation   = make_temp_relation(this) %}

  {# Required configs #}
  {% set surrogate_key = config.get('surrogate_key') %}
  {% set unique_key    = config.get('unique_key') %}

  {# Optional admin columns with defaults #}
  {% set start_ts_col  = config.get('start_ts_col',  'start_ts') %}
  {% set end_ts_col    = config.get('end_ts_col',    'end_ts') %}
  {% set scd2_hash_col = config.get('scd2_hash_col', 'scd2_hash') %}
  {% set version_col   = config.get('version_col',   'version_number') %}
  {% set current_col   = config.get('current_col',   'is_current') %}

  {# Validate required configs #}
  {% if surrogate_key is none %}
    {{ exceptions.raise_compiler_error("Missing required config: surrogate_key") }}
  {% endif %}
  {% if unique_key is none %}
    {{ exceptions.raise_compiler_error("Missing required config: unique_key") }}
  {% endif %}
  {% if unique_key is string %}
    {% set unique_key = [unique_key] %}
  {% endif %}

  {#---------------------------#
   # Timestamp helpers
   #---------------------------#}
  {% set datetime     = modules.datetime %}
  {% set start_ts     = datetime.datetime.now().replace(microsecond=0) %}
  {% set end_ts       = start_ts - datetime.timedelta(seconds=1) %}
  {% set high_date    = '9999-12-31 00:00:00' %}
  {% set fmt          = '%Y-%m-%d %H:%M:%S' %}
  {% set start_ts_str = start_ts.strftime(fmt) %}
  {% set end_ts_str   = end_ts.strftime(fmt) %}

  {#---------------------------#
   # Build temp table from model SQL
   #---------------------------#}
  
  {% call statement('create_temp', fetch_result=False) %}
    {{ create_table_as(False, temp_relation, sql) }}
  {% endcall %}

  {#---------------------------#
   # Check target existence (error if missing)
   #---------------------------#}
  {% set existing = adapter.get_relation(
        database=this.database,
        schema=this.schema,
        identifier=this.identifier) %}

  {% if existing is none %}
    {% call statement('drop_temp_guard', fetch_result=False) %}
      drop table if exists {{ temp_relation }};
    {% endcall %}
    {{ exceptions.raise_compiler_error("SCD2 requires an existing target table: " ~ this ~ ". Create it (with admin columns) before running.") }}
  {% endif %}

  {#---------------------------#
   # Ignore full refresh (always do DML)
   #---------------------------#}
  {% if should_full_refresh() %}
    {{ log("Note: --full-refresh detected but ignored. This SCD2 materialization always performs UPDATE + INSERT against the existing target.", info=True) }}
  {% endif %}

  {#---------------------------#
   # schema checks
   #---------------------------#}
  {% set tgt_cols         = adapter.get_columns_in_relation(this) %}
  {% set tgt_names_lower  = tgt_cols | map(attribute='name') | map('lower') | list %}

  {% set src_cols         = adapter.get_columns_in_relation(temp_relation) %}
  {% set src_names        = src_cols | map(attribute='name') | list %}
  {% set src_names_lower  = src_names | map('lower') | list %}

  {% set required_target = [start_ts_col, end_ts_col, version_col, current_col, scd2_hash_col, surrogate_key] %}
  {% for col in required_target %}
    {% if col | lower not in tgt_names_lower %}
      {% call statement('drop_temp_guard_missing_tgt', fetch_result=False) %}
        drop table if exists {{ temp_relation }};
      {% endcall %}
      {{ exceptions.raise_compiler_error("Target " ~ this ~ " is missing required column '" ~ col ~ "'.") }}
    {% endif %}
  {% endfor %}

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

  {% if scd2_hash_col | lower not in src_names_lower %}
    {% call statement('drop_temp_guard_missing_src_hash', fetch_result=False) %}
      drop table if exists {{ temp_relation }};
    {% endcall %}
    {{ exceptions.raise_compiler_error("Temp (source) is missing scd2 hash column '" ~ scd2_hash_col ~ "'.") }}
  {% endif %}

  {#---------------------------#
   # Column planning for INSERT
   #---------------------------#}
  {% set admin_cols = [start_ts_col, end_ts_col, version_col, current_col, 'prior_' ~ surrogate_key] %}
  {% set tgt_names = tgt_cols | map(attribute='name') | list %}
  {% set insert_cols = [] %}
  {% for c in src_names %}
    {% if c | lower not in admin_cols | map('lower') | list
          and c | lower != surrogate_key | lower
          and c in tgt_names %}
      {% do insert_cols.append(c) %}
    {% endif %}
  {% endfor %}

  {% set insert_cols_csv = insert_cols | join(', \n\t\t\t') %}
  {% set insert_vals     = [] %}
  {% for c in insert_cols %}{% do insert_vals.append('s.' ~ c ) %}{% endfor %}
  {% set insert_vals_csv = insert_vals | join(', \n\t\t\t') %}

  {% set eqs = [] %}
  {% for k in unique_key %}{% do eqs.append('t.' ~ k ~ ' = s.' ~ k) %}{% endfor %}
  {% set join_on = eqs | join(' and ') %}
  
  {#---------------------------#
   # Close off changed current rows
   #---------------------------#}
  {% call statement('close_out', fetch_result=True) %}
  
    select count(0) 
      from {{ temp_relation }} s
      join {{ this }} t
     on {{ join_on }} 
       and t.{{ current_col }} = true
       and t.{{ scd2_hash_col }} <> s.{{ scd2_hash_col }};     
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
     and t.{{ current_col }} = true
    where t.{{ surrogate_key }} is null
       or s.{{ scd2_hash_col }} <> t.{{ scd2_hash_col }};
  {% endcall %}

  {% set res = load_result('insert_rows') %}
  {% set inserted = (res.table.rows[0][0] if res and res.table and res.table.rows else 0) %}


  {#---------------------------#
   # SCD2 DML: Update + Insert
    # This will:
    # 1) Update existing current rows to set them as not current
    # 2) Insert new rows with updated data, setting them as current
    #    and setting the start_ts to now, end_ts to high_date
    #    and version to current + 1 (or 1 if no prior version)
    #    Also, it will set prior_surrogate_key to the previous surrogate_key
    #    for the same unique_key.
    #    This allows tracking of the previous surrogate_key for lineage.
    #    Note: This assumes surrogate_key is unique per row.
   #---------------------------#}
  {% call statement('main', fetch_result=False) %}
   begin;
    insert into {{ this }}
    ( {{ insert_cols_csv }}, 
      {{ start_ts_col }}, 
      {{ end_ts_col }}, 
      {{ version_col }}, 
      {{ current_col }}, 
      prior_{{ surrogate_key }} 
    )
    select
      {{ insert_vals_csv }},
      '{{ start_ts_str }}'::timestamp as {{ start_ts_col }},
      '{{ high_date }}'::timestamp as {{ end_ts_col }},
      coalesce(t.{{ version_col }} + 1, 1) as {{ version_col }},
      true as {{ current_col }},
      coalesce(t.{{ surrogate_key }}, -1) as prior_{{ surrogate_key }}
    from {{ temp_relation }} s
    left join {{ this }} t
      on {{ join_on }}
     and t.{{ current_col }} = true
    where t.{{ surrogate_key }} is null
       or s.{{ scd2_hash_col }} <> t.{{ scd2_hash_col }}
    order by       
    {# if unique_key is a list, join it: #}
    {% if unique_key is sequence %}
      {{ unique_key | join(', ') }}
    {% else %}
      {{ unique_key }}
    {% endif %};

    update {{ this }} t
      set {{ current_col }} = false,
          {{ end_ts_col }}  = '{{ end_ts_str }}'::timestamp
    from {{ temp_relation }} s
    where {{ join_on }}
      and t.{{ current_col }} = true
      and t.{{ scd2_hash_col }} <> s.{{ scd2_hash_col }};     

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
