defmodule Singula.Response do
  defstruct [:body, :json, :status_code]

  @type t :: %__MODULE__{body: binary, json: nil | map | list, status_code: integer}
end

defmodule Singula.Error do
  defstruct [:code, :developer_message, :user_message]

  @type t :: %__MODULE__{code: integer | nil, developer_message: binary | nil, user_message: binary | nil}
end

defmodule Singula.Client do
  require Logger

  @type payload :: map | binary

  @callback get(binary) :: {:ok, Singula.Response.t()} | {:error, Singula.error()}
  def get(path, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    signed_request(http_client, current_time, :get, path, "", Accept: "application/json")
  end

  @callback patch(binary, payload) :: {:ok, Singula.Response.t()} | {:error, Singula.error()}
  def patch(path, data, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    body = if is_map(data), do: Jason.encode!(data), else: data

    signed_request(http_client, current_time, :patch, path, body,
      "Content-Type": "application/json; charset=utf-8",
      Accept: "application/json"
    )
  end

  @callback post(binary, payload) :: {:ok, Singula.Response.t()} | {:error, Singula.error()}
  def post(path, data, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    body = if is_map(data), do: Jason.encode!(data), else: data

    signed_request(http_client, current_time, :post, path, body,
      "Content-Type": "application/json; charset=utf-8",
      Accept: "application/json"
    )
  end

  defp signed_request(http_client, current_time, method, path, body, headers, options \\ []) do
    url = singula_url(path)
    headers = Keyword.merge(signed_headers(method, path, current_time), headers)
    options = Keyword.merge(options, recv_timeout: timeout())

    response = http_client.request(method, url, body, headers, options)

    Singula.Telemetry.emit_response_event(%{response: response})

    translate_response(response)
  end

  defp signed_headers(method, path, current_time) do
    method = method |> to_string |> String.upcase()
    timestamp = current_time.() |> DateTime.to_unix()
    api_key = Application.get_env(:singula, :api_key)
    api_secret = Application.get_env(:singula, :api_secret)
    path = URI.parse(path).path

    signature = :crypto.mac(:hmac, :sha256, api_secret, "#{timestamp}#{method}#{path}") |> Base.encode16()

    [
      Authorization: "hmac #{api_key}:#{signature}",
      Timestamp: timestamp
    ]
  end

  defp translate_response({:error, error}), do: {:error, error}

  defp translate_response({:ok, %HTTPoison.Response{body: body, headers: headers, status_code: status_code}}) do
    response = %Singula.Response{body: body, status_code: status_code}

    response =
      Enum.find(headers, fn {key, _value} -> String.downcase(key) == "content-type" end)
      |> case do
        nil ->
          response

        {_, "application/json" <> _charset} ->
          %Singula.Response{response | json: Jason.decode!(body)}

        _otherwise ->
          Logger.error("Unknown Singula response: #{inspect(response)}")
          response
      end

    separate_error(response)
  end

  defp separate_error(%Singula.Response{json: %{"errorCode" => code} = json}) do
    {:error, %Singula.Error{code: code, developer_message: json["developerMessage"], user_message: json["userMessage"]}}
  end

  defp separate_error(response), do: {:ok, response}

  defp singula_url(path), do: Application.get_env(:singula, :base_url) <> path
  defp timeout, do: Application.get_env(:singula, :timeout_ms, 10000)
end
