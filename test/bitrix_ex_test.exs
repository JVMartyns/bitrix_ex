defmodule BitrixExTest do
  use ExUnit.Case, async: true
  doctest BitrixEx

  @tasks_empty %{"result" => %{"tasks" => []}}
  @tasks [
    %{"id" => 1, "title" => "test", "parentId" => 0, "groupId" => 1},
    %{"id" => 2, "title" => "test2", "parentId" => 0, "groupId" => 1}
  ]

  setup do
    mock_fn = fn
      %{
        method: :get,
        url: "https://mydomain.bitrix24.com/rest/1/xxxx/tasks.task.list.json?"
      } ->
        %Tesla.Env{status: 200, body: @tasks_empty}

      %{
        method: :get,
        url: "https://mydomain.bitrix24.com/rest/rest/tasks.task.list.json?auth=your_access_token"
      } ->
        %Tesla.Env{status: 200, body: @tasks_empty}

      %{
        method: :get,
        url:
          "https://mydomain.bitrix24.com/rest/1/xxxx/tasks.task.list.json?select%5B0%5D=ID&select%5B1%5D=TITLE&filter%5BGROUP_ID%5D=1"
      } ->
        body = %{
          "result" => %{
            "tasks" =>
              Enum.map(@tasks, fn task -> %{"id" => task["id"], "title" => task["title"]} end)
          }
        }

        %Tesla.Env{status: 200, body: body}
    end

    Tesla.Mock.mock(mock_fn)

    :ok
  end

  describe "call_method" do
    test "call method using a webhook url" do
      assert BitrixEx.call_method("tasks.task.list") == {:ok, %{"result" => %{"tasks" => []}}}
    end

    test "call method using a webhook url with params" do
      body = %{
        "result" => %{
          "tasks" => [
            %{"id" => 1, "title" => "test", "parentId" => 0, "groupId" => 1},
            %{"id" => 2, "title" => "test2", "parentId" => 0, "groupId" => 1}
          ]
        }
      }

      Tesla.Mock.mock(fn %{method: :get} = env ->
        assert env.url =~ "/rest/1/xxxx/tasks.task.list.json"
        assert env.url =~ URI.encode_query(%{"select[0]" => "ID"})
        assert env.url =~ URI.encode_query(%{"select[1]" => "TITLE"})
        assert env.url =~ URI.encode_query(%{"select[2]" => "PARENT_ID"})
        assert env.url =~ URI.encode_query(%{"select[3]" => "GROUP_ID"})
        assert env.url =~ URI.encode_query(%{"filter[PARTNER_ID]" => 0})
        assert env.url =~ URI.encode_query(%{"filter[GROUP_ID]" => 1})

        %Tesla.Env{status: 200, body: body}
      end)

      params = %{
        select: ["ID", "TITLE", "PARENT_ID", "GROUP_ID"],
        filter: %{"PARTNER_ID" => 0, "GROUP_ID" => 1}
      }

      assert BitrixEx.call_method("tasks.task.list", params) == {:ok, body}
    end

    test "call method using a application url" do
      Tesla.Mock.mock(fn %{method: :get} = env ->
        assert env.url =~ "/rest/tasks.task.list.json"
        assert env.url =~ URI.encode_query(%{auth: "my_access_token"})

        body = %{"result" => %{"tasks" => []}}

        %Tesla.Env{status: 200, body: body}
      end)

      {:ok, body} = BitrixEx.call_method("tasks.task.list", %{auth: "my_access_token"})

      assert body == %{"result" => %{"tasks" => []}}
    end

    test "call method using a application url with params" do
      body = %{
        "result" => %{
          "tasks" => [
            %{"id" => 1, "title" => "test", "parentId" => 0, "groupId" => 1},
            %{"id" => 2, "title" => "test2", "parentId" => 0, "groupId" => 1}
          ]
        }
      }

      Tesla.Mock.mock(fn %{method: :get} = env ->
        assert env.url =~ "/rest/tasks.task.list.json"
        assert env.url =~ URI.encode_query(%{auth: "my_access_token"})
        assert env.url =~ URI.encode_query(%{"select[0]" => "ID"})
        assert env.url =~ URI.encode_query(%{"select[1]" => "TITLE"})
        assert env.url =~ URI.encode_query(%{"select[2]" => "PARENT_ID"})
        assert env.url =~ URI.encode_query(%{"select[3]" => "GROUP_ID"})
        assert env.url =~ URI.encode_query(%{"filter[PARTNER_ID]" => 0})
        assert env.url =~ URI.encode_query(%{"filter[GROUP_ID]" => 1})

        %Tesla.Env{status: 200, body: body}
      end)

      params = %{
        auth: "my_access_token",
        select: ["ID", "TITLE", "PARENT_ID", "GROUP_ID"],
        filter: %{"PARTNER_ID" => 0, "GROUP_ID" => 1}
      }

      assert BitrixEx.call_method("tasks.task.list", params) == {:ok, body}
    end

    test "call unsupported method" do
      body = %{"error" => "ERROR_METHOD_NOT_FOUND", "error_description" => "Method not found!"}

      Tesla.Mock.mock(fn %{method: :get} = env ->
        assert env.url =~ "/rest/1/xxxx/unsupported.method.json"

        %Tesla.Env{status: 200, body: body}
      end)

      assert BitrixEx.call_method("unsupported.method") == {:error, body}
    end

    test "connection error" do
      Tesla.Mock.mock(fn %{method: :get} ->
        {:error, :econnrefused}
      end)

      assert BitrixEx.call_method("tasks.task.list") == {:error, :econnrefused}
    end

    test "when response is ok but an error has been returned" do
      body =
        "<html>\r\n<head><title>404 Not Found</title></head>\r\n<body>\r\n<center><h1>404 Not Found</h1></center>\r\n<hr><center>nginx</center>\r\n</body>\r\n</html>\r\n"

      Tesla.Mock.mock(fn %{method: :get} ->
        %Tesla.Env{status: 404, body: body}
      end)

      assert BitrixEx.call_method("tasks.task.list") == {:error, body}
    end
  end

  describe "authorization_url" do
    test "get authorization url" do
      assert BitrixEx.authorization_url() ==
               "https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&response_type=code"

      redirect_uri = "https://mydomain.bitrix24.com/callback"

      assert BitrixEx.authorization_url(redirect_uri) ==
               "https://mydomain.bitrix24.com/oauth/authorize/?client_id=app.xxxxxxxxxxxxxx.xxxxxxxx&redirect_uri=https%3A%2F%2Fmydomain.bitrix24.com%2Fcallback&response_type=code"
    end
  end

  describe "client_id" do
    setup do
      current = Application.get_env(:bitrix_ex, :client_id)

      on_exit(fn -> Application.put_env(:bitrix_ex, :client_id, current) end)
    end

    test "get client id" do
      current = Application.get_env(:bitrix_ex, :client_id)
      assert BitrixEx.client_id() == current
    end

    test "raise error when client id is not set" do
      Application.delete_env(:bitrix_ex, :client_id)

      assert_raise ArgumentError, fn -> BitrixEx.client_id() end
    end
  end

  describe "client_secret" do
    setup do
      current = Application.get_env(:bitrix_ex, :client_secret)

      on_exit(fn -> Application.put_env(:bitrix_ex, :client_secret, current) end)
    end

    test "get client secret" do
      current = Application.get_env(:bitrix_ex, :client_secret)
      assert BitrixEx.client_secret() == current
    end

    test "raise error when client secret is not set" do
      Application.delete_env(:bitrix_ex, :client_secret)

      assert_raise ArgumentError, fn -> BitrixEx.client_secret() end
    end
  end

  describe "oauth_url" do
    setup do
      current = Application.get_env(:bitrix_ex, :oauth_url)

      on_exit(fn -> Application.put_env(:bitrix_ex, :oauth_url, current) end)
    end

    test "get oauth url" do
      current = Application.get_env(:bitrix_ex, :oauth_url)
      assert BitrixEx.oauth_url() == current
    end

    test "raise error when oauth url is not set" do
      Application.delete_env(:bitrix_ex, :oauth_url)

      assert_raise ArgumentError, fn -> BitrixEx.oauth_url() end
    end
  end

  describe "authenticate" do
    test "authenticate" do
      client_code = "my_client_code"
      client_id = Application.get_env(:bitrix_ex, :client_id)
      client_secret = Application.get_env(:bitrix_ex, :client_secret)

      body = %{
        "access_token" => "my_access_token",
        "expires_in" => 3600,
        "refresh_token" => "my_refresh_token"
      }

      Tesla.Mock.mock(fn %{method: :get, url: url} ->
        assert url =~ "https://oauth.bitrix.info/oauth/token/"
        assert url =~ URI.encode_query(%{client_id: client_id})
        assert url =~ URI.encode_query(%{client_secret: client_secret})
        assert url =~ URI.encode_query(%{grant_type: "authorization_code"})
        assert url =~ URI.encode_query(%{code: client_code})

        %Tesla.Env{status: 200, body: body}
      end)

      assert BitrixEx.authenticate(client_code) == {:ok, body}
    end
  end

  describe "refresh_token" do
    test "refresh token" do
      refresh_token = "my_refresh_token"
      client_id = Application.get_env(:bitrix_ex, :client_id)
      client_secret = Application.get_env(:bitrix_ex, :client_secret)

      body = %{
        "access_token" => "my_access_token",
        "expires_in" => 3600,
        "refresh_token" => "my_refresh_token"
      }

      Tesla.Mock.mock(fn %{method: :get, url: url} ->
        assert url =~ "https://oauth.bitrix.info/oauth/token/"
        assert url =~ URI.encode_query(%{client_id: client_id})
        assert url =~ URI.encode_query(%{client_secret: client_secret})
        assert url =~ URI.encode_query(%{grant_type: "refresh_token"})
        assert url =~ URI.encode_query(%{refresh_token: refresh_token})

        %Tesla.Env{status: 200, body: body}
      end)

      assert BitrixEx.refresh_token(refresh_token) == {:ok, body}
    end
  end

  describe "webhook_url" do
    setup do
      current = Application.get_env(:bitrix_ex, :webhook_url)

      on_exit(fn -> Application.put_env(:bitrix_ex, :webhook_url, current) end)
    end

    test "get webhook url" do
      current = Application.get_env(:bitrix_ex, :webhook_url)
      assert BitrixEx.webhook_url() == current
    end

    test "raise error when webhook url is not set" do
      Application.delete_env(:bitrix_ex, :webhook_url)

      assert_raise ArgumentError, fn -> BitrixEx.webhook_url() end
    end
  end

  describe "application_url" do
    setup do
      current = Application.get_env(:bitrix_ex, :application_url)

      on_exit(fn -> Application.put_env(:bitrix_ex, :application_url, current) end)
    end

    test "get application url" do
      current = Application.get_env(:bitrix_ex, :application_url)

      assert BitrixEx.application_url() == current
    end

    test "raise error when application url is not set" do
      Application.delete_env(:bitrix_ex, :application_url)

      assert_raise ArgumentError, fn -> BitrixEx.application_url() end
    end
  end
end
