defmodule SmokeTest.Singula do
  use ExUnit.Case
  require Logger

  setup_all do
    :ok = Singula.Telemetry.attach_singula_response_handler()
    :ok = Singula.Telemetry.attach_librato_response_handler()

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

  setup_all [:setup_test_customer, :setup_defaults]
  setup :merge_saved_test_context

  test "get item by id and currency", %{subscription_item_id: item_id, currency: currency} do
    assert Singula.item_by_id_and_currency(item_id, currency) ==
             {:ok,
              %Singula.Item{
                category_id: 257,
                currency: :SEK,
                entitlements: [%Singula.Entitlement{id: 5960, name: "C More TV4"}],
                id: "6D3A56FF5065478ABD61",
                minimum_term_month_count: nil,
                name: "C More TV4",
                one_off_price: nil,
                recurring_billing: %{amount: "139.00", month_count: 1},
                free_trial: %Singula.FreeTrial{number_of_days: 14},
              }}
  end

  test "get non-existing item by id and currency", %{currency: currency} do
    assert Singula.item_by_id_and_currency("non-existing", currency) ==
             {:error,
              %Singula.Error{
                code: 90069,
                developer_message: "Catalogue item not found",
                user_message: "No item could be found with the given code"
              }}
  end

  test "update customer", %{customer_id: customer_id} do
    customer = %Singula.Customer{id: customer_id, first_name: "Test"}
    assert Singula.update_customer(customer) == :ok
  end

  describe "get customer by id" do
    test "returns set parameters", %{customer_id: customer_id, email: email, username: username, vimond_id: vimond_id} do
      assert Singula.customer_fetch(customer_id) ==
               {:ok,
                %Singula.Customer{
                  active: true,
                  addresses: [%Singula.Address{post_code: 12220, country_code: "SWE"}],
                  custom_attributes: [
                    %{name: "accepted_play_terms", value: "Telia"},
                    %{name: "accepted_play_terms_date", value: "2020-02-25"}
                  ],
                  id: customer_id,
                  date_of_birth: nil,
                  email: email,
                  external_unique_id: vimond_id,
                  first_name: "Test",
                  last_name: "TV4 Media SmokeTest",
                  username: username
                }}
    end

    test "when customer not found" do
      assert Singula.customer_fetch("12345678-90ab-cdef-1234-567890abcdef") ==
               {
                 :error,
                 %Singula.Error{
                   code: 90068,
                   developer_message: "Customer 12345678-90ab-cdef-1234-567890abcdef not located",
                   user_message: "Customer cannot be located"
                 }
               }
    end
  end

  describe "search external id" do
    test "returns set parameters", %{customer_id: customer_id, email: email, username: username, vimond_id: vimond_id} do
      assert Singula.customer_search(vimond_id) ==
               {:ok,
                %Singula.Customer{
                  active: true,
                  addresses: [%Singula.Address{post_code: 12220, country_code: "SWE"}],
                  custom_attributes: [
                    %{name: "accepted_play_terms", value: "Telia"},
                    %{name: "accepted_play_terms_date", value: "2020-02-25"}
                  ],
                  id: customer_id,
                  date_of_birth: nil,
                  email: email,
                  external_unique_id: vimond_id,
                  first_name: "Test",
                  last_name: "TV4 Media SmokeTest",
                  username: username
                }}
    end

    test "returns error 90068 when not finding customer" do
      assert Singula.customer_search("666") == {
               :error,
               %Singula.Error{
                 code: 90068,
                 developer_message: "Customer with external ID 666 not located",
                 user_message: "Customer cannot be located"
               }
             }
    end
  end

  describe "fetch customer contracts" do
    test "returns 0 when no contracts", %{customer_id: customer_id} do
      assert Singula.customer_contracts(customer_id) == {:ok, []}
    end

    test "returns customer not found passing invalid UUID" do
      assert Singula.customer_contracts("non_existing_customer_id") == {
               :error,
               %Singula.Error{
                 code: 500,
                 developer_message: "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                 user_message: "System Failure - please retry later."
               }
             }
    end
  end

  describe "fetch customer PPV purchases" do
    test "returns 0 when no purchases", %{customer_id: customer_id} do
      assert Singula.customer_purchases_ppv(customer_id) == {:ok, []}
    end

    test "returns customer not found passing invalid UUID" do
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

  describe "create cart with an item" do
    test "returns new cart with passed customer_id", %{
      customer_id: customer_id,
      subscription_item_id: subscription_item_id,
      currency: currency
    } do
      assert {:ok, cart_id} = Singula.create_cart_with_item(customer_id, subscription_item_id, currency)

      save_in_test_context(:cart_id, cart_id)
    end

    test "returns PPV in cart when adding it", %{
      customer_id: customer_id,
      ppv_item_id: ppv_item_id,
      currency: currency,
      asset: asset
    } do
      assert {:ok, cart_id} =
               Singula.create_cart_with_item(customer_id, ppv_item_id, currency, %Singula.MetaData{
                 asset: asset
               })

      save_in_test_context(:ppv_cart_id, cart_id)
    end

    test "returns customer not found passing invalid UUID", %{subscription_item_id: item_id, currency: currency} do
      assert Singula.create_cart_with_item("non_existing_customer_id", item_id, currency) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end

    test "returns error 90069 for non-existing item code", %{customer_id: customer_id, currency: currency} do
      assert Singula.create_cart_with_item(customer_id, "incorrect_item_id", currency) ==
               {:error,
                %Singula.Error{
                  code: 90069,
                  developer_message: "Unable to find sales item with code: incorrect_item_id",
                  user_message: "No item could be found with the given code"
                }}
    end
  end

  describe "fetch cart details" do
    test "returns no free trial subscription", %{
      customer_id: customer_id,
      currency: currency,
      no_free_trial_item_id: subscription_item_id
    } do
      assert {:ok, cart_id} = Singula.create_cart_with_item(customer_id, subscription_item_id, currency)

      assert Singula.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Singula.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Singula.CartDetail.Item{
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
      assert Singula.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Singula.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Singula.CartDetail.Item{
                      cost: "0.00",
                      item_id: subscription_item_id,
                      item_name: "C More TV4",
                      quantity: 1,
                      trial: %Singula.CartDetail.Item.Trial{
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
      assert Singula.fetch_cart(customer_id, cart_id) ==
               {:ok,
                %Singula.CartDetail{
                  currency: :SEK,
                  id: String.to_integer(cart_id),
                  items: [
                    %Singula.CartDetail.Item{
                      asset: asset,
                      cost: "149.00",
                      item_id: ppv_item_id,
                      item_name: "Matchbiljett - 149",
                      quantity: 1
                    }
                  ],
                  total_cost: "149.00"
                }}
    end

    test "returns customer not found passing invalid UUID", %{cart_id: cart_id} do
      assert Singula.fetch_cart("non_existing_customer_id", cart_id) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
    end

    test "returns error 90040 for non-existing cart", %{customer_id: customer_id} do
      assert Singula.fetch_cart(customer_id, 666) ==
               {:error,
                %Singula.Error{
                  code: 90040,
                  developer_message: "Unable to get cart 666 for customer #{customer_id}",
                  user_message: "Cart ID provided is incorrect or does not exist"
                }}
    end

    test "unhandled error for invalid cart id ", %{customer_id: customer_id} do
      assert Singula.fetch_cart(customer_id, "non-numeric-cart") ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message: "java.lang.NumberFormatException: For input string: \"non-numeric-cart\"",
                  user_message: "System Failure - please retry later."
                }}
    end
  end

  describe "fetch item on sale" do
    test "returns empty list for item without discount", %{no_discount_item_id: item_id, currency: currency} do
      assert Singula.fetch_item_discounts(item_id, currency) == {:ok, []}
    end

    test "returns discount codes for item", %{subscription_item_id: item_id, currency: currency} do
      assert {:ok, discounts} = Singula.fetch_item_discounts(item_id, currency)

      discount = Enum.find(discounts, fn discount -> discount["id"] == 10125 end)
      campaign = Enum.find(discount["linkedCombos"], fn campaign -> campaign["campaign"] == "TESTWITHCAMPAIGN" end)

      assert campaign == %{
               "campaign" => "TESTWITHCAMPAIGN",
               "promotion" => "PROMO1",
               "source" => "TESTWITHSOURCE"
             }

      save_in_test_context(:discount, %Singula.Discount{
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
               Singula.create_cart_with_item(customer_id, subscription_item_id, currency, %Singula.MetaData{
                 discount: discount
               })

      assert Singula.fetch_cart(customer_id, cart_id) == {
               :ok,
               %Singula.CartDetail{
                 currency: :SEK,
                 discount: %Singula.CartDetail.Discount{
                   discount_amount: "224.50",
                   discount_end_date: nil
                 },
                 id: String.to_integer(cart_id),
                 items: [
                   %Singula.CartDetail.Item{
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
      assert Singula.create_cart_with_item(customer_id, subscription_item_id, currency, %Singula.MetaData{
               discount: %Singula.Discount{
                 campaign: "wrong_campaign",
                 source: "broken_source",
                 promotion: "invalid_promotion"
               }
             }) ==
               {:error,
                %Singula.Error{
                  code: 90022,
                  developer_message: "Invalid discount code for cart",
                  user_message: "Discount does not exist"
                }}
    end
  end

  describe "check out cart with Dibs" do
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
              }} = Singula.customer_redirect_dibs(customer_id, currency, dibs_redirect_data)

      save_in_test_context(:transaction_id, transaction_id)
    end

    test "redirect returns customer not found passing invalid UUID", %{currency: currency} do
      dibs_redirect_data = %{
        itemDescription: "REGISTER_CARD",
        amount: "1.00",
        payment_method: "cc.test",
        billing_city: "Stockholm"
      }

      assert Singula.customer_redirect_dibs("non_existing_customer_id", currency, dibs_redirect_data) ==
               {:error,
                %Singula.Error{
                  code: 500,
                  developer_message:
                    "java.lang.IllegalArgumentException: Invalid UUID string: non_existing_customer_id",
                  user_message: "System Failure - please retry later."
                }}
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

      dibs_payment_method = %Singula.PaymentMethodProvider.Dibs{
        dibs_ccPart: "**** **** **** 0000",
        dibs_ccPrefix: "457110",
        dibs_ccType: "Visa",
        dibs_expM: "12",
        dibs_expY: "21",
        receipt: payment_method_receipt,
        transactionId: transaction_id
      }

      assert {:ok, payment_method_id} = Singula.add_payment_method(customer_id, currency, dibs_payment_method)

      save_in_test_context(:payment_method_id, payment_method_id)
    end

    test "list payment methods", %{customer_id: customer_id, payment_method_id: payment_method_id} do
      assert Singula.payment_methods(customer_id) ==
               {:ok,
                [
                  %Singula.DibsPaymentMethod{
                    id: payment_method_id,
                    default: true,
                    masked_card: "457110*** **** 0000",
                    expiry_date: "12/2021"
                  }
                ]}
    end

    test "checking out subscription cart returns cart details", %{
      customer_id: customer_id,
      cart_id: cart_id,
      payment_method_id: payment_method_id,
      subscription_item_id: item_id
    } do
      assert {:ok, %Singula.CartDetail{contract_id: contract_id, order_id: order_id} = cart} =
               Singula.customer_cart_checkout(customer_id, cart_id, payment_method_id)

      assert cart == %Singula.CartDetail{
               contract_id: contract_id,
               currency: :SEK,
               items: [
                 %Singula.CartDetail.Item{
                   cost: "0.00",
                   item_id: item_id,
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Singula.CartDetail.Item.Trial{
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
      assert {:ok, %Singula.CartDetail{order_id: order_id} = cart} =
               Singula.customer_cart_checkout(customer_id, cart_id, payment_method_id)

      assert cart == %Singula.CartDetail{
               currency: :SEK,
               items: [
                 %Singula.CartDetail.Item{
                   cost: "149.00",
                   item_id: item_id,
                   item_name: "Matchbiljett - 149",
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

  describe "fetch customer contracts after checkout" do
    test "returns purchased subscription", %{
      customer_id: customer_id,
      subscription_item_id: item_id,
      contract_id: contract_id,
      order_id: order_id,
      payment_method_id: payment_method_id
    } do
      assert Singula.customer_contracts(customer_id) ==
               {:ok,
                [
                  %Singula.Contract{
                    active: true,
                    contract_id: contract_id,
                    item_id: item_id,
                    item_name: "C More TV4",
                    order_id: order_id
                  }
                ]}

      assert Singula.customer_contract(customer_id, contract_id) ==
               {:ok,
                %Singula.ContractDetails{
                  balance: %{amount: 0.00, currency: :SEK},
                  id: contract_id,
                  order_id: order_id,
                  item_id: item_id,
                  item_name: "C More TV4",
                  paid_up_to_date: Date.utc_today() |> Date.add(14),
                  recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
                  upcoming_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
                  start_date: Date.utc_today(),
                  status: :ACTIVE,
                  payment_method_id: payment_method_id
                }}
    end

    test "returns purchased pay per view", %{
      customer_id: customer_id,
      ppv_item_id: item_id,
      asset: asset,
      ppv_order_id: order_id
    } do
      assert Singula.customer_purchases_ppv(customer_id) ==
               {:ok, [%Singula.PPV{asset: asset, item_id: item_id, order_id: order_id,  entitlements: [%Singula.Entitlement{id: 5967, name: "Matchbiljett 149 kr"}]}]}
    end
  end

  describe "create a cart with an item for a deleted customer" do
    test "returns error 90062", %{subscription_item_id: item_id, currency: currency} do
      unix_time_now = DateTime.to_unix(DateTime.utc_now())
      user_id = "smoke_test_#{unix_time_now}"
      external_id = unix_time_now
      email = "#{user_id}@bbrtest.se"
      customer_id = create_test_customer(external_id, user_id, email)
      :ok = Singula.anonymise_customer(customer_id)

      assert Singula.create_cart_with_item(customer_id, item_id, currency) ==
               {:error,
                %Singula.Error{
                  code: 90062,
                  developer_message: "Unable to add sales item with code: null",
                  user_message: "Items could not be added"
                }}
    end
  end

  describe "check out cart with Klarna" do
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
              }} = Singula.customer_redirect_klarna(customer_id, currency, klarna_redirect_data)
    end
  end

  test "cancel contract", %{customer_id: customer_id, contract_id: contract_id} do
    assert Singula.cancel_contract(customer_id, contract_id) == {:ok, Date.utc_today() |> Date.add(14)}
  end

  test "withdraw cancel contract", %{customer_id: customer_id, contract_id: contract_id} do
    assert Singula.withdraw_cancel_contract(customer_id, contract_id) == :ok
  end

  test "change a contract changes immediately for upgrades", %{
    customer_id: customer_id,
    contract_id: contract_id,
    order_id: order_id,
    payment_method_id: payment_method_id
  } do
    assert Singula.change_contract(customer_id, contract_id, "4151C241C3DD41529A87") == :ok

    {:ok, contract} = Singula.customer_contract(customer_id, contract_id)
    assert contract.order_id > order_id

    assert contract == %Singula.ContractDetails{
             balance: %{amount: 0.00, currency: :SEK},
             id: contract_id,
             order_id: contract.order_id,
             item_id: "4151C241C3DD41529A87",
             item_name: "C More All Sport",
             paid_up_to_date: Date.utc_today() |> Timex.shift(months: 1),
             recurring_billing: %{amount: 449.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 449.00, currency: :SEK, frequency: :MONTH, length: 1},
             start_date: Date.utc_today(),
             status: :ACTIVE,
             payment_method_id: payment_method_id
           }
  end

  test "change a contract that is scheduled for downgrades", %{
    customer_id: customer_id,
    contract_id: contract_id,
    subscription_item_id: item_id,
    order_id: order_id,
    payment_method_id: payment_method_id
  } do
    assert Singula.change_contract(customer_id, contract_id, item_id) == :ok

    {:ok, contract} = Singula.customer_contract(customer_id, contract_id)
    assert contract.order_id > order_id

    assert contract == %Singula.ContractDetails{
             balance: %{amount: 0.00, currency: :SEK},
             change_date: Date.utc_today() |> Timex.shift(months: 1),
             change_to_item_id: item_id,
             id: contract_id,
             order_id: contract.order_id,
             item_id: "4151C241C3DD41529A87",
             item_name: "C More All Sport",
             paid_up_to_date: Date.utc_today() |> Timex.shift(months: 1),
             recurring_billing: %{amount: 449.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 449.00, currency: :SEK, frequency: :MONTH, length: 1},
             start_date: Date.utc_today(),
             status: :DOWNGRADE_SCHEDULED,
             payment_method_id: payment_method_id
           }
  end

  test "withdraw a contract change that is scheduled for downgrade", %{
    customer_id: customer_id,
    contract_id: contract_id
  } do
    assert Singula.withdraw_change_contract(customer_id, contract_id) == :ok
  end

  test "get available crossgrades for a contract", %{customer_id: customer_id, contract_id: contract_id} do
    assert {:ok, crossgrades} = Singula.crossgrades_for_contract(customer_id, contract_id)

    assert crossgrades
           |> Enum.reject(&(&1.change_type == :CROSSGRADE))
           |> Enum.sort_by(& &1.item_id) == [
             %Singula.Crossgrade{
               currency: :SEK,
               item_id: "180B2AD9332349E6A7A4",
               change_type: :DOWNGRADE,
               change_cost: "-340.00"
             },
             %Singula.Crossgrade{
               currency: :SEK,
               item_id: "6D3A56FF5065478ABD61",
               change_type: :DOWNGRADE,
               change_cost: "-310.00"
             },
             %Singula.Crossgrade{
               currency: :SEK,
               item_id: "9781F421A5894FC0AA96",
               change_type: :DOWNGRADE,
               change_cost: "-250.00"
             }
           ]
  end

  test "update contract with new payment method", %{
    customer_id: customer_id,
    contract_id: contract_id,
    payment_method_receipt: payment_method_receipt,
    currency: currency
  } do
    dibs_redirect_data = %{
      itemDescription: "REGISTER_CARD",
      amount: "1.00",
      payment_method: "cc.test",
      billing_city: "Stockholm"
    }

    assert {:ok, %{"transactionId" => transaction_id}} =
             Singula.customer_redirect_dibs(customer_id, currency, dibs_redirect_data)

    dibs_payment_method = %Singula.PaymentMethodProvider.Dibs{
      dibs_ccPart: "**** **** **** 0000",
      dibs_ccPrefix: "457110",
      dibs_ccType: "Visa",
      dibs_expM: "12",
      dibs_expY: "21",
      receipt: payment_method_receipt,
      transactionId: transaction_id
    }

    {:ok, payment_method_id} = Singula.add_payment_method(customer_id, currency, dibs_payment_method)

    :ok = Singula.update_payment_method(customer_id, contract_id, payment_method_id)

    {:ok, contract_detail} = Singula.customer_contract(customer_id, contract_id)

    assert contract_detail.payment_method_id == payment_method_id
  end

  defp setup_test_customer(_context) do
    unix_time_now = DateTime.to_unix(DateTime.utc_now())
    user_id = "smoke_test_#{unix_time_now}"
    external_id = to_string(unix_time_now)
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
    {:ok, contracts} = Singula.customer_contracts(customer_id)

    Enum.each(contracts, fn %{contract_id: contract_id} ->
      # BUG: Inconsistent behavior calling cancel-endpoint. Will succeed most of the times,
      # but sometimes returns error code 90006 ("Failed to cancel contract").
      # A re-run will succeed...
      cancel_date = Date.utc_today()
      {:ok, ^cancel_date} = Singula.cancel_contract(customer_id, contract_id, to_string(cancel_date))

      Logger.info("Deleted contract #{contract_id} for test user: #{customer_id}")
    end)

    :ok = Singula.anonymise_customer(customer_id)
    Logger.info("Deleted smoke test user: #{customer_id}")
  end

  defp create_test_customer(external_id, user_id, email) do
    customer = %Singula.Customer{
      external_unique_id: external_id,
      username: user_id,
      password: "Smoke123",
      email: email,
      last_name: "TV4 Media SmokeTest",
      addresses: [%Singula.Address{post_code: "12220"}],
      custom_attributes: [
        %{name: "accepted_play_terms_date", value: "2020-02-25"},
        %{name: "accepted_play_terms", value: "Telia"}
      ]
    }

    {:ok, customer_id} = Singula.create_customer(customer)
    customer_id
  end

  defp setup_defaults(_context) do
    # The hard-coded values below should ideally created for the test-suite
    # by API calls. As documentation is lacking, we are using pre-configured
    # values from the integration environment until we can do better.

    [
      currency: :SEK,
      # C More TV4
      subscription_item_id: "6D3A56FF5065478ABD61",
      no_free_trial_item_id: "4151C241C3DD41529A87",
      # C More - IAP
      no_discount_item_id: "4905D3C22B7F4B55A4ED",
      ppv_item_id: "8F9AA56706904775AD7F",
      payment_method_receipt: 602_229_546,
      asset: %Singula.Asset{id: 12_345_678, title: "Sportsboll"}
    ]
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
