defmodule Paywizard.MetaData do
  defstruct [:asset, :referrer, :discount]

  @type t :: %__MODULE__{
          asset: Paywizard.Asset.t() | nil,
          referrer: binary | nil,
          discount: Paywizard.Discount.t() | nil
        }
end
