locals {
  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
    [
      {
        "name": "LOG_LEVEL",
        "value": "debug,info"
      },
      {
        "name": "NUM_HISTORY_SHARDS",
        "value": "128"
      },
      {
        "name": "DB",
        "value": "postgresql"
      },
      {
        "name": "POSTGRES_HOST",
        "value": module.temporal_aurora_rds.cluster_endpoint
      },
      {
        "name": "POSTGRES_PORT",
        "value": tostring(module.temporal_aurora_rds.cluster_port)
      },
      {
        "name": "POSTGRES_USER",
        "value": var.temporal_aurora_username
      },
      {
        "name": "POSTGRES_PASSWORD",
        "value": random_string.temporal_aurora_password.result
      },
      {
        "name": "DBNAME",
        "value": "temporal"
      },
      {
        "name": "DBNAME_VISIBILITY",
        "value": "temporal_visibility"
      },
      {
        "name": "DYNAMIC_CONFIG_FILE_PATH",
        "value": "/etc/temporal/ecs/dynamic_config/dynamicconfig-sql.yaml"
      },
      {
        "name": "ECS_DEPLOYED",
        "value": "true"
      }
    ]
  )
}