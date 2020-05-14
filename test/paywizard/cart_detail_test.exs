defmodule Paywizard.CartDetailTest do
  use ExUnit.Case, async: true
  alias Paywizard.CartDetail

  describe "parse cart containing" do
    test "ppv" do
      payload = %{
        "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
        "id" => 121_385,
        "items" => [
          %{
            "cost" => %{"amount" => "249.00", "currency" => "SEK"},
            "itemCode" => "A2D895F14D6B4F2DA03C",
            "itemData" => %{
              "id" => 10_255_800,
              "name" => "Rögle BK - Växjö Lakers HC"
            },
            "itemName" => "PPV - 249",
            "quantity" => 1
          }
        ],
        "totalCost" => %{"amount" => "249.00", "currency" => "SEK"}
      }

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_385,
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   asset: %Paywizard.Asset{id: 10_255_800, title: "Rögle BK - Växjö Lakers HC"},
                   cost: "249.00",
                   item_id: "A2D895F14D6B4F2DA03C",
                   item_name: "PPV - 249",
                   quantity: 1
                 }
               ],
               total_cost: "249.00"
             }
    end

    test "subscription without free trial" do
      payload = %{
        "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
        "id" => 121_357,
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

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_357,
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "449.00",
                   item_id: "4151C241C3DD41529A87",
                   item_name: "C More All Sport",
                   quantity: 1
                 }
               ],
               total_cost: "449.00"
             }
    end

    test "subscription with free trial" do
      payload = %{
        "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
        "id" => 121_357,
        "items" => [
          %{
            "cost" => %{"amount" => "0.00", "currency" => "SEK"},
            "freeTrial" => %{
              "applied" => true,
              "firstPaymentAmount" => %{
                "amount" => "139.00",
                "currency" => "SEK"
              },
              "numberOfDays" => 14,
              "firstPaymentDate" => "2020-02-02T00:00:00+02:00"
            },
            "itemCode" => "6D3A56FF5065478ABD61",
            "itemData" => "",
            "itemName" => "C More TV4",
            "quantity" => 1
          }
        ],
        "totalCost" => %{"amount" => "0.00", "currency" => "SEK"}
      }

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_357,
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "0.00",
                   item_id: "6D3A56FF5065478ABD61",
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Paywizard.CartDetail.Item.Trial{
                     first_payment_date: ~D[2020-02-02],
                     free_trial: true,
                     first_payment_amount: "139.00"
                   }
                 }
               ],
               total_cost: "0.00"
             }
    end

    test "subscription with used free trial" do
      payload = %{
        "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
        "id" => 121_418,
        "items" => [
          %{
            "cost" => %{"amount" => "139.00", "currency" => "SEK"},
            "freeTrial" => %{
              "applied" => false,
              "reason" => "Customer is not eligible for free trial"
            },
            "itemCode" => "6D3A56FF5065478ABD61",
            "itemData" => "",
            "itemName" => "C More TV4",
            "quantity" => 1
          }
        ],
        "totalCost" => %{"amount" => "139.00", "currency" => "SEK"}
      }

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_418,
               currency: :SEK,
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "139.00",
                   item_id: "6D3A56FF5065478ABD61",
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Paywizard.CartDetail.Item.Trial{free_trial: false}
                 }
               ],
               total_cost: "139.00"
             }
    end

    test "subscription with expiring discount" do
      payload = %{
        "discount" => %{
          "discountAmount" => %{"amount" => "50.00", "currency" => "SEK"},
          "discountName" => "Field Sales - 50 SEK off 24 months",
          "indefinite" => false,
          "itemCode" => "95AC5A5C31A64F76B323",
          "numberOfOccurrences" => 24
        },
        "discountCode" => %{"campaignCode" => "NONE", "promoCode" => "NONE", "sourceCode" => "NONE"},
        "id" => 121_435,
        "items" => [
          %{
            "cost" => %{"amount" => "449.00", "currency" => "SEK"},
            "itemCode" => "95AC5A5C31A64F76B323",
            "itemData" => %{"referrerId" => "A003_FS"},
            "itemName" => "Field Sales - All Sport 24",
            "quantity" => 1
          }
        ],
        "totalCost" => %{"amount" => "399.00", "currency" => "SEK"}
      }

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_435,
               discount: %Paywizard.CartDetail.Discount{
                 discount_end_date: ~D[2022-02-02],
                 discount_amount: "50.00"
               },
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "449.00",
                   item_id: "95AC5A5C31A64F76B323",
                   item_name: "Field Sales - All Sport 24",
                   quantity: 1
                 }
               ],
               currency: :SEK,
               total_cost: "399.00"
             }
    end

    test "subscription with trial and indefinite discount" do
      payload = %{
        "discount" => %{
          "discountAmount" => %{"amount" => "69.50", "currency" => "SEK"},
          "discountCode" => %{
            "campaignCode" => "TESTWITHCAMPAIGN",
            "promoCode" => "PROMO1",
            "sourceCode" => "TESTWITHSOURCE"
          },
          "discountName" => "TestGatedDiscount50%Off",
          "indefinite" => true,
          "itemCode" => "6D3A56FF5065478ABD61"
        },
        "discountCode" => %{
          "campaignCode" => "TESTWITHCAMPAIGN",
          "promoCode" => "PROMO1",
          "sourceCode" => "TESTWITHSOURCE"
        },
        "id" => 121_448,
        "items" => [
          %{
            "cost" => %{"amount" => "0.00", "currency" => "SEK"},
            "freeTrial" => %{
              "applied" => true,
              "firstPaymentAmount" => %{"amount" => "69.50", "currency" => "SEK"},
              "firstPaymentDate" => "2020-05-27T00:00:00+02:00",
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

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_448,
               discount: %Paywizard.CartDetail.Discount{
                 discount_end_date: nil,
                 discount_amount: "69.50"
               },
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "0.00",
                   item_id: "6D3A56FF5065478ABD61",
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Paywizard.CartDetail.Item.Trial{
                     first_payment_amount: "69.50",
                     first_payment_date: ~D[2020-05-27],
                     free_trial: true
                   }
                 }
               ],
               currency: :SEK,
               total_cost: "0.00"
             }
    end

    test "subscription with trial and expiring discount" do
      payload = %{
        "discount" => %{
          "discountAmount" => %{"amount" => "69.50", "currency" => "SEK"},
          "discountCode" => %{
            "campaignCode" => "TESTWITHCAMPAIGN",
            "promoCode" => "PROMO1",
            "sourceCode" => "TESTWITHSOURCE"
          },
          "discountName" => "TestGatedDiscount50%Off",
          "indefinite" => false,
          "itemCode" => "6D3A56FF5065478ABD61",
          "numberOfOccurrences" => 24
        },
        "discountCode" => %{
          "campaignCode" => "TESTWITHCAMPAIGN",
          "promoCode" => "PROMO1",
          "sourceCode" => "TESTWITHSOURCE"
        },
        "id" => 121_448,
        "items" => [
          %{
            "cost" => %{"amount" => "0.00", "currency" => "SEK"},
            "freeTrial" => %{
              "applied" => true,
              "firstPaymentAmount" => %{"amount" => "69.50", "currency" => "SEK"},
              "firstPaymentDate" => "2020-05-27T00:00:00+02:00",
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

      assert CartDetail.new(payload) == %Paywizard.CartDetail{
               id: 121_448,
               discount: %Paywizard.CartDetail.Discount{
                 discount_end_date: ~D[2022-02-02],
                 discount_amount: "69.50"
               },
               items: [
                 %Paywizard.CartDetail.Item{
                   cost: "0.00",
                   item_id: "6D3A56FF5065478ABD61",
                   item_name: "C More TV4",
                   quantity: 1,
                   trial: %Paywizard.CartDetail.Item.Trial{
                     first_payment_amount: "69.50",
                     first_payment_date: ~D[2020-05-27],
                     free_trial: true
                   }
                 }
               ],
               currency: :SEK,
               total_cost: "0.00"
             }
    end
  end
end
