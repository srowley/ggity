defmodule GGity.Scale.Y.Continuous do
  @moduledoc false

  alias GGity.Scale.{Continuous, Y}

  @base_axis_intervals [0.1, 0.2, 0.25, 0.4, 0.5, 0.75, 1.0, 2.0, 2.5, 4.0, 5.0, 7.5, 10]

  @type t() :: %__MODULE__{}
  @type mapping() :: map()

  defstruct width: 200,
            breaks: 5,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            transform: nil

  @spec new(keyword()) :: Y.Continuous.t()
  def new(options \\ []), do: struct(Y.Continuous, options)

  @spec train(Y.Continuous.t(), {number(), number()}) :: Y.Continuous.t()
  def train(scale, {min, max}) do
    range = max - min
    struct(scale, transformations(range, min, max, scale))
  end

  defp transformations(0, min, _max, %Y.Continuous{} = scale) do
    [
      tick_values: [min],
      inverse: fn _value -> scale.width / 2 end,
      transform: fn _value -> scale.width / 2 end
    ]
  end

  defp transformations(range, min, max, %Y.Continuous{} = scale) do
    raw_interval_size = range / (scale.breaks - 1)
    order_of_magnitude = :math.ceil(:math.log10(raw_interval_size) - 1)
    power_of_ten = :math.pow(10, order_of_magnitude)
    adjusted_interval_size = axis_interval_lookup(raw_interval_size / power_of_ten) * power_of_ten
    adjusted_min = adjusted_interval_size * Float.floor(min / adjusted_interval_size)
    adjusted_max = adjusted_interval_size * Float.ceil(max / adjusted_interval_size)

    adjusted_interval_count =
      round(1.0001 * (adjusted_max - adjusted_min) / adjusted_interval_size)

    tick_values =
      Enum.map(
        1..(adjusted_interval_count + 1),
        &(adjusted_min + (&1 - 1) * adjusted_interval_size)
      )

    [
      tick_values: tick_values,
      inverse: Continuous.transform({adjusted_min, adjusted_max}, {0, scale.width}),
      transform: Continuous.transform({adjusted_min, adjusted_max}, {0, scale.width})
    ]
  end

  defp axis_interval_lookup(value) do
    Enum.find(@base_axis_intervals, &(&1 >= value))
  end
end
