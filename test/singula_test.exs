defmodule SingulaTest do
  use ExUnit.Case
  import Hammox

  alias Singula.{Asset, CartDetail, Customer}

  setup :verify_on_exit!

  describe "create customer" do
    setup do
      %{
        customer: %Singula.Customer{
          external_unique_id: "123",
          username: "username",
          email: "user@host.com",
          password: "IC4nH4zS3cretP4ssword",
          first_name: "user",
          last_name: "test",
          addresses: [%{country_code: "SWE", post_code: "12345"}],
          date_of_birth: "1990-01-01",
          custom_attributes: [
            %{name: "no_ads", value: "false"},
            %{name: "generic_ads", value: "false"},
            %{name: "cmore_newsletter", value: "false"},
            %{name: "accepted_play_terms", value: "2019-10-16"},
            %{name: "accepted_fotbollskanalen_terms", value: "2012-12-12"},
            %{name: "accepted_cmore_terms", value: "2018-08-08"}
          ]
        }
      }
    end

    test "succeeds", %{customer: customer} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer", payload ->
        assert payload == %{
                 addresses: [%{postCode: "12345", countryCode: "SWE"}],
                 customAttributes: [
                   %{name: "no_ads", value: "false"},
                   %{name: "generic_ads", value: "false"},
                   %{name: "cmore_newsletter", value: "false"},
                   %{name: "accepted_play_terms", value: "2019-10-16"},
                   %{name: "accepted_fotbollskanalen_terms", value: "2012-12-12"},
                   %{name: "accepted_cmore_terms", value: "2018-08-08"}
                 ],
                 dateOfBirth: "1990-01-01",
                 email: "user@host.com",
                 externalUniqueIdentifier: "123",
                 title: "-",
                 firstName: "user",
                 lastName: "test",
                 username: "username",
                 password: "IC4nH4zS3cretP4ssword"
               }

        data = %{
          "href" => "/customer/06ac6f40-d290-4ec3-99c7-066303dc667c",
          "rel" => "Get customer",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_customer(customer) == {:ok, "06ac6f40-d290-4ec3-99c7-066303dc667c"}
    end

    test "username already exists", %{customer: customer} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer", _payload ->
        {:error,
         %Singula.Error{
           code: 90074,
           developer_message: "Username smoke_200624_01 already exists",
           user_message: "Username provided already exists"
         }}
      end)

      assert Singula.create_customer(customer) == {
               :error,
               %Singula.Error{
                 code: 90074,
                 developer_message: "Username smoke_200624_01 already exists",
                 user_message: "Username provided already exists"
               }
             }
    end

    test "external unique identifier already exists", %{customer: customer} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer", _payload ->
        {:error,
         %Singula.Error{
           code: 90084,
           developer_message: "External unique identifier ext_smoke_200624_01 already exists",
           user_message: "External unique identifier provided already exists"
         }}
      end)

      assert Singula.create_customer(customer) ==
               {:error,
                %Singula.Error{
                  code: 90084,
                  developer_message: "External unique identifier ext_smoke_200624_01 already exists",
                  user_message: "External unique identifier provided already exists"
                }}
    end

    test "email already exists", %{customer: customer} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer", _payload ->
        {:error,
         %Singula.Error{
           code: 90101,
           developer_message: "Email address test200624_01@cmore.se already exists",
           user_message: "Email address provided already exists"
         }}
      end)

      assert Singula.create_customer(customer) ==
               {:error,
                %Singula.Error{
                  code: 90101,
                  developer_message: "Email address test200624_01@cmore.se already exists",
                  user_message: "Email address provided already exists"
                }}
    end
  end

  test "update customer" do
    MockSingulaHTTPClient
    |> expect(:patch, fn "/apis/customers/v1/customer/12345", payload ->
      assert payload == %{firstName: "Tester"}

      data = %{
        "href" => "/customer/4b7a1fb4-c36f-45bd-8142-309ea57dc3e8",
        "rel" => "Get customer",
        "type" => "application/json"
      }

      {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
    end)

    customer = %Customer{id: "12345", first_name: "Tester"}
    assert Singula.update_customer(customer) == :ok
  end

  test "anomymise customer" do
    MockSingulaHTTPClient
    |> expect(:post, fn "/apis/customers/v1/customer/12345/anonymise", "" ->
      data = %{
        "href" => "/customer/4b7a1fb4-c36f-45bd-8142-309ea57dc3e8",
        "rel" => "Get customer",
        "type" => "application/json"
      }

      {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
    end)

    assert Singula.anonymise_customer("12345") == :ok
  end

  describe "get customer" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/customers/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0" ->
        data = %{
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
          "email" => "singula_purchase_test2@cmore.se",
          "externalUniqueIdentifier" => 100_471_887,
          "firstName" => "Singula_purchase_test2@cmore.se",
          "lastName" => "Singula_purchase_test2@cmore.se",
          "phone" => 0,
          "referAFriend" => %{"active" => false, "code" => "PIh70mZL"},
          "title" => "-",
          "username" => "singula_purchase_test2@cmore.se"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_fetch("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                %Customer{
                  active: true,
                  id: "ff160270-5197-4c90-835c-cd1fff8b19d0",
                  date_of_birth: nil,
                  addresses: [%Singula.Address{post_code: "Postcode", country_code: "SWE"}],
                  custom_attributes: [%{name: "accepted_cmore_terms", value: "2018-09-25"}],
                  email: "singula_purchase_test2@cmore.se",
                  external_unique_id: "100471887",
                  first_name: "Singula_purchase_test2@cmore.se",
                  last_name: "Singula_purchase_test2@cmore.se",
                  username: "singula_purchase_test2@cmore.se"
                }}
    end

    test "when customer not found" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/customers/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0" ->
        {:error,
         %Singula.Error{
           code: 90068,
           developer_message: "Customer 27dc778b-582e-4551-88c6-43806128a1a0 not located",
           user_message: "Customer cannot be located"
         }}
      end)

      assert Singula.customer_fetch("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:error,
                %Singula.Error{
                  code: 90068,
                  developer_message: "Customer 27dc778b-582e-4551-88c6-43806128a1a0 not located",
                  user_message: "Customer cannot be located"
                }}
    end
  end

  describe "search customer" do
    test "with an existing external customer id" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => "100471887"} ->
        data = %{
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
          "email" => "singula_purchase_test2@cmore.se",
          "externalUniqueIdentifier" => 100_471_887,
          "firstName" => "Singula_purchase_test2@cmore.se",
          "lastName" => "Singula_purchase_test2@cmore.se",
          "phone" => 0,
          "referAFriend" => %{"active" => false, "code" => "PIh70mZL"},
          "title" => "-",
          "username" => "singula_purchase_test2@cmore.se"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_search("100471887") ==
               {:ok,
                %Customer{
                  active: true,
                  id: "ff160270-5197-4c90-835c-cd1fff8b19d0",
                  date_of_birth: nil,
                  addresses: [%Singula.Address{post_code: "Postcode", country_code: "SWE"}],
                  custom_attributes: [%{name: "accepted_cmore_terms", value: "2018-09-25"}],
                  email: "singula_purchase_test2@cmore.se",
                  external_unique_id: "100471887",
                  first_name: "Singula_purchase_test2@cmore.se",
                  last_name: "Singula_purchase_test2@cmore.se",
                  username: "singula_purchase_test2@cmore.se"
                }}
    end

    test "with an incorrect external customer id" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/customers/v1/customer/search", %{"externalUniqueIdentifier" => "666"} ->
        {:error,
         %Singula.Error{
           code: 90068,
           user_message: "Customer cannot be located",
           developer_message: "Customer with external ID 666 not located"
         }}
      end)

      assert Singula.customer_search("666") ==
               {:error,
                %Singula.Error{
                  code: 90068,
                  user_message: "Customer cannot be located",
                  developer_message: "Customer with external ID 666 not located"
                }}
    end
  end

  describe "get contracts" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract?activeOnly=true" ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_contracts("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                [
                  %Singula.Contract{
                    active: true,
                    contract_id: 9_719_738,
                    item_id: "6D3A56FF5065478ABD61",
                    item_name: "C More TV4",
                    order_id: 112_233
                  }
                ]}
    end

    test "fails" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/non_existing_customer_id/contract?activeOnly=true" ->
        {:error,
         %Singula.Error{
           code: 500,
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
           user_message: "System Failure - please retry later."
         }}
      end)

      assert Singula.customer_contracts("non_existing_customer_id") ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end
  end

  describe "get contract" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738" ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:ok,
                %Singula.ContractDetails{
                  id: 9_622_082,
                  item_id: "4FC7D926073348038362",
                  item_name: "Field Sales - All Sport 12 plus 12",
                  balance: %{amount: -399.00, currency: :SEK},
                  recurring_billing: %{amount: 399.00, currency: :SEK, frequency: :MONTH, length: 24},
                  minimum_term: %{frequency: :MONTH, length: 24},
                  status: :ACTIVE,
                  start_date: ~D[2020-04-22],
                  paid_up_to_date: ~D[2020-04-22],
                  payment_method_id: 3_070_939
                }}
    end

    test "causes system failure" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/contracts/v1/customer/non_existing_customer_id/contract/9719738" ->
        {:error,
         %Singula.Error{
           code: 500,
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
           user_message: "System Failure - please retry later."
         }}
      end)

      assert Singula.customer_contract("non_existing_customer_id", 9_719_738) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end
  end

  describe "get ppv purchases" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/1",
                          %{type: "PPV"} ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/2",
                          %{type: "PPV"} ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_purchases_ppv("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
               {:ok,
                [
                  %Singula.PPV{
                    order_id: 112_233,
                    asset: %Singula.Asset{id: 1, title: "1"},
                    item_id: "A2D895F14D6B4F2DA03C"
                  },
                  %Singula.PPV{
                    order_id: 445_566,
                    asset: %Singula.Asset{id: 2, title: "2"},
                    item_id: "A2D895F14D6B4F2DA03C"
                  }
                ]}
    end

    test "causing system failure" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/non_existing_customer_id/purchases/1", %{type: "PPV"} ->
        {:error,
         %Singula.Error{
           code: 500,
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
           user_message: "System Failure - please retry later."
         }}
      end)

      assert Singula.customer_purchases_ppv("non_existing_customer_id") ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end
  end

  describe "fetch single use promo code" do
    test "succeeds when promo code exists" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/promocode/TESTLM8WVE" ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.fetch_single_use_promo_code("TESTLM8WVE") ==
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
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/promocode/NON-EXISTING-CODE" ->
        {:error,
         %Singula.Error{
           code: 90123,
           developer_message: "Error response from promocode service404",
           user_message: "Promo code not found"
         }}
      end)

      assert Singula.fetch_single_use_promo_code("NON-EXISTING-CODE") ==
               {:error,
                %Singula.Error{
                  code: 90123,
                  developer_message: "Error response from promocode service404",
                  user_message: "Promo code not found"
                }}
    end
  end

  describe "create cart" do
    test "without meta data" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{}}]}

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency") == {:ok, "10000"}
    end

    test "with asset" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{id: "654321", name: "Sportsboll"}}]}

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               asset: %Singula.Asset{id: "654321", title: "Sportsboll"}
             }) == {:ok, "10000"}
    end

    test "with referrer" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{referrerId: "A003_FS"}}]}

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{referrer: "A003_FS"}) ==
               {:ok, "10000"}
    end

    test "with discount" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{discountId: "10097", promoCode: "NONE", campaignCode: "NONE", sourceCode: "NONE"}
               }

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               discount: %Singula.Discount{discount: "10097"}
             }) == {:ok, "10000"}
    end

    test "with multi-use voucher discount" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{promoCode: "MULTI_HELLO", campaignCode: "NETONNET", sourceCode: "PARTNER"}
               }

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               discount: %Singula.Discount{
                 is_single_use: false,
                 promotion: "MULTI_HELLO",
                 campaign: "NETONNET",
                 source: "PARTNER"
               }
             }) == {:ok, "10000"}
    end

    test "with single-use voucher discount" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{individualPromoCode: "SINGLE-HELLO"}
               }

        data = %{
          "rel" => "Get cart details",
          "href" => "/customer/customer_id/cart/10000",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 201}}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               discount: %Singula.Discount{
                 is_single_use: true,
                 promotion: "SINGLE-HELLO"
               }
             }) == {:ok, "10000"}
    end

    test "causing system failure" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:error,
         %Singula.Error{
           code: 500,
           user_message: "System Failure - please retry later.",
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: customer_id"
         }}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency") ==
               {:error,
                %Singula.Error{
                  code: 500,
                  user_message: "System Failure - please retry later.",
                  developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: customer_id"
                }}
    end

    test "discount not found" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{discountId: "10097", promoCode: "NONE", campaignCode: "NONE", sourceCode: "NONE"}
               }

        {:error,
         %Singula.Error{
           code: 90115,
           developer_message: "Discount criteria not matched",
           user_message: "Discount criteria not matched"
         }}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               discount: %Singula.Discount{discount: "10097"}
             }) ==
               {:error,
                %Singula.Error{
                  code: 90115,
                  developer_message: "Discount criteria not matched",
                  user_message: "Discount criteria not matched"
                }}
    end

    test "voucher not found" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{
                   promoCode: "invalid_promotion",
                   campaignCode: "wrong_campaign",
                   sourceCode: "broken_source"
                 }
               }

        {:error,
         %Singula.Error{
           code: 90022,
           user_message: "Discount does not exist",
           developer_message: "Invalid discount code for cart"
         }}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency", %Singula.MetaData{
               discount: %Singula.Discount{
                 campaign: "wrong_campaign",
                 source: "broken_source",
                 promotion: "invalid_promotion"
               }
             }) ==
               {:error,
                %Singula.Error{
                  code: 90022,
                  user_message: "Discount does not exist",
                  developer_message: "Invalid discount code for cart"
                }}
    end

    test "item not added to cart" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:error,
         %Singula.Error{
           code: 90062,
           user_message: "Items could not be added",
           developer_message: "Unable to add sales item with code: null"
         }}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency") ==
               {:error,
                %Singula.Error{
                  code: 90062,
                  user_message: "Items could not be added",
                  developer_message: "Unable to add sales item with code: null"
                }}
    end

    test "item not found" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency", data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}]
               }

        {:error,
         %Singula.Error{
           code: 90069,
           user_message: "No item could be found with the given code",
           developer_message: "Unable to find sales item with code: item_id"
         }}
      end)

      assert Singula.create_cart_with_item("customer_id", "item_id", "currency") ==
               {:error,
                %Singula.Error{
                  code: 90069,
                  user_message: "No item could be found with the given code",
                  developer_message: "Unable to find sales item with code: item_id"
                }}
    end
  end

  describe "get cart" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        data = %{
          "id" => 121_765,
          "totalCost" => %{"amount" => "449.00", "currency" => "SEK"},
          "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
          "items" => [
            %{
              "itemCode" => "4151C241C3DD41529A87",
              "itemData" => "",
              "itemName" => "C More All Sport",
              "quantity" => 1,
              "cost" => %{"amount" => "449.00", "currency" => "SEK"}
            }
          ]
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.fetch_cart("customer_id", "121765") ==
               {:ok,
                %Singula.CartDetail{
                  currency: :SEK,
                  id: 121_765,
                  items: [
                    %Singula.CartDetail.Item{
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
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        {:error,
         %Singula.Error{
           code: 90040,
           user_message: "Cart ID provided is incorrect or does not exist",
           developer_message: "Unable to get cart 121765 for customer customer_id"
         }}
      end)

      assert Singula.fetch_cart("customer_id", "121765") ==
               {:error,
                %Singula.Error{
                  code: 90040,
                  user_message: "Cart ID provided is incorrect or does not exist",
                  developer_message: "Unable to get cart 121765 for customer customer_id"
                }}
    end

    test "causing system failure" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/purchases/v1/customer/customer_id/cart/121765" ->
        {:error,
         %Singula.Error{
           code: 500,
           user_message: "System Failure - please retry later.",
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: customer_id"
         }}
      end)

      assert Singula.fetch_cart("customer_id", "121765") ==
               {:error,
                %Singula.Error{
                  code: 500,
                  user_message: "System Failure - please retry later.",
                  developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: customer_id"
                }}
    end
  end

  describe "get item discounts" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/item_id/discounts?currency=currency" ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.fetch_item_discounts("item_id", "currency") ==
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
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/item_id/discounts?currency=currency" ->
        data = %{"discounts" => []}
        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.fetch_item_discounts("item_id", "currency") == {:ok, []}
    end
  end

  describe "create dibs redirect" do
    test "succeeds" do
      MockSingulaHTTPClient
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

        data = %{
          "type" => "redirect",
          "transactionId" => "mrngn-fiX9MEbB4S0",
          "redirectURL" =>
            "<form action=\"https:\/\/securedt.dibspayment.com\/verify\/bin\/cmoretest\/index\" method = \"POST\"><input type=\"hidden\" name=\"referenceNo\" value=\"mrngn-fiX9MEbB4S0-27674\"\/><input type=\"text\" name=\"billingAddress\" value=\"Address Line 1\"\/><input type=\"text\" name=\"billingCity\" value=\"Stockholm\"\/><input type=\"text\" name=\"billingCountry\" value=\"SE\"\/><input type=\"text\" name=\"billingFirstName\" value=\"Forename\"\/><input type=\"text\" name=\"billingLastName\" value=\"TV4 Media SmokeTest\"\/><input type=\"text\" name=\"currency\" value=\"SEK\"\/><input type=\"text\" name=\"data\" value=\"1:REGISTER_CARD:1:100:\"\/><input type=\"text\" name=\"eMail\" value=\"user@host.com\"\/><input type=\"text\" name=\"MAC\" value=\"D18242FF449D6A674622392AE34256F291B43ED6\"\/><input type=\"text\" name=\"pageSet\" value=\"cmore-payment-window-2-0\"\/><input type=\"text\" name=\"customReturnUrl\" value=\"https:\/\/www.google.se\"\/><input type=\"text\" name=\"method\" value=\"cc.test\"\/><input type=\"text\" name=\"authOnly\" value=\"true\"\/><button type=\"submit\">Submit<\/button><\/form>",
          "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      assert Singula.customer_redirect_dibs("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, redirect_data) ==
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
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/non_existing_customer_id/redirect", _data ->
        {:error,
         %Singula.Error{
           code: 500,
           user_message: "System Failure - please retry later.",
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id"
         }}
      end)

      assert Singula.customer_redirect_dibs("non_existing_customer_id", :SEK, %{}) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  user_message: "System Failure - please retry later.",
                  developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id"
                }}
    end
  end

  describe "create klarna redirect" do
    test "succeeds" do
      MockSingulaHTTPClient
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

        data = %{
          "type" => "klarnaSession",
          "transactionId" => "2m56mfCGyV7VWh96k",
          "sessionId" => "22aa3f2a-ca55-19a6-8790-540a527fc877",
          "clientToken" => "eyJhbGciOiJSUzI1NiIs",
          "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
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

      assert Singula.customer_redirect_klarna("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, redirect_data) ==
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
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/non_existing_customer_id/redirect", _data ->
        {:error,
         %Singula.Error{
           code: 500,
           developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
           user_message: "System Failure - please retry later."
         }}
      end)

      assert Singula.customer_redirect_klarna("non_existing_customer_id", :SEK, %{}) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end
  end

  describe "add dibs payment method to customer" do
    setup do
      dibs_payment_method =
        Singula.PaymentMethodProvider.Dibs.new(
          "HrE7FZvc16lUo1ASCLt",
          "617371666",
          "**** **** **** 0000",
          "457110",
          "Visa",
          "12",
          "21"
        )

      {:ok, dibs_payment_method: dibs_payment_method}
    end

    test "on success", %{dibs_payment_method: dibs_payment_method} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :defaultMethod, value: true},
                   %{key: :dibs_ccPart, value: "************0000"},
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

        data = %{"paymentMethodId" => 26574}
        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.add_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:ok, 26574}
    end

    test "transaction not found", %{dibs_payment_method: dibs_payment_method} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          _payment_method_data ->
        {:error,
         %Singula.Error{
           code: 90047,
           developer_message: "Token not generated",
           user_message: "Payment method creation failure"
         }}
      end)

      assert Singula.add_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:error,
                %Singula.Error{
                  code: 90047,
                  developer_message: "Token not generated",
                  user_message: "Payment method creation failure"
                }}
    end

    test "receipt not found", %{dibs_payment_method: dibs_payment_method} do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
                          _payment_method_data ->
        {:error,
         %Singula.Error{
           code: 90054,
           developer_message: "Authorisation failed",
           user_message: "Payment provider cannot complete transaction"
         }}
      end)

      assert Singula.add_payment_method("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK, dibs_payment_method) ==
               {:error,
                %Singula.Error{
                  code: 90054,
                  developer_message: "Authorisation failed",
                  user_message: "Payment provider cannot complete transaction"
                }}
    end
  end

  describe "add klarna payment method to customer" do
    test "on success" do
      MockSingulaHTTPClient
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

        data = %{"paymentMethodId" => 654_321}
        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      payment_method = %Singula.PaymentMethodProvider.Klarna{
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

      assert Singula.add_payment_method("4ad58d9d-8976-47c0-af2c-35debf38d0eb", :SEK, payment_method) ==
               {:ok, 654_321}
    end
  end

  test "add not provided payment method to customer" do
    MockSingulaHTTPClient
    |> expect(:post, fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod", data ->
      assert data == %{
               "currencyCode" => :SEK,
               "data" => [],
               "digest" => "7e842b89f8d45d4162f32a197d5fc61b0d025a33672808b6fc35c6ee6deddccd",
               "merchantCode" => "BBR",
               "provider" => :NOT_PROVIDED,
               "uuid" => "30f86e79-ed75-4022-a16e-d55d9f09af8d"
             }

      data = %{"paymentMethodId" => 26574}
      {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
    end)

    assert Singula.add_payment_method(
             "ff160270-5197-4c90-835c-cd1fff8b19d0",
             :SEK,
             %Singula.PaymentMethodProvider.None{}
           ) == {:ok, 26574}
  end

  describe "set dibs payment method on contract" do
    test "success" do
      MockSingulaHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/83315a42-af04-4e59-949a-ef2b3e7bf3dd/contract/20919/paymentmethod",
           %{
             paymentMethodId: 67890
           } ->
          {:ok,
           %Singula.Response{
             status_code: 200,
             body:
               "{\"rel\":\"Get contract details\",\"href\":\"\\/customer\\/83315a42-af04-4e59-949a-ef2b3e7bf3dd\\/contract\\/20919\",\"type\":\"application\\/json\"}"
           }}
        end
      )

      assert Singula.update_payment_method("83315a42-af04-4e59-949a-ef2b3e7bf3dd", 20919, 67890) == :ok
    end
  end

  describe "checkout cart" do
    test "success for subscription that supports free trial" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
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
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
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
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        data = %{
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

        {:ok, %Singula.Response{status_code: 200, body: Jason.encode!(data), json: data}}
      end)

      assert Singula.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
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
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:error,
         %Singula.Error{
           code: 90040,
           user_message: "Cart ID provided is incorrect or does not exist",
           developer_message: "No cart found with given ID"
         }}
      end)

      assert Singula.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:error,
                %Singula.Error{
                  code: 90040,
                  user_message: "Cart ID provided is incorrect or does not exist",
                  developer_message: "No cart found with given ID"
                }}
    end

    test "payment authorization fault" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
                          %{"paymentMethodId" => 26574} ->
        {:error,
         %Singula.Error{
           code: 90045,
           user_message: "Payment attempt failed",
           developer_message: "Unable to authorise payment: PaymentAttemptFailedException server_error PSP error: 402"
         }}
      end)

      assert Singula.customer_cart_checkout("ff160270-5197-4c90-835c-cd1fff8b19d0", "118114", 26574) ==
               {:error,
                %Singula.Error{
                  code: 90045,
                  user_message: "Payment attempt failed",
                  developer_message:
                    "Unable to authorise payment: PaymentAttemptFailedException server_error PSP error: 402"
                }}
    end
  end

  describe "cancel contract" do
    test "successfully" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel",
                          %{"cancelDate" => ""} ->
        data = %{"status" => "CUSTOMER_CANCELLED", "cancellationDate" => "2020-05-12"}

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) == {:ok, ~D[2020-05-12]}
    end

    test "when minimum term blocks cancellation" do
      MockSingulaHTTPClient
      |> expect(:post, fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel",
                          %{"cancelDate" => "2020-02-02"} ->
        {:error,
         %Singula.Error{
           code: 90006,
           developer_message: "Unable to cancel contract : 9622756",
           user_message: "Failed to cancel contract"
         }}
      end)

      assert Singula.cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738, "2020-02-02") ==
               {:error,
                %Singula.Error{
                  code: 90006,
                  developer_message: "Unable to cancel contract : 9622756",
                  user_message: "Failed to cancel contract"
                }}
    end
  end

  describe "withdraw cancel contract" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel/withdraw", %{} ->
          data = %{
            "href" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738",
            "rel" => "Get contract details",
            "type" => "application/json"
          }

          {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
        end
      )

      assert Singula.withdraw_cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) == :ok
    end

    test "fails" do
      MockSingulaHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/cancel/withdraw", %{} ->
          {:error,
           %Singula.Error{
             code: 90017,
             developer_message: "Contract cannot be cancelled at this time",
             user_message: "Contract cannot be changed at this time"
           }}
        end
      )

      assert Singula.withdraw_cancel_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:error,
                %Singula.Error{
                  code: 90017,
                  developer_message: "Contract cannot be cancelled at this time",
                  user_message: "Contract cannot be changed at this time"
                }}
    end
  end

  describe "withdraw change contract" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/change/withdraw", %{} ->
          data = %{
            "href" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738",
            "rel" => "Get contract details",
            "type" => "application/json"
          }

          {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
        end
      )

      assert Singula.withdraw_change_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) == :ok
    end

    test "fails" do
      MockSingulaHTTPClient
      |> expect(
        :post,
        fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/change/withdraw", %{} ->
          {:error,
           %Singula.Error{
             code: 90108,
             developer_message:
               "Unable to withdraw change of contract 9719738 for customer ff160270-5197-4c90-835c-cd1fff8b19d0/6296944; invalid state ACTIVE",
             user_message: "Unable to withdraw scheduled contract change"
           }}
        end
      )

      assert Singula.withdraw_change_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
               {:error,
                %Singula.Error{
                  code: 90108,
                  developer_message:
                    "Unable to withdraw change of contract 9719738 for customer ff160270-5197-4c90-835c-cd1fff8b19d0/6296944; invalid state ACTIVE",
                  user_message: "Unable to withdraw scheduled contract change"
                }}
    end
  end

  test "crossgrades for contract" do
    MockSingulaHTTPClient
    |> expect(
      :get,
      fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/change" ->
        data = %{
          "crossgradePaths" => [
            %{
              "itemCode" => "180B2AD9332349E6A7A4",
              "name" => "C More",
              "changeCost" => %{"amount" => "109.00", "currency" => "SEK"},
              "changeType" => "DOWNGRADE"
            },
            %{
              "itemCode" => "C943A5FED47E444B96E1",
              "name" => "C More All Sport - 12 months",
              "changeCost" => %{"amount" => "449.00", "currency" => "SEK"},
              "changeType" => "CROSSGRADE"
            },
            %{
              "itemCode" => "9781F421A5894FC0AA96",
              "name" => "C More Mycket Sport",
              "changeCost" => %{"amount" => "199.00", "currency" => "SEK"},
              "changeType" => "UPGRADE"
            },
            %{
              "itemCode" => "4151C241C3DD41529A87",
              "name" => "C More All Sport",
              "changeCost" => %{"amount" => "449.00", "currency" => "SEK"},
              "changeType" => "UPGRADE"
            }
          ]
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end
    )

    assert Singula.crossgrades_for_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738) ==
             {:ok,
              [
                %Singula.Crossgrade{
                  currency: :SEK,
                  item_id: "180B2AD9332349E6A7A4",
                  change_type: :DOWNGRADE,
                  change_cost: "109.00"
                },
                %Singula.Crossgrade{
                  currency: :SEK,
                  item_id: "C943A5FED47E444B96E1",
                  change_type: :CROSSGRADE,
                  change_cost: "449.00"
                },
                %Singula.Crossgrade{
                  currency: :SEK,
                  item_id: "9781F421A5894FC0AA96",
                  change_type: :UPGRADE,
                  change_cost: "199.00"
                },
                %Singula.Crossgrade{
                  currency: :SEK,
                  item_id: "4151C241C3DD41529A87",
                  change_type: :UPGRADE,
                  change_cost: "449.00"
                }
              ]}
  end

  test "change a contract" do
    MockSingulaHTTPClient
    |> expect(
      :post,
      fn "/apis/contracts/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738/change",
         %{itemCode: "180B2AD9332349E6A7A4"} ->
        data = %{
          "href" => "/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/contract/9719738",
          "rel" => "Get contract details",
          "type" => "application/json"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end
    )

    assert Singula.change_contract("ff160270-5197-4c90-835c-cd1fff8b19d0", 9_719_738, "180B2AD9332349E6A7A4") == :ok
  end

  describe "get item" do
    test "successfully" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        data = %{
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

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK) ==
               {:ok,
                %Singula.Item{
                  id: "6D3A56FF5065478ABD61",
                  category_id: 101,
                  currency: :SEK,
                  name: "C More TV4",
                  entitlements: [%Singula.Entitlement{id: 5960, name: "C More TV4"}],
                  recurring_billing: %{amount: "139.00", month_count: 1}
                }}
    end

    test "without required payload" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        data = %{
          "active" => true,
          "categoryId" => 101,
          "description" => "C More TV4",
          "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
          "freeTrial" => %{"active" => true, "numberOfDays" => 14},
          "itemId" => "6D3A56FF5065478ABD61",
          "itemType" => "SERVICE",
          "name" => "C More TV4"
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert_raise FunctionClauseError, "no function clause matching in Singula.Item.new/1", fn ->
        Singula.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK)
      end
    end

    test "fails" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
        {:error,
         %Singula.Error{
           code: 90069,
           developer_message: "Catalogue item not found",
           user_message: "No item could be found with the given code"
         }}
      end)

      assert Singula.item_by_id_and_currency("6D3A56FF5065478ABD61", :SEK) ==
               {:error,
                %Singula.Error{
                  code: 90069,
                  developer_message: "Catalogue item not found",
                  user_message: "No item could be found with the given code"
                }}
    end
  end

  describe "get payment methods" do
    test "succeeds" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/payment-methods/v1/customer/76f8f800-e51d-4093-b573-31e4226a0da8/list" ->
        data = %{
          "PaymentMethod" => [
            %{
              "cardType" => "Visa",
              "defaultMethod" => true,
              "expiryDate" => "12/2023",
              "maskedCard" => "402005*** **** 0000",
              "paymentMethodId" => 28604,
              "provider" => "DIBS",
              "tokenId" => "eJ0cAVyX-JKzz2u7c-V"
            },
            %{
              "defaultMethod" => false,
              "email" => "test@cmore.se",
              "paymentMethodId" => 28646,
              "provider" => "KLARNA",
              "tokenId" => "nSX2OIPMS48UcL35aRv"
            }
          ]
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.payment_methods("76f8f800-e51d-4093-b573-31e4226a0da8") ==
               {:ok,
                [
                  %Singula.DibsPaymentMethod{
                    id: 28604,
                    default: true,
                    expiry_date: "12/2023",
                    masked_card: "402005*** **** 0000"
                  },
                  %Singula.KlarnaPaymentMethod{id: 28646, default: false}
                ]}
    end

    test "filter out unsupported payment methods" do
      MockSingulaHTTPClient
      |> expect(:get, fn "/apis/payment-methods/v1/customer/76f8f800-e51d-4093-b573-31e4226a0da8/list" ->
        data = %{
          "PaymentMethod" => [
            %{
              "cardType" => "Visa",
              "defaultMethod" => true,
              "expiryDate" => "12/2023",
              "maskedCard" => "402005*** **** 0000",
              "paymentMethodId" => 28604,
              "provider" => "DIBS",
              "tokenId" => "eJ0cAVyX-JKzz2u7c-V"
            },
            %{
              "paymentMethodId" => 100_000,
              "provider" => "DIAGNAL",
              "cardType" => "VISA",
              "maskedCard" => "426397xxxx1307",
              "expiryDate" => "01/2021",
              "email" => "customer@singuladecisions.com",
              "tokenId" => "string",
              "defaultMethod" => true
            }
          ]
        }

        {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
      end)

      assert Singula.payment_methods("76f8f800-e51d-4093-b573-31e4226a0da8") ==
               {:ok,
                [
                  %Singula.DibsPaymentMethod{
                    id: 28604,
                    default: true,
                    expiry_date: "12/2023",
                    masked_card: "402005*** **** 0000"
                  }
                ]}
    end
  end

  test "get category" do
    MockSingulaHTTPClient
    |> expect(:get, fn "/apis/catalogue/v1/category/224?limited=false" ->
      data = %{
        "categories" => [
          %{
            "categories" => [
              %{"categoryId" => 256, "name" => "C+More"},
              %{"categoryId" => 259, "name" => "C+More+All+Sport"},
              %{"categoryId" => 258, "name" => "C+More+Mycket+Sport"},
              %{"categoryId" => 257, "name" => "C+More+TV4"}
            ],
            "categoryId" => 227,
            "name" => "Sweden"
          },
          %{
            "categories" => [
              %{"categoryId" => 261, "name" => "C+More+Film+og+Serier+DK"}
            ],
            "categoryId" => 229,
            "name" => "Denmark"
          },
          %{
            "categories" => [
              %{"categoryId" => 260, "name" => "C+More+Film+og+Serier+NO"}
            ],
            "categoryId" => 228,
            "name" => "Norway"
          }
        ],
        "categoryId" => 224,
        "name" => "Subscription"
      }

      {:ok, %Singula.Response{body: Jason.encode!(data), json: data, status_code: 200}}
    end)

    assert Singula.category(224, false) ==
             {:ok,
              %Singula.Category{
                categories: [
                  %Singula.Category{
                    categories: [
                      %Singula.Category{id: 256, name: "C+More"},
                      %Singula.Category{id: 259, name: "C+More+All+Sport"},
                      %Singula.Category{id: 258, name: "C+More+Mycket+Sport"},
                      %Singula.Category{id: 257, name: "C+More+TV4"}
                    ],
                    id: 227,
                    name: "Sweden"
                  },
                  %Singula.Category{
                    categories: [
                      %Singula.Category{id: 261, name: "C+More+Film+og+Serier+DK"}
                    ],
                    id: 229,
                    name: "Denmark"
                  },
                  %Singula.Category{
                    categories: [
                      %Singula.Category{id: 260, name: "C+More+Film+og+Serier+NO"}
                    ],
                    id: 228,
                    name: "Norway"
                  }
                ],
                id: 224,
                name: "Subscription"
              }}
  end
end
