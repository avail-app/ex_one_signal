defmodule ExOneSignalTest do
  use ExUnit.Case, async: true
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

  describe "deliver/1" do
    test "can deliver a notification to OneSignal", %{bypass: bypass, client: client, notification: notification} do
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        {:ok, body, _} = Plug.Conn.read_body(conn)
        body = Poison.decode!(body)

        assert body["headings"] == %{"en" => "Title"}
        assert body["contents"] == %{"en" => "Body"}
        assert body["include_player_ids"] == ["abc123", "def456"]
        assert body["data"] == %{"url" => "https://example.com"}
        assert body["ios_badgeType"] == "Increase"
        assert body["ios_badgeCount"] == 0

        Plug.Conn.resp(conn, 200, "{\"recipients\": 5}")
      end

      assert {:ok, _body} = ExOneSignal.deliver(client, notification)
    end

    test "can deliver a notification to OneSignal and set the badge count", %{bypass: bypass, client: client, notification: notification} do
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        {:ok, body, _} = Plug.Conn.read_body(conn)
        body = Poison.decode!(body)

        assert body["headings"] == %{"en" => "Title"}
        assert body["contents"] == %{"en" => "Body"}
        assert body["include_player_ids"] == ["abc123", "def456"]
        assert body["data"] == %{"url" => "https://example.com"}
        assert body["ios_badgeType"] == "SetTo"
        assert body["ios_badgeCount"] == 3
        assert body["content_available"] == false

        Plug.Conn.resp(conn, 200, "{\"recipients\": 5}")
      end

      assert {:ok, _body} = ExOneSignal.deliver(client, set_badge_count(notification, 3))
    end

    test "can deliver a notification silently", %{bypass: bypass, client: client, notification: notification} do
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        {:ok, body, _} = Plug.Conn.read_body(conn)
        body = Poison.decode!(body)

        assert body["headings"] == %{}
        assert body["contents"] == %{}
        assert body["include_player_ids"] == ["abc123", "def456"]
        assert body["data"] == %{"url" => "https://example.com"}
        assert body["ios_badgeType"] == "SetTo"
        assert body["ios_badgeCount"] == 5
        assert body["content_available"] == true

        Plug.Conn.resp(conn, 200, "{\"recipients\": 5}")
      end

      notification =
        notification
        |> set_badge_count(5)
        |> set_send_silently
      assert {:ok, _body} = ExOneSignal.deliver(client, notification)
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

      assert {:ok, response_body} == ExOneSignal.deliver(client, Notification.new)
    end

    test "when an invalid status code is returned, the response errors are returned", %{bypass: bypass, client: client} do
      errors = ["The errors"]

      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        Plug.Conn.resp(conn, 400, Poison.encode!(%{errors: errors}))
      end

      assert {:error, errors} == ExOneSignal.deliver(client, Notification.new)
    end

    test "returns an error when the service is down", %{bypass: bypass, client: client} do
      Bypass.down(bypass)
      assert {:error, :econnrefused} = ExOneSignal.deliver(client, Notification.new)
    end
  end

  describe "deliver_later/3" do
    test "can deliver the notification asynchronously and still get the response", %{bypass: bypass, client: client} do
      response_body = %{"recipients" => 5}
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        Plug.Conn.resp(conn, 200, Poison.encode!(response_body))
      end

      {:ok, process_id} = ExOneSignal.deliver_later(client, Notification.new)

      receive do
        {^process_id, response} ->
          case response do
            {:ok, body} ->
              assert response_body == body
          end
      end
    end

    test "can supply a callback, rather than using `response do`", %{bypass: bypass, client: client} do
      response_body = %{"recipients" => 5}
      Bypass.expect_once bypass, "POST", @notification_path, fn conn ->
        Plug.Conn.resp(conn, 200, Poison.encode!(response_body))
      end

      {:ok, process_id} = ExOneSignal.deliver_later(client, Notification.new, fn(response) ->
        case response do
          {:ok, body} ->
            assert response_body == body
        end
      end)

      # also receive so the test doesn't exit early
      receive do
        {^process_id, {:ok, body}} ->
          assert response_body == body
      end
    end
  end
end
