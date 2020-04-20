defmodule Paywizard.PPV do
  defstruct [:item_id, :asset_id]

  @type t :: %__MODULE__{item_id: binary, asset_id: binary}

  def new(items) do
    items
    |> Enum.map(fn ppv_item ->
      %__MODULE__{
        item_id: ppv_item["salesItemCode"],
        asset_id: ppv_item["itemData"]["id"] |> to_string
      }
    end)
  end
end
