# BitrixEx

HTTP client make using Tesla for integrating with the Bitrix24 API

This client provides functions to interact with the Bitrix24 API, including methods for making API calls using webhooks or local/standard applications, user authentication, and token management.

## Installation

To use the BitrixEx module, you need to add it to your project's dependencies
and configure it in your application's configuration.

```elixir
def deps do
  [
    {:bitrix_ex, "~> 0.1.0"}
  ]
end
```

## Obtaining access credentials

In your Bitrix24 account, register a new local application.

During the authentication process, the Bitrix server will make a GET request to your application containing the authorization code in the query parameters.

Define an endpoint that your application will use to handle the Bitrix server call.

After registering your application, Bitrix will generate your application ID (client_id) and your secret key (client_secret).

Something like: `http://localhost:4000/callback`.

You can use the `BitrixEx.authorization_url/0` function to get your authorization URL.

In a browser, use the authorization URL. The Bitrix server will redirect the call to your application endpoint.

You will receive an authorization token with 30 seconds validity in the query parameters.

After obtaining your authorization token (client_code), use the `BitrixEx.authenticate/1` function to obtain your access token.

The access token will be used in requests that do not use the webhook.

## BitrixEx Configuration

Before using the module, you need to configure the Bitrix24 API settings
in your application's configuration. This includes specifying the domain,
webhook URL, application URL, client ID, client secret, and OAuth URL.
You can set these values in your application's configuration file or
through environment variables.

Example configuration:

```elixir
# config/config.exs
config :bitrix_ex,
  webhook_url: System.get_env("BITRIX_WEBHOOK_URL"),
  application_url: System.get_env("BITRIX_APPLICATION_URL"),
  client_id: System.get_env("BITRIX_CLIENT_ID"),
  client_secret: System.get_env("BITRIX_CLIENT_SECRET"),
  oauth_url: System.get_env("BITRIX_OAUTH_URL")

# config :bitrix_ex,
#   webhook_url: "https://mydomain.bitrix24.com/rest/1/xxxx",
#   application_url: "https://mydomain.bitrix24.com/rest/", # or just "https://mydomain.bitrix24.com"
#   client_id: "app.xxxxxxxxxxxxxx.xxxxxxxx",
#   client_secret: "xxXXxxxxxxXXXxXxXxXXXxXxxxXxXXXxxxxXXxXXxxXxxXxxxx",
#   oauth_url: "https://oauth.bitrix.info/oauth/token/"
```

## Usage

### Call method using a webhook url

Necessary configuration

```elixir
# config/config.exs
config :bitrix_ex,
  webhook_url: "https://mydomain.bitrix24.com/rest/1/xxxx"
```

```elixir
iex> BitrixEx.call_method("tasks.task.list")
{:ok, %{"result" => %{"tasks" => [...]}}}
```

Passing additional parameters

```elixir
iex> method = "tasks.task.list"
iex> params = %{select: ["ID", "TITLE"], filter: %{"GROUP_ID" => 1}}
iex> BitrixEx.call_method(method, params)
{:ok,
  %{
    "result" => %{
      "tasks" => [
        %{"id" => 1, "title" => "test"},
        %{"id" => 2, "title" => "test2"}
      ]
    }
  }
}
```

### Call method using a standard application url

Necessary configuration

```elixir
# config/config.exs
config :bitrix_ex,
  application_url: "https://mydomain.bitrix24.com/rest/"
  # or just "https://mydomain.bitrix24.com"
```

For this call the access token must be passed in the params

```elixir
iex> access_token = "your_access_token"
iex> BitrixEx.call_method("tasks.task.list", %{auth: access_token})
{:ok, %{"result" => %{"tasks" => [...]}}}
```

Passing additional parameters

```elixir
iex> method = "tasks.task.list"
iex> access_token = "your_access_token"
iex> params = %{auth: access_token, select: ["ID", "NAME"], filter: %{"GROUP_ID" => 1}}
iex> BitrixEx.call_method(method, params)
{:ok, %{"result" => %{"tasks" => [...]}}}
```

