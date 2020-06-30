defmodule Singula.HTTPClientTest do
  use ExUnit.Case, async: true
  import Hammox
  alias Singula.HTTPClient

  setup :verify_on_exit!

  setup_all do
    {:ok, current_time: fn -> ~U[2020-02-02 20:20:02.02Z] end}
  end

  test "handle network error", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :get,
      "https://singula.example.b17g.net/api/get/päth",
      "",
      [
        Authorization: "hmac admin:1A9820392174E71E9A66758F29EEC28596FA9DC75A3EC5A29F7EDB6C86A74409",
        Timestamp: 1_580_674_802,
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:error, %HTTPoison.Error{reason: :nxdomain}}
    end)

    assert HTTPClient.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:error, %HTTPoison.Error{reason: :nxdomain}}
  end

  test "handle singula error", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :get,
      "https://singula.example.b17g.net/api/get/päth",
      "",
      [
        Authorization: "hmac admin:1A9820392174E71E9A66758F29EEC28596FA9DC75A3EC5A29F7EDB6C86A74409",
        Timestamp: 1_580_674_802,
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        error = %{
          "developerMessage" => "Username smoke_200624_01 already exists",
          "errorCode" => 90074,
          "moreInfo" =>
            "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
          "userMessage" => "Username provided already exists"
        }

        {:ok,
         %HTTPoison.Response{
           body: Jason.encode!(error),
           status_code: 400,
           headers: [{"Content-Type", "application/json"}],
           request: %HTTPoison.Request{url: ""}
         }}
    end)

    assert HTTPClient.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:error,
              %Singula.Error{
                code: 90074,
                developer_message: "Username smoke_200624_01 already exists",
                user_message: "Username provided already exists"
              }}
  end

  test "signed get", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :get,
      "https://singula.example.b17g.net/api/get/päth",
      "",
      [
        Authorization: "hmac admin:1A9820392174E71E9A66758F29EEC28596FA9DC75A3EC5A29F7EDB6C86A74409",
        Timestamp: 1_580_674_802,
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:ok,
         %HTTPoison.Response{
           body: "{\"key\":\"value\"}",
           status_code: 200,
           headers: [{"Content-Type", "application/json"}],
           request: %HTTPoison.Request{url: ""}
         }}
    end)

    assert HTTPClient.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "{\"key\":\"value\"}", json: %{"key" => "value"}, status_code: 200}}
  end

  test "signed patch", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :patch,
      "https://singula.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac admin:B65D6E5E74DEA8CC585D779DE815AF965F774A4CC3870CB5839D5784B5733134",
        Timestamp: 1_580_674_802,
        "Content-Type": "application/json; charset=utf-8",
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:ok,
         %HTTPoison.Response{
           body: "{\"key\":\"value\"}",
           status_code: 200,
           headers: [{"Content-Type", "application/json;charset=UTF-8"}],
           request: %HTTPoison.Request{url: ""}
         }}
    end)

    assert HTTPClient.patch("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "{\"key\":\"value\"}", json: %{"key" => "value"}, status_code: 200}}
  end

  test "signed post", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :post,
      "https://singula.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac admin:67A59DAFC94D26EAA8B12178D6FDED3257E19F69485FDBEEBD129266F41A519A",
        Timestamp: 1_580_674_802,
        "Content-Type": "application/json; charset=utf-8",
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
    end)

    assert HTTPClient.post("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "", status_code: 200}}
  end
end
