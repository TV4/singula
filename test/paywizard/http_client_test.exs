defmodule Paywizard.HTTPClientTest do
  use ExUnit.Case, async: true
  import Hammox
  alias Paywizard.HTTPClient

  setup :verify_on_exit!

  setup do
    {:ok, current_time: fn -> ~U[2020-02-02 20:20:02.02Z] end}
  end

  test "signed get", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :get,
      "https://paywizard.example.b17g.net/api/get/päth",
      "",
      [
        Authorization: "hmac admin:1A9820392174E71E9A66758F29EEC28596FA9DC75A3EC5A29F7EDB6C86A74409",
        Timestamp: 1_580_674_802,
        Accept: "application/json"
      ],
      [recv_timeout: nil] ->
        {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
    end)

    assert HTTPClient.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
  end

  test "signed patch", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :patch,
      "https://paywizard.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac admin:B65D6E5E74DEA8CC585D779DE815AF965F774A4CC3870CB5839D5784B5733134",
        Timestamp: 1_580_674_802,
        "Content-Type": "application/json; charset=utf-8",
        Accept: "application/json"
      ],
      [recv_timeout: nil] ->
        {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
    end)

    assert HTTPClient.patch("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
  end

  test "signed post", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :post,
      "https://paywizard.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac admin:67A59DAFC94D26EAA8B12178D6FDED3257E19F69485FDBEEBD129266F41A519A",
        Timestamp: 1_580_674_802,
        "Content-Type": "application/json; charset=utf-8",
        Accept: "application/json"
      ],
      [recv_timeout: nil] ->
        {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
    end)

    assert HTTPClient.post("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
  end
end
