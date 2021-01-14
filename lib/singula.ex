defmodule Singula do
  alias Singula.{CartDetail, Contract, ContractDetails, Customer, Digest, Item, MetaData, PaymentMethodProvider, PPV}
  require Logger

  @type error :: Singula.Error.t()

  @callback create_customer(Customer.t()) :: {:ok, Customer.id()} | {:error, error}
  def create_customer(customer) do
    payload = Customer.to_payload(customer) |> Map.put(:title, "-")

    with {:ok, %Singula.Response{json: %{"href" => href}}} <-
           post(:create_customer, "/apis/customers/v1/customer", payload, 201) do
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

    with {:ok, _response} <-
           patch(:update_customer, "/apis/customers/v1/customer/#{customer.id}", payload, 201) do
      :ok
    end
  end

  @callback anonymise_customer(Customer.id()) :: :ok | {:error, error}
  def anonymise_customer(customer_id) do
    with {:ok, _response} <-
           post(
             :anonymise_customer,
             "/apis/customers/v1/customer/#{customer_id}/anonymise",
             "",
             200
           ) do
      :ok
    end
  end

  @callback customer_fetch(Customer.id()) :: {:ok, Customer.t()} | {:error, error}
  def customer_fetch(customer_id) do
    with {:ok, %Singula.Response{json: data}} <- get(:customer_fetch, "/apis/customers/v1/customer/#{customer_id}", 200) do
      {:ok, Customer.new(data)}
    end
  end

  def customer_search(query) when is_map(query) do
    with :ok <- validate_query(query),
         {:ok, %Singula.Response{json: data}} <-
           post(
             :customer_search,
             "/apis/customers/v1/customer/search",
             query,
             200
           ) do
      {:ok, Customer.new(data)}
    end
  end

  @callback customer_search(String.t() | map()) :: {:ok, Customer.t()} | {:error, error}
  def customer_search(external_id) do
    customer_search(%{"externalUniqueIdentifier" => external_id})
  end

  defp validate_query(query) do
    Map.keys(query)
    |> Enum.reject(fn key ->
      Enum.member?(["customerId", "email", "externalUniqueIdentifier"], key)
    end)
    |> case do
      [] ->
        :ok

      invalid_keys ->
        {:error, %Singula.Error{developer_message: "Following key(s) are invalid: #{inspect(invalid_keys)}"}}
    end
  end

  @callback customer_contracts(Customer.id()) :: {:ok, list(Contract.t())} | {:error, error}
  @callback customer_contracts(Customer.id(), active_only :: boolean) ::
              {:ok, list(Contract.t())} | {:error, error}
  def customer_contracts(customer_id, active_only \\ true) do
    with {:ok, %Singula.Response{json: data}} <-
           get(
             :customer_contracts,
             "/apis/contracts/v1/customer/#{customer_id}/contract?activeOnly=#{active_only}",
             200
           ) do
      {:ok, Contract.new(data)}
    end
  end

  @callback customer_contract(Customer.id(), Contract.contract_id()) :: {:ok, ContractDetails.t()} | {:error, error}
  def customer_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: data}} <-
           get(
             :customer_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}",
             200
           ) do
      {:ok, ContractDetails.new(data)}
    end
  end

  @callback customer_purchases_ppv(Customer.id()) :: {:ok, list(PPV.t())} | {:error, error}
  def customer_purchases_ppv(customer_id) do
    items_pager("/apis/purchases/v1", "/customer/#{customer_id}/purchases/1", %{type: "PPV"})
  end

  @callback fetch_single_use_promo_code(promo_code :: binary) :: {:ok, map} | {:error, error}
  def fetch_single_use_promo_code(promo_code) do
    with {:ok, %Singula.Response{json: data}} <-
           get(:fetch_single_use_promo_code, "/apis/purchases/v1/promocode/#{URI.encode(promo_code)}", 200) do
      {:ok, data}
    end
  end

  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency()) ::
              {:ok, cart_id :: binary} | {:error, error}
  @callback create_cart_with_item(Customer.id(), item_id :: binary, Item.currency(), MetaData.t()) ::
              {:ok, cart_id :: binary} | {:error, error}
  def create_cart_with_item(customer_id, item_id, currency, meta_data \\ %MetaData{}) do
    with {:ok, %Singula.Response{json: %{"href" => href}}} <-
           post(
             :create_cart_with_item,
             "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
             cart_items_with_discount(item_id, meta_data),
             201
           ) do
      cart_id = String.split(href, "/") |> List.last()
      {:ok, cart_id}
    end
  end

  @callback fetch_cart(Customer.id(), cart_id :: binary) :: {:ok, CartDetail.t()} | {:error, error}
  def fetch_cart(customer_id, cart_id) do
    with {:ok, %Singula.Response{json: data}} <-
           get(:fetch_cart, "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}", 200) do
      {:ok, CartDetail.new(data)}
    end
  end

  @callback fetch_item_discounts(item_id :: binary, Item.currency()) :: {:ok, list} | {:error, error}
  def fetch_item_discounts(item_id, currency) do
    with {:ok, %Singula.Response{json: %{"discounts" => discounts}}} <-
           get(:fetch_item_discounts, "/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}", 200) do
      {:ok, discounts}
    end
  end

  @callback customer_redirect_dibs(Customer.id(), Item.currency(), map) :: {:ok, map} | {:error, error}
  def customer_redirect_dibs(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data}} <-
           post(
             :customer_redirect_dibs,
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:DIBS, currency, redirect_data),
             200
           ) do
      {:ok, data}
    end
  end

  @callback customer_redirect_klarna(Customer.id(), Item.currency(), map) :: {:ok, map} | {:error, error}
  def customer_redirect_klarna(customer_id, currency, redirect_data) do
    with {:ok, %Singula.Response{json: data}} <-
           post(
             :customer_redirect_klarna,
             "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
             Digest.generate(:KLARNA, currency, redirect_data),
             200
           ) do
      {:ok, data}
    end
  end

  @callback payment_methods(Customer.id()) ::
              {:ok, [Singula.DibsPaymentMethod.t() | Singula.KlarnaPaymentMethod.t()]} | {:error, error}
  def payment_methods(customer_id) do
    with {:ok, %Singula.Response{json: %{"PaymentMethod" => payment_methods}}} <-
           get(:customer_payment_methods, "/apis/payment-methods/v1/customer/#{customer_id}/list", 200) do
      payment_methods =
        Enum.reduce(payment_methods, [], fn
          %{"provider" => "DIBS"} = payment_method, acc ->
            [Singula.DibsPaymentMethod.new(payment_method) | acc]

          %{"provider" => "KLARNA"} = payment_method, acc ->
            [Singula.KlarnaPaymentMethod.new(payment_method) | acc]

          _, acc ->
            acc
        end)
        |> Enum.reverse()

      {:ok, payment_methods}
    end
  end

  @callback update_payment_method(Customer.id(), Contract.contract_id(), integer) :: :ok | {:error, error}
  def update_payment_method(customer_id, contract_id, payment_method_id) do
    with {:ok, _response} <-
           post(
             :update_payment_method,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/paymentmethod",
             %{paymentMethodId: payment_method_id},
             200
           ) do
      :ok
    end
  end

  @callback add_payment_method(Customer.id(), Item.currency(), PaymentMethodProvider.t()) ::
              {:ok, payment_method_id :: integer} | {:error, error}
  def add_payment_method(customer_id, currency, payment_method) do
    digest =
      Digest.generate(
        PaymentMethodProvider.name(payment_method),
        currency,
        PaymentMethodProvider.data(payment_method)
      )

    add_payment_method(customer_id, digest)
  end

  @callback customer_cart_checkout(Customer.id(), binary, integer) :: {:ok, CartDetail.t()} | {:error, error}
  def customer_cart_checkout(customer_id, cart_id, payment_method_id) do
    with {:ok, %Singula.Response{json: data}} <-
           post(
             :customer_cart_checkout,
             "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
             %{"paymentMethodId" => payment_method_id},
             200
           ) do
      {:ok, CartDetail.new(data)}
    end
  end

  @callback cancel_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, cancellation_date :: Date.t()} | {:error, error}
  @callback cancel_contract(Customer.id(), Contract.contract_id(), cancel_date :: Date.t()) ::
              {:ok, cancellation_date :: Date.t()} | {:error, error}
  def cancel_contract(customer_id, contract_id, cancel_date \\ nil) do
    data = if cancel_date, do: %{"cancelDate" => cancel_date}, else: %{}

    with {:ok, %Singula.Response{json: %{"cancellationDate" => cancellation_date}}} <-
           post(
             :cancel_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel",
             data,
             200
           ) do
      Date.from_iso8601(cancellation_date)
    end
  end

  @callback withdraw_cancel_contract(Customer.id(), Contract.contract_id()) :: :ok | {:error, error}
  def withdraw_cancel_contract(customer_id, contract_id) do
    with {:ok, _response} <-
           post(
             :withdraw_cancel_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/cancel/withdraw",
             %{},
             200
           ) do
      :ok
    end
  end

  @callback crossgrades_for_contract(Customer.id(), Contract.contract_id()) ::
              {:ok, list(Singula.Crossgrade.t())} | {:error, error}
  def crossgrades_for_contract(customer_id, contract_id) do
    with {:ok, %Singula.Response{json: json}} <-
           get(
             :crossgrades_for_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change",
             200
           ) do
      crossgrades =
        json
        |> Map.get("crossgradePaths", [])
        |> Enum.map(fn crossgrade_path ->
          Singula.Crossgrade.new(crossgrade_path)
        end)

      {:ok, crossgrades}
    end
  end

  @callback change_contract(Customer.id(), Contract.contract_id(), item_id :: binary) :: :ok | {:error, error}
  @callback change_contract(Customer.id(), Contract.contract_id(), item_id :: binary, referrer :: binary | nil) ::
              :ok | {:error, error}
  def change_contract(customer_id, contract_id, item_id, referrer \\ nil) do
    data = %{itemCode: item_id}

    data =
      if referrer do
        Map.put(data, :referrerId, referrer)
      else
        data
      end

    with {:ok, _response} <-
           post(
             :change_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change",
             data,
             200
           ) do
      :ok
    end
  end

  @callback withdraw_change_contract(Customer.id(), Contract.contract_id()) :: :ok | {:error, error}
  def withdraw_change_contract(customer_id, contract_id) do
    with {:ok, _response} <-
           post(
             :withdraw_change_contract,
             "/apis/contracts/v1/customer/#{customer_id}/contract/#{contract_id}/change/withdraw",
             %{},
             200
           ) do
      :ok
    end
  end

  @callback item_by_id_and_currency(item_id :: binary, Item.currency()) :: {:ok, Item.t()} | {:error, error}
  def item_by_id_and_currency(item_id, currency) do
    with {:ok, %Singula.Response{json: data}} <-
           get(:item_by_id_and_currency, "/apis/catalogue/v1/item/#{item_id}?currency=#{currency}", 200) do
      {:ok, Item.new(data)}
    end
  end

  @callback category(category_id :: binary | integer, limited :: boolean) ::
              {:ok, %Singula.Category{}} | {:error, error}
  def category(category_id, limited \\ true) do
    with {:ok, %Singula.Response{json: data}} <-
           get(:category, "/apis/catalogue/v1/category/#{category_id}?limited=#{limited}", 200) do
      {:ok, Singula.Category.new(data)}
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

  defp add_payment_method(customer_id, digest) do
    with {:ok, %Singula.Response{json: %{"paymentMethodId" => payment_method_id}}} <-
           post(
             :add_payment_method,
             "/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod",
             digest,
             200
           ) do
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
    with {:ok, %Singula.Response{json: data}} <-
           post(:customer_paged_purchases, path_prefix <> path, payload, 200) do
      items = Map.get(data, "items", [])
      acc = acc ++ items

      case data do
        %{"nextPageLink" => path} -> items_pager(path_prefix, path, payload, acc)
        _ -> {:ok, PPV.new(acc)}
      end
    end
  end

  defp request(request_fn, request_args, success_status_code) do
    with {:ok, %Singula.Response{status_code: ^success_status_code}} = result <- Kernel.apply(request_fn, request_args) do
      result
    else
      {:ok, %Singula.Response{} = response} ->
        {:error, %Singula.Error{developer_message: inspect(response)}}

      {:error, %Singula.Error{} = error} ->
        {:error, error}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, %Singula.Error{developer_message: HTTPoison.Error.message(error)}}
    end
  end

  defp get(label, path, success_status_code) do
    log(label, fn ->
      request(&http_client().get/1, [path], success_status_code)
    end)
  end

  defp post(label, path, body, success_status_code) do
    log(label, fn ->
      request(&http_client().post/2, [path, body], success_status_code)
    end)
  end

  defp patch(label, path, body, success_status_code) do
    log(label, fn ->
      request(&http_client().patch/2, [path, body], success_status_code)
    end)
  end

  defp log(name, request_function) do
    {time, response} = :timer.tc(request_function)

    Singula.Telemetry.emit_response_time(name, div(time, 1000))

    response
  end

  defp http_client, do: Application.get_env(:singula, :http_client, Singula.HTTPClient)
end
