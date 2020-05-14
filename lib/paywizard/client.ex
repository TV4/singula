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
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().get("/apis/customers/v1/customer/#{customer_id}") do
      {:ok, response} = Jason.decode(body)
      {:ok, Customer.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} ->
        {:ok, %{"errorCode" => 90068}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_search(binary) :: {:ok, Customer.t()} | {:paywizard_error, :customer_not_found}
  def customer_search(external_id) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => external_id}) do
      {:ok, response} = Jason.decode(body)
      {:ok, Customer.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} ->
        {:ok, %{"errorCode" => 90068}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_contracts(Customer.customer_id()) ::
              {:ok, list(Contract.t())} | {:paywizard_error, :customer_not_found}
  def customer_contracts(customer_id, active_only \\ true) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract?activeOnly=#{active_only}") do
      {:ok, response} = Jason.decode(body)
      {:ok, Contract.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_contract(Customer.customer_id(), Contract.contract_id()) ::
              {:ok, ContractDetails.t()} | {:paywizard_error, :customer_not_found}
  def customer_contract(customer_id, contract_id) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().get("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}") do
      {:ok, response} = Jason.decode(body)
      {:ok, ContractDetails.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback cancel_contract(Customer.customer_id(), Contract.contract_id()) :: {:ok, cancellation_date :: Date.t()}
  def cancel_contract(customer_id, contract_id, cancel_date \\ "") do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel", %{
        "cancelDate" => cancel_date
      })

    {:ok, %{"cancellationDate" => cancellation_date}} = Jason.decode(body)
    Date.from_iso8601(cancellation_date)
  end

  @callback withdraw_cancel_contract(Customer.customer_id(), Contract.contract_id()) ::
              :ok | {:paywizard_error, :cancellation_withdrawal_fault}
  def withdraw_cancel_contract(customer_id, contract_id) do
    with {:ok, %HTTPoison.Response{status_code: 200}} <-
           http_client().post("/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel/withdraw", %{}) do
      :ok
    else
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"errorCode" => 90017}} -> {:paywizard_error, :cancellation_withdrawal_fault}
        end
    end
  end

  @callback customer_purchases_ppv(Customer.customer_id()) ::
              {:ok, list(PPV.t())} | {:paywizard_error, :customer_not_found}
  def customer_purchases_ppv(customer_id) do
    items_pager("/apis/purchases/v1", "/customer/#{customer_id}/purchases/1", %{type: "PPV"})
  end

  defp items_pager(path_prefix, path, payload, acc \\ []) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <- http_client().post(path_prefix <> path, payload),
         {:ok, data} <- Jason.decode(body) do
      items = Map.get(data, "items", [])
      acc = acc ++ items

      case data do
        %{"nextPageLink" => path} -> items_pager(path_prefix, path, payload, acc)
        _ -> {:ok, PPV.new(acc)}
      end
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
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

  defp cart_items_with_discount(item_id, meta_data) do
    %{items: [%{itemCode: item_id, itemData: item_data(meta_data)}]}
    |> add_discount(meta_data.discount)
  end

  defp add_discount(cart_data, %Paywizard.Discount{} = discount) do
    discount_code =
      %{
        discountId: discount.discount,
        campaignCode: discount.campaign,
        promoCode: discount.promotion,
        sourceCode: discount.source
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    Map.put(cart_data, :discountCode, discount_code)
  end

  defp add_discount(cart_data, nil), do: cart_data

  @callback create_cart_with_item(Customer.customer_id(), binary, currency) ::
              {:ok, cart_id :: binary}
              | {:paywizard_error, :incorrect_item | :customer_not_found | :item_not_added_to_cart}
  @callback create_cart_with_item(Customer.customer_id(), binary, currency, MetaData.t()) ::
              {:ok, cart_id :: binary}
              | {:paywizard_error,
                 :incorrect_item | :customer_not_found | :item_not_added_to_cart | :discount_not_found}
  def create_cart_with_item(customer_id, item_id, currency, meta_data \\ %MetaData{}) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 201}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
             cart_items_with_discount(item_id, meta_data)
           ) do
      {:ok, %{"href" => href}} = Jason.decode(body)
      cart_id = String.split(href, "/") |> List.last()
      {:ok, cart_id}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} ->
        Jason.decode(body)
        |> case do
          {:ok, %{"errorCode" => 90022}} -> {:paywizard_error, :discount_not_found}
          {:ok, %{"errorCode" => 90069}} -> {:paywizard_error, :incorrect_item}
        end

      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}

      {:ok, %HTTPoison.Response{body: body, status_code: 400}} ->
        Jason.decode(body)
        |> case do
          {:ok, %{"errorCode" => 90062}} -> {:paywizard_error, :item_not_added_to_cart}
          {:ok, %{"userMessage" => "Discount criteria not matched"}} -> {:paywizard_error, :discount_not_found}
        end
    end
  end

  @callback fetch_cart(Customer.customer_id(), binary) ::
              {:ok, CartDetail.t()}
              | {:paywizard_error, :cart_not_found | :customer_not_found}
  def fetch_cart(customer_id, cart_id) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}") do
      {:ok, response} = Jason.decode(body)
      {:ok, CartDetail.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} ->
        {:ok, %{"errorCode" => 90040}} = Jason.decode(body)
        {:paywizard_error, :cart_not_found}

      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback fetch_item_discounts(item_id :: binary, currency :: currency) :: {:ok, list}
  def fetch_item_discounts(item_id, currency) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      http_client().get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")

    {:ok, %{"discounts" => discounts}} = Jason.decode(body)
    {:ok, discounts}
  end

  @callback customer_redirect_dibs(Customer.customer_id(), currency) ::
              {:ok, map}
              | {:paywizard_error, :customer_not_found}
  def customer_redirect_dibs(customer_id, currency) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:DIBS, currency, dibs_redirect_data())
           ) do
      {:ok, _response} = Jason.decode(body)
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
        {:paywizard_error, :customer_not_found}
    end
  end

  @callback customer_redirect_klarna(Customer.customer_id(), currency) ::
              {:ok, map}
              | {:paywizard_error, :customer_not_found}
  def customer_redirect_klarna(customer_id, currency) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:KLARNA, currency, klarna_redirect_data(currency))
           ) do
      {:ok, _response} = Jason.decode(body)
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} ->
        {:ok, %{"errorCode" => 500}} = Jason.decode(body)
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

  defp create_payment_method(customer_id, digest) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().post(
             "/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod",
             digest
           ) do
      {:ok, %{"paymentMethodId" => payment_method_id}} = Jason.decode(body)
      {:ok, payment_method_id}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 400}} ->
        Jason.decode(body)
        |> case do
          {:ok, %{"errorCode" => 90054}} -> {:paywizard_error, :receipt_not_found}
          {:ok, %{"errorCode" => 90047}} -> {:paywizard_error, :transaction_not_found}
        end
    end
  end

  @callback customer_cart_checkout(Customer.customer_id(), binary, integer) ::
              {:ok, CartDetail.t()} | {:paywizard_error, :cart_not_found | :payment_authorisation_fault}
  def customer_cart_checkout(customer_id, cart_id, payment_method_id) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client().post(
             "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
             %{"paymentMethodId" => payment_method_id}
           ) do
      {:ok, response} = Jason.decode(body)
      {:ok, CartDetail.new(response)}
    else
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} ->
        {:ok, %{"errorCode" => 90040}} = Jason.decode(body)
        {:paywizard_error, :cart_not_found}

      {:ok, %HTTPoison.Response{body: body, status_code: 400}} ->
        {:ok, %{"errorCode" => 90045}} = Jason.decode(body)
        {:paywizard_error, :payment_authorisation_fault}
    end
  end

  @callback item_by_id_and_currency(binary, currency) :: {:ok, Item.t()}
  def item_by_id_and_currency(item_id, currency) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      http_client().get("/apis/catalogue/v1/item/#{item_id}?currency=#{currency}")

    {:ok, data} = Jason.decode(body)
    {:ok, Item.new(data)}
  end

  # def customer_is_username_available(username) do
  #   {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
  #     http_client().post(
  #       "/apis/customers/v1/customer/isusernameavailable",
  #       %{"username" => username}
  #     )

  #   {:ok, _response} = Jason.decode(body)
  # end

  defp dibs_redirect_data do
    # TODO: set production values once known.
    %{
      itemDescription: "REGISTER_CARD",
      amount: "1.00",
      payment_method: "cc.test",
      billing_city: "Stockholm"
    }
  end

  defp klarna_redirect_data(currency) do
    %{
      itemDescription: "REGISTER_CARD",
      countryCode: "SE",
      amount: "1.00",
      currency: currency,
      subscription: true,
      duration: 12,
      productIdentifier: "test",
      authorisation: false,
      tax_amount: 0,
      purchase_country: "SE",
      tax_rate: 0
    }
  end

  defp http_client, do: Application.get_env(:paywizard, :http_client, Paywizard.HTTPClient)
end
