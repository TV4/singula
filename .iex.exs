Application.put_all_env(
  paywizard: [
    http_client: Paywizard.HTTPClient,
    uuid_generator: &UUID.uuid4/0,
    base_url: System.get_env("PAYWIZARD_BASE_URL"),
    api_key: System.get_env("PAYWIZARD_API_KEY"),
    api_secret: System.get_env("PAYWIZARD_API_SECRET"),
    client_name: System.get_env("PAYWIZARD_CLIENT_NAME"),
    merchant_password: System.get_env("PAYWIZARD_MERCHANT_PASSWORD"),
    timeout_ms: System.get_env("PAYWIZARD_TIMEOUT_MS", "10000") |> String.to_integer()
  ]
)

IO.puts("Configured Application paywizard: #{inspect(Application.get_all_env(:paywizard), pretty: true)}")
