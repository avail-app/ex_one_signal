defmodule ExOneSignalTest do
  use ExUnit.Case
  import ExOneSignal.Notification
  alias ExOneSignal.Notification

  @notification_path "/api/v1/notifications"

  setup do
    bypass = Bypass.open
    client = ExOneSignal.new(base_url: "localhost:#{bypass.port}")
    notification =
      Notification.new
      |> set_title("Title")
      |> set_body("Body")
      |> add_players(["abc123", "def456"])
      |> add_data(:url, "https://example.com")

    {:ok, bypass: bypass, client: client, notification: notification}
  end

  describe "send/1" do
    test "can send a notification to OneSignal", %{bypass: bypass, client: client, notification: notification} do
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        {:ok, body, _} = Plug.Conn.read_body(conn)
        body = Poison.decode!(body)

        assert body["headings"] == %{"en" => "Title"}
        assert body["contents"] == %{"en" => "Body"}
        assert body["include_player_ids"] == ["abc123", "def456"]
        assert body["data"] == %{"url" => "https://example.com"}

        Plug.Conn.resp(conn, 200, "{\"recipients\": 5}")
      end

      assert {:ok, _body} = ExOneSignal.send(client, notification)
    end

    test "will receive a decoded response body when the connection returns a successful code", %{bypass: bypass, client: client} do
      response_body =
        %{
          "errors" => ["An error"],
          "id" => "",
          "recipients" => 4
        }
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        Plug.Conn.resp(conn, 200, Poison.encode!(response_body))
      end

      assert {:ok, ^response_body} = ExOneSignal.send(client, Notification.new)
    end

    test "when an invalid status code is returned, the response errors are returned", %{bypass: bypass, client: client} do
      errors = ["The errors"]

      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        Plug.Conn.resp(conn, 400, Poison.encode!(%{errors: errors}))
      end

      assert {:error, ^errors} = ExOneSignal.send(client, Notification.new)
    end

    test "returns an error when the service is down", %{bypass: bypass, client: client} do
      Bypass.down(bypass)
      assert {:error, :econnrefused} = ExOneSignal.send(client, Notification.new)
    end
  end
end
