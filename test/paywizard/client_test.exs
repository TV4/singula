defmodule Paywizard.ClientTest do
  use ExUnit.Case
  import Hammox

  alias Paywizard.{Asset, CartDetail, Client, Customer, DibsPaymentMethod}

  setup :verify_on_exit!

  describe "get customer" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/customers/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "active" => true,
               "addresses" => [
                 %{
                   "addressType" => "HOME",
                   "countryCode" => "SWE",
                   "line1" => "Address Line 1",
                   "postCode" => "Postcode"
                 }
               ],
               "auditInfo" => %{
                 "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "creationDate" => "2020-03-22T07:19:21+01:00",
                 "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "modifiedDate" => "2020-03-22T07:19:21+01:00"
               },
               "customAttributes" => [%{"name" => "accepted_cmore_terms", "value" => "2018-09-25"}],
               "customerId" => "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "email" => "paywizard_purchase_test2@cmore.se",
               "externalUniqueIdentifier" => 100_471_887,
               "firstName" => "Paywizard_purchase_test2@cmore.se",
               "lastName" => "Paywizard_purchase_test2@cmore.se",
               "phone" => 0,
               "referAFriend" => %{"active" => false, "code" => "PIh70mZL"},
               "title" => "-",
               "username" => "paywizard_purchase_test2@cmore.se"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.customer_fetch("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                %Customer{
                  active: true,
                  customer_id: "ff160270-5197-4c90-835c-cd1fff8b19d0",
                  date_of_birth: nil,
                  address_post_code: "Postcode",
                  custom_attributes: [%{name: "accepted_cmore_terms", value: "2018-09-25"}],
                  email: "paywizard_purchase_test2@cmore.se",
                  external_unique_id: "100471887",
                  first_name: "Paywizard_purchase_test2@cmore.se",
                  last_name: "Paywizard_purchase_test2@cmore.se",
                  username: "paywizard_purchase_test2@cmore.se"
                }}
    end

    test "when customer not found" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/customers/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "developerMessage" => "Customer 27dc778b-582e-4551-88c6-43806128a1a0 not located",
               "errorCode" => 90068,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Customer cannot be located"
             }
             |> Jason.encode!(),
           status_code: 404
         }}
      end)

      assert Client.customer_fetch("ff160270-5197-4c90-835c-cd1fff8b19d0") == {:paywizard_error, :customer_not_found}
    end
  end

  describe "search customer" do
    test "with an existing external customer id" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => "100471887"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "active" => true,
               "addresses" => [
                 %{
                   "addressType" => "HOME",
                   "countryCode" => "SWE",
                   "line1" => "Address Line 1",
                   "postCode" => "Postcode"
                 }
               ],
               "auditInfo" => %{
                 "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "creationDate" => "2020-03-22T07:19:21+01:00",
                 "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "modifiedDate" => "2020-03-22T07:19:21+01:00"
               },
               "customAttributes" => [%{"name" => "accepted_cmore_terms", "value" => "2018-09-25"}],
               "customerId" => "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "email" => "paywizard_purchase_test2@cmore.se",
               "externalUniqueIdentifier" => 100_471_887,
               "firstName" => "Paywizard_purchase_test2@cmore.se",
               "lastName" => "Paywizard_purchase_test2@cmore.se",
               "phone" => 0,
               "referAFriend" => %{"active" => false, "code" => "PIh70mZL"},
               "title" => "-",
               "username" => "paywizard_purchase_test2@cmore.se"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.customer_search("100471887") ==
               {:ok,
                %Customer{
                  active: true,
                  customer_id: "ff160270-5197-4c90-835c-cd1fff8b19d0",
                  date_of_birth: nil,
                  address_post_code: "Postcode",
                  custom_attributes: [%{name: "accepted_cmore_terms", value: "2018-09-25"}],
                  email: "paywizard_purchase_test2@cmore.se",
                  external_unique_id: "100471887",
                  first_name: "Paywizard_purchase_test2@cmore.se",
                  last_name: "Paywizard_purchase_test2@cmore.se",
                  username: "paywizard_purchase_test2@cmore.se"
                }}
    end

    test "with an incorrect external customer id" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => "666"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90068,
               "userMessage" => "Customer cannot be located",
               "developerMessage" => "Customer with external ID 666 not located",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 404
         }}
      end)

      assert Client.customer_search("666") == {:paywizard_error, :customer_not_found}
    end
  end

  describe "get contracts" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract?activeOnly=true" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "contractCount" => 1,
               "contracts" => [
                 %{
                   "active" => true,
                   "contractId" => 9_719_738,
                   "orderId" => 112_233,
                   "itemCode" => "6D3A56FF5065478ABD61",
                   "link" => %{
                     "href" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738",
                     "rel" => "Get contract details",
                     "type" => "application/json"
                   },
                   "name" => "C More TV4",
                   "startDate" => "2020-04-20",
                   "status" => "ACTIVE"
                 }
               ]
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.customer_contracts("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                [
                  %Paywizard.Contract{
                    active: true,
                    contract_id: 9_719_738,
                    item_id: "6D3A56FF5065478ABD61",
                    item_name: "C More TV4",
                    order_id: 112_233
                  }
                ]}
    end

    test "fails" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract?activeOnly=true" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.customer_contracts("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "get contract" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "active" => true,
               "auditInfo" => %{
                 "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "creationDate" => "2020-04-22T21:12:29+02:00",
                 "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
                 "modifiedDate" => "2020-04-22T21:12:29+02:00"
               },
               "balance" => %{"amount" => "-399.00", "currency" => "SEK"},
               "billing" => %{
                 "frequency" => %{"frequency" => "MONTH", "length" => 24},
                 "initial" => %{"amount" => "0.00", "currency" => "SEK"},
                 "recurring" => %{"amount" => "399.00", "currency" => "SEK"}
               },
               "contractId" => 9_622_082,
               "entitlements" => [%{"id" => 5963, "name" => "C More All Sport"}],
               "itemCode" => "4FC7D926073348038362",
               "lastPaymentDate" => "2020-04-22",
               "minimumTerm" => %{"frequency" => "MONTH", "length" => 24},
               "name" => "Field Sales - All Sport 12 plus 12",
               "nextPaymentDate" => "2020-04-22",
               "paidUpToDate" => "2020-04-22",
               "paymentMethodId" => 3_070_939,
               "startDate" => "2020-04-22",
               "status" => "ACTIVE"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.customer_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:ok,
                %Paywizard.ContractDetails{
                  id: 9_622_082,
                  item_id: "4FC7D926073348038362",
                  item_name: "Field Sales - All Sport 12 plus 12",
                  balance: %{amount: "-399.00", currency: :SEK},
                  recurring_billing: %{amount: "399.00", currency: :SEK, frequency: :MONTH, length: 24},
                  minimum_term: %{frequency: :MONTH, length: 24},
                  status: :ACTIVE,
                  start_date: ~D[2020-04-22],
                  paid_up_to_date: ~D[2020-04-22]
                }}
    end

    test "causes system failure" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.customer_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "cancel contract" do
    test "successfully" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel",
                          %{"cancelDate" => ""} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{"status" => "CUSTOMER_CANCELLED", "cancellationDate" => "2020-05-12"}
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) == {:ok, ~D[2020-05-12]}
    end

    test "when minimum term blocks cancellation" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel",
                          %{"cancelDate" => "2020-02-02"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "developerMessage" => "Unable to cancel contract : 9622756",
               "errorCode" => 90006,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Failed to cancel contract"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738, "2020-02-02") ==
               {:paywizard_error, :contract_cancellation_fault}
    end
  end

  describe "withdraw cancel contract" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel/withdraw", %{} ->
          {:ok,
           %Paywizard.Response{
             body:
               %{
                 "href" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738",
                 "rel" => "Get contract details",
                 "type" => "application/json"
               }
               |> Jason.encode!(),
             status_code: 200
           }}
        end
      )

      assert Client.withdraw_cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) == :ok
    end

    test "fails" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel/withdraw", %{} ->
          {:ok,
           %Paywizard.Response{
             body:
               %{
                 "errorCode" => 90017,
                 "userMessage" => "Contract cannot be changed at this time",
                 "developerMessage" => "Contract cannot be cancelled at this time",
                 "moreInfo" =>
                   "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
               }
               |> Jason.encode!(),
             status_code: 400
           }}
        end
      )

      assert Client.withdraw_cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:paywizard_error, :cancellation_withdrawal_fault}
    end
  end

  describe "create cart" do
    test "without meta data" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{}}]}

        {:ok,
         %Paywizard.Response{
           body:
             %{"rel" => "Get cart details", "href" => "/customer/customer_id/cart/10000", "type" => "application/json"}
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency") == {:ok, "10000"}
    end

    test "with asset" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{id: "654321", name: "Sportsboll"}}]}

        {:ok,
         %Paywizard.Response{
           body:
             %{"rel" => "Get cart details", "href" => "/customer/customer_id/cart/10000", "type" => "application/json"}
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{
               asset: %Paywizard.Asset{id: "654321", title: "Sportsboll"}
             }) == {:ok, "10000"}
    end

    test "with referrer" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{referrerId: "A003_FS"}}]}

        {:ok,
         %Paywizard.Response{
           body:
             %{"rel" => "Get cart details", "href" => "/customer/customer_id/cart/10000", "type" => "application/json"}
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{referrer: "A003_FS"}) ==
               {:ok, "10000"}
    end

    test "with discount" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{discountId: "10097", promoCode: "NONE", campaignCode: "NONE", sourceCode: "NONE"}
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{"rel" => "Get cart details", "href" => "/customer/customer_id/cart/10000", "type" => "application/json"}
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{
               discount: %Paywizard.Discount{discount: "10097"}
             }) == {:ok, "10000"}
    end

    test "with voucher discount" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{promoCode: "HELLO", campaignCode: "NETONNET", sourceCode: "PARTNER"}
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{"rel" => "Get cart details", "href" => "/customer/customer_id/cart/10000", "type" => "application/json"}
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{
               discount: %Paywizard.Discount{promotion: "HELLO", campaign: "NETONNET", source: "PARTNER"}
             }) == {:ok, "10000"}
    end

    test "causing system failure" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency") ==
               {:paywizard_error, :customer_not_found}
    end

    test "discount not found" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{discountId: "10097", promoCode: "NONE", campaignCode: "NONE", sourceCode: "NONE"}
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90115,
               "developerMessage" => "Discount criteria not matched",
               "userMessage" => "Discount criteria not matched",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{
               discount: %Paywizard.Discount{discount: "10097"}
             }) == {:paywizard_error, :discount_not_found}
    end

    test "voucher not found" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{
                   promoCode: "invalid_promotion",
                   campaignCode: "wrong_campaign",
                   sourceCode: "broken_source"
                 }
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90022,
               "userMessage" => "Discount does not exist",
               "developerMessage" => "Invalid discount code for cart",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 404
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency", %Paywizard.MetaData{
               discount: %Paywizard.Discount{
                 campaign: "wrong_campaign",
                 source: "broken_source",
                 promotion: "invalid_promotion"
               }
             }) == {:paywizard_error, :discount_not_found}
    end

    test "item not added to cart" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "developerMessage" => "Unable to add sales item with code: null",
               "errorCode" => 90062,
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Items could not be added"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency") ==
               {:paywizard_error, :item_not_added_to_cart}
    end

    test "item not found" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90069,
               "userMessage" => "No item could be found with the given code",
               "developerMessage" => "Unable to find sales item with code: item_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 404
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency") == {:paywizard_error, :incorrect_item}
    end
  end

  describe "get cart" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        {:ok,
         %Paywizard.Response{
           body:
             "{\"id\":121765,\"totalCost\":{\"amount\":\"449.00\",\"currency\":\"SEK\"},\"items\":[{\"itemCode\":\"4151C241C3DD41529A87\",\"itemData\":\"\",\"itemName\":\"C More All Sport\",\"quantity\":1,\"cost\":{\"amount\":\"449.00\",\"currency\":\"SEK\"}}],\"discountCode\":{\"campaignCode\":\"NONE\",\"sourceCode\":\"NONE\",\"promoCode\":\"NONE\"}}",
           status_code: 200
         }}
      end)

      assert Client.fetch_cart("customer_id", "121765") ==
               {:ok,
                %Paywizard.CartDetail{
                  currency: :SEK,
                  id: 121_765,
                  items: [
                    %Paywizard.CartDetail.Item{
                      cost: "449.00",
                      item_id: "4151C241C3DD41529A87",
                      item_name: "C More All Sport",
                      quantity: 1
                    }
                  ],
                  total_cost: "449.00"
                }}
    end

    test "when cart not found" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90040,
               "userMessage" => "Cart ID provided is incorrect or does not exist",
               "developerMessage" => "Unable to get cart 121765 for customer customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 404
         }}
      end)

      assert Client.fetch_cart("customer_id", "121765") == {:paywizard_error, :cart_not_found}
    end

    test "causing system failure" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.fetch_cart("customer_id", "121765") == {:paywizard_error, :customer_not_found}
    end
  end

  describe "get item discounts" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/item_id/discounts?currency=currency" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "discounts" => [
                 %{
                   "description" => "3 occurrences 100% off",
                   "discountType" => "PERCENTAGE",
                   "id" => 10116,
                   "indefinite" => false,
                   "name" => "3 occurrences 100% off",
                   "occurrences" => 3,
                   "referAFriendCodeRequired" => false,
                   "value" => %{"percentage" => 100}
                 },
                 %{
                   "description" => "Test gated",
                   "discountType" => "PERCENTAGE",
                   "id" => 10125,
                   "indefinite" => true,
                   "linkedCombos" => [
                     %{"campaign" => "NONE", "promotion" => "PROMO4", "source" => "NONE"},
                     %{"campaign" => "TESTWITHCAMPAIGN", "promotion" => "PROMO1", "source" => "TESTWITHSOURCE"},
                     %{"campaign" => "TESTWITHCAMPAIGNONLY", "promotion" => "PROMO3", "source" => "NONE"},
                     %{"campaign" => "NONE", "promotion" => "PROMO2", "source" => "TESTWITHSOURCEONLY"}
                   ],
                   "name" => "TestGatedDiscount50%Off",
                   "referAFriendCodeRequired" => false,
                   "value" => %{"percentage" => 50}
                 }
               ]
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.fetch_item_discounts("item_id", "currency") ==
               {:ok,
                [
                  %{
                    "description" => "3 occurrences 100% off",
                    "discountType" => "PERCENTAGE",
                    "id" => 10116,
                    "indefinite" => false,
                    "name" => "3 occurrences 100% off",
                    "occurrences" => 3,
                    "referAFriendCodeRequired" => false,
                    "value" => %{"percentage" => 100}
                  },
                  %{
                    "description" => "Test gated",
                    "discountType" => "PERCENTAGE",
                    "id" => 10125,
                    "indefinite" => true,
                    "linkedCombos" => [
                      %{"campaign" => "NONE", "promotion" => "PROMO4", "source" => "NONE"},
                      %{"campaign" => "TESTWITHCAMPAIGN", "promotion" => "PROMO1", "source" => "TESTWITHSOURCE"},
                      %{"campaign" => "TESTWITHCAMPAIGNONLY", "promotion" => "PROMO3", "source" => "NONE"},
                      %{"campaign" => "NONE", "promotion" => "PROMO2", "source" => "TESTWITHSOURCEONLY"}
                    ],
                    "name" => "TestGatedDiscount50%Off",
                    "referAFriendCodeRequired" => false,
                    "value" => %{"percentage" => 50}
                  }
                ]}
    end

    test "for item without discounts" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/item_id/discounts?currency=currency" ->
        {:ok, %Paywizard.Response{body: "{\"discounts\":[]}", status_code: 200}}
      end)

      assert Client.fetch_item_discounts("item_id", "currency") == {:ok, []}
    end
  end

  describe "create dibs redirect" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/redirect", data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :amount, value: "1.00"},
                   %{key: :billing_city, value: "Stockholm"},
                   %{key: :itemDescription, value: "REGISTER_CARD"},
                   %{key: :payment_method, value: "cc.test"}
                 ],
                 "digest" => "7e842b89f8d45d4162f32a197d5fc61b0d025a33672808b6fc35c6ee6deddccd",
                 "merchantCode" => "BBR",
                 "provider" => :DIBS,
                 "uuid" => "30f86e79-ed75-4022-a16e-d55d9f09af8d"
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "type" => "redirect",
               "transactionId" => "mrngn-fiX9MEbB4S0",
               "redirectURL" =>
                 "<form action=\"https:\/\/securedt.dibspayment.com\/verify\/bin\/cmoretest\/index\" method = \"POST\"><input type=\"hidden\" name=\"referenceNo\" value=\"mrngn-fiX9MEbB4S0-27674\"\/><input type=\"text\" name=\"billingAddress\" value=\"Address Line 1\"\/><input type=\"text\" name=\"billingCity\" value=\"Stockholm\"\/><input type=\"text\" name=\"billingCountry\" value=\"SE\"\/><input type=\"text\" name=\"billingFirstName\" value=\"Forename\"\/><input type=\"text\" name=\"billingLastName\" value=\"TV4 Media SmokeTest\"\/><input type=\"text\" name=\"currency\" value=\"SEK\"\/><input type=\"text\" name=\"data\" value=\"1:REGISTER_CARD:1:100:\"\/><input type=\"text\" name=\"eMail\" value=\"user@host.com\"\/><input type=\"text\" name=\"MAC\" value=\"D18242FF449D6A674622392AE34256F291B43ED6\"\/><input type=\"text\" name=\"pageSet\" value=\"cmore-payment-window-2-0\"\/><input type=\"text\" name=\"customReturnUrl\" value=\"https:\/\/www.google.se\"\/><input type=\"text\" name=\"method\" value=\"cc.test\"\/><input type=\"text\" name=\"authOnly\" value=\"true\"\/><button type=\"submit\">Submit<\/button><\/form>",
               "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      assert Client.customer_redirect_dibs("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, redirect_data) ==
               {:ok,
                %{
                  "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b",
                  "redirectURL" =>
                    "<form action=\"https://securedt.dibspayment.com/verify/bin/cmoretest/index\" method = \"POST\"><input type=\"hidden\" name=\"referenceNo\" value=\"mrngn-fiX9MEbB4S0-27674\"/><input type=\"text\" name=\"billingAddress\" value=\"Address Line 1\"/><input type=\"text\" name=\"billingCity\" value=\"Stockholm\"/><input type=\"text\" name=\"billingCountry\" value=\"SE\"/><input type=\"text\" name=\"billingFirstName\" value=\"Forename\"/><input type=\"text\" name=\"billingLastName\" value=\"TV4 Media SmokeTest\"/><input type=\"text\" name=\"currency\" value=\"SEK\"/><input type=\"text\" name=\"data\" value=\"1:REGISTER_CARD:1:100:\"/><input type=\"text\" name=\"eMail\" value=\"user@host.com\"/><input type=\"text\" name=\"MAC\" value=\"D18242FF449D6A674622392AE34256F291B43ED6\"/><input type=\"text\" name=\"pageSet\" value=\"cmore-payment-window-2-0\"/><input type=\"text\" name=\"customReturnUrl\" value=\"https://www.google.se\"/><input type=\"text\" name=\"method\" value=\"cc.test\"/><input type=\"text\" name=\"authOnly\" value=\"true\"/><button type=\"submit\">Submit</button></form>",
                  "transactionId" => "mrngn-fiX9MEbB4S0",
                  "type" => "redirect"
                }}
    end

    test "causes system failure" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/non_existing_customer_id/redirect", _data ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.customer_redirect_dibs("non_existing_customer_id", :SEK, %{}) ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "create klarna redirect" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/redirect", data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :amount, value: "1.00"},
                   %{key: :authorisation, value: false},
                   %{key: :countryCode, value: "SE"},
                   %{key: :currency, value: :SEK},
                   %{key: :duration, value: 12},
                   %{key: :itemDescription, value: "C More"},
                   %{key: :productIdentifier, value: "test"},
                   %{key: :purchase_country, value: "SE"},
                   %{key: :subscription, value: true},
                   %{key: :tax_amount, value: 0},
                   %{key: :tax_rate, value: 0}
                 ],
                 "digest" => "7e842b89f8d45d4162f32a197d5fc61b0d025a33672808b6fc35c6ee6deddccd",
                 "merchantCode" => "BBR",
                 "provider" => :KLARNA,
                 "uuid" => "30f86e79-ed75-4022-a16e-d55d9f09af8d"
               }

        {:ok,
         %Paywizard.Response{
           body:
             %{
               "type" => "klarnaSession",
               "transactionId" => "2m56mfCGyV7VWh96k",
               "sessionId" => "22aa3f2a-ca55-19a6-8790-540a527fc877",
               "clientToken" => "eyJhbGciOiJSUzI1NiIs",
               "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      redirect_data = %{
        itemDescription: "C More",
        countryCode: "SE",
        amount: "1.00",
        currency: :SEK,
        subscription: true,
        duration: 12,
        productIdentifier: "test",
        authorisation: false,
        tax_amount: 0,
        purchase_country: "SE",
        tax_rate: 0
      }

      assert Client.customer_redirect_klarna("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, redirect_data) ==
               {:ok,
                %{
                  "type" => "klarnaSession",
                  "transactionId" => "2m56mfCGyV7VWh96k",
                  "sessionId" => "22aa3f2a-ca55-19a6-8790-540a527fc877",
                  "clientToken" => "eyJhbGciOiJSUzI1NiIs",
                  "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
                }}
    end

    test "causes system failure" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/redirect", _data ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.customer_redirect_klarna("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, %{}) ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "add dibs payment method to customer" do
    setup do
      dibs_payment_method = %DibsPaymentMethod{
        dibs_ccPart: "**** **** **** 0000",
        dibs_ccPrefix: "457110",
        dibs_ccType: "Visa",
        dibs_expM: "12",
        dibs_expY: "21",
        transactionId: "HrE7FZvc16lUo1ASCLt",
        receipt: "617371666"
      }

      {:ok, dibs_payment_method: dibs_payment_method}
    end

    test "on success", %{dibs_payment_method: dibs_payment_method} do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :defaultMethod, value: true},
                   %{key: :dibs_ccPart, value: "**** **** **** 0000"},
                   %{key: :dibs_ccPrefix, value: "457110"},
                   %{key: :dibs_ccType, value: "Visa"},
                   %{key: :dibs_expM, value: "12"},
                   %{key: :dibs_expY, value: "21"},
                   %{key: :receipt, value: "617371666"},
                   %{key: :transactionId, value: "HrE7FZvc16lUo1ASCLt"}
                 ],
                 "digest" => "7e842b89f8d45d4162f32a197d5fc61b0d025a33672808b6fc35c6ee6deddccd",
                 "merchantCode" => "BBR",
                 "provider" => :DIBS,
                 "uuid" => "30f86e79-ed75-4022-a16e-d55d9f09af8d"
               }

        {:ok, %Paywizard.Response{body: Jason.encode!(%{paymentMethodId: 26574}), status_code: 200}}
      end)

      assert Client.customer_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:ok, 26574}
    end

    test "transaction not found", %{dibs_payment_method: dibs_payment_method} do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          _payment_method_data ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90047,
               "developerMessage" => "Token not generated",
               "userMessage" => "Payment method creation failure",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.customer_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:paywizard_error, :transaction_not_found}
    end

    test "receipt not found", %{dibs_payment_method: dibs_payment_method} do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          _payment_method_data ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90054,
               "userMessage" => "Payment provider cannot complete transaction",
               "developerMessage" => "Authorisation failed",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.customer_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:paywizard_error, :receipt_not_found}
    end
  end

  describe "add klarna payment method to customer" do
    test "on success" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/4ad58d9d-8976-47c0-af2c-35debf38d0eb/paymentmethod",
                          data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :locale, value: "sv-SE"},
                   %{
                     key: :order_lines,
                     value:
                       "[{\"name\":\"PPV - 249\",\"purchase_currency\":\"SEK\",\"quantity\":1,\"tax_amount\":\"37.0\",\"total_amount\":\"149.00\",\"unit_price\":\"149.00\"}]"
                   },
                   %{key: :receipt, value: "dea12664-6e1f-1aef-bfb0-e9968842f32c"},
                   %{key: :redirectUrl, value: "http://localhost:4000"},
                   %{key: :transactionId, value: "2m56mfCGyV7VWh96k"}
                 ],
                 "digest" => "7e842b89f8d45d4162f32a197d5fc61b0d025a33672808b6fc35c6ee6deddccd",
                 "merchantCode" => "BBR",
                 "provider" => :KLARNA,
                 "uuid" => "30f86e79-ed75-4022-a16e-d55d9f09af8d"
               }

        {:ok, %Paywizard.Response{status_code: 200, body: %{"paymentMethodId" => 654_321} |> Jason.encode!()}}
      end)

      payment_method = %Paywizard.KlarnaPaymentMethod{
        receipt: "dea12664-6e1f-1aef-bfb0-e9968842f32c",
        transactionId: "2m56mfCGyV7VWh96k",
        redirectUrl: "http://localhost:4000",
        order_lines: [
          %{
            name: "PPV - 249",
            purchase_currency: :SEK,
            quantity: 1,
            tax_amount: "37.0",
            total_amount: "149.00",
            unit_price: "149.00"
          }
        ]
      }

      assert Paywizard.Client.customer_payment_method("4ad58d9d-8976-47c0-af2c-35debf38d0eb", :SEK, payment_method) ==
               {:ok, 654_321}
    end
  end

  describe "checkout cart" do
    test "success for subscription that supports free trial" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:ok,
         %Paywizard.Response{
           status_code: 200,
           body:
             %{
               "orderId" => "order_id_123",
               "contractDetails" => %{
                 "contractId" => 18978,
                 "itemCode" => "6D3A56FF5065478ABD61",
                 "itemName" => "C More TV4",
                 "status" => "ACTIVE"
               },
               "items" => [
                 %{
                   "cost" => %{"amount" => "0.00", "currency" => "SEK"},
                   "freeTrial" => %{
                     "applied" => true,
                     "firstPaymentAmount" => %{"amount" => "139.00", "currency" => "SEK"},
                     "firstPaymentDate" => "2020-04-05T00:00:00+02:00",
                     "numberOfDays" => 14
                   },
                   "itemCode" => "6D3A56FF5065478ABD61",
                   "itemData" => "",
                   "itemName" => "C More TV4",
                   "quantity" => 1
                 }
               ],
               "totalCost" => %{"amount" => "0.00", "currency" => "SEK"}
             }
             |> Jason.encode!()
         }}
      end)

      assert Client.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:ok,
                %CartDetail{
                  contract_id: 18978,
                  order_id: "order_id_123",
                  currency: :SEK,
                  total_cost: "0.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "6D3A56FF5065478ABD61",
                      cost: "0.00",
                      trial: %CartDetail.Item.Trial{
                        free_trial: true,
                        first_payment_date: ~D[2020-04-05],
                        first_payment_amount: "139.00"
                      },
                      item_name: "C More TV4",
                      quantity: 1
                    }
                  ]
                }}
    end

    test "success for subscription that don't support free trial" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:ok,
         %Paywizard.Response{
           status_code: 200,
           body:
             %{
               "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
               "id" => 119_469,
               "items" => [
                 %{
                   "cost" => %{"amount" => "449.00", "currency" => "SEK"},
                   "itemCode" => "4151C241C3DD41529A87",
                   "itemData" => "",
                   "itemName" => "C More All Sport",
                   "quantity" => 1
                 }
               ],
               "totalCost" => %{"amount" => "449.00", "currency" => "SEK"}
             }
             |> Jason.encode!()
         }}
      end)

      assert Client.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:ok,
                %CartDetail{
                  id: 119_469,
                  currency: :SEK,
                  total_cost: "449.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "4151C241C3DD41529A87",
                      cost: "449.00",
                      trial: nil,
                      item_name: "C More All Sport",
                      quantity: 1
                    }
                  ]
                }}
    end

    test "success for PPV" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:ok,
         %Paywizard.Response{
           status_code: 200,
           body:
             %{
               "items" => [
                 %{
                   "cost" => %{"amount" => "149.00", "currency" => "SEK"},
                   "itemCode" => "A2D895F14D6B4F2DA03C",
                   "itemData" => %{"id" => 10_255_800, "name" => "Rögle BK - Växjö Lakers HC"},
                   "itemName" => "PPV - 249",
                   "quantity" => 1
                 }
               ],
               "totalCost" => %{"amount" => "149.00", "currency" => "SEK"}
             }
             |> Jason.encode!()
         }}
      end)

      assert Client.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:ok,
                %CartDetail{
                  currency: :SEK,
                  total_cost: "149.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "A2D895F14D6B4F2DA03C",
                      item_name: "PPV - 249",
                      trial: nil,
                      cost: "149.00",
                      quantity: 1,
                      asset: %Asset{id: 10_255_800, title: "Rögle BK - Växjö Lakers HC"}
                    }
                  ]
                }}
    end

    test "cart not found" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:ok,
         %Paywizard.Response{
           status_code: 404,
           body:
             %{
               errorCode: 90040,
               userMessage: "Cart ID provided is incorrect or does not exist",
               developerMessage: "No cart found with given ID",
               moreInfo:
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!()
         }}
      end)

      assert Client.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:paywizard_error, :cart_not_found}
    end

    test "payment authorization fault" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:ok,
         %Paywizard.Response{
           status_code: 400,
           body:
             %{
               errorCode: 90045,
               userMessage: "Payment attempt failed",
               developerMessage:
                 "Unable to authorise payment: PaymentAttemptFailedException server_error PSP error: 402",
               moreInfo:
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!()
         }}
      end)

      assert Client.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:paywizard_error, :payment_authorisation_fault}
    end
  end

  describe "get ppv purchases" do
    test "succeeds" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/1",
                          %{type: "PPV"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "currentPage" => 1,
               "items" => [
                 %{
                   "entitlements" => 5961,
                   "itemData" => %{"id" => 1, "name" => "1"},
                   "orderId" => 112_233,
                   "purchaseDate" => "2020-04-01T13:04:29+02:00",
                   "salesItemCode" => "A2D895F14D6B4F2DA03C",
                   "salesItemName" => "PPV - 249",
                   "type" => "PPV"
                 }
               ],
               "nextPageLink" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/2",
               "numberOfPages" => 2,
               "totalResults" => 2
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/2",
                          %{type: "PPV"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "currentPage" => 2,
               "items" => [
                 %{
                   "entitlements" => 5961,
                   "itemData" => %{"id" => 2, "name" => "2"},
                   "orderId" => 445_566,
                   "purchaseDate" => "2020-04-01T13:10:10+02:00",
                   "salesItemCode" => "A2D895F14D6B4F2DA03C",
                   "salesItemName" => "PPV - 249",
                   "type" => "PPV"
                 }
               ],
               "numberOfPages" => 2,
               "previousPageLink" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/1",
               "totalResults" => 2
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.customer_purchases_ppv("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                [
                  %Paywizard.PPV{
                    order_id: 112_233,
                    asset: %Paywizard.Asset{id: 1, title: "1"},
                    item_id: "A2D895F14D6B4F2DA03C"
                  },
                  %Paywizard.PPV{
                    order_id: 445_566,
                    asset: %Paywizard.Asset{id: 2, title: "2"},
                    item_id: "A2D895F14D6B4F2DA03C"
                  }
                ]}
    end

    test "causing system failure" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/1",
                          %{type: "PPV"} ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "developerMessage" =>
                 "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert Client.customer_purchases_ppv("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:paywizard_error, :customer_not_found}
    end
  end

  describe "get item" do
    test "successfully" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "active" => true,
               "categoryId" => 101,
               "description" => "C More TV4",
               "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
               "freeTrial" => %{"active" => true, "numberOfDays" => 14},
               "itemId" => "6D3A56FF5065478ABD61",
               "itemType" => "SERVICE",
               "name" => "C More TV4",
               "pricing" => %{
                 "frequency" => %{"frequency" => "MONTH", "length" => 1},
                 "initial" => %{"amount" => "0.00", "currency" => "SEK"},
                 "recurring" => %{"amount" => "139.00", "currency" => "SEK"}
               }
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK) ==
               {:ok,
                %Paywizard.Item{
                  id: "6D3A56FF5065478ABD61",
                  category_id: 101,
                  currency: :SEK,
                  name: "C More TV4",
                  entitlements: [5960],
                  recurring_billing: %{amount: "139.00", month_count: 1}
                }}
    end

    test "without required payload" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "active" => true,
               "categoryId" => 101,
               "description" => "C More TV4",
               "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
               "freeTrial" => %{"active" => true, "numberOfDays" => 14},
               "itemId" => "6D3A56FF5065478ABD61",
               "itemType" => "SERVICE",
               "name" => "C More TV4"
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert_raise RuntimeError, ~r/Incoming item payload was incomplete:/, fn ->
        Client.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK)
      end
    end

    test "causing system failure" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 500,
               "userMessage" => "System Failure - please retry later.",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 500
         }}
      end)

      assert_raise RuntimeError, ~r/item_by_id_and_currency did not get an successful response. Error:/, fn ->
        Client.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK)
      end
    end
  end

  describe "fetch single use promo code" do
    test "succeeds when promo code exists" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/promocode/TESTLM8WVE" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "promoCode" => "TESTLM8WVE",
               "availableForUse" => true,
               "numberOfRedemptions" => 0,
               "redemptionsPerCustomer" => 1,
               "promotionName" => "singelPromo",
               "promotionAvailability" => %{
                 "from" => "2020-06-02T13:34:40+02:00",
                 "to" => "2049-12-31T01:00:00+01:00"
               },
               "promotionActive" => true,
               "batchActive" => true,
               "discounts" => [
                 %{
                   "id" => 10218,
                   "name" => "SingelDiscount desc",
                   "description" => "SingelDiscount",
                   "friendReferred" => false
                 }
               ]
             }
             |> Jason.encode!(),
           status_code: 200
         }}
      end)

      assert Client.fetch_single_use_promo_code("TESTLM8WVE") ==
               {:ok,
                %{
                  "promoCode" => "TESTLM8WVE",
                  "availableForUse" => true,
                  "numberOfRedemptions" => 0,
                  "redemptionsPerCustomer" => 1,
                  "promotionName" => "singelPromo",
                  "promotionAvailability" => %{
                    "from" => "2020-06-02T13:34:40+02:00",
                    "to" => "2049-12-31T01:00:00+01:00"
                  },
                  "promotionActive" => true,
                  "batchActive" => true,
                  "discounts" => [
                    %{
                      "id" => 10218,
                      "name" => "SingelDiscount desc",
                      "description" => "SingelDiscount",
                      "friendReferred" => false
                    }
                  ]
                }}
    end

    test "fails when promo code does not exists" do
      MockPaywizardHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/promocode/NON-EXISTING-CODE" ->
        {:ok,
         %Paywizard.Response{
           body:
             %{
               "errorCode" => 90123,
               "userMessage" => "Promo code not found",
               "developerMessage" => "Error response from promocode service404",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)"
             }
             |> Jason.encode!(),
           status_code: 400
         }}
      end)

      assert Client.fetch_single_use_promo_code("NON-EXISTING-CODE") == {:paywizard_error, :promo_code_not_found}
    end
  end
end
