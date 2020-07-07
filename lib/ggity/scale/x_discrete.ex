defmodule GGity.Scale.X.Discrete do
  @moduledoc false

  alias GGity.Scale.X

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct width: 200,
            levels: nil,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            transform: nil

  @spec new(keyword()) :: X.Discrete.t()
  def new(options \\ []), do: struct(X.Discrete, options)

  @spec train(X.Discrete.t(), list()) :: X.Discrete.t()
  def train(scale, levels) do
    scale = struct(scale, levels: levels)
    struct(scale, transformations(scale))
  end

  defp transformations(scale) do
    number_of_levels = length(scale.levels)

    values_map =
      scale.levels
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, (2 * index + 1) * (scale.width / (2 * number_of_levels))}
      end)
      |> Enum.into(%{})

    transform = fn value -> values_map[to_string(value)] end

    [
      tick_values: scale.levels,
      inverse: transform,
      transform: transform
    ]
  end
end
