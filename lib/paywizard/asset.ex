defmodule Paywizard.Asset do
  @enforce_keys [:id, :title]
  defstruct [:id, :title]

  @type t :: %__MODULE__{}
end
