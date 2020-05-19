defmodule Paywizard.ContractDetailsTest do
  use ExUnit.Case, async: true
  alias Paywizard.ContractDetails

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
      "paidUpToDate" => "2020-04-22",
      "paymentMethodId" => 3_070_939,
      "startDate" => "2020-04-22",
      "status" => "ACTIVE"
    }

    assert ContractDetails.new(payload) == %Paywizard.ContractDetails{
             id: 9_622_082,
             item_name: "Field Sales - All Sport 12 plus 12",
             minimum_term: %{frequency: :MONTH, length: 24},
             balance: %{amount: "-399.00", currency: :SEK},
             recurring_billing: %{amount: "399.00", currency: :SEK, frequency: :MONTH, length: 24},
             status: :ACTIVE,
             start_date: ~D[2020-04-22],
             paid_up_to_date: ~D[2020-04-22]
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

    assert ContractDetails.new(payload) == %Paywizard.ContractDetails{
             id: 9_719_738,
             item_name: "C More TV4",
             balance: %{amount: "0.00", currency: :SEK},
             recurring_billing: %{amount: "139.00", currency: :SEK, frequency: :MONTH, length: 1},
             status: :ACTIVE,
             start_date: ~D[2020-04-20],
             paid_up_to_date: ~D[2020-05-04]
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

    assert ContractDetails.new(payload) == %Paywizard.ContractDetails{
             balance: %{amount: "0.00", currency: :SEK},
             id: 19844,
             item_name: "C More TV4",
             minimum_term: nil,
             paid_up_to_date: ~D[2020-06-02],
             recurring_billing: %{amount: "139.00", currency: :SEK, frequency: :MONTH, length: 1},
             start_date: ~D[2020-05-19],
             status: :ACTIVE
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

    assert ContractDetails.new(payload) == %Paywizard.ContractDetails{
             balance: %{amount: "0.00", currency: :SEK},
             id: 19846,
             item_name: "C More TV4",
             minimum_term: nil,
             paid_up_to_date: ~D[2020-05-19],
             recurring_billing: %{amount: "139.00", currency: :SEK, frequency: :MONTH, length: 1},
             start_date: ~D[2020-05-19],
             status: :ACTIVE
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

    assert ContractDetails.new(payload) == %Paywizard.ContractDetails{
             balance: %{amount: "-2189.00", currency: :SEK},
             id: 19848,
             item_name: "Field Sales - All Sport 12 plus 12 Apple TV full price",
             minimum_term: %{frequency: :MONTH, length: 24},
             paid_up_to_date: ~D[2020-05-19],
             recurring_billing: %{
               amount: "399.00",
               currency: :SEK,
               frequency: :MONTH,
               length: 1
             },
             start_date: ~D[2020-05-19],
             status: :ACTIVE
           }
  end
end
