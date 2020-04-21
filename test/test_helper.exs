Application.put_all_env(
  paywizard: [
    http_client: MockPaywizardHTTPClient,
    uuid_generator: fn -> "30f86e79-ed75-4022-a16e-d55d9f09af8d" end,
    base_url: "https://paywizard.example.b17g.net",
    api_key: "admin",
    api_secret: "***REMOVED***",
    client_name: "BBR",
    merchant_password: "icanhazcheezeburger"
  ]
)

ExUnit.start()
