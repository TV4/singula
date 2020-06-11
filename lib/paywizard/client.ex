defmodule Paywizard.Crossgrade do
  defstruct [:item_id, :recurring_price, :currency]

  def new(%{"itemCode" => item_id, "changeCost" => %{"amount" => recurring_price, "currency" => currency}}) do
    %__MODULE__{item_id: item_id, recurring_price: recurring_price, currency: String.to_atom(currency)}
  end
end

defmodule Paywizard.Client do
  alias Paywizard.{
    CartDetail,
    Contract,
    ContractDetails,
    Customer,
    DibsPaymentMethod,
    Digest,
    Item,
    KlarnaPaymentMethod,
    MetaData,
    PPV
  }

  require Logger

  @type currency :: :DKK | :NOK | :SEK

  @callback customer_fetch(Customer.customer_id()) :: {:ok, Customer.t()} | {:paywizard_error, :customer_not_found}
  def customer_fetch(customer_id) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/customers/v1/customer/#{customer_id}") do
      {:ok, Customer.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90068}, status_code: 404}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_search(binary) :: {:ok, Customer.t()} | {:paywizard_error, :customer_not_found}
  def customer_search(external_id) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => external_id}) do
      {:ok, Customer.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90068}, status_code: 404}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_contracts(Customer.customer_id()) ::
              {:ok, list(Contract.t())} | {:paywizard_error, :customer_not_found}
  def customer_contracts(customer_id, active_only \\ true) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract?activeOnly=#{active_only}") do
      {:ok, Contract.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_contract(Customer.customer_id(), Contract.contract_id()) ::
              {:ok, ContractDetails.t()} | {:paywizard_error, :customer_not_found}
  def customer_contract(customer_id, contract_id) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}") do
      {:ok, ContractDetails.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_purchases_ppv(Customer.customer_id()) ::
              {:ok, list(PPV.t())} | {:paywizard_error, :customer_not_found}
  def customer_purchases_ppv(customer_id) do
    items_pager("/apis/purchases/v1", "/customer/#{customer_id}/purchases/1", %{type: "PPV"})
  end

  @callback fetch_single_use_promo_code(promo_code :: binary) :: {:ok, map} | {:paywizard_error, :promo_code_not_found}
  def fetch_single_use_promo_code(promo_code) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/purchases/v1/promocode/#{promo_code}") do
      {:ok, data}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90123}, status_code: 400}} ->
        {:paywizard_error, :promo_code_not_found}
    end
  end

  @callback create_cart_with_item(Customer.customer_id(), item_id :: binary, currency) ::
              {:ok, cart_id :: binary}
              | {:paywizard_error, :incorrect_item | :customer_not_found | :item_not_added_to_cart}
  @callback create_cart_with_item(Customer.customer_id(), item_id :: binary, currency, MetaData.t()) ::
              {:ok, cart_id :: binary}
              | {:paywizard_error,
                 :incorrect_item | :customer_not_found | :item_not_added_to_cart | :discount_not_found}
  def create_cart_with_item(customer_id, item_id, currency, meta_data \\ %MetaData{}) do
    with {:ok, %Paywizard.Response{json: %{"href" => href}, status_code: 201}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
             cart_items_with_discount(item_id, meta_data)
           ) do
      cart_id = String.split(href, "/") |> List.last()
      {:ok, cart_id}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90022}, status_code: 404}} ->
        {:paywizard_error, :discount_not_found}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 90069}, status_code: 404}} ->
        {:paywizard_error, :incorrect_item}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 90062}, status_code: 400}} ->
        {:paywizard_error, :item_not_added_to_cart}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 90115}, status_code: 400}} ->
        {:paywizard_error, :discount_not_found}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback fetch_cart(Customer.customer_id(), cart_id :: binary) ::
              {:ok, CartDetail.t()}
              | {:paywizard_error, :cart_not_found | :customer_not_found}
  def fetch_cart(customer_id, cart_id) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}") do
      {:ok, CartDetail.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90040}, status_code: 404}} ->
        {:paywizard_error, :cart_not_found}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback fetch_item_discounts(item_id :: binary, currency) :: {:ok, list}
  def fetch_item_discounts(item_id, currency) do
    {:ok, %Paywizard.Response{json: %{"discounts" => discounts}, status_code: 200}} =
      http_client().get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")

    {:ok, discounts}
  end

  @callback customer_redirect_dibs(Customer.customer_id(), currency, map) ::
              {:ok, map}
              | {:paywizard_error, :customer_not_found}
  def customer_redirect_dibs(customer_id, currency, redirect_data) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:DIBS, currency, redirect_data)
           ) do
      {:ok, data}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_redirect_klarna(Customer.customer_id(), currency, map) ::
              {:ok, map}
              | {:paywizard_error, :customer_not_found}
  def customer_redirect_klarna(customer_id, currency, redirect_data) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:KLARNA, currency, redirect_data)
           ) do
      {:ok, data}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_payment_method(Customer.customer_id(), currency, DibsPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer}
              | {:paywizard_error, :receipt_not_found | :transaction_not_found}
  def customer_payment_method(customer_id, currency, %DibsPaymentMethod{} = dibs_payment_method) do
    digest = Digest.generate(:DIBS, currency, Map.from_struct(dibs_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_payment_method(Customer.customer_id(), currency, KlarnaPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer}
              | {:paywizard_error, :receipt_not_found | :transaction_not_found}
  def customer_payment_method(customer_id, currency, %KlarnaPaymentMethod{} = klarna_payment_method) do
    digest = Digest.generate(:KLARNA, currency, KlarnaPaymentMethod.to_provider_data(klarna_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_cart_checkout(Customer.customer_id(), binary, integer) ::
              {:ok, CartDetail.t()} | {:paywizard_error, :cart_not_found | :payment_authorisation_fault}
  def customer_cart_checkout(customer_id, cart_id, payment_method_id) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
             %{"paymentMethodId" => payment_method_id}
           ) do
      {:ok, CartDetail.new(data)}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90040}, status_code: 404}} ->
        {:paywizard_error, :cart_not_found}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 90045}, status_code: 400}} ->
        {:paywizard_error, :payment_authorisation_fault}
    end
  end

  @callback cancel_contract(Customer.customer_id(), Contract.contract_id()) ::
              {:ok, cancellation_date :: Date.t()} | {:paywizard_error, :contract_cancellation_fault}
  def cancel_contract(customer_id, contract_id, cancel_date \\ "") do
    with {:ok, %Paywizard.Response{json: %{"cancellationDate" => cancellation_date}, status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel", %{
             "cancelDate" => cancel_date
           }) do
      Date.from_iso8601(cancellation_date)
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90006}, status_code: 400}} ->
        {:paywizard_error, :contract_cancellation_fault}
    end
  end

  @callback withdraw_cancel_contract(Customer.customer_id(), Contract.contract_id()) ::
              :ok | {:paywizard_error, :cancellation_withdrawal_fault}
  def withdraw_cancel_contract(customer_id, contract_id) do
    with {:ok, %Paywizard.Response{status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel/withdraw", %{}) do
      :ok
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90017}}} ->
        {:paywizard_error, :cancellation_withdrawal_fault}
    end
  end

  @callback crossgrades_for_contract(Customer.customer_id(), Contract.contract_id()) :: {:ok, list(item_id :: binary)}
  def crossgrades_for_contract(customer_id, contract_id) do
    with {:ok, %Paywizard.Response{json: %{"crossgradePaths" => crossgrade_paths}, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change") do
      crossgrades = Enum.map(crossgrade_paths, fn crossgrade_path -> Paywizard.Crossgrade.new(crossgrade_path) end)
      {:ok, crossgrades}
    end
  end

  @callback item_by_id_and_currency(binary, currency) :: {:ok, Item.t()}
  def item_by_id_and_currency(item_id, currency) do
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/catalogue/v1/item/#{item_id}?currency=#{currency}") do
      {:ok, Item.new(data)}
    else
      error ->
        raise "item_by_id_and_currency did not get an successful response. Error: #{inspect(error)}"
    end
  end

  defp cart_items_with_discount(item_id, meta_data) do
    %{items: [%{itemCode: item_id, itemData: item_data(meta_data)}]}
    |> add_discount(meta_data.discount)
  end

  defp add_discount(cart_data, %Paywizard.Discount{} = discount) do
    Map.put(cart_data, :discountCode, discount_code(discount))
  end

  defp add_discount(cart_data, nil), do: cart_data

  defp discount_code(%Paywizard.Discount{is_single_use: true} = discount) do
    %{
      individualPromoCode: discount.promotion
    }
  end

  defp discount_code(%Paywizard.Discount{} = discount) do
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
    with {:ok, %Paywizard.Response{json: %{"paymentMethodId" => payment_method_id}, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod",
             digest
           ) do
      {:ok, payment_method_id}
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 90054}, status_code: 400}} ->
        {:paywizard_error, :receipt_not_found}

      {:ok, %Paywizard.Response{json: %{"errorCode" => 90047}, status_code: 400}} ->
        {:paywizard_error, :transaction_not_found}
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
    with {:ok, %Paywizard.Response{json: data, status_code: 200}} <- http_client().post(path_prefix <> path, payload) do
      items = Map.get(data, "items", [])
      acc = acc ++ items

      case data do
        %{"nextPageLink" => path} -> items_pager(path_prefix, path, payload, acc)
        _ -> {:ok, PPV.new(acc)}
      end
    else
      {:ok, %Paywizard.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:paywizard_error, :customer_not_found}
    end
  end

  defp http_client, do: Application.get_env(:paywizard, :http_client, Paywizard.HTTPClient)
end
