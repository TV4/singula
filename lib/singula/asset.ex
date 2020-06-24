defmodule Singula.Asset do
  @enforce_keys [:id, :title]
  defstruct [:id, :title]

  @type t :: %__MODULE__{id: integer, title: binary}
end
