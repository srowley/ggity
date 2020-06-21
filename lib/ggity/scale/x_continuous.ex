defmodule GGity.Scale.X.Continuous do
  @moduledoc false

  alias GGity.Scale.X

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

  @spec new(list(record()), keyword()) :: X.Continuous.t()
  def new(values, options \\ []) do
    scale = struct(X.Continuous, options)
    struct(scale, transformations(scale, values))
  end

  # Many parts of this library are influenced by ContEx, but this part (which is itself copied
  # in GGity.Scale.Y.Continuous) is more or less flat-out copied - license acknowledgement below:

  # Copyright (c) 2020 John Jessop (mindOk)

  # Permission is hereby granted, free of charge, to any person obtaining a copy
  # of this software and associated documentation files (the "Software"), to deal
  # in the Software without restriction, including without limitation the rights
  # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to whom the Software is
  # furnished to do so, subject to the following conditions:

  # The above copyright notice and this permission notice shall be included in all
  # copies or substantial portions of the Software.

  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  # SOFTWARE.

  defp transformations(%X.Continuous{} = scale, values) do
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
