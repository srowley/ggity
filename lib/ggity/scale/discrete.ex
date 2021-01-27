defmodule GGity.Scale.Discrete do
  @moduledoc false

  @doc false
  @spec transform(list(), {number(), number()}) :: (binary() -> binary())
  def transform([_single_level], {palette_min, palette_max}) do
    fn _value -> palette_min + (palette_max - palette_min) / 2 end
  end

  @doc false
  def transform(levels, {palette_min, palette_max}) do
    interval = (palette_max - palette_min) / (length(levels) - 1)

    levels_map =
      levels
      |> Enum.with_index()
      |> Enum.map(fn {level, index} -> {level, palette_min + index * interval} end)
      |> Map.new()

    fn value -> levels_map[to_string(value)] end
  end

  @doc false
  @spec transform(list(), list()) :: (binary() -> binary())
  def transform(levels, palette) when is_list(levels) and is_list(palette) do
    levels_map =
      palette
      |> Stream.cycle()
      |> Enum.take(length(levels))
      |> Enum.zip(levels)
      |> Enum.map(fn {aesthetic, value} -> {value, aesthetic} end)
      |> Map.new()

    fn value -> levels_map[to_string(value)] end
  end
end
