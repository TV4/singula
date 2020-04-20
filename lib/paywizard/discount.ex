defmodule Paywizard.Discount do
  defstruct [:discount, promotion: "NONE", campaign: "NONE", source: "NONE"]

  @type t :: %__MODULE__{}
end
