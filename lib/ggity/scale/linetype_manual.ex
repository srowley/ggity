defmodule GGity.Scale.Linetype.Manual do
  @moduledoc false

  alias GGity.Scale.Linetype

  @default_linetype :solid
  @linetype_specs %{
    solid: "",
    dashed: "4",
    dotted: "1",
    longdash: "6 2",
    dotdash: "1 2 3 2",
    twodash: "2 2 6 2"
  }
  @valid_linetypes Map.keys(@linetype_specs)

  @type t() :: %__MODULE__{}

  defstruct transform: nil,
            levels: nil

  @spec new(atom()) :: Linetype.Manual.t()
  def new(value \\ @default_linetype) when value in @valid_linetypes do
    value = get_specs(value)
    struct(Linetype.Manual, levels: [value], transform: fn _value -> value end)
  end

  defp get_specs(value) do
    @linetype_specs[value] || ""
  end
end
