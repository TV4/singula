defmodule Singula.Crossgrade do
  defstruct [:item_id, :currency, :change_type, :change_cost]

  @type t :: %__MODULE__{
          item_id: binary,
          currency: :DKK | :NOK | :SEK,
          change_type: :DOWNGRADE | :CROSSGRADE | :UPGRADE,
          change_cost: binary
        }

  def new(%{"itemCode" => item_id, "changeCost" => %{"currency" => currency, "amount" => amount}, "changeType" => change_type}) do
    %__MODULE__{item_id: item_id, currency: String.to_atom(currency), change_type: String.to_atom(change_type),
    change_cost: amount}
  end
end
