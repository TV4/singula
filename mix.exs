defmodule Singula.MixProject do
  use Mix.Project

  def project do
    [
      app: :singula,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: ["test.watch": :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.6"},
      {:elixir_uuid, "~> 1.2"},
      {:timex, "~> 3.6"},
      {:telemetry, "~> 0.4.2"},
      {:mix_test_watch, "~> 1.0", only: :test},
      {:hammox, "~> 0.2", only: :test}
    ]
  end
end
