defmodule ExOneSignal do
  @moduledoc """
  Documentation for ExOneSignal.
  """
  alias ExOneSignal.Notification

  defstruct [:base_url, :app_id, :api_key]

  @base_url "https://onesignal.com"

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: supervisor_name()]])
    ]
    opts = [
      strategy: :one_for_one,
      name: ExOneSignal.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  def supervisor_name, do: ExOneSignal.TaskSupervisor

  def new(attrs \\ []) do
    %ExOneSignal{
      base_url: Keyword.get(attrs, :base_url, @base_url),
      api_key: Keyword.get(attrs, :api_key, get_api_key()),
      app_id: Keyword.get(attrs, :app_id, get_app_id()),
    }
  end

  def deliver(%ExOneSignal{base_url: base_url} = client \\ ExOneSignal.new, %Notification{} = notification) do
    with \
      {:ok, _} <- can_deliver?(client),
      body_params <- get_default_params(client, notification),
      {:ok, body} <- Poison.encode(body_params)
    do
      url = base_url <> get_path(:notifications)
      headers = get_headers(client)

      HTTPoison.start

      HTTPoison.post(url, body, headers)
      |> handle_response
    end
  end

  def deliver_later(%Notification{} = notification, callback) when is_function(callback),
    do: deliver_later(ExOneSignal.new, notification, callback)
  def deliver_later(%ExOneSignal{} = client \\ ExOneSignal.new, %Notification{} = notification, callback \\ :NOP) do
    pid = self()
    Task.Supervisor.start_child supervisor_name(), fn ->
      response = deliver(client, notification)

      # respond to the callback otherwise send response back to the previous process
      if is_function(callback) do
        callback.(response)
      end

      # Send back to the parent process the response. The parent is responsible
      # for matching on the returned PID
      send(pid, {self(), response})
    end
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: Poison.decode(body)
  defp handle_response({:ok, %HTTPoison.Response{body: body}}),
    do: {:error, Poison.decode!(body)["errors"]}
  defp handle_response({_, %HTTPoison.Error{reason: reason}}),
    do: {:error, reason}
  defp handle_response({_, _}),
    do: {:error, :unexpected_error}

  defp get_path(:notifications), do: "/api/v1/notifications"

  defp get_headers(%ExOneSignal{api_key: api_key}, additional_headers \\ %{}) when is_map(additional_headers) do
    %{
      "Authorization" => "Basic " <> api_key,
      "Content-Type"  => "application/json"
    }
    |> Map.merge(additional_headers)
  end

  def get_default_params(%ExOneSignal{app_id: app_id}, notification),
    do: Map.put(notification, :app_id, app_id)

  defp config, do: Application.get_env(:ex_one_signal, ExOneSignal)

  defp get_api_key, do: Keyword.get(config(), :api_key, "")

  defp get_app_id,  do: Keyword.get(config(), :app_id, "")

  defp can_deliver?(%ExOneSignal{app_id: ""}),
    do: {:error, "Please set a an app_id in the ExOneSignal config"}
  defp can_deliver?(%ExOneSignal{api_key: ""}),
    do: {:error, "Please set a an api_key in the ExOneSignal config"}
  defp can_deliver?(%ExOneSignal{}), do: {:ok, :deliver}
end
