defmodule GGity.Scale.X.DateTime do
  @moduledoc false

  alias GGity.Scale.X

  @type t() :: %__MODULE__{}
  @type record() :: map()

  defstruct width: 200,
            breaks: 5,
            x_label: :na,
            y_label: :na,
            date_labels: :waivers,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            values: nil,
            transform: nil

  @spec new(list(record()), keyword()) :: X.DateTime.t()
  def new(values, options \\ []) do
    scale = struct(X.DateTime, options)
    struct(scale, transformations(scale, values))
  end

  defp transformations(%X.DateTime{} = scale, values) do
    {min, max} = min_max(values)
    range = diff(max, min)
    interval_size = round(range / (scale.breaks - 1))
    interval_count = round(1.0001 * range / interval_size)

    tick_values =
      Enum.map(
        1..(interval_count + 1),
        &add(min, (&1 - 1) * interval_size)
      )

    [
      tick_values: tick_values,
      inverse: fn value ->
        floor(diff(value, min) / diff(max, min) * scale.width)
      end,
      values: values,
      transform: fn value ->
        diff(value, min) / diff(max, min) * scale.width
      end
    ]
  end

  defp diff(%date_type_1{} = first, %date_type_2{} = second, unit \\ :microsecond)
       when date_type_1 in [DateTime, NaiveDateTime] and date_type_1 == date_type_2 do
    apply(date_type_1, :diff, [first, second, unit])
  end

  defp add(%date_type{} = first, time_quantity, unit \\ :microsecond)
       when date_type in [DateTime, NaiveDateTime] do
    apply(date_type, :add, [first, time_quantity, unit])
  end

  defp min_max([]), do: raise(Enum.EmptyError)

  defp min_max([single_value]), do: {single_value, single_value}

  defp min_max([%date_type{} | _rest] = dates) when date_type in [DateTime, NaiveDateTime] do
    {Enum.min_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end),
     Enum.max_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end)}
  end
end
