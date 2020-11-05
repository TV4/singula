defmodule Singula.Entitlement do
  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{id: integer, name: binary}

  def new(%{"id" => id, "name" => name}), do: %__MODULE__{id: id, name: name}
end
