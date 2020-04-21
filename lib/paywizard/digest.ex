defmodule Paywizard.Digest do
  def generate(provider, currency, data) do
    uuid = uuid_generator().()

    data =
      data
      |> Enum.map(fn {key, value} -> %{key: key, value: value} end)

    %{
      "currencyCode" => currency,
      "data" => data,
      "digest" => digest(uuid),
      "merchantCode" => client_name(),
      "provider" => provider,
      "uuid" => uuid
    }
  end

  defp digest(uuid) do
    merchant_password = Application.get_env(:paywizard, :merchant_password)

    :crypto.hash(:sha256, "#{client_name()}#{uuid}#{merchant_password}")
    |> Base.encode16()
    |> String.downcase()
  end

  defp uuid_generator, do: Application.get_env(:paywizard, :uuid_generator, &UUID.uuid4/0)
  defp client_name, do: Application.get_env(:paywizard, :client_name)
end
