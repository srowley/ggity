defmodule GGity.Scale.X.DateTime do
  @moduledoc false

  alias GGity.Scale.X

  @type t() :: %__MODULE__{}
  @type datetime() :: %DateTime{} | %NaiveDateTime{}
  @type record() :: map()

  defstruct width: 200,
            breaks: 5,
            date_labels: :waivers,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            transform: nil

  @spec new(keyword()) :: X.DateTime.t()
  def new(options \\ []), do: struct(X.DateTime, options)

  @spec train(X.DateTime.t(), {datetime(), datetime()}) :: X.DateTime.t()
  def train(%X.DateTime{} = scale, {min, max}) do
    range = diff(max, min)
    interval_size = round(range / (scale.breaks - 1))
    interval_count = round(1.0001 * range / interval_size)

    tick_values =
      Enum.map(
        1..(interval_count + 1),
        &add(min, (&1 - 1) * interval_size)
      )

    struct(
      scale,
      tick_values: tick_values,
      inverse: fn value ->
        floor(diff(value, min) / diff(max, min) * scale.width)
      end,
      transform: fn value ->
        diff(value, min) / diff(max, min) * scale.width
      end
    )
  end

  defp diff(%date_type_1{} = first, %date_type_2{} = second, unit \\ :microsecond)
       when date_type_1 in [DateTime, NaiveDateTime] and date_type_1 == date_type_2 do
    apply(date_type_1, :diff, [first, second, unit])
  end

  defp add(%date_type{} = first, time_quantity, unit \\ :microsecond)
       when date_type in [DateTime, NaiveDateTime] do
    apply(date_type, :add, [first, time_quantity, unit])
  end
end
