import Config

config :bitrix_ex,
  webhook_url: "https://mydomain.bitrix24.com/rest/1/xxxx",
  application_url: "https://mydomain.bitrix24.com/rest/",
  client_id: "app.xxxxxxxxxxxxxx.xxxxxxxx",
  client_secret: "xxXXxxxxxxXXXxXxXxXXXxXxxxXxXXXxxxxXXxXXxxXxxXxxxx",
  oauth_url: "https://oauth.bitrix.info/oauth/token/"

config :tesla,
  adapter: Tesla.Mock
