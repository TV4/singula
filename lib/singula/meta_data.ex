defmodule Singula.MetaData do
  defstruct [:asset, :referrer, :discount]

  @type t :: %__MODULE__{
          asset: Singula.Asset.t() | nil,
          referrer: binary | nil,
          discount: Singula.Discount.t() | nil
        }
end
