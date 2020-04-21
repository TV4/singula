defmodule Paywizard.ClientTest do
  use ExUnit.Case
  import Hammox

  alias Paywizard.{Asset, CartDetail, Client, Customer, DibsPaymentMethod}

  setup :verify_on_exit!

  test "customer fetch" do
    MockPaywizardHTTPClient
    |> expect(:get, fn "/apis/customers/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0" ->
      {:ok,
       %HTTPoison.Response{
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
             "customAttributes" => [
               %{"name" => "accepted_cmore_terms", "value" => "2018-09-25"}
             ],
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
                external_unique_id: 100_471_887,
                first_name: "Paywizard_purchase_test2@cmore.se",
                last_name: "Paywizard_purchase_test2@cmore.se",
                username: "paywizard_purchase_test2@cmore.se"
              }}
  end

  describe "create cart" do
    test "without meta data" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{}}]}

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "rel" => "Get cart details",
               "href" => "/customer/customer_id/cart/10000",
               "type" => "application/json"
             }
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item("customer_id", "item_id", "currency") == {:ok, "10000"}
    end

    test "with asset" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{id: "654321", name: "Sportsboll"}}]
               }

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "rel" => "Get cart details",
               "href" => "/customer/customer_id/cart/10000",
               "type" => "application/json"
             }
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item(
               "customer_id",
               "item_id",
               "currency",
               %Paywizard.MetaData{
                 asset: %Paywizard.Asset{id: "654321", title: "Sportsboll"}
               }
             ) == {:ok, "10000"}
    end

    test "with referrer" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{items: [%{itemCode: "item_id", itemData: %{referrerId: "A003_FS"}}]}

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "rel" => "Get cart details",
               "href" => "/customer/customer_id/cart/10000",
               "type" => "application/json"
             }
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item(
               "customer_id",
               "item_id",
               "currency",
               %Paywizard.MetaData{referrer: "A003_FS"}
             ) ==
               {:ok, "10000"}
    end

    test "with discount" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{
                   discountId: "10097",
                   promoCode: "NONE",
                   campaignCode: "NONE",
                   sourceCode: "NONE"
                 }
               }

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "rel" => "Get cart details",
               "href" => "/customer/customer_id/cart/10000",
               "type" => "application/json"
             }
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item(
               "customer_id",
               "item_id",
               "currency",
               %Paywizard.MetaData{
                 discount: %Paywizard.Discount{discount: "10097"}
               }
             ) == {:ok, "10000"}
    end

    test "with voucher discount" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{
                   promoCode: "HELLO",
                   campaignCode: "NETONNET",
                   sourceCode: "PARTNER"
                 }
               }

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "rel" => "Get cart details",
               "href" => "/customer/customer_id/cart/10000",
               "type" => "application/json"
             }
             |> Jason.encode!(),
           status_code: 201
         }}
      end)

      assert Client.create_cart_with_item(
               "customer_id",
               "item_id",
               "currency",
               %Paywizard.MetaData{
                 discount: %Paywizard.Discount{
                   promotion: "HELLO",
                   campaign: "NETONNET",
                   source: "PARTNER"
                 }
               }
             ) ==
               {:ok, "10000"}
    end

    test "discount not found" do
      MockPaywizardHTTPClient
      |> expect(:post, fn "/apis/purchases/v1/customer/customer_id/cart/currency/currency",
                          data ->
        assert data == %{
                 items: [%{itemCode: "item_id", itemData: %{}}],
                 discountCode: %{
                   discountId: "10097",
                   promoCode: "NONE",
                   campaignCode: "NONE",
                   sourceCode: "NONE"
                 }
               }

        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "developerMessage" => "Discount criteria not matched",
               "moreInfo" =>
                 "Documentation on this failure can be found in SwaggerHub (https://swagger.io/tools/swaggerhub/)",
               "userMessage" => "Discount criteria not matched"
             }
             |> Jason.encode!(),
           request: %HTTPoison.Request{
             url:
               "https://bbr-paywizard-proxy.b17g-stage.net/apis/purchases/v1/customer/35cae6c1-384a-4070-ae4f-79e198a25fef/cart/currency/SEK"
           },
           status_code: 400
         }}
      end)

      assert Client.create_cart_with_item(
               "customer_id",
               "item_id",
               "currency",
               %Paywizard.MetaData{
                 discount: %Paywizard.Discount{discount: "10097"}
               }
             ) == {:paywizard_error, :discount_not_found}
    end
  end

  test "create dibs redirect" do
    MockPaywizardHTTPClient
    |> expect(
      :post,
      fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/redirect",
         data ->
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
         %HTTPoison.Response{
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
      end
    )

    assert Client.customer_redirect_dibs("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK) ==
             {:ok,
              %{
                "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b",
                "redirectURL" =>
                  "<form action=\"https://securedt.dibspayment.com/verify/bin/cmoretest/index\" method = \"POST\"><input type=\"hidden\" name=\"referenceNo\" value=\"mrngn-fiX9MEbB4S0-27674\"/><input type=\"text\" name=\"billingAddress\" value=\"Address Line 1\"/><input type=\"text\" name=\"billingCity\" value=\"Stockholm\"/><input type=\"text\" name=\"billingCountry\" value=\"SE\"/><input type=\"text\" name=\"billingFirstName\" value=\"Forename\"/><input type=\"text\" name=\"billingLastName\" value=\"TV4 Media SmokeTest\"/><input type=\"text\" name=\"currency\" value=\"SEK\"/><input type=\"text\" name=\"data\" value=\"1:REGISTER_CARD:1:100:\"/><input type=\"text\" name=\"eMail\" value=\"user@host.com\"/><input type=\"text\" name=\"MAC\" value=\"D18242FF449D6A674622392AE34256F291B43ED6\"/><input type=\"text\" name=\"pageSet\" value=\"cmore-payment-window-2-0\"/><input type=\"text\" name=\"customReturnUrl\" value=\"https://www.google.se\"/><input type=\"text\" name=\"method\" value=\"cc.test\"/><input type=\"text\" name=\"authOnly\" value=\"true\"/><button type=\"submit\">Submit</button></form>",
                "transactionId" => "mrngn-fiX9MEbB4S0",
                "type" => "redirect"
              }}
  end

  test "create klarna redirect" do
    MockPaywizardHTTPClient
    |> expect(
      :post,
      fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/redirect",
         data ->
        assert data == %{
                 "currencyCode" => :SEK,
                 "data" => [
                   %{key: :amount, value: "1.00"},
                   %{key: :authorisation, value: false},
                   %{key: :countryCode, value: "SE"},
                   %{key: :currency, value: :SEK},
                   %{key: :duration, value: 12},
                   %{key: :itemDescription, value: "REGISTER_CARD"},
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
         %HTTPoison.Response{
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
      end
    )

    assert Client.customer_redirect_klarna("ff160270-5197-4c90-835c-cd1fff8b19d0", :SEK) ==
             {:ok,
              %{
                "type" => "klarnaSession",
                "transactionId" => "2m56mfCGyV7VWh96k",
                "sessionId" => "22aa3f2a-ca55-19a6-8790-540a527fc877",
                "clientToken" => "eyJhbGciOiJSUzI1NiIs",
                "digest" => "ec2198bbf344e08d14e931c5e06e8bc21a4ce8f947959e072b1f9ac75af1833b"
              }}
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
      |> expect(
        :post,
        fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
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

          {:ok,
           %HTTPoison.Response{
             body: Jason.encode!(%{paymentMethodId: 26574}),
             status_code: 200
           }}
        end
      )

      assert Client.customer_payment_method(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               :SEK,
               dibs_payment_method
             ) ==
               {:ok, 26574}
    end

    test "transaction not found", %{dibs_payment_method: dibs_payment_method} do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
           _payment_method_data ->
          {:ok,
           %HTTPoison.Response{
             body:
               %{
                 "developerMessage" => "Token not generated",
                 "errorCode" => 90047,
                 "moreInfo" => "http://apis.paywizard.com/rest/errors.html#90047",
                 "userMessage" => "Payment method creation failure"
               }
               |> Jason.encode!(),
             status_code: 400
           }}
        end
      )

      assert Client.customer_payment_method(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               :SEK,
               dibs_payment_method
             ) ==
               {:paywizard_error, :transaction_not_found}
    end

    test "receipt not found", %{dibs_payment_method: dibs_payment_method} do
      %{
        "errorCode" => 90054,
        "userMessage" => "Payment provider cannot complete transaction",
        "developerMessage" => "Authorisation failed",
        "moreInfo" => "http://apis.paywizard.com/rest/errors.html#90054"
      }

      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/payment-methods/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/paymentmethod",
           _payment_method_data ->
          {:ok,
           %HTTPoison.Response{
             body:
               %{
                 "errorCode" => 90054,
                 "userMessage" => "Payment provider cannot complete transaction",
                 "developerMessage" => "Authorisation failed",
                 "moreInfo" => "http://apis.paywizard.com/rest/errors.html#90054"
               }
               |> Jason.encode!(),
             status_code: 400
           }}
        end
      )

      assert Client.customer_payment_method(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               :SEK,
               dibs_payment_method
             ) ==
               {:paywizard_error, :receipt_not_found}
    end
  end

  describe "add klarna payment method to customer" do
    test "on success" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/payment-methods/v1/customer/4ad58d9d-8976-47c0-af2c-35debf38d0eb/paymentmethod",
           data ->
          assert data == %{
                   "currencyCode" => :SEK,
                   "data" => [
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

          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: %{"paymentMethodId" => 654_321} |> Jason.encode!()
           }}
        end
      )

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

      assert Paywizard.Client.customer_payment_method(
               "4ad58d9d-8976-47c0-af2c-35debf38d0eb",
               :SEK,
               payment_method
             ) ==
               {:ok, 654_321}
    end
  end

  describe "checkout cart" do
    test "success for subscription that supports free trial" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
           %{"paymentMethodId" => 26574} ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               %{
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
        end
      )

      assert Client.customer_cart_checkout(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "118114",
               26574
             ) ==
               {:ok,
                %CartDetail{
                  currency: :SEK,
                  total_cost: "0.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "6D3A56FF5065478ABD61",
                      cost: "0.00",
                      eligible_for_free_trial: true,
                      item_name: "C More TV4",
                      quantity: 1
                    }
                  ]
                }}
    end

    test "success for subscription that don't support free trial" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
           %{"paymentMethodId" => 26574} ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               %{
                 "discountCode" => %{
                   "campaignCode" => "NONE",
                   "promoCode" => "NONE",
                   "sourceCode" => "NONE"
                 },
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
        end
      )

      assert Client.customer_cart_checkout(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "118114",
               26574
             ) ==
               {:ok,
                %CartDetail{
                  currency: :SEK,
                  total_cost: "449.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "4151C241C3DD41529A87",
                      cost: "449.00",
                      eligible_for_free_trial: nil,
                      item_name: "C More All Sport",
                      quantity: 1
                    }
                  ]
                }}
    end

    test "success for PPV" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
           %{"paymentMethodId" => 26574} ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               %{
                 "items" => [
                   %{
                     "cost" => %{"amount" => "149.00", "currency" => "SEK"},
                     "itemCode" => "A2D895F14D6B4F2DA03C",
                     "itemData" => %{
                       "id" => 10_255_800,
                       "name" => "Rögle BK - Växjö Lakers HC"
                     },
                     "itemName" => "PPV - 249",
                     "quantity" => 1
                   }
                 ],
                 "totalCost" => %{"amount" => "149.00", "currency" => "SEK"}
               }
               |> Jason.encode!()
           }}
        end
      )

      assert Client.customer_cart_checkout(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "118114",
               26574
             ) ==
               {:ok,
                %CartDetail{
                  currency: :SEK,
                  total_cost: "149.00",
                  items: [
                    %CartDetail.Item{
                      item_id: "A2D895F14D6B4F2DA03C",
                      item_name: "PPV - 249",
                      eligible_for_free_trial: nil,
                      cost: "149.00",
                      quantity: 1,
                      asset: %Asset{id: 10_255_800, title: "Rögle BK - Växjö Lakers HC"}
                    }
                  ]
                }}
    end

    test "cart not found" do
      MockPaywizardHTTPClient
      |> expect(
        :post,
        fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/cart/118114/checkout",
           %{"paymentMethodId" => 26574} ->
          {:ok,
           %HTTPoison.Response{
             status_code: 404,
             body:
               %{
                 errorCode: 90040,
                 userMessage: "Cart ID provided is incorrect or does not exist",
                 developerMessage: "No cart found with given ID",
                 moreInfo: "http://apis.paywizard.com/rest/errors.html#90040"
               }
               |> Jason.encode!()
           }}
        end
      )

      assert Client.customer_cart_checkout(
               "ff160270-5197-4c90-835c-cd1fff8b19d0",
               "118114",
               26574
             ) ==
               {:paywizard_error, :cart_not_found}
    end
  end

  test "entitlements" do
    MockPaywizardHTTPClient
    |> expect(:get, fn "/apis/catalogue/v1/item/6D3A56FF5065478ABD61?currency=SEK" ->
      {:ok,
       %HTTPoison.Response{
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

    assert Client.entitlements("6D3A56FF5065478ABD61", :SEK) == {:ok, [5960]}
  end

  test "get ppv purchases" do
    MockPaywizardHTTPClient
    |> expect(
      :post,
      fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/1",
         %{type: "PPV"} ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "currentPage" => 1,
               "items" => [
                 %{
                   "entitlements" => 5961,
                   "itemData" => %{"id" => 1, "name" => 1},
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
      end
    )
    |> expect(
      :post,
      fn "/apis/purchases/v1/customer/ff160270-5197-4c90-835c-cd1fff8b19d0/purchases/2",
         %{type: "PPV"} ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "currentPage" => 2,
               "items" => [
                 %{
                   "entitlements" => 5961,
                   "itemData" => %{"id" => 2, "name" => 2},
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
      end
    )

    assert Client.customer_purchases_ppv("ff160270-5197-4c90-835c-cd1fff8b19d0") ==
             {:ok,
              [
                %Paywizard.PPV{asset_id: "1", item_id: "A2D895F14D6B4F2DA03C"},
                %Paywizard.PPV{asset_id: "2", item_id: "A2D895F14D6B4F2DA03C"}
              ]}
  end
end