### Generate authorization url

- The authorization url can be used to get the authorization code.
- The authorization code can be exchanged for an access token.
- The access token can be used to make API calls.
- The authorization code expires after 30 seconds.

Necessary configuration

```elixir
# config/config.exs
config :bitrix_ex,
  application_url: "https://mydomain.bitrix24.com/rest/",
  client_id: "app.xxxxxxxxxxxxxx.xxxxxxxx"
```

```elixir
iex> redirect_uri = "https://mydomain.com/callback"
iex> BitrixEx.authorization_url(redirect_uri)
"https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&response_type=code"
```

Passing a optional redirect uri

```elixir
iex> redirect_uri = "https://mydomain.com/callback"
iex> BitrixEx.authorization_url(redirect_uri)
"https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&redirect_uri=https%3A%2F%2Fmydomain.com%2Fcallback&response_type=code"
```

### authenticate application and get access token

Necessary configuration

```elixir
config :bitrix_ex,
  oauth_url: "https://oauth.bitrix.info/oauth/token/",
  client_id: "app.xxxxxxxxxxxxxx.xxxxxxxx",
  client_secret: "xxXXxxxxxxXXXxXxXxXXXxXxxxXxXXXxxxxXXxXXxxXxxXxxxx"
```

For this call the authorization code must be passed in the params

```elixir
iex> authorization_code = "your_authorization_code"
iex> BitrixEx.authenticate(authorization_code)
{:ok,
  %{
    "access_token" => "your_access_token",
    "expires_in" => 3600,
    "refresh_token" => "your_refresh_token"
  }
}
```

### Refreshing access token

Necessary configuration

```elixir
config :bitrix_ex,
  oauth_url: "https://oauth.bitrix.info/oauth/token/",
  client_id: "app.xxxxxxxxxxxxxx.xxxxxxxx",
  client_secret: "xxXXxxxxxxXXXxXxXxXXXxXxxxXxXXXxxxxXXxXXxxXxxXxxxx"
```

For this call the refresh token must be passed in the params

```elixir
iex> refresh_token = "your_refresh_token"
iex> BitrixEx.refresh_token(refresh_token)
{:ok,
  %{
    "access_token" => "your_access_token",
    "expires_in" => 3600,
    "refresh_token" => "your_refresh_token"
  }
}
```

## Notes

Bitrix supports the following comparison operations:

- "=" - equal
- "!" - not equal
- "<" - less
- "<=" - less or equal
- ">" - more
- ">=" - more or equal

```elixir
%{filter: %{"GROUP_ID" => 1}} # group_id = 1
%{filter: %{"=GROUP_ID" => 1}} # group_id = 1
%{filter: %{"!=GROUP_ID" => 1}} # group_id != 1
%{filter: %{"<GROUP_ID" => 1}} # group_id < 1
%{filter: %{"<=GROUP_ID" => 1}} # group_id <= 1
%{filter: %{">GROUP_ID" => 1}} # group_id > 1
%{filter: %{">=GROUP_ID" => 1}} # group_id >= 1
```

Each method in Bitrix has its own behavior. For example, a "list" method can bring different fields from a "get" method.

Sometimes one method brings you a Json result with camelCase fields while another brings you one with UPPERCASE.

In some "get" methods you can pass the parameters `%{id: 1}` simply and in other cases `%{ID: 1}` or `%{params: %{id: 1}}`

In some "list" methods you can filter boolean fields as `true` or `false` and in others it will be `"Y"` or `"N"`

```elixir
%{filter: %{"ACTIVE" => true}}
%{filter: %{"ACTIVE" => "Y"}}
%{filter: %{"ACTIVE" => false}}
%{filter: %{"ACTIVE" => "N"}}
```

Likewise, not all methods support all of the Boolean filters listed above.

It is very important that you evaluate each case and develop ways to normalize the data.

Você pode ver os métodos disponíveis da documentação da API

[Bitrix24 REST API (Documentation)](https://training.bitrix24.com/rest_help/index.php)
