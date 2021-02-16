defmodule Singula.ContractDetailsTest do
  use ExUnit.Case, async: true
  alias Singula.ContractDetails

  test "parse minimum term" do
    payload = %{
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
      "orderId" => 112_707,
      "paidUpToDate" => "2020-04-22",
      "paymentMethodId" => 3_070_939,
      "startDate" => "2020-04-22",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             id: 9_622_082,
             order_id: 112_707,
             item_id: "4FC7D926073348038362",
             item_name: "Field Sales - All Sport 12 plus 12",
             minimum_term: %{frequency: :MONTH, length: 24},
             balance: %{amount: -399.00, currency: :SEK},
             recurring_billing: %{amount: 399.0, currency: :SEK, frequency: :MONTH, length: 24},
             status: :ACTIVE,
             start_date: ~D[2020-04-22],
             paid_up_to_date: ~D[2020-04-22],
             payment_method_id: 3_070_939
           }
  end

  test "parse without minimum term" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-04-20T10:01:48+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-04-20T10:01:48+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "139.00", "currency" => "SEK"}
      },
      "contractId" => 9_719_738,
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "name" => "C More TV4",
      "nextPaymentDate" => "2020-05-04",
      "paidUpToDate" => "2020-05-04",
      "paymentMethodId" => 10_246_312,
      "startDate" => "2020-04-20",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             id: 9_719_738,
             item_id: "6D3A56FF5065478ABD61",
             item_name: "C More TV4",
             balance: %{amount: 0.00, currency: :SEK},
             recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
             status: :ACTIVE,
             start_date: ~D[2020-04-20],
             paid_up_to_date: ~D[2020-05-04],
             payment_method_id: 10_246_312
           }
  end

  test "parse with free trial and expiring discount" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-05-19T10:42:10+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-05-19T10:42:10+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "139.00", "currency" => "SEK"},
        "upcoming" => %{"amount" => "0.00", "currency" => "SEK"}
      },
      "contractId" => 19844,
      "discount" => %{
        "discountAmount" => %{"amount" => "139.00", "currency" => "SEK"},
        "discountEndDate" => "2020-08-02",
        "discountName" => "3 occurrences 100% off",
        "discountPercentage" => 100,
        "indefinite" => false,
        "itemCode" => "6D3A56FF5065478ABD61",
        "numberOfOccurrences" => 3
      },
      "discountCode" => "",
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "name" => "C More TV4",
      "nextPaymentDate" => "2020-06-02",
      "orderId" => 112_863,
      "paidUpToDate" => "2020-06-02",
      "paymentMethodId" => 27541,
      "startDate" => "2020-05-19",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             id: 19844,
             order_id: 112_863,
             item_id: "6D3A56FF5065478ABD61",
             item_name: "C More TV4",
             status: :ACTIVE,
             balance: %{amount: 0.00, currency: :SEK},
             minimum_term: nil,
             paid_up_to_date: ~D[2020-06-02],
             recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 0.00, currency: :SEK, frequency: :MONTH, length: 1},
             discount: %{amount: 139.0, currency: :SEK, discount_end_date: ~D[2020-08-02]},
             start_date: ~D[2020-05-19],
             payment_method_id: 27541
           }
  end

  test "parse with used free trial and expiring discount" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-05-19T11:06:27+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-05-19T11:06:27+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "139.00", "currency" => "SEK"},
        "upcoming" => %{"amount" => "0.00", "currency" => "SEK"}
      },
      "contractId" => 19846,
      "discount" => %{
        "discountAmount" => %{"amount" => "139.00", "currency" => "SEK"},
        "discountEndDate" => "2020-07-19",
        "discountName" => "3 occurrences 100% off",
        "discountPercentage" => 100,
        "indefinite" => false,
        "itemCode" => "6D3A56FF5065478ABD61",
        "numberOfOccurrences" => 3
      },
      "discountCode" => "",
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "lastPaymentDate" => "2020-05-19",
      "name" => "C More TV4",
      "nextPaymentDate" => "2020-05-19",
      "orderId" => 112_865,
      "paidUpToDate" => "2020-05-19",
      "paymentMethodId" => 27543,
      "startDate" => "2020-05-19",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             balance: %{amount: 0.00, currency: :SEK},
             item_id: "6D3A56FF5065478ABD61",
             id: 19846,
             item_name: "C More TV4",
             minimum_term: nil,
             order_id: 112_865,
             paid_up_to_date: ~D[2020-05-19],
             recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 0.00, currency: :SEK, frequency: :MONTH, length: 1},
             discount: %{amount: 139.0, currency: :SEK, discount_end_date: ~D[2020-07-19]},
             start_date: ~D[2020-05-19],
             status: :ACTIVE,
             payment_method_id: 27543
           }
  end

  test "parse with initial cost and expiring discount" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-05-19T13:32:20+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-05-19T13:32:20+02:00"
      },
      "balance" => %{"amount" => "-2189.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "1990.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "399.00", "currency" => "SEK"},
        "upcoming" => %{"amount" => "0.00", "currency" => "SEK"}
      },
      "contractId" => 19848,
      "discount" => %{
        "discountAmount" => %{"amount" => "200.00", "currency" => "SEK"},
        "discountEndDate" => "2021-04-19",
        "discountName" => "Fields Sales - 200 SEK off for 12 months",
        "indefinite" => false,
        "itemCode" => "8FB4E247D57B40E09FA7",
        "numberOfOccurrences" => 12
      },
      "discountCode" => "",
      "entitlements" => [%{"id" => 5963, "name" => "C More All Sport"}],
      "itemCode" => "8FB4E247D57B40E09FA7",
      "lastPaymentDate" => "2020-05-19",
      "minimumTerm" => %{"frequency" => "MONTH", "length" => 24},
      "name" => "Field Sales - All Sport 12 plus 12 Apple TV full price",
      "nextPaymentDate" => "2020-05-19",
      "orderId" => 112_868,
      "paidUpToDate" => "2020-05-19",
      "paymentMethodId" => 27545,
      "startDate" => "2020-05-19",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             balance: %{amount: -2189.00, currency: :SEK},
             id: 19848,
             item_id: "8FB4E247D57B40E09FA7",
             item_name: "Field Sales - All Sport 12 plus 12 Apple TV full price",
             minimum_term: %{frequency: :MONTH, length: 24},
             order_id: 112_868,
             paid_up_to_date: ~D[2020-05-19],
             recurring_billing: %{amount: 399.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 0.00, currency: :SEK, frequency: :MONTH, length: 1},
             discount: %{amount: 200.00, currency: :SEK, discount_end_date: ~D[2021-04-19]},
             start_date: ~D[2020-05-19],
             status: :ACTIVE,
             payment_method_id: 27545
           }
  end

  test "parse with expiring discount" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-08-25T10:00:55+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-08-25T10:00:58+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "449.00", "currency" => "SEK"},
        "upcoming" => %{"amount" => "349.00", "currency" => "SEK"}
      },
      "contractId" => 20673,
      "discount" => %{
        "discountAmount" => %{"amount" => "100.00", "currency" => "SEK"},
        "discountEndDate" => "2021-07-25",
        "discountName" => "12 occurrences 100 SEK off",
        "indefinite" => false,
        "itemCode" => "C943A5FED47E444B96E1",
        "numberOfOccurrences" => 12
      },
      "discountCode" => "",
      "entitlements" => [%{"id" => 5963, "name" => "C More All Sport"}],
      "itemCode" => "C943A5FED47E444B96E1",
      "lastPaymentDate" => "2020-08-25",
      "minimumTerm" => %{"frequency" => "MONTH", "length" => 12},
      "name" => "C More All Sport - 12 months",
      "nextPaymentDate" => "2020-09-25",
      "orderId" => 113_983,
      "paidUpToDate" => "2020-09-25",
      "paymentMethodId" => 28390,
      "startDate" => "2020-08-25",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             balance: %{amount: 0.00, currency: :SEK},
             id: 20673,
             item_id: "C943A5FED47E444B96E1",
             item_name: "C More All Sport - 12 months",
             minimum_term: %{frequency: :MONTH, length: 12},
             order_id: 113_983,
             paid_up_to_date: ~D[2020-09-25],
             recurring_billing: %{amount: 449.00, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 349.00, currency: :SEK, frequency: :MONTH, length: 1},
             discount: %{amount: 100.0, currency: :SEK, discount_end_date: ~D[2021-07-25]},
             start_date: ~D[2020-08-25],
             status: :ACTIVE,
             payment_method_id: 28390
           }
  end

  test "parse with indefinite discount" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2021-02-16T15:44:19+01:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2021-02-16T15:44:19+01:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "139.00", "currency" => "SEK"},
        "upcoming" => %{"amount" => "69.50", "currency" => "SEK"}
      },
      "contractId" => 32783,
      "discount" => %{
        "discountAmount" => %{"amount" => "69.50", "currency" => "SEK"},
        "discountName" => "TestGatedDiscount50%Off",
        "discountPercentage" => 50,
        "indefinite" => true,
        "itemCode" => "6D3A56FF5065478ABD61"
      },
      "discountCode" => %{
        "campaignCode" => "TESTWITHCAMPAIGN",
        "promoCode" => "PROMO1",
        "sourceCode" => "TESTWITHSOURCE"
      },
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "name" => "C More TV4",
      "nextPaymentDate" => "2021-03-02",
      "orderId" => 129_986,
      "paidUpToDate" => "2021-03-02",
      "paymentMethodId" => 42752,
      "startDate" => "2021-02-16",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             balance: %{amount: 0.0, currency: :SEK},
             id: 32783,
             item_id: "6D3A56FF5065478ABD61",
             item_name: "C More TV4",
             order_id: 129_986,
             paid_up_to_date: ~D[2021-03-02],
             recurring_billing: %{amount: 139.0, currency: :SEK, frequency: :MONTH, length: 1},
             upcoming_billing: %{amount: 69.5, currency: :SEK, frequency: :MONTH, length: 1},
             discount: %{amount: 69.5, currency: :SEK, discount_end_date: nil},
             start_date: ~D[2021-02-16],
             status: :ACTIVE,
             payment_method_id: 42752
           }
  end

  test "parse scheduled contract change" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-04-20T10:01:48+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-04-20T10:01:48+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => "139.00", "currency" => "SEK"}
      },
      "changeDate" => "2020-05-04",
      "changeToItem" => "180B2AD9332349E6A7A4",
      "contractId" => 9_719_738,
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "name" => "C More TV4",
      "nextPaymentDate" => "2020-05-04",
      "paidUpToDate" => "2020-05-04",
      "paymentMethodId" => 10_246_312,
      "startDate" => "2020-04-20",
      "status" => "DOWNGRADE_SCHEDULED"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             id: 9_719_738,
             item_id: "6D3A56FF5065478ABD61",
             item_name: "C More TV4",
             balance: %{amount: 0.00, currency: :SEK},
             change_date: ~D[2020-05-04],
             change_to_item_id: "180B2AD9332349E6A7A4",
             recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
             status: :DOWNGRADE_SCHEDULED,
             start_date: ~D[2020-04-20],
             paid_up_to_date: ~D[2020-05-04],
             payment_method_id: 10_246_312
           }
  end

  test "parse with amount as float or string return float" do
    payload = %{
      "active" => true,
      "auditInfo" => %{
        "createdByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "creationDate" => "2020-04-20T10:01:48+02:00",
        "modifiedByUser" => "89d83946-b4b5-4a7b-a92d-7b999c62e8a0",
        "modifiedDate" => "2020-04-20T10:01:48+02:00"
      },
      "balance" => %{"amount" => "0.00", "currency" => "SEK"},
      "billing" => %{
        "frequency" => %{"frequency" => "MONTH", "length" => 1},
        "initial" => %{"amount" => "0.00", "currency" => "SEK"},
        "recurring" => %{"amount" => 139.00, "currency" => "SEK"}
      },
      "contractId" => 9_719_738,
      "entitlements" => [%{"id" => 5960, "name" => "C More TV4"}],
      "itemCode" => "6D3A56FF5065478ABD61",
      "name" => "C More TV4",
      "nextPaymentDate" => "2020-05-04",
      "paidUpToDate" => "2020-05-04",
      "paymentMethodId" => 10_246_312,
      "startDate" => "2020-04-20",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Singula.ContractDetails{
             id: 9_719_738,
             item_id: "6D3A56FF5065478ABD61",
             item_name: "C More TV4",
             balance: %{amount: 0.00, currency: :SEK},
             recurring_billing: %{amount: 139.00, currency: :SEK, frequency: :MONTH, length: 1},
             status: :ACTIVE,
             start_date: ~D[2020-04-20],
             paid_up_to_date: ~D[2020-05-04],
             payment_method_id: 10_246_312
           }
  end
end
