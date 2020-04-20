defmodule Paywizard.MetaData do
  defstruct [:asset, :referrer, :discount]

  @type t :: %__MODULE__{}
end
