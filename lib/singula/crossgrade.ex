defmodule Singula.Crossgrade do
  defstruct [:item_id, :currency]
  @type t :: %__MODULE__{item_id: binary, currency: :DKK | :NOK | :SEK}

  def new(%{"itemCode" => item_id, "changeCost" => %{"currency" => currency}}) do
    %__MODULE__{item_id: item_id, currency: String.to_atom(currency)}
  end
end
