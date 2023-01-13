defmodule GGity.Scale.Discrete do
  @moduledoc false

  @doc false
  @spec transform(list(), list()) :: (binary() -> binary())
  def transform(levels, palette) when is_list(levels) and is_list(palette) do
    levels_map =
      palette
      |> Enum.zip(levels)
      |> Map.new(fn {aesthetic, value} -> {value, aesthetic} end)

    fn value -> levels_map[to_string(value)] end
  end
end
