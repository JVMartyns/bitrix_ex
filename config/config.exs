import Config

config :bitrix_ex,
  webhook_url: System.get_env("BITRIX_WEBHOOK_URL"),
  application_url: System.get_env("BITRIX_APPLICATION_URL"),
  client_id: System.get_env("BITRIX_CLIENT_ID"),
  client_secret: System.get_env("BITRIX_CLIENT_SECRET"),
  oauth_url: System.get_env("BITRIX_OAUTH_URL")

config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
