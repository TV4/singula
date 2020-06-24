defmodule Singula.Discount do
  defstruct [:discount, is_single_use: false, promotion: "NONE", campaign: "NONE", source: "NONE"]

  @type t :: %__MODULE__{discount: binary | nil, promotion: binary, campaign: binary | nil, source: binary | nil}
end
