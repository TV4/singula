defmodule Singula.ClientTest do
  use ExUnit.Case, async: true
  import Hammox
  alias Singula.Client

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
        Authorization: "hmac key:F1DDF5074C308F8AE0FBC9276B2DD4BE32BC7AD6EB5EA95A5B2DEEA3A21ADB1F",
        Timestamp: 1_580_674_802,
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:error, %HTTPoison.Error{reason: :nxdomain}}
    end)

    assert Client.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:error, %HTTPoison.Error{reason: :nxdomain}}
  end

  test "handle singula error", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :get,
      "https://singula.example.b17g.net/api/get/päth",
      "",
      [
        Authorization: "hmac key:F1DDF5074C308F8AE0FBC9276B2DD4BE32BC7AD6EB5EA95A5B2DEEA3A21ADB1F",
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

    assert Client.get("/api/get/päth", MockHTTPClient, current_time) ==
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
        Authorization: "hmac key:F1DDF5074C308F8AE0FBC9276B2DD4BE32BC7AD6EB5EA95A5B2DEEA3A21ADB1F",
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

    assert Client.get("/api/get/päth", MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "{\"key\":\"value\"}", json: %{"key" => "value"}, status_code: 200}}
  end

  test "signed patch", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :patch,
      "https://singula.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac key:DDB91529F8F7DB674697CCB147041673AFB3810CF30A52EF147F42045D01C400",
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

    assert Client.patch("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "{\"key\":\"value\"}", json: %{"key" => "value"}, status_code: 200}}
  end

  test "signed post", %{current_time: current_time} do
    MockHTTPClient
    |> expect(:request, fn
      :post,
      "https://singula.example.b17g.net/api/get/päth",
      "{\"key\":\"value\"}",
      [
        Authorization: "hmac key:EF6FEE99F26A66493D12D350BEEC335E38B70F11F54BA46CCF688EC1AFDB8E16",
        Timestamp: 1_580_674_802,
        "Content-Type": "application/json; charset=utf-8",
        Accept: "application/json"
      ],
      [recv_timeout: 10000] ->
        {:ok, %HTTPoison.Response{body: "", status_code: 200, request: %HTTPoison.Request{url: ""}}}
    end)

    assert Client.post("/api/get/päth", %{key: "value"}, MockHTTPClient, current_time) ==
             {:ok, %Singula.Response{body: "", status_code: 200}}
  end
end
