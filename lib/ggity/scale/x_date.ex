defmodule GGity.Scale.X.Date do
  @moduledoc false

  alias GGity.Scale.X

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct width: 200,
            breaks: 5,
            x_label: :na,
            y_label: :na,
            date_labels: "",
            tick_values: nil,
            inverse: nil,
            values: nil,
            transform: nil

  @spec new(list(record()), keyword()) :: X.Date.t()
  def new(values, options \\ []) do
    scale = struct(X.Date, options)
    struct(scale, transformations(scale, values))
  end

  defp transformations(%X.Date{} = scale, values) do
    {min, max} = Enum.min_max(values)
    range = Date.diff(max, min)
    interval_size = round(range / (scale.breaks - 1))
    interval_count = round(1.0001 * range / interval_size)

    tick_values =
      Enum.map(
        1..(interval_count + 1),
        &Date.add(min, (&1 - 1) * interval_size)
      )

    [
      tick_values: tick_values,
      inverse: fn value ->
        floor(Date.diff(value, min) / Date.diff(max, min) * scale.width)
      end,
      values: values,
      transform: fn value ->
        Date.diff(value, min) / Date.diff(max, min) * scale.width
      end
    ]
  end
end
