# ExOneSignal
[![CircleCI](https://circleci.com/gh/logit-ai/ex_one_signal.svg?style=svg)](https://circleci.com/gh/logit-ai/ex_one_signal)

A simple interface to interact with [OneSignal](https://onesignal.com/)'s push notification API.

## Installation
This package can be installed by adding `ex_one_signal` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_one_signal, "~> 0.1.0"}
  ]
end
```

## Docs
The docs can be found at [https://hexdocs.pm/ex_one_signal](https://hexdocs.pm/ex_one_signal).

## Usage
### Config
Add the following to your project's `config.exs`
``` elixir
config :ex_one_signal, ExOneSignal,
  api_key: "your-one-signal-api-key",
  app_id: "your-one-signal-app-id"
```

### Simple Notification
To create a notification, all you'll need is to set a message body (`contents`)
and add at least one target user (`include_player_ids`).

``` elixir
import ExOneSignal.Notification, except: [new: 0]
alias ExOneSignal.Notification

Notification.new
|> set_body("Example Body")
|> add_player("one-signal-player-id")
|> ExOneSignal.deliver
```

### Adding a Title
You can add a title (`headings`) and the default language will be English.
``` elixir
iex> set_title(Notification.new, "Title")
%Notification{headings: %{en: "Title"}}
```

Alternatively, you can add titles for multiple languages
``` elixir
iex> Notification.new
iex> |> set_title("English", :en)
iex> |> set_title("Français", :fr)
%Notification{headings: %{en: "English", fr: "Français"}}
```

### Adding a Message Body
You can add a body (`contents`) and the default language will be English.
``` elixir
iex> set_body(Notification.new, "Body")
%Notification{contents: %{en: "Body"}}
```

Alternatively, you can add bodies for multiple languages
``` elixir
iex> Notification.new
iex> |> set_body("English", :en)
iex> |> set_body("Français", :fr)
%Notification{contents: %{en: "English", fr: "Français"}}
```

### Specifying Target Users
To deliver a notification to a user's device, all you need is to add their OneSignal
`player_id_token`.
``` elixir
iex> Notification.new
iex> |> add_player("one-signal-player-token")
%Notification{include_player_ids: ["one-signal-player-token"]}
```

### Adding Additional Meta Data
Notifications can contain additional meta information that will be readable by
your client application (e.g. iOS or Android applications).

``` elixir
iex> Notification.new
iex> |> add_data(:targetUrl, "https://example.com")
%Notification{data: %{url: "https://example.com"}}
```

### Asynchonous Delivery
If you don't want to lock up your current process waiting on the network request
to OneSignal, you can use the `deliver_later` function to fire off the
notification in the background.

``` elixir
iex> Notification.new
iex> |> ExOneSignal.deliver_later
{:ok, #PID<0.255.0>}
```

To get the response from the async request, just setup a receive request and
match on the returned process identifier. It is highly recommended with this
approach to use a timeout in the receive block.

``` elixir
{:ok, process_id} = ExOneSignal.deliver_later(Notification.new)

receive do
  {^process_id, response} ->
    case response do
      {:ok, body} ->
        # do something
    end
  after
    1_000 ->
      # the receive timed out after 1 second
end
```

Alternatively, supply a callback function that will fire when the request finishes.

``` elixir
ExOneSignal.deliver_later(Notification.new, fn(response) ->
  case response do
    {:ok, body} ->
      # do something
  end
end)
```
