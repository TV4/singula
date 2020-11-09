defmodule Singula.FreeTrial do
  @enforce_keys [:number_of_days]
  defstruct [:number_of_days]

  @type t :: %__MODULE__{number_of_days: integer}

  def new(number_of_days) do
    %__MODULE__{number_of_days: number_of_days}
  end
end
