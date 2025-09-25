{% materialization copy_to_postgres, default %}
  {%- set existing_relation = load_cached_relation(this) -%}
  {%- set target_relation = this.incorporate(type='table') -%}
  {%- set intermediate_relation = make_intermediate_relation(target_relation) -%}
  {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}
  {%- set backup_relation_type = 'table' if existing_relation is none else existing_relation.type -%}
  {%- set backup_relation = make_backup_relation(target_relation, backup_relation_type) -%}
  {%- set preexisting_backup_relation = load_cached_relation(backup_relation) -%}
  {% set grant_config = config.get('grants') %}

  -- Drop intermediate & backup if they exist
  {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
  {{ drop_relation_if_exists(preexisting_backup_relation) }}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- Get user-defined configs
  {% set columns = config.get('columns') %}
  {% set csv_path = config.get('csv_path') %}
  {% if not columns or not csv_path %}
    {% do exceptions.raise_compiler_error("Both 'columns' and 'csv_path' must be set in config()") %}
  {% endif %}

  -- Create the intermediate table
  {% call statement('create_table', fetch_result=False) %}
    CREATE TABLE {{ intermediate_relation }}
    (
        {{ columns }}
    );
  {% endcall %}

  -- Load CSV using COPY
  {% call statement('copy_data', fetch_result=False) %}
    COPY {{ intermediate_relation }}
    FROM '{{ csv_path }}'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
  {% endcall %}

  -- Create indexes if defined
  {% do create_indexes(intermediate_relation) %}

  -- Backup the existing target table
  {% if existing_relation is not none %}
    {% set existing_relation = load_cached_relation(existing_relation) %}
    {% if existing_relation is not none %}
      {{ adapter.rename_relation(existing_relation, backup_relation) }}
    {% endif %}
  {% endif %}

  -- Promote intermediate to target
  {{ adapter.rename_relation(intermediate_relation, target_relation) }}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}
  {% do persist_docs(target_relation, model) %}

  {{ adapter.commit() }}

  -- Drop backup table
  {{ drop_relation_if_exists(backup_relation) }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  -- Required dummy 'main' block to satisfy dbt
  {% call statement('main', fetch_result=False) %}
    select 1;
  {% endcall %}

  {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}
