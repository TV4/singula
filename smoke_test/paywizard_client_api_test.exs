defmodule SmokeTest.PaywizardClientApi do
  use ExUnit.Case
  require Logger

  alias Paywizard.Response
  alias Paywizard.HTTPClient

  setup_all do
    Application.put_all_env(
      paywizard: [
        http_client: Paywizard.HTTPClient,
        uuid_generator: &UUID.uuid4/0,
        base_url: System.get_env("PAYWIZARD_BASE_URL"),
        api_key: System.get_env("PAYWIZARD_API_KEY"),
        api_secret: System.get_env("PAYWIZARD_API_SECRET"),
        client_name: System.get_env("PAYWIZARD_CLIENT_NAME"),
        merchant_password: System.get_env("PAYWIZARD_MERCHANT_PASSWORD"),
        timeout_ms: System.get_env("PAYWIZARD_TIMEOUT_MS", "10000") |> String.to_integer()
      ]
    )
  end

  setup_all [:setup_test_customer, :setup_defaults]
  setup :merge_saved_test_context

  describe "Searching external id" do
    test "returns set parameters", %{customer_id: customer_id, email: email, username: username, vimond_id: vimond_id} do
      assert Paywizard.Client.customer_search(vimond_id) ==
               {:ok,
                %Paywizard.Customer{
                  active: true,
                  address_post_code: 12220,
                  custom_attributes: [
                    %{name: "Accepted Play Terms Date", value: "2020-02-25"},
                    %{name: "Accepted Play Terms", value: "Telia"}
                  ],
                  customer_id: customer_id,
                  date_of_birth: nil,
                  email: email,
                  external_unique_id: to_string(vimond_id),
                  first_name: "Forename",
                  last_name: "TV4 Media SmokeTest",
                  username: username
                }}
    end

    test "returns error 90068 when not finding customer" do
      assert Paywizard.Client.customer_search(666) == {:paywizard_error, :customer_not_found}
    end
  end

  describe("Fetching customer contract") do
    test "returns 0 when no contracts", %{customer_id: customer_id} do
      assert Paywizard.Client.customer_contracts(customer_id) == {:ok, []}
    end

    test "returns customer not found passing invalid UUID" do
      assert Paywizard.Client.customer_contracts("non_existing_customer_id") == {:paywizard_error, :customer_not_found}
    end
  end

  describe("Fetching customer PPV") do
    test "returns 0 when no PPV's", %{customer_id: customer_id} do
      assert Paywizard.Client.customer_purchases_ppv(customer_id) == {:ok, []}
    end

    test "returns customer not found passing invalid UUID" do
      assert Paywizard.Client.customer_purchases_ppv("non_existing_customer_id") ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "Creating cart with an item" do
    test "returns new cart with passed customer_id", %{
      customer_id: customer_id,
      subscription_item_id: subscription_item_id,
      currency: currency
    } do
      assert {:ok, cart_id} = Paywizard.Client.create_cart_with_item(customer_id, subscription_item_id, currency)

      save_in_test_context(:cart_id, cart_id)
    end

    test "returns PPV in cart when adding it", %{
      customer_id: customer_id,
      ppv_item_id: ppv_item_id,
      currency: currency,
      asset: asset
    } do
      assert {:ok, cart_id} =
               Paywizard.Client.create_cart_with_item(customer_id, ppv_item_id, currency, %Paywizard.MetaData{
                 asset: asset
               })

      save_in_test_context(:ppv_cart_id, cart_id)
    end

    test "returns customer not found passing invalid UUID", %{subscription_item_id: item_id, currency: currency} do
      assert Paywizard.Client.create_cart_with_item("non_existing_customer_id", item_id, currency) ==
               {:paywizard_error, :customer_not_found}
    end

    test "returns error 90069 for non-existing item code", %{customer_id: customer_id, currency: currency} do
      assert Paywizard.Client.create_cart_with_item(customer_id, "incorrect_item_id", currency) ==
               {:paywizard_error, :incorrect_item}
    end
  end

  describe "Fetching cart details" do
    test "returns no free trial subscription", %{
      customer_id: customer_id,
      currency: currency,
      no_free_trial_item_id: subscription_item_id
    } do
      assert {:ok, cart_id} = Paywizard.Client.create_cart_with_item(customer_id, subscription_item_id, currency)

      assert Paywizard.Client.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Paywizard.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Paywizard.CartDetail.Item{
                      cost: "449.00",
                      item_id: subscription_item_id,
                      item_name: "C More All Sport",
                      quantity: 1
                    }
                  ],
                  total_cost: "449.00"
                }}
    end

    test "returns added subscription", %{
      customer_id: customer_id,
      cart_id: cart_id,
      subscription_item_id: subscription_item_id
    } do
      assert Paywizard.Client.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Paywizard.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Paywizard.CartDetail.Item{
                      cost: "0.00",
                      item_id: subscription_item_id,
                      item_name: "C More TV4",
                      quantity: 1,
                      trial: %Paywizard.CartDetail.Item.Trial{
                        first_payment_amount: "139.00",
                        first_payment_date: Date.utc_today() |> Date.add(14),
                        free_trial: true
                      }
                    }
                  ],
                  total_cost: "0.00"
                }}
    end

    test "returns added ppv", %{customer_id: customer_id, ppv_cart_id: cart_id, ppv_item_id: ppv_item_id, asset: asset} do
      assert Paywizard.Client.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Paywizard.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Paywizard.CartDetail.Item{
                      asset: asset,
                      cost: "149.00",
                      item_id: ppv_item_id,
                      item_name: "PPV - 149",
                      quantity: 1
                    }
                  ],
                  total_cost: "149.00"
                }}
    end

    test "returns customer not found passing invalid UUID", %{cart_id: cart_id} do
      assert Paywizard.Client.fetch_cart("non_existing_customer_id", cart_id) == {:paywizard_error, :customer_not_found}
    end

    test "returns error 90040 for non-existing cart", %{customer_id: customer_id} do
      assert Paywizard.Client.fetch_cart(customer_id, 666) == {:paywizard_error, :cart_not_found}
    end

    test "unhandled error for invalid cart id ", %{customer_id: customer_id} do
      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.get("/apis/purchases/v1/customer/#{customer_id}/cart/non-numeric-cart")

      assert Jason.decode!(body) == %{
               "developerMessage" => "java.lang.NumberFormatException: For input string: \"non-numeric-cart\"",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }

      assert Paywizard.Client.fetch_cart(customer_id, "non-numeric-cart") == {:paywizard_error, :customer_not_found}
    end
  end

  describe "Fetching item on sale" do
    test "returns empty list for item without discount", %{no_discount_item_id: item_id, currency: currency} do
      assert Paywizard.Client.fetch_item_discounts(item_id, currency) == {:ok, []}
    end

    test "returns discount codes for item", %{subscription_item_id: item_id, currency: currency} do
      assert {:ok, discounts} = Paywizard.Client.fetch_item_discounts(item_id, currency)

      discount = Enum.find(discounts, fn discount -> discount["id"] == 10125 end)
      campaign = Enum.find(discount["linkedCombos"], fn campaign -> campaign["campaign"] == "TESTWITHCAMPAIGN" end)

      assert campaign == %{
               "campaign" => "TESTWITHCAMPAIGN",
               "promotion" => "PROMO1",
               "source" => "TESTWITHSOURCE"
             }

      save_in_test_context(:discount, %Paywizard.Discount{
        campaign: "TESTWITHCAMPAIGN",
        promotion: "PROMO1",
        source: "TESTWITHSOURCE"
      })
    end

    test "returns subscription with gated multi use discount", %{
      customer_id: customer_id,
      currency: currency,
      no_free_trial_item_id: subscription_item_id,
      discount: discount
    } do
      assert {:ok, cart_id} =
               Paywizard.Client.create_cart_with_item(customer_id, subscription_item_id, currency, %Paywizard.MetaData{
                 discount: discount
               })

      assert Paywizard.Client.fetch_cart(customer_id, cart_id) == {
               :ok,
               %Paywizard.CartDetail{
                 currency: :SEK,
                 discount: %Paywizard.CartDetail.Discount{
                   discount_amount: "224.50",
                   discount_end_date: nil
                 },
                 id: String.to_integer(cart_id),
                 items: [
                   %Paywizard.CartDetail.Item{
                     cost: "449.00",
                     item_id: "4151C241C3DD41529A87",
                     item_name: "C More All Sport",
                     quantity: 1
                   }
                 ],
                 total_cost: "224.50"
               }
             }
    end

    test "returns error 90022 for non-existing discount code", %{
      customer_id: customer_id,
      currency: currency,
      no_free_trial_item_id: subscription_item_id
    } do
      assert Paywizard.Client.create_cart_with_item(customer_id, subscription_item_id, currency, %Paywizard.MetaData{
               discount: %Paywizard.Discount{
                 campaign: "wrong_campaign",
                 source: "broken_source",
                 promotion: "invalid_promotion"
               }
             }) == {:paywizard_error, :discount_not_found}
    end
  end

  describe "Checking out cart" do
    test "redirect returns an transaction_id with redirect URL", %{customer_id: customer_id, currency: currency} do
      # BUG: Can return: "com.mgt.util.exception.system.SystemException: Error connecting to provider"

      dibs_redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      assert {:ok,
              %{
                "digest" => _digest,
                "redirectURL" => _redirect_form,
                "transactionId" => transaction_id,
                "type" => "redirect"
              }} = Paywizard.Client.customer_redirect_dibs(customer_id, currency, dibs_redirect_data)

      save_in_test_context(:transaction_id, transaction_id)
    end

    test "redirect returns customer not found passing invalid UUID", %{currency: currency} do
      dibs_redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      assert Paywizard.Client.customer_redirect_dibs("non_existing_customer_id", currency, dibs_redirect_data) ==
               {:paywizard_error, :customer_not_found}
    end

    test "setting up a dibs payment method returns a payment_method_id",
         %{
           customer_id: customer_id,
           payment_method_receipt: payment_method_receipt,
           transaction_id: transaction_id,
           currency: currency
         } do
      # TODO: The receipt is returned once the pre-populated form-data gets submitted.
      #       A hard coded receipt is used for testing until its properly received.

      dibs_payment_method = %Paywizard.DibsPaymentMethod{
        dibs_ccPart: "**** **** **** 0000",
        dibs_ccPrefix: "457110",
        dibs_ccType: "Visa",
        dibs_expM: "12",
        dibs_expY: "21",
        receipt: payment_method_receipt,
        transactionId: transaction_id
      }

      assert {:ok, payment_method_id} =
               Paywizard.Client.customer_payment_method(customer_id, currency, dibs_payment_method)

      save_in_test_context(:payment_method_id, payment_method_id)
    end

    test "checking out subscription cart returns cart details", %{
      customer_id: customer_id,
      cart_id: cart_id,
      payment_method_id: payment_method_id,
      subscription_item_id: item_id
    } do
      assert {:ok, %Paywizard.CartDetail{contract_id: contract_id, order_id: order_id} = cart} =
               Paywizard.Client.customer_cart_checkout(customer_id, cart_id, payment_method_id)

      assert cart == %Paywizard.CartDetail{
               contract_id: contract_id,
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "0.00",
                   item_id: item_id,
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Paywizard.CartDetail.Item.Trial{
                     first_payment_amount: "139.00",
                     first_payment_date: Date.utc_today() |> Date.add(14),
                     free_trial: true
                   }
                 }
               ],
               order_id: order_id,
               total_cost: "0.00"
             }

      refute contract_id == nil
      refute order_id == nil

      save_in_test_context(:contract_id, contract_id)
      save_in_test_context(:order_id, order_id)
    end

    test "checking out ppv cart returns cart details", %{
      customer_id: customer_id,
      ppv_cart_id: cart_id,
      payment_method_id: payment_method_id,
      ppv_item_id: item_id,
      asset: asset
    } do
      assert {:ok, %Paywizard.CartDetail{order_id: order_id} = cart} =
               Paywizard.Client.customer_cart_checkout(customer_id, cart_id, payment_method_id)

      assert cart == %Paywizard.CartDetail{
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "149.00",
                   item_id: item_id,
                   item_name: "PPV - 149",
                   asset: asset,
                   quantity: 1
                 }
               ],
               order_id: order_id,
               total_cost: "149.00"
             }

      refute order_id == nil
      save_in_test_context(:ppv_order_id, order_id)
    end
  end

  describe "Fetching customer contracts after checkout" do
    test "returns purchased subscription", %{
      customer_id: customer_id,
      subscription_item_id: item_id,
      contract_id: contract_id,
      order_id: order_id
    } do
      assert Paywizard.Client.customer_contracts(customer_id) ==
               {:ok,
                [
                  %Paywizard.Contract{
                    active: true,
                    contract_id: contract_id,
                    item_id: item_id,
                    item_name: "C More TV4",
                    order_id: order_id
                  }
                ]}
    end

    test "returns purchased pay per view", %{
      customer_id: customer_id,
      ppv_item_id: item_id,
      asset: asset,
      ppv_order_id: order_id
    } do
      assert Paywizard.Client.customer_purchases_ppv(customer_id) ==
               {:ok,
                [
                  %Paywizard.PPV{asset: asset, item_id: item_id, order_id: order_id}
                ]}
    end
  end

  describe "Creating cart with an item for a deleted customer" do
    test "returns error 90062", %{subscription_item_id: item_id, currency: currency} do
      unix_time_now = DateTime.to_unix(DateTime.utc_now())
      user_id = "smoke_test_#{unix_time_now}"
      external_id = unix_time_now
      email = "#{user_id}@bbrtest.se"
      customer_id = create_test_customer(external_id, user_id, email)
      delete_test_customer(customer_id)

      assert Paywizard.Client.create_cart_with_item(customer_id, item_id, currency) ==
               {:paywizard_error, :item_not_added_to_cart}
    end
  end

  describe "Checking out cart - Klarna" do
    test "create a klarna session", %{customer_id: customer_id, currency: currency} do
      klarna_redirect_data = %{
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

      assert {:ok,
              %{
                "clientToken" => _client_token,
                "digest" => _digest,
                "sessionId" => _session_id,
                "transactionId" => _transaction_id,
                "type" => "klarnaSession"
              }} = Paywizard.Client.customer_redirect_klarna(customer_id, currency, klarna_redirect_data)
    end
  end

  defp setup_test_customer(_context) do
    unix_time_now = DateTime.to_unix(DateTime.utc_now())
    user_id = "smoke_test_#{unix_time_now}"
    external_id = unix_time_now
    email = "#{user_id}@bbrtest.se"

    customer_id = create_test_customer(external_id, user_id, email)
    Logger.info("Created smoke test user: #{customer_id}")

    on_exit(fn -> cancel_contracts(customer_id) end)

    %{
      customer_id: customer_id,
      email: email,
      username: user_id,
      vimond_id: external_id
    }
  end

  defp cancel_contracts(customer_id) do
    {:ok, contracts} = Paywizard.Client.customer_contracts(customer_id)

    Enum.each(contracts, fn %{contract_id: contract_id} ->
      # BUG: Inconsistent behavior calling cancel-endpoint. Will succeed most of the times,
      # but sometimes returns error code 90006 ("Failed to cancel contract").
      # A re-run will succeed...
      cancel_date = Date.utc_today()
      {:ok, ^cancel_date} = Paywizard.Client.cancel_contract(customer_id, contract_id, to_string(cancel_date))

      Logger.info("Deleted contract #{contract_id} for test user: #{customer_id}")
    end)

    delete_test_customer(customer_id)
    |> case do
      {:ok, %Response{status_code: 200}} ->
        Logger.info("Deleted smoke test user: #{customer_id}")

      {:ok,
       %Paywizard.Response{
         body:
           "{\"errorCode\":4644,\"developerMessage\":\"Contact has active subscription or is in credit control cycle\",\"moreInfo\":\"Documentation on this failure can be found in SwaggerHub (https:\\/\\/swagger.io\\/tools\\/swaggerhub\\/)\"}",
         status_code: 400
       }} ->
        Logger.warn("Failed deleting smoke test user, retrying…")
        :timer.sleep(1000)
        cancel_contracts(customer_id)
    end
  end

  defp create_test_customer(external_id, user_id, email) do
    %{"href" => href} =
      get_post_body(
        "/apis/customers/v1/customer",
        %{
          "externalUniqueIdentifier" => external_id,
          "username" => user_id,
          "password" => "Smoke123",
          "email" => email,
          "title" => "Mr",
          "lastName" => "TV4 Media SmokeTest",
          "addresses" => [
            %{
              "countryCode" => "SWE",
              "postCode" => "12220"
            }
          ],
          "customAttributes" => [
            %{
              "name" => "Accepted Play Terms Date",
              "value" => "2020-02-25"
            },
            %{
              "name" => "Accepted Play Terms",
              "value" => "Telia"
            }
          ],
          "active" => true
        }
      )

    customer_id = String.split(href, "/") |> List.last()
    customer_id
  end

  defp delete_test_customer(customer_id) do
    HTTPClient.post("/apis/customers/v1/customer/#{customer_id}/anonymise", %{})
  end

  defp setup_defaults(_context) do
    # The hard-coded values below should ideally created for the test-suite
    # by API calls. As documentation is lacking, we are using pre-configured
    # values from the integration environment until we can do better.

    [
      currency: :SEK,
      subscription_item_id: "6D3A56FF5065478ABD61",
      no_free_trial_item_id: "4151C241C3DD41529A87",
      no_discount_item_id: "180B2AD9332349E6A7A4",
      ppv_item_id: "8F9AA56706904775AD7F",
      payment_method_receipt: 602_229_546,
      asset: %Paywizard.Asset{id: 12_345_678, title: "Sportsboll"}
    ]
  end

  defp get_post_body(path, data) do
    {:ok, %Response{body: body}} = HTTPClient.post(path, data)
    {:ok, data} = Jason.decode(body)
    data
  end

  defp save_in_test_context(key, value) do
    unless Process.whereis(SmokeState) do
      {:ok, _pid} = Agent.start(fn -> %{} end, name: SmokeState)
    end

    Agent.update(SmokeState, &Map.put(&1, key, value))
  end

  defp merge_saved_test_context(_) do
    if Process.whereis(SmokeState) do
      Agent.get(SmokeState, & &1)
    else
      :ok
    end
  end
end
