ExUnit.configure(exclude: :pending, timeout: 10000)
# ExUnit.configure(include: :wip, exclude: :test)
Application.put_all_env(
  singula: [
    client: MockSingulaClient,
    uuid_generator: fn -> "30f86e79-ed75-4022-a16e-d55d9f09af8d" end,
    today: fn -> ~D[2020-02-02] end,
    base_url: "https://singula.example.b17g.net",
    api_key: "key",
    api_secret: "secret",
    client_name: "BBR",
    merchant_password: "icanhazcheezeburger"
  ]
)

ExUnit.start()
