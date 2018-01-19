defmodule ExOneSignal.NotificationTest do
  use ExUnit.Case
  import ExOneSignal.Notification
  alias ExOneSignal.Notification

  describe "struct" do
    test "a base notification has default params" do
      assert \
        %Notification{
          headings: %{},
          contents: %{},
          data: %{},
          include_player_ids: []
        } == Notification.new
    end
  end

  describe "set_title/3" do
    test "can add a title and it will default to \"en\"" do
      assert %Notification{headings: %{en: "Title"}} ==
        Notification.new
        |> set_title("Title")
    end

    test "can add a title for multiple languages" do
      assert %Notification{headings: %{en: "Title", fr: "French Title"}} ==
        Notification.new
        |> set_title("Title")
        |> set_title("French Title", :fr)
    end

    test "cannot specify a non atom language" do
      assert_raise FunctionClauseError, fn ->
        set_title(Notification.new, "Title", "en")
      end
    end
  end

  describe "set_body/3" do
    test "can add a body and it will default to \"en\"" do
      assert %Notification{contents: %{en: "Body"}} ==
        Notification.new
        |> set_body("Body")
    end

    test "can add a body for multiple languages" do
      assert %Notification{contents: %{en: "Body", fr: "French Body"}} ==
        Notification.new
        |> set_body("Body")
        |> set_body("French Body", :fr)
    end

    test "cannot specify a non atom language" do
      assert_raise FunctionClauseError, fn ->
        set_body(Notification.new, "Body", "en")
      end
    end
  end

  describe "add_data/3" do
    test "can add multiple additional data parameters" do
      assert \
        %Notification{
          data: %{
            url: "https://example.com",
            flag: "a flag"
          }
        } ==
        Notification.new
        |> add_data(:url, "https://example.com")
        |> add_data(:flag, "a flag")
    end

    test "cannot specify a non atom key" do
      assert_raise FunctionClauseError, fn ->
        add_data(Notification.new, "url", "https://example.com")
      end
    end

    test "cannot specify a non bitstring value" do
      assert_raise FunctionClauseError, fn ->
        add_data(Notification.new, "url", :my_url)
      end
    end
  end

  describe "add_player/2" do
    test "can add a target player id" do
      assert %Notification{include_player_ids: ["abc123"]} ==
        Notification.new
        |> add_player("abc123")
    end

    test "can add multiple target player ids" do
      assert %Notification{include_player_ids: ["abc123", "def456"]} ==
        Notification.new
        |> add_player("def456")
        |> add_player("abc123")
    end

    test "cannot add a non bitstring player id" do
      assert_raise FunctionClauseError, fn ->
        Notification.new
        |> add_player(:abc123)
      end
    end
  end

  describe "add_players" do
    test "can add multiple target player ids" do
      assert %Notification{include_player_ids: ["abc123", "def456", "ghi789"]} ==
        Notification.new
        |> add_players(["ghi789"])
        |> add_players(["abc123", "def456"])
    end

    test "must pass a list of player ids" do
      assert_raise FunctionClauseError, fn ->
        Notification.new
        |> add_players("abc123")
      end
    end
  end
end
