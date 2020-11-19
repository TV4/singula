defmodule Mix.Tasks.Crawl do
  use Mix.Task

  def run(_args) do
    load_config()
    start_deps()

    ### Remove comments to crawl through everything

    # {:ok, %Singula.Response{json: %{"Category" => categories}}} =
    #  Singula.HTTPClient.get("/apis/catalogue/v1/category/root")

    # all_entitlements =
    #  Enum.reduce(categories, %{}, fn %{"categoryId" => category, "name" => name}, acc ->
    #    Map.put(acc, name, map_category(category))
    #  end)
    #  |> IO.inspect()

    entitlements = map_category(212)
    # entitlements =  Map.get(all_entitlements, "published")

    Enum.map(entitlements, fn %Singula.Entitlement{id: id} = entitlement ->
      {:ok, %Vimond.ProductPayment{product_id: product_id}} = Vimond.Client.product_payment(id, vimond_config())
      {:ok, %Vimond.Product{product_group_id: product_group_id}} = Vimond.Client.product(product_id, vimond_config())
      {entitlement, product_group_id}
    end)
    |> IO.inspect()
  end

  defp map_category(category) do
    items = fetch_items("/category/#{category}/item/search/1?limited=false&pagesize=50") |> List.flatten()

    items_ids = Enum.map(items, fn %{"itemId" => itemId} -> itemId end)

    Enum.map(items_ids, fn item_id ->
      try do
        {:ok, %Singula.Item{entitlements: entitlements}} = Singula.item_by_id_and_currency(item_id, :SEK)
        entitlements
      rescue
        _error ->
          []
      end
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp fetch_items(next_url) do
    fetch_items(next_url, [])
  end

  defp fetch_items(next_url, acc) do
    {:ok, %Singula.Response{json: json}} =
      Singula.HTTPClient.post("/apis/catalogue/v1" <> next_url, %{
        currency: :SEK
      })

    # ugly ass hack
    case json do
      nil ->
        acc

      json ->
        case Map.get(json, "nextPageLink", nil) do
          nil ->
            items = Map.get(json, "items")
            [items | acc]

          next_url ->
            items = Map.get(json, "items")

            fetch_items(next_url, [items | acc])
        end
    end
  end

  defp load_config() do
    Application.put_all_env(
      singula: [
        http_client: Singula.HTTPClient,
        uuid_generator: &UUID.uuid4/0,
        base_url: System.get_env("SINGULA_BASE_URL"),
        api_key: System.get_env("SINGULA_API_KEY"),
        api_secret: System.get_env("SINGULA_API_SECRET"),
        client_name: System.get_env("SINGULA_CLIENT_NAME"),
        merchant_password: System.get_env("SINGULA_MERCHANT_PASSWORD"),
        timeout_ms: System.get_env("SINGULA_TIMEOUT_MS", "10000") |> String.to_integer()
      ]
    )
  end

  defp start_deps do
    Application.load(:singula)

    Application.spec(:singula)
    |> Keyword.get(:applications)
    |> Enum.map(&Application.ensure_all_started(&1))
  end

  def vimond_config() do
    %Vimond.Config{
      base_url: System.get_env("VIMOND_BASE_URL"),
      api_key: System.get_env("VIMOND_API_KEY"),
      api_secret: System.get_env("VIMOND_API_SECRET")
    }
  end
end
