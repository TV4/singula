defmodule SmokeTest.PaywizardClientApi do
  use ExUnit.Case
  require Logger

  alias HTTPoison.Response
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
        timeout_ms: System.get_env("PAYWIZARD_TIMEOUT_MS") |> String.to_integer()
      ]
    )
  end

  setup_all [:setup_test_customer, :setup_defaults]
  setup :merge_saved_test_context

  describe "Searching external id" do
    test "returns set parameters", %{customer_id: customer_id, email: email, username: username, vimond_id: vimond_id} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => vimond_id})

      assert Jason.decode!(body)
             |> Map.drop(["auditInfo", "referAFriend"]) ==
               %{
                 "active" => true,
                 "addresses" => [
                   %{"addressType" => "HOME", "countryCode" => "SWE", "line1" => "Address Line 1", "postCode" => 12220}
                 ],
                 "customAttributes" => [
                   %{"name" => "Accepted Play Terms Date", "value" => "2020-02-25"},
                   %{"name" => "Accepted Play Terms", "value" => "Telia"}
                 ],
                 "customerId" => customer_id,
                 "email" => email,
                 "externalUniqueIdentifier" => vimond_id,
                 "firstName" => "Forename",
                 "lastName" => "TV4 Media SmokeTest",
                 "phone" => 0,
                 "title" => "Mr",
                 "username" => username
               }
    end

    test "returns error 90068 when not finding customer" do
      {:ok, %Response{body: body, status_code: 404}} =
        HTTPClient.post("/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => 666})

      assert Jason.decode!(body) == %{
               "developerMessage" => "Customer with external ID 666 not located",
               "errorCode" => 90068,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Customer cannot be located"
             }
    end
  end

  describe("Fetching customer contract") do
    test "returns 0 when no contracts", %{customer_id: customer_id} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/contracts/v1/customer/#{customer_id}/contract")

      assert Jason.decode!(body) == %{"contractCount" => 0}
    end

    test "returns customer not found passing invalid UUID" do
      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.get("/apis/contracts/v1/customer/non_existing_customer_id/contract")

      assert Jason.decode!(body) == %{
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
    end
  end

  describe("Fetching customer PPV") do
    test "returns 0 when no PPV's", %{customer_id: customer_id} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post("/apis/purchases/v1/customer/#{customer_id}/purchases/1", %{type: "PPV"})

      assert Jason.decode!(body) == %{"totalResults" => 0}
    end

    test "returns customer not found passing invalid UUID" do
      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.post("/apis/purchases/v1/customer/non_existing_customer_id/purchases/1", %{type: "PPV"})

      assert Jason.decode!(body) == %{
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
    end
  end

  describe "Creating cart with an item" do
    test "returns new cart with passed customer_id", %{
      customer_id: customer_id,
      subscription_item_id: subscription_item_id,
      currency: currency
    } do
      {:ok, %Response{body: body, status_code: 201}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
          %{items: [%{itemCode: subscription_item_id}]}
        )

      data = Jason.decode!(body)
      %{"href" => href} = data
      cart_id = String.split(href, "/") |> List.last() |> String.to_integer()

      assert data == %{
               "href" => "/customer/#{customer_id}/cart/#{cart_id}",
               "rel" => "Get cart details",
               "type" => "application/json"
             }

      save_in_test_context(:cart_id, cart_id)
    end

    test "returns PPV in cart when adding it", %{
      customer_id: customer_id,
      ppv_item_id: ppv_item_id,
      currency: currency,
      asset: asset
    } do
      {:ok, %Response{body: body, status_code: 201}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
          %{items: [%{itemCode: ppv_item_id, itemData: %{id: asset.id, name: asset.title}}]}
        )

      data = Jason.decode!(body)
      %{"href" => href} = data
      cart_id = String.split(href, "/") |> List.last() |> String.to_integer()

      assert data == %{
               "href" => "/customer/#{customer_id}/cart/#{cart_id}",
               "rel" => "Get cart details",
               "type" => "application/json"
             }

      save_in_test_context(:ppv_cart_id, cart_id)
    end

    test "returns customer not found passing invalid UUID", %{subscription_item_id: item_id, currency: currency} do
      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/non_existing_customer_id/cart/currency/#{currency}",
          %{items: [%{itemCode: item_id}]}
        )

      assert Jason.decode!(body) == %{
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
    end

    test "returns error 90069 for non-existing item code", %{customer_id: customer_id, currency: currency} do
      {:ok, %Response{body: body, status_code: 404}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
          %{items: [%{itemCode: "incorrect_item_id"}]}
        )

      assert Jason.decode!(body) == %{
               "developerMessage" => "Unable to find sales item with code: incorrect_item_id",
               "errorCode" => 90069,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "No item could be found with the given code"
             }
    end
  end

  describe "Fetching cart details" do
    test "returns added subscription", %{
      customer_id: customer_id,
      cart_id: cart_id,
      subscription_item_id: subscription_item_id
    } do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}")

      assert Jason.decode!(body)
             |> update_in(["items", Access.at(0), "freeTrial"], fn trial -> Map.delete(trial, "firstPaymentDate") end) ==
               %{
                 "discountCode" => %{
                   "campaignCode" => "NONE",
                   "promoCode" => "NONE",
                   "sourceCode" => "NONE"
                 },
                 "id" => cart_id,
                 "items" => [
                   %{
                     "cost" => %{"amount" => "0.00", "currency" => "SEK"},
                     "freeTrial" => %{
                       "applied" => true,
                       "firstPaymentAmount" => %{
                         "amount" => "139.00",
                         "currency" => "SEK"
                       },
                       "numberOfDays" => 14
                     },
                     "itemCode" => subscription_item_id,
                     "itemData" => "",
                     "itemName" => "C More TV4",
                     "quantity" => 1
                   }
                 ],
                 "totalCost" => %{"amount" => "0.00", "currency" => "SEK"}
               }
    end

    test "returns added ppv", %{customer_id: customer_id, ppv_cart_id: cart_id, ppv_item_id: ppv_item_id, asset: asset} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}")

      assert Jason.decode!(body) == %{
               "discountCode" => %{
                 "campaignCode" => "NONE",
                 "promoCode" => "NONE",
                 "sourceCode" => "NONE"
               },
               "id" => cart_id,
               "items" => [
                 %{
                   "cost" => %{"amount" => "149.00", "currency" => "SEK"},
                   "itemCode" => ppv_item_id,
                   "itemData" => %{"id" => asset.id, "name" => asset.title},
                   "itemName" => "PPV - 149",
                   "quantity" => 1
                 }
               ],
               "totalCost" => %{"amount" => "149.00", "currency" => "SEK"}
             }
    end

    test "returns customer not found passing invalid UUID", %{cart_id: cart_id} do
      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.get("/apis/purchases/v1/customer/non_existing_customer_id/cart/#{cart_id}")

      assert Jason.decode!(body) == %{
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
    end

    test "returns error 90040 for non-existing cart", %{customer_id: customer_id} do
      {:ok, %Response{body: body, status_code: 404}} =
        HTTPClient.get("/apis/purchases/v1/customer/#{customer_id}/cart/666")

      assert Jason.decode!(body) == %{
               "developerMessage" => "Unable to get cart 666 for customer #{customer_id}",
               "errorCode" => 90040,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Cart ID provided is incorrect or does not exist"
             }

      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.get("/apis/purchases/v1/customer/#{customer_id}/cart/non-numeric-cart")

      assert Jason.decode!(body) == %{
               "developerMessage" => "java.lang.NumberFormatException: For input string: \"non-numeric-cart\"",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
    end
  end

  describe "Fetching item on sale" do
    test "returns discount codes for item", %{subscription_item_id: item_id, currency: currency} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")

      {:ok, %{"discounts" => discounts}} = Jason.decode(body)

      discount = Enum.find(discounts, fn discount -> discount["id"] == 10125 end)
      campaign = Enum.find(discount["linkedCombos"], fn campaign -> campaign["campaign"] == "TESTWITHCAMPAIGN" end)

      assert campaign == %{
               "campaign" => "TESTWITHCAMPAIGN",
               "promotion" => "PROMO1",
               "source" => "TESTWITHSOURCE"
             }

      save_in_test_context(:discount, campaign)
    end

    test "returns empty list for item without discount", %{no_discount_item_id: item_id, currency: currency} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/catalogue/v1/item/#{item_id}/discounts?currency=#{currency}")

      assert Jason.decode(body) == {:ok, %{"discounts" => []}}
    end

    test "returns discount codes for given campaign", %{discount: discount, customer_id: customer_id, cart_id: cart_id} do
      keys_sort = &(&1 |> Map.values() |> Enum.sort())
      date_delete = &(&1 |> Map.delete("startDate") |> Map.delete("endDate"))

      data = %{
        "campaignCode" => discount["campaign"],
        "sourceCode" => discount["source"],
        "promoCode" => discount["promotion"]
      }

      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/setdiscountcode", data)

      added_discount =
        Jason.decode!(body)
        |> get_in(["discount", "discountCode"])

      discount = date_delete.(discount)
      added_discount = date_delete.(added_discount)

      assert keys_sort.(discount) == keys_sort.(added_discount)
    end

    test "returns error 90022 for non-existing discount code", %{customer_id: customer_id, cart_id: cart_id} do
      data = %{
        "campaignCode" => "wrong_campaign",
        "sourceCode" => "broken_source",
        "promoCode" => "invalid_promotion"
      }

      {:ok, %Response{body: body, status_code: 404}} =
        HTTPClient.post("/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/setdiscountcode", data)

      assert Jason.decode!(body) == %{
               "developerMessage" => "Invalid discount code for cart",
               "errorCode" => 90022,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Discount does not exist"
             }
    end
  end

  describe "Checking out cart" do
    test "redirect returns an transaction_id with redirect URL", %{customer_id: customer_id, currency: currency} do
      # BUG: Can return: "com.mgt.util.exception.system.SystemException: Error connecting to provider"

      # The value of the `redirectURL` field will soon match its name.
      # The project needs to provide Paywizard with the desired format.
      # A first draft is ready to be acknowledged internally before hand-off.
      dibs_redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post(
          "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
          Paywizard.Digest.generate(:DIBS, currency, dibs_redirect_data)
        )

      {:ok, data} = Jason.decode(body)

      assert data == Map.merge(Map.take(data, ["digest", "redirectURL", "transactionId"]), %{"type" => "redirect"})

      %{"transactionId" => transaction_id} = data
      save_in_test_context(:transaction_id, transaction_id)
    end

    test "redirect returns customer not found passing invalid UUID", %{currency: currency} do
      dibs_redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      {:ok, %Response{body: body, status_code: 500}} =
        HTTPClient.post(
          "/apis/payment-methods/v1/customer/non_existing_customer_id/redirect",
          Paywizard.Digest.generate(:DIBS, currency, dibs_redirect_data)
        )

      assert Jason.decode!(body) == %{
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "errorCode" => 500,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "System Failure - please retry later."
             }
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

      dibs_payment_method = %{
        dibs_ccPart: "**** **** **** 0000",
        dibs_ccPrefix: "457110",
        dibs_ccType: "Visa",
        dibs_expM: "12",
        dibs_expY: "21",
        receipt: payment_method_receipt,
        transactionId: transaction_id
      }

      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post(
          "/apis/payment-methods/v1/customer/#{customer_id}/paymentmethod",
          Paywizard.Digest.generate(:DIBS, currency, dibs_payment_method)
        )

      %{"paymentMethodId" => payment_method_id} = Jason.decode!(body)

      save_in_test_context(:payment_method_id, payment_method_id)
    end

    test "checking out subscription cart returns cart details", %{
      customer_id: customer_id,
      cart_id: cart_id,
      payment_method_id: payment_method_id,
      subscription_item_id: item_id
    } do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
          %{"paymentMethodId" => payment_method_id}
        )

      assert Jason.decode!(body)
             |> update_in(["items", Access.at(0), "freeTrial"], fn trial -> Map.delete(trial, "firstPaymentDate") end)
             |> update_in(["contractDetails"], fn contract -> Map.delete(contract, "contractId") end)
             |> Map.delete("orderId") ==
               %{
                 "contractDetails" => %{
                   "itemCode" => item_id,
                   "itemName" => "C More TV4",
                   "status" => "ACTIVE"
                 },
                 "discount" => %{
                   "discountAmount" => %{"amount" => "69.50", "currency" => "SEK"},
                   "discountCode" => %{
                     "campaignCode" => "TESTWITHCAMPAIGN",
                     "promoCode" => "PROMO1",
                     "sourceCode" => "TESTWITHSOURCE"
                   },
                   "discountName" => "TestGatedDiscount50%Off",
                   "indefinite" => true,
                   "itemCode" => item_id
                 },
                 "discountCode" => %{
                   "campaignCode" => "TESTWITHCAMPAIGN",
                   "promoCode" => "PROMO1",
                   "sourceCode" => "TESTWITHSOURCE"
                 },
                 "items" => [
                   %{
                     "cost" => %{"amount" => "0.00", "currency" => "SEK"},
                     "freeTrial" => %{
                       "applied" => true,
                       "firstPaymentAmount" => %{
                         "amount" => "69.50",
                         "currency" => "SEK"
                       },
                       "numberOfDays" => 14
                     },
                     "itemCode" => item_id,
                     "itemData" => "",
                     "itemName" => "C More TV4",
                     "quantity" => 1
                   }
                 ],
                 "totalCost" => %{"amount" => "0.00", "currency" => "SEK"}
               }
    end

    test "checking out ppv cart returns cart details", %{
      customer_id: customer_id,
      ppv_cart_id: cart_id,
      payment_method_id: payment_method_id,
      ppv_item_id: item_id,
      asset: asset
    } do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/#{cart_id}/checkout",
          %{"paymentMethodId" => payment_method_id}
        )

      assert Jason.decode!(body)
             |> Map.delete("orderId") == %{
               "items" => [
                 %{
                   "cost" => %{"amount" => "149.00", "currency" => "SEK"},
                   "itemCode" => item_id,
                   "itemData" => %{"id" => asset.id, "name" => asset.title},
                   "itemName" => "PPV - 149",
                   "quantity" => 1
                 }
               ],
               "totalCost" => %{"amount" => "149.00", "currency" => "SEK"}
             }
    end
  end

  describe "Fetching customer contracts after checkout" do
    test "returns purchased subscription", %{customer_id: customer_id, subscription_item_id: item_id} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.get("/apis/contracts/v1/customer/#{customer_id}/contract")

      {contract_id, data} =
        Jason.decode!(body)
        |> pop_in(["contracts", Access.at(0), "contractId"])

      assert data
             |> update_in(["contracts", Access.at(0)], fn contract ->
               Map.drop(contract, ["link", "startDate", "orderId"])
             end) ==
               %{
                 "contractCount" => 1,
                 "contracts" => [
                   %{
                     "active" => true,
                     "itemCode" => item_id,
                     "name" => "C More TV4",
                     "status" => "ACTIVE"
                   }
                 ]
               }

      save_in_test_context(:contract_id, contract_id)
    end

    test "returns purchased pay per view", %{customer_id: customer_id, ppv_item_id: item_id, asset: asset} do
      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post("/apis/purchases/v1/customer/#{customer_id}/purchases/1", %{type: "PPV"})

      assert Jason.decode!(body)
             |> update_in(["items", Access.at(0)], fn item -> Map.drop(item, ["purchaseDate", "orderId"]) end) ==
               %{
                 "currentPage" => 1,
                 "items" => [
                   %{
                     "entitlements" => [%{"id" => 5967, "name" => "Matchbiljett 149 kr"}],
                     "itemData" => %{"id" => asset.id, "name" => asset.title},
                     "salesItemCode" => item_id,
                     "salesItemName" => "PPV - 149",
                     "type" => "PPV"
                   }
                 ],
                 "numberOfPages" => 1,
                 "totalResults" => 1
               }
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

      item = %{itemCode: item_id}

      {:ok, %Response{body: body, status_code: 400}} =
        HTTPClient.post(
          "/apis/purchases/v1/customer/#{customer_id}/cart/currency/#{currency}",
          %{items: [item]}
        )

      assert Jason.decode!(body) == %{
               "errorCode" => 90062,
               "userMessage" => "Items could not be added",
               "developerMessage" => "Unable to add sales item with code: null",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
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

      {:ok, %Response{body: body, status_code: 200}} =
        HTTPClient.post(
          "/apis/payment-methods/v1/customer/#{customer_id}/redirect",
          Paywizard.Digest.generate(:KLARNA, currency, klarna_redirect_data)
        )

      assert Jason.decode!(body)
             |> Map.keys() == ["clientToken", "digest", "sessionId", "transactionId", "type"]
    end
  end

  defp setup_test_customer(_context) do
    unix_time_now = DateTime.to_unix(DateTime.utc_now())
    user_id = "smoke_test_#{unix_time_now}"
    external_id = unix_time_now
    email = "#{user_id}@bbrtest.se"

    customer_id = create_test_customer(external_id, user_id, email)
    Logger.info("Created smoke test user: #{customer_id}")

    on_exit(fn ->
      contract_id = state_get(:contract_id)

      if contract_id do
        # BUG: Inconsistent behavior calling cancel-endpoint. Will succeed most of the times,
        # but sometimes returns error code 90006 ("Failed to cancel contract").
        # A re-run will succeed...

        cancel_date = Date.utc_today()
        {:ok, ^cancel_date} = Paywizard.Client.cancel_contract(customer_id, contract_id, to_string(cancel_date))

        Logger.info("Deleted contracts for test user: #{customer_id}")
      end

      {:ok, %Response{status_code: 200}} = delete_test_customer(customer_id)
      Logger.info("Deleted smoke test user: #{customer_id}")
    end)

    %{
      customer_id: customer_id,
      email: email,
      username: user_id,
      vimond_id: external_id
    }
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

  defp state_get(key) do
    Agent.get(SmokeState, &Map.get(&1, key))
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
