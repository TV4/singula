defmodule Paywizard.HTTPClient do
  require Logger

  @callback get(binary) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def get(path, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    signed_request(http_client, current_time, :get, path, "", Accept: "application/json")
  end

  @callback patch(binary, map) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def patch(path, data, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    body = if is_map(data), do: Jason.encode!(data), else: data

    signed_request(http_client, current_time, :patch, path, body,
      "Content-Type": "application/json; charset=utf-8",
      Accept: "application/json"
    )
  end

  @callback post(binary, map) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def post(path, data, http_client \\ HTTPoison, current_time \\ &DateTime.utc_now/0) do
    body = if is_map(data), do: Jason.encode!(data), else: data

    signed_request(http_client, current_time, :post, path, body,
      "Content-Type": "application/json; charset=utf-8",
      Accept: "application/json"
    )
  end

  defp signed_request(http_client, current_time, method, path, body, headers, options \\ []) do
    url = paywizard_url(path)
    headers = Keyword.merge(signed_headers(method, path, current_time), headers)
    options = Keyword.merge(options, recv_timeout: timeout())
    Logger.debug("Paywizard request: #{inspect({method, url, body, headers, options})}")

    {time, response} = :timer.tc(fn -> http_client.request(method, url, body, headers, options) end)
    Logger.debug("Paywizard response: #{inspect(response)}")
    Logger.info("Paywizard request time: measure#paywizard.request=#{div(time, 1000)}ms")

    response
  end

  defp signed_headers(method, path, current_time) do
    method = method |> to_string |> String.upcase()
    timestamp = current_time.() |> DateTime.to_unix()
    api_key = Application.get_env(:paywizard, :api_key)
    api_secret = Application.get_env(:paywizard, :api_secret)
    path = URI.parse(path).path

    signature = :crypto.hmac(:sha256, api_secret, "#{timestamp}#{method}#{path}") |> Base.encode16()

    [
      Authorization: "hmac #{api_key}:#{signature}",
      Timestamp: timestamp
    ]
  end

  defp paywizard_url(path), do: Application.get_env(:paywizard, :base_url) <> path
  defp timeout, do: Application.get_env(:paywizard, :timeout_ms)
end
