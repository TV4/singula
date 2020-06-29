defmodule Singula do
  alias Singula.{
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

  @callback create_customer(Customer.t()) ::
              {:ok, Customer.id()}
              | {:error,
                 :singula_username_exists_failure_fault
                 | :singula_email_address_already_exists_fault
                 | :singula_external_unique_identifier_already_exists_fault}
  def create_customer(customer) do
    payload = Customer.to_payload(customer) |> Map.put(:title, "-")

    with {:ok, %Singula.Response{json: %{"href" => href}, status_code: 201}} <-
           http_client().post("/apis/customers/v1/customer", payload) do
      customer_id = String.split(href, "/") |> List.last()
      {:ok, customer_id}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90074}, status_code: 400}} ->
        {:error, :singula_username_exists_failure_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90084}, status_code: 400}} ->
        {:error, :singula_external_unique_identifier_already_exists_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90101}, status_code: 400}} ->
        {:error, :singula_email_address_already_exists_fault}
    end
  end

  @callback update_customer(Customer.t()) :: :ok
  def update_customer(customer) do
    payload =
      Customer.to_payload(customer)
      |> Enum.reject(fn {_key, value} -> value in [[], nil] end)
      |> Map.new()

    with {:ok, %Singula.Response{status_code: 201}} <-
           http_client().patch("/apis/customers/v1/customer/#{customer.id}", payload) do
      :ok
    end
  end

  @callback anonymise_customer(Customer.id()) :: :ok
  def anonymise_customer(customer_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           http_client().post("/apis/customers/v1/customer/#{customer_id}/anonymise", "") do
      :ok
    end
  end

  @callback customer_fetch(Customer.id()) :: {:ok, Customer.t()} | {:error, :singula_invalid_customer_id_fault}
  def customer_fetch(customer_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/customers/v1/customer/#{customer_id}") do
      {:ok, Customer.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90068}, status_code: 404}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_search(binary) :: {:ok, Customer.t()} | {:error, :singula_invalid_customer_id_fault}
  def customer_search(external_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => external_id}) do
      {:ok, Customer.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90068}, status_code: 404}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_contracts(Customer.id()) ::
              {:ok, list(Contract.t())} | {:error, :singula_invalid_customer_id_fault}
  def customer_contracts(customer_id, active_only \\ true) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract?activeOnly=#{active_only}") do
      {:ok, Contract.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, ContractDetails.t()} | {:error, :singula_invalid_customer_id_fault}
  def customer_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}") do
      {:ok, ContractDetails.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_purchases_ppv(Customer.id()) ::
              {:ok, list(PPV.t())} | {:error, :singula_invalid_customer_id_fault}
  def customer_purchases_ppv(customer_id) do
    items_pager("/apis/purchases/v1", "/customer/#{customer_id}/purchases/1", %{type: "PPV"})
  end

  @callback fetch_single_use_promo_code(promo_code :: binary) ::
              {:ok, map} | {:error, :singula_no_promo_code_found_fault}
  def fetch_single_use_promo_code(promo_code) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/purchases/v1/promocode/#{promo_code}") do
      {:ok, data}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90123}, status_code: 400}} ->
        {:error, :singula_no_promo_code_found_fault}
    end
  end

  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency()) ::
              {:ok, cart_id :: binary}
              | {:error,
                 :singula_unknown_item_code_fault
                 | :singula_invalid_customer_id_fault
                 | :singula_unable_to_add_items_fault}
  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency(), MetaData.t()) ::
              {:ok, cart_id :: binary}
              | {:error,
                 :singula_unknown_item_code_fault
                 | :singula_invalid_customer_id_fault
                 | :singula_unable_to_add_items_fault
                 | :singula_invalid_discount_code_fault
                 | :singula_discount_criteria_not_matched_fault}
  def create_cart_with_item(customer_id, item_id, currency, meta_data \\ %MetaData{}) do
    with {:ok, %Singula.Response{json: %{"href" => href}, status_code: 201}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
             cart_items_with_discount(item_id, meta_data)
           ) do
      cart_id = String.split(href, "/") |> List.last()
      {:ok, cart_id}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90022}, status_code: 404}} ->
        {:error, :singula_invalid_discount_code_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90069}, status_code: 404}} ->
        {:error, :singula_unknown_item_code_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90062}, status_code: 400}} ->
        {:error, :singula_unable_to_add_items_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90115}, status_code: 400}} ->
        {:error, :singula_discount_criteria_not_matched_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback fetch_cart(Customer.id(), cart_id :: binary) ::
              {:ok, CartDetail.t()}
              | {:error, :singula_no_cart_found_fault | :singula_invalid_customer_id_fault}
  def fetch_cart(customer_id, cart_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}") do
      {:ok, CartDetail.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90040}, status_code: 404}} ->
        {:error, :singula_no_cart_found_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback fetch_item_discounts(item_id :: binary, Item.currency()) :: {:ok, list}
  def fetch_item_discounts(item_id, currency) do
    {:ok, %Singula.Response{json: %{"discounts" => discounts}, status_code: 200}} =
      http_client().get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")

    {:ok, discounts}
  end

  @callback customer_redirect_dibs(Customer.id(), Item.currency(), map) ::
              {:ok, map}
              | {:error, :singula_invalid_customer_id_fault}
  def customer_redirect_dibs(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:DIBS, currency, redirect_data)
           ) do
      {:ok, data}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_redirect_klarna(Customer.id(), Item.currency(), map) ::
              {:ok, map}
              | {:error, :singula_invalid_customer_id_fault}
  def customer_redirect_klarna(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:KLARNA, currency, redirect_data)
           ) do
      {:ok, data}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  @callback customer_payment_method(Customer.id(), Item.currency(), DibsPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer}
              | {:error, :singula_provider_processing_fault | :singula_payment_method_creation_failed_fault}
  def customer_payment_method(customer_id, currency, %DibsPaymentMethod{} = dibs_payment_method) do
    digest = Digest.generate(:DIBS, currency, Map.from_struct(dibs_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_payment_method(Customer.id(), Item.currency(), KlarnaPaymentMethod.t()) ::
              {:ok, payment_method_id :: integer}
              | {:error, :singula_provider_processing_fault | :singula_payment_method_creation_failed_fault}
  def customer_payment_method(customer_id, currency, %KlarnaPaymentMethod{} = klarna_payment_method) do
    digest = Digest.generate(:KLARNA, currency, KlarnaPaymentMethod.to_provider_data(klarna_payment_method))
    create_payment_method(customer_id, digest)
  end

  @callback customer_cart_checkout(Customer.id(), binary, integer) ::
              {:ok, CartDetail.t()} | {:error, :singula_no_cart_found_fault | :singula_payment_authorisation_fault}
  def customer_cart_checkout(customer_id, cart_id, payment_method_id) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
             %{"paymentMethodId" => payment_method_id}
           ) do
      {:ok, CartDetail.new(data)}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90040}, status_code: 404}} ->
        {:error, :singula_no_cart_found_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90045}, status_code: 400}} ->
        {:error, :singula_payment_authorisation_fault}
    end
  end

  @callback cancel_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, cancellation_date :: Date.t()} | {:error, :singula_contract_cancellation_fault}
  def cancel_contract(customer_id, contract_id, cancel_date \\ "") do
    with {:ok, %Singula.Response{json: %{"cancellationDate" => cancellation_date}, status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel", %{
             "cancelDate" => cancel_date
           }) do
      Date.from_iso8601(cancellation_date)
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90006}, status_code: 400}} ->
        {:error, :singula_contract_cancellation_fault}
    end
  end

  @callback withdraw_cancel_contract(Customer.id(), Contract.contract_id()) ::
              :ok | {:error, :singula_cancellation_withdrawal_fault}
  def withdraw_cancel_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel/withdraw", %{}) do
      :ok
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90017}}} ->
        {:error, :singula_cancellation_withdrawal_fault}
    end
  end

  @callback crossgrades_for_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, list(Singula.Crossgrade.t())}
  def crossgrades_for_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: %{"crossgradePaths" => crossgrade_paths}, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change") do
      crossgrades = Enum.map(crossgrade_paths, fn crossgrade_path -> Singula.Crossgrade.new(crossgrade_path) end)
      {:ok, crossgrades}
    end
  end

  @callback change_contract(Customer.id(), Contract.contract_id(), item_id :: binary) :: :ok
  def change_contract(customer_id, contract_id, item_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change", %{
             itemCode: item_id
           }) do
      :ok
    end
  end

  @callback withdraw_change_contract(Customer.id(), Contract.contract_id()) ::
              :ok | {:error, :singula_change_withdrawal_fault}
  def withdraw_change_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change/withdraw", %{}) do
      :ok
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90108}}} ->
        {:error, :singula_change_withdrawal_fault}
    end
  end

  @callback item_by_id_and_currency(item_id :: binary, Item.currency()) ::
              {:ok, Item.t()} | {:error, :singula_system_failure_fault}
  def item_by_id_and_currency(item_id, currency) do
    with {:ok, %Singula.Response{json: data, status_code: 200}} <-
           http_client().get("/apis/catalogue/v1/item/#{item_id}?currency=#{currency}") do
      {:ok, Item.new(data)}
    else
      _ -> {:error, :singula_system_failure_fault}
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
    %{
      individualPromoCode: discount.promotion
    }
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
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod",
             digest
           ) do
      {:ok, payment_method_id}
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 90054}, status_code: 400}} ->
        {:error, :singula_provider_processing_fault}

      {:ok, %Singula.Response{json: %{"errorCode" => 90047}, status_code: 400}} ->
        {:error, :singula_payment_method_creation_failed_fault}
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
    with {:ok, %Singula.Response{json: data, status_code: 200}} <- http_client().post(path_prefix <> path, payload) do
      items = Map.get(data, "items", [])
      acc = acc ++ items

      case data do
        %{"nextPageLink" => path} -> items_pager(path_prefix, path, payload, acc)
        _ -> {:ok, PPV.new(acc)}
      end
    else
      {:ok, %Singula.Response{json: %{"errorCode" => 500}, status_code: 500}} ->
        {:error, :singula_invalid_customer_id_fault}
    end
  end

  defp http_client, do: Application.get_env(:singula, :http_client, Singula.HTTPClient)
end
