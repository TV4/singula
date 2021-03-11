Application.put_all_env(
  singula: [
    client: Singula.Client,
    uuid_generator: &UUID.uuid4/0,
    base_url: System.get_env("SINGULA_BASE_URL"),
    api_key: System.get_env("SINGULA_API_KEY"),
    api_secret: System.get_env("SINGULA_API_SECRET"),
    client_name: System.get_env("SINGULA_CLIENT_NAME"),
    merchant_password: System.get_env("SINGULA_MERCHANT_PASSWORD"),
    timeout_ms: System.get_env("SINGULA_TIMEOUT_MS", "10000") |> String.to_integer()
  ]
)

IO.puts("Configured Application singula: #{inspect(Application.get_all_env(:singula), pretty: true)}")
