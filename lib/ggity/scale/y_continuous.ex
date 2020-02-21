defmodule GGity.Scale.Y.Continuous do
  @moduledoc false

  alias GGity.Scale.Y

  @base_axis_intervals [0.1, 0.2, 0.25, 0.4, 0.5, 0.75, 1.0, 2.0, 2.5, 4.0, 5.0, 7.5, 10]

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct width: 200,
            breaks: 5,
            x_label: :na,
            y_label: :na,
            tick_values: nil,
            inverse: nil,
            values: nil,
            transform: nil

  @spec new(list(record()), keyword()) :: Y.Continuous.t()
  def new(values, options \\ []) do
    scale = struct(Y.Continuous, options)
    struct(scale, transformations(scale, values))
  end

  defp transformations(%Y.Continuous{} = scale, values) do
    {min, max} = Enum.min_max(values)
    range = max - min
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
      inverse: fn value ->
        floor((value - adjusted_min) / (adjusted_max - adjusted_min) * scale.width)
      end,
      values: values,
      transform: fn value ->
        floor((value - adjusted_min) / (adjusted_max - adjusted_min) * scale.width)
      end
    ]
  end

  defp axis_interval_lookup(value) do
    Enum.find(@base_axis_intervals, &(&1 >= value))
  end
end
