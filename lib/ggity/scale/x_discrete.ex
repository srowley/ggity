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
            values: nil,
            inverse: nil,
            transform: nil

  @spec new(list(record()), keyword()) :: X.Discrete.t()
  # def new(values, options \\ [])

  def new(values, options \\ []) do
    levels =
      values
      |> Enum.sort()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.uniq()

    scale = struct(X.Discrete, [{:levels, levels}, {:values, values} | options])
    struct(scale, transformations(scale))
  end

  defp transformations(scale) do
    number_of_levels = length(scale.levels)

    values_map =
      scale.levels
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, index / (number_of_levels - 1) * scale.width}
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
