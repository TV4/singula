defmodule Singula.Category do
  defstruct [:id, :name, categories: []]
  @type t :: %__MODULE__{}

  def new(payload) do
    categories = Map.get(payload, "categories", [])

    %__MODULE__{
      id: payload["categoryId"],
      name: payload["name"],
      categories: Enum.map(categories, fn category -> new(category) end)
    }
  end
end
