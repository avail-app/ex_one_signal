defmodule ExOneSignal do
  @moduledoc """
  Documentation for ExOneSignal.
  """
  alias ExOneSignal.Notification

  defstruct [:base_url, :app_id, :api_key]

  @base_url "https://onesignal.com"

  def new(attrs \\ []) do
    %ExOneSignal{
      base_url: Keyword.get(attrs, :base_url, @base_url),
      api_key: Keyword.get(attrs, :api_key, get_api_key()),
      app_id: Keyword.get(attrs, :app_id, get_app_id()),
    }
  end

  def send(%ExOneSignal{base_url: base_url} = client \\ ExOneSignal.new, %Notification{} = notification) do
    with \
      {:ok, _} <- can_send?(client),
      body_params <- get_default_params(client, notification),
      {:ok, body} <- Poison.encode(body_params)
    do
      url = base_url <> get_path(:send)
      headers = get_headers(client)

      HTTPoison.start

      HTTPoison.post(url, body, headers)
      |> handle_response
    end
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: Poison.decode(body)
  defp handle_response({:ok, %HTTPoison.Response{body: body}}),
    do: {:error, Poison.decode!(body)["errors"]}
  defp handle_response({_, %HTTPoison.Error{reason: reason}}),
    do: {:error, reason}
  defp handle_response({status, thing}) do
    IO.inspect status
    IO.inspect thing
    {:error, :unexpected_error}
  end

  defp get_path(:send), do: "/api/v1/notifications"

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

  defp can_send?(%ExOneSignal{app_id: ""}),
    do: {:error, "Please set a an app_id in the ExOneSignal config"}
  defp can_send?(%ExOneSignal{api_key: ""}),
    do: {:error, "Please set a an api_key in the ExOneSignal config"}
  defp can_send?(%ExOneSignal{}), do: {:ok, :send}
end
