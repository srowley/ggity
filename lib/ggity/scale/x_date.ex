defmodule GGity.Scale.X.Date do
  @moduledoc false

  alias GGity.Scale.X

  @type t() :: %__MODULE__{}
  @type date() :: %Date{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct width: 200,
            breaks: 5,
            date_labels: :waivers,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            transform: nil

  @spec new(keyword()) :: X.Date.t()
  def new(options \\ []), do: struct(X.Date, options)

  @spec train(X.Date.t(), {date(), date()}) :: X.Date.t()
  def train(scale, {min, max}) do
    range = Date.diff(max, min)
    interval_size = round(range / (scale.breaks - 1))
    interval_count = round(1.0001 * range / interval_size)

    tick_values =
      Enum.map(
        1..(interval_count + 1),
        &Date.add(min, (&1 - 1) * interval_size)
      )

    struct(
      scale,
      tick_values: tick_values,
      inverse: fn value ->
        floor(Date.diff(value, min) / Date.diff(max, min) * scale.width)
      end,
      transform: fn value ->
        Date.diff(value, min) / Date.diff(max, min) * scale.width
      end
    )
  end
end
