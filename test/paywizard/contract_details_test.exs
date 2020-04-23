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
             recurring_billing: %{amount: "399.00", currency: :SEK, frequency: :MONTH, length: 24},
             status: :ACTIVE,
             start_date: ~D[2020-04-22],
             minimum_term: %{frequency: :MONTH, length: 24}
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
             recurring_billing: %{amount: "139.00", currency: :SEK, frequency: :MONTH, length: 1},
             status: :ACTIVE,
             start_date: ~D[2020-04-20]
           }
  end
end
