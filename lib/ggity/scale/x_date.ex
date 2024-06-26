defmodule GGity.Scale.X.Date do
  @moduledoc false

  alias GGity.Scale.{Continuous, X}

  @duration_day 1
  @duration_month @duration_day * 30
  @duration_year @duration_day * 365

  @tick_intervals [
    {:days, 1, @duration_day},
    {:days, 2, @duration_day * 2},
    {:days, 5, @duration_day * 5},
    {:days, 10, @duration_day * 10},
    {:months, 1, @duration_month},
    {:months, 3, @duration_month * 3},
    {:months, 6, @duration_month * 6},
    {:years, 1, @duration_year},
    {:years, 5, @duration_year * 5},
    {:years, 10, @duration_year * 10},
    {:years, 15, @duration_year * 15}
  ]

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
  def train(scale, {min, max}) when min == max do
    struct(
      scale,
      tick_values: min,
      inverse: fn _value -> min end,
      transform: fn _value -> scale.width / 2 end
    )
  end

  def train(scale, {min, max}) do
    range = Date.diff(max, min)
    unrounded_interval_size = range / (scale.breaks - 1)
    tick_interval = pretty_interval_for(unrounded_interval_size)

    adjusted_min = round_down_to(min, tick_interval)

    {adjusted_max, adjusted_breaks} =
      calculate_end_interval(adjusted_min, max, tick_interval, scale.breaks)

    tick_values =
      Enum.map(0..adjusted_breaks, fn tick ->
        add_interval(adjusted_min, tick_interval, tick)
      end)

    struct(
      scale,
      tick_values: tick_values,
      inverse: Continuous.transform({adjusted_min, adjusted_max}, {0, scale.width}),
      transform: Continuous.transform({adjusted_min, adjusted_max}, {0, scale.width})
    )
  end

  # This part (except where ContEx copied from Timex as noted further below) is more or less copied
  # ContEx - license acknowledgement below:

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

  defp pretty_interval_for(initial_size) do
    default = List.last(@tick_intervals)
    Enum.find(@tick_intervals, default, &(elem(&1, 2) >= initial_size))
  end

  defp calculate_end_interval(start, target, tick_interval, max_steps) do
    Enum.reduce_while(1..max_steps, {start, 0}, fn step, {_current_end, _index} ->
      new_end = add_interval(start, tick_interval, step)

      if Date.compare(new_end, target) == :lt,
        do: {:cont, {new_end, step}},
        else: {:halt, {new_end, step}}
    end)
  end

  defp round_down_multiple(value, multiple), do: div(value, multiple) * multiple

  defp round_down_to(dt, {:days, 1, _multiple}), do: dt

  defp round_down_to(dt, {:days, n, _multiple}) do
    %{dt | day: round_down_multiple(dt.day, n) + 1}
  end

  defp round_down_to(dt, {:months, 1, _multiple}) do
    %{dt | day: 1}
  end

  defp round_down_to(dt, {:months, n, _multiple}), do: round_down_month(dt, n)

  defp round_down_to(dt, {:years, 1, _multiple}) do
    %{dt | day: 1, month: 1}
  end

  defp round_down_to(dt, {:years, n, _multiple}) do
    %{dt | year: round_down_multiple(dt.year, n)}
  end

  defp round_down_month(dt, n) do
    {month, year} =
      case {round_down_multiple(dt.month, n), dt.year} do
        {month, year} when month > 0 ->
          {month, year}

        {month, year} ->
          {month + 12, year - 1}
      end

    day = :calendar.last_day_of_the_month(year, month)
    %{dt | day: day, month: month, year: year}
  end

  defp add_interval(dt, {:days, interval_size, _duration}, count) do
    Date.add(dt, interval_size * count)
  end

  defp add_interval(dt, {:months, interval_size, _duration}, count) do
    date_add(dt, interval_size * count, :months)
  end

  defp add_interval(dt, {:years, interval_size, _duration}, count) do
    date_add(dt, interval_size * count, :years)
  end

  defp date_add(dt, amount_to_add, :years) do
    shift_by(dt, amount_to_add, :years)
  end

  defp date_add(dt, amount_to_add, :months) do
    new_date = shift_by(dt, amount_to_add, :months)

    if is_last_day_of_month(dt) do
      ldom_new = :calendar.last_day_of_the_month(new_date.year, new_date.month)
      %{new_date | day: ldom_new}
    else
      new_date
    end
  end

  defp is_last_day_of_month(%{year: year, month: month, day: day}) do
    :calendar.last_day_of_the_month(year, month) == day
  end

  # DateTime shifting methods copied from `defimpl Timex.Protocol, for: DateTime`
  # License Details:
  # The MIT License (MIT)

  ## Copyright (c) 2016 Paul Schoenfelder

  # Permission is hereby granted, free of charge, to any person obtaining a copy
  # of this software and associated documentation files (the "Software"), to deal
  # in the Software without restriction, including without limitation the rights
  # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to whom the Software is
  # furnished to do so, subject to the following conditions:

  # The above copyright notice and this permission notice shall be included in
  # all copies or substantial portions of the Software.

  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  # THE SOFTWARE.

  defp shift_by(%{year: y} = datetime, value, :years) do
    shifted = %{datetime | year: y + value}
    # If a plain shift of the year fails, then it likely falls on a leap day,
    # so set the day to the last day of that month
    case :calendar.valid_date({shifted.year, shifted.month, shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        %{shifted | day: last_day}

      true ->
        shifted
    end
  end

  defp shift_by(%{} = datetime, 0, :months), do: datetime

  # Positive shifts
  defp shift_by(%{year: year, month: month, day: day} = datetime, value, :months)
       when value > 0 do
    if month + value <= 12 do
      ldom = :calendar.last_day_of_the_month(year, month + value)

      if day > ldom do
        %{datetime | month: month + value, day: ldom}
      else
        %{datetime | month: month + value}
      end
    else
      diff = 12 - month + 1
      shift_by(%{datetime | year: year + 1, month: 1}, value - diff, :months)
    end
  end

  # Negative shifts
  defp shift_by(%{year: year, month: month, day: day} = datetime, value, :months) do
    if month + value >= 1 do
      ldom = :calendar.last_day_of_the_month(year, month + value)

      if day > ldom do
        %{datetime | month: month + value, day: ldom}
      else
        %{datetime | month: month + value}
      end
    else
      shift_by(%{datetime | year: year - 1, month: 12}, value + month, :months)
    end
  end
end
