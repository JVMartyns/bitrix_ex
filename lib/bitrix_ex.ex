defmodule BitrixEx do
  @moduledoc """
  HTTP client make using Tesla for integrating with the Bitrix24 API
  """

  @client Tesla.client([
            Tesla.Middleware.JSON,
            Tesla.Middleware.FollowRedirects,
            Tesla.Middleware.Telemetry
          ])

  @doc """
  Call method using a webhook url

      config :bitrix_ex,
        webhook_url: "https://mydomain.bitrix24.com/rest/1/xxxx"

  ## Examples

      iex> BitrixEx.call_method("tasks.task.list")
      {:ok, %{"result" => %{"tasks" => []}}}
  """
  @spec call_method(method :: String.t()) :: {:ok, map()} | {:error, any()}
  def call_method(method), do: call_method(method, %{}, [])

  @doc """
  Call method using a webhook url

  ## Examples

      config :bitrix_ex,
        webhook_url: "https://mydomain.bitrix24.com/rest/1/xxxx"

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

  Call method using a local or standard application

  ## Examples

      config :bitrix_ex,
        application_url: "https://mydomain.bitrix24.com/rest/",
        # or just "https://mydomain.bitrix24.com"

  for this call the access token must be passed in the params

      iex> access_token = "your_access_token"
      iex> BitrixEx.call_method("tasks.task.list", %{auth: access_token})
      {:ok, %{"result" => %{"tasks" => []}}}
  """
  @spec call_method(
          method :: String.t(),
          params :: map()
        ) :: {:ok, map()} | {:error, any()}
  def call_method(method, params) do
    call_method(method, params, [])
  end

  @doc """
  Similar to the previous ones, but it has the additional parameter `opts`
  for using Tesla resources.
  """
  @spec call_method(
          method :: String.t(),
          params :: map(),
          opts :: keyword()
        ) :: {:ok, map()} | {:error, any()}
  def call_method(method, %{auth: _access_token} = params, opts) do
    url =
      application_url()
      |> URI.parse()
      |> URI.append_path("/rest/" <> method <> ".json")
      |> URI.append_query(encode_query(params))
      |> URI.to_string()

    @client
    |> Tesla.get(url, opts)
    |> handle_response()
  end

  def call_method(method, params, opts) do
    url =
      webhook_url()
      |> URI.parse()
      |> URI.append_path("/" <> method <> ".json")
      |> URI.append_query(encode_query(params))
      |> URI.to_string()

    @client
    |> Tesla.get(url, opts)
    |> handle_response()
  end

  @doc """
  Generate authorization url

  ## Examples

      iex> BitrixEx.authorization_url()
      "https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&response_type=code"

  additionally you can add a redirect uri

      iex> redirect_uri = "https://mydomain.com/callback"
      iex> BitrixEx.authorization_url(redirect_uri)
      "https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&redirect_uri=https%3A%2F%2Fmydomain.com%2Fcallback&response_type=code"
  """
  @spec authorization_url(redirect_uri :: String.t()) :: String.t()
  def authorization_url(redirect_uri \\ "") do
    redirect = if redirect_uri != "", do: %{redirect_uri: redirect_uri}, else: %{}
    params = Map.merge(%{response_type: "code", client_id: client_id()}, redirect)

    application_url()
    |> URI.parse()
    |> URI.merge("/oauth/authorize/")
    |> URI.append_query(encode_query(params))
    |> URI.to_string()
  end

  @doc "authenticate application add get access token"
  @spec authenticate(
          client_code :: String.t(),
          opts :: keyword()
        ) :: {:ok, map()} | {:error, any()}
  def authenticate(client_code, opts \\ []) do
    params = %{
      grant_type: "authorization_code",
      client_id: client_id(),
      client_secret: client_secret(),
      code: client_code
    }

    url =
      oauth_url()
      |> URI.parse()
      |> URI.append_query(encode_query(params))
      |> URI.to_string()

    @client
    |> Tesla.get(url, opts)
    |> handle_response()
  end

  @doc "use refresh token to get a new access token"
  @spec refresh_token(
          refresh_token :: String.t(),
          opts :: keyword()
        ) :: {:ok, map()} | {:error, any()}
  def refresh_token(refresh_token, opts \\ []) do
    params = %{
      grant_type: "refresh_token",
      client_id: client_id(),
      client_secret: client_secret(),
      refresh_token: refresh_token
    }

    url =
      oauth_url()
      |> URI.parse()
      |> URI.append_query(encode_query(params))
      |> URI.to_string()

    @client
    |> Tesla.get(url, opts)
    |> handle_response()
  end

  @spec oauth_url() :: binary()
  def oauth_url, do: Application.fetch_env!(:bitrix_ex, :oauth_url)

  @spec webhook_url() :: binary()
  def webhook_url, do: Application.fetch_env!(:bitrix_ex, :webhook_url)

  @spec application_url() :: binary()
  def application_url, do: Application.fetch_env!(:bitrix_ex, :application_url)

  @spec client_id() :: binary()
  def client_id, do: Application.fetch_env!(:bitrix_ex, :client_id)

  @spec client_secret() :: binary()
  def client_secret, do: Application.fetch_env!(:bitrix_ex, :client_secret)

  defp handle_response({:ok, %Tesla.Env{body: %{"error" => _error} = body}}), do: {:error, body}
  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}), do: {:ok, body}
  defp handle_response({:ok, %Tesla.Env{body: body}}), do: {:error, body}
  defp handle_response({:error, error}), do: {:error, error}

  defp encode_query(query) do
    query
    |> Enum.flat_map(&encode_pair/1)
    |> URI.encode_query()
  end

  defp encode_pair({key, value}) when is_map(value) do
    encode_pair({key, Enum.map(value, fn {k, v} -> {k, v} end)})
  end

  defp encode_pair({key, value}) when is_list(value) do
    if list_of_tuples?(value) do
      Enum.flat_map(value, fn {k, v} -> encode_pair({"#{key}[#{k}]", v}) end)
    else
      Enum.map(value, fn e -> {"#{key}[#{index_of(value, e)}]", e} end)
    end
  end

  defp encode_pair({key, value}), do: [{key, value}]

  defp list_of_tuples?([{k, _} | rest]) when is_atom(k) or is_binary(k), do: list_of_tuples?(rest)
  defp list_of_tuples?([]), do: true
  defp list_of_tuples?(_other), do: false
  defp index_of(enum, term), do: Enum.find_index(enum, &(&1 == term))
end
