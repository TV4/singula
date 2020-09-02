defmodule Singula do
  alias Singula.{
    CartDetail,
    Contract,
    ContractDetails,
    Customer,
    AddDibsPaymentMethod,
    Digest,
    Item,
    AddKlarnaPaymentMethod,
    MetaData,
    PPV
  }

  require Logger

  @type error :: Singula.Error.t() | HTTPoison.Error.t()

  @callback create_customer(Customer.t()) :: {:ok, Customer.id()} | {:error, error}
  def create_customer(customer) do
    payload = Customer.to_payload(customer) |> Map.put(:title, "-")

    with {:ok, %Singula.Response{json: %{"href" => href}, status_code: 201}} <-
           log(:create_customer, fn -> http_client().post("/apis/customers/v1/customer", payload) end) do
      customer_id = String.split(href, "/") |> List.last()
      {:ok, customer_id}
    end
  end

  @callback update_customer(Customer.t()) :: :ok | {:error, error}
  def update_customer(customer) do
    payload =
      Customer.to_payload(customer)
      |> Enum.reject(fn {_key, value} -> value in [[], nil] end)
      |> Map.new()

    with {:ok, %Singula.Response{status_code: 201}} <-
           log(:update_customer, fn -> http_client().patch("/apis/customers/v1/customer/#{customer.id}", payload) end) do
      :ok
    end
  end

  @callback anonymise_customer(Customer.id()) :: :ok | {:error, error}
  def anonymise_customer(customer_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           log(:anonymise_customer, fn ->
             http_client().post("/apis/customers/v1/customer/#{customer_id}/anonymise", "")
           end) do
      :ok
    end
  end

  @callback customer_fetch(Customer.id()) :: {:ok, Customer.t()} | {:error, error}
  def customer_fetch(customer_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_fetch, fn -> http_client().get("/apis/customers/v1/customer/#{customer_id}") end) do
      {:ok, Customer.new(data)}
    end
  end

  @callback customer_search(binary) :: {:ok, Customer.t()} | {:error, error}
  def customer_search(external_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_search, fn ->
             http_client().post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => external_id})
           end) do
      {:ok, Customer.new(data)}
    end
  end

  @callback customer_contracts(Customer.id()) ::
              {:ok, list(Contract.t())} | {:error, error}
  def customer_contracts(customer_id, active_only \\ true) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_contracts, fn ->
             http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract?activeOnly=#{active_only}")
           end) do
      {:ok, Contract.new(data)}
    end
  end

  @callback customer_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, ContractDetails.t()} | {:error, error}
  def customer_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_contract, fn ->
             http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}")
           end) do
      {:ok, ContractDetails.new(data)}
    end
  end

  @callback customer_purchases_ppv(Customer.id()) ::
              {:ok, list(PPV.t())} | {:error, error}
  def customer_purchases_ppv(customer_id) do
    items_pager("/apis/purchases/v1", "/customer/#{customer_id}/purchases/1", %{type: "PPV"})
  end

  @callback fetch_single_use_promo_code(promo_code :: binary) ::
              {:ok, map} | {:error, error}
  def fetch_single_use_promo_code(promo_code) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:fetcH_single_use_promo_code, fn -> http_client().get("/apis/purchases/v1/promocode/#{promo_code}") end) do
      {:ok, data}
    end
  end

  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency()) ::
              {:ok, cart_id :: binary} | {:error, error}
  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency(), MetaData.t()) ::
              {:ok, cart_id :: binary} | {:error, error}
  def create_cart_with_item(customer_id, item_id, currency, meta_data \\ %MetaData{}) do
    with {:ok, %Singula.Response{json: %{"href" => href}, status_code: 201}} <-
           log(:create_cart_with_item, fn ->
             http_client().post(
               "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
               cart_items_with_discount(item_id, meta_data)
             )
           end) do
      cart_id = String.split(href, "/") |> List.last()
      {:ok, cart_id}
    end
  end

  @callback fetch_cart(Customer.id(), cart_id :: binary) ::
              {:ok, CartDetail.t()} | {:error, error}
  def fetch_cart(customer_id, cart_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:fetch_cart, fn -> http_client().get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}") end) do
      {:ok, CartDetail.new(data)}
    end
  end

  @callback fetch_item_discounts(item_id :: binary, Item.currency()) ::
              {:ok, list} | {:error, error}
  def fetch_item_discounts(item_id, currency) do
    with {:ok, %Singula.Response{json: %{"discounts" => discounts}, status_code: 200}} <-
           log(:fetch_item_discounts, fn ->
             http_client().get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")
           end) do
      {:ok, discounts}
    end
  end

  @callback customer_redirect_dibs(Customer.id(), Item.currency(), map) ::
              {:ok, map} | {:error, error}
  def customer_redirect_dibs(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_redirect_dibs, fn ->
             http_client().post(
               "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
               Digest.generate(:DIBS, currency, redirect_data)
             )
           end) do
      {:ok, data}
    end
  end

  @callback customer_redirect_klarna(Customer.id(), Item.currency(), map) ::
              {:ok, map} | {:error, error}
  def customer_redirect_klarna(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_redirect_klarna, fn ->
             http_client().post(
               "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
               Digest.generate(:KLARNA, currency, redirect_data)
             )
           end) do
      {:ok, data}
    end
  end

  @callback payment_methods(Customer.id()) ::
              {:ok, [Singula.DibsPaymentMethod.t() | Singula.KlarnaPaymentMethod.t()]} | {:error, error}
  def payment_methods(customer_id) do
    with {:ok, %Singula.Response{json: %{"PaymentMethod" => payment_methods}, status_code: 200}} <-
           log(:customer_payment_methods, fn ->
             http_client().get("/apis/payment-methods/v1/customer/#{customer_id}/list")
           end) do
      payment_methods =
        Enum.reduce(payment_methods, [], fn
          %{"provider" => "DIBS"} = payment_method, acc -> [Singula.DibsPaymentMethod.new(payment_method) | acc]
          %{"provider" => "KLARNA"} = payment_method, acc -> [Singula.KlarnaPaymentMethod.new(payment_method) | acc]
          _, acc -> acc
        end)
        |> Enum.reverse()

      {:ok, payment_methods}
    end
  end

  @callback update_payment_method(Customer.id(), Contract.contract_id(), integer) :: :ok
  def update_payment_method(customer_id, contract_id, payment_method_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           log(:update_payment_method, fn ->
             http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/paymentmethod", %{
               paymentMethodId: payment_method_id
             })
           end) do
      :ok
    end
  end

  @callback customer_payment_method(Customer.id(), Item.currency(), AddDibsPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer} | {:error, error}
  def customer_payment_method(customer_id, currency, %AddDibsPaymentMethod{} = dibs_payment_method) do
    digest = Digest.generate(:DIBS, currency, Map.from_struct(dibs_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_payment_method(Customer.id(), Item.currency(), AddKlarnaPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer} | {:error, error}
  def customer_payment_method(customer_id, currency, %AddKlarnaPaymentMethod{} = klarna_payment_method) do
    digest = Digest.generate(:KLARNA, currency, AddKlarnaPaymentMethod.to_provider_data(klarna_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_cart_checkout(Customer.id(), binary, integer) ::
              {:ok, CartDetail.t()} | {:error, error}
  def customer_cart_checkout(customer_id, cart_id, payment_method_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_cart_checkout, fn ->
             http_client().post(
               "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
               %{"paymentMethodId" => payment_method_id}
             )
           end) do
      {:ok, CartDetail.new(data)}
    end
  end

  @callback cancel_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, cancellation_date :: Date.t()} | {:error, error}
  def cancel_contract(customer_id, contract_id, cancel_date \\ "") do
    with {:ok, %Singula.Response{json: %{"cancellationDate" => cancellation_date}, status_code: 200}} <-
           log(:cancel_contract, fn ->
             http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel", %{
               "cancelDate" => cancel_date
             })
           end) do
      Date.from_iso8601(cancellation_date)
    end
  end

  @callback withdraw_cancel_contract(Customer.id(), Contract.contract_id()) ::
              :ok | {:error, error}
  def withdraw_cancel_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           log(:withdraw_cancel_contract, fn ->
             http_client().post(
               "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel/withdraw",
               %{}
             )
           end) do
      :ok
    end
  end

  @callback crossgrades_for_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, list(Singula.Crossgrade.t())} | {:error, error}
  def crossgrades_for_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: %{"crossgradePaths" => crossgrade_paths}, status_code: 200}} <-
           log(:crossgrades_for_contract, fn ->
             http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change")
           end) do
      crossgrades = Enum.map(crossgrade_paths, fn crossgrade_path -> Singula.Crossgrade.new(crossgrade_path) end)
      {:ok, crossgrades}
    end
  end

  @callback change_contract(Customer.id(), Contract.contract_id(), item_id :: binary) ::
              :ok | {:error, error}
  def change_contract(customer_id, contract_id, item_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           log(:change_contract, fn ->
             http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change", %{
               itemCode: item_id
             })
           end) do
      :ok
    end
  end

  @callback withdraw_change_contract(Customer.id(), Contract.contract_id()) ::
              :ok | {:error, error}
  def withdraw_change_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           log(:withdraw_change_contract, fn ->
             http_client().post(
               "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change/withdraw",
               %{}
             )
           end) do
      :ok
    end
  end

  @callback item_by_id_and_currency(item_id :: binary, Item.currency()) :: {:ok, Item.t()} | {:error, error}
  def item_by_id_and_currency(item_id, currency) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:item_by_id_and_currency, fn ->
             http_client().get("/apis/catalogue/v1/item/#{item_id}?currency=#{currency}")
           end) do
      {:ok, Item.new(data)}
    end
  end

  defp cart_items_with_discount(item_id, meta_data) do
    %{items: [%{itemCode: item_id, itemData: item_data(meta_data)}]}
    |> add_discount(meta_data.discount)
  end

  defp add_discount(cart_data, %Singula.Discount{} = discount) do
    Map.put(cart_data, :discountCode, discount_code(discount))
  end

  defp add_discount(cart_data, nil), do: cart_data

  defp discount_code(%Singula.Discount{is_single_use: true} = discount) do
    %{individualPromoCode: discount.promotion}
  end

  defp discount_code(%Singula.Discount{} = discount) do
    %{
      discountId: discount.discount,
      campaignCode: discount.campaign,
      promoCode: discount.promotion,
      sourceCode: discount.source
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp create_payment_method(customer_id, digest) do
    with {:ok, %Singula.Response{json: %{"paymentMethodId" => payment_method_id}, status_code: 200}} <-
           log(:create_payment_method, fn ->
             http_client().post("/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod", digest)
           end) do
      {:ok, payment_method_id}
    end
  end

  defp item_data(meta_data) do
    meta_data
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn
      {_, nil}, item_data ->
        item_data

      {:referrer, referrer}, item_data ->
        Map.put(item_data, :referrerId, referrer)

      {:asset, asset}, item_data ->
        Map.merge(item_data, %{id: asset.id, name: asset.title})

      _, item_data ->
        item_data
    end)
  end

  defp items_pager(path_prefix, path, payload, acc \\ []) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           log(:customer_paged_purchases, fn -> http_client().post(path_prefix <> path, payload) end) do
      items = Map.get(data, "items", [])
      acc = acc ++ items

      case data do
        %{"nextPageLink" => path} -> items_pager(path_prefix, path, payload, acc)
        _ -> {:ok, PPV.new(acc)}
      end
    end
  end

  defp log(name, request_function) do
    {time, response} = :timer.tc(request_function)

    Singula.Telemetry.emit_response_time(name, div(time, 1000))

    response
  end

  defp http_client, do: Application.get_env(:singula, :http_client, Singula.HTTPClient)
end
