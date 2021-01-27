defmodule GGity.Scale.X.DateTime do
  @moduledoc false

  alias GGity.Scale.{Continuous, X}

  @duration_sec 1000
  @duration_min @duration_sec * 60
  @duration_hour @duration_min * 60
  @duration_day @duration_hour * 24
  @duration_month @duration_day * 30
  @duration_year @duration_day * 365

  @tick_intervals [
    {:seconds, 1, @duration_sec},
    {:seconds, 5, @duration_sec * 5},
    {:seconds, 15, @duration_sec * 15},
    {:seconds, 30, @duration_sec * 30},
    {:minutes, 1, @duration_min},
    {:minutes, 5, @duration_min * 5},
    {:minutes, 15, @duration_min * 15},
    {:minutes, 30, @duration_min * 30},
    {:hours, 1, @duration_hour},
    {:hours, 3, @duration_hour * 3},
    {:hours, 6, @duration_hour * 6},
    {:hours, 12, @duration_hour * 12},
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
  @type date_time() :: %DateTime{} | %NaiveDateTime{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct width: 200,
            breaks: 5,
            date_labels: :waivers,
            labels: :waivers,
            tick_values: nil,
            inverse: nil,
            transform: nil

  @spec new(keyword()) :: X.DateTime.t()
  def new(options \\ []), do: struct(X.DateTime, options)

  @spec train(X.DateTime.t(), {date_time(), date_time()}) :: X.DateTime.t()
  def train(scale, {%date_type{} = min, %date_type{} = max})
      when min == max and date_type in [DateTime, NaiveDateTime] do
    struct(
      scale,
      tick_values: min,
      inverse: fn _value -> min end,
      transform: fn _value -> scale.width / 2 end
    )
  end

  def train(scale, {%date_type{} = min, %date_type{} = max})
      when date_type in [DateTime, NaiveDateTime] do
    range = diff(max, min)
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

  defp diff(%date_type{} = max, %date_type{} = min) when date_type in [DateTime, NaiveDateTime] do
    apply(date_type, :diff, [max, min, :millisecond])
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

  defp calculate_end_interval(%date_type{} = start, target, tick_interval, max_steps) do
    Enum.reduce_while(1..max_steps, {start, 0}, fn step, {_current_end, _index} ->
      new_end = add_interval(start, tick_interval, step)

      # if Date.compare(new_end, target) == :lt,
      if apply(date_type, :compare, [new_end, target]) == :lt,
        do: {:cont, {new_end, step}},
        else: {:halt, {new_end, step}}
    end)
  end

  defp round_down_to(dt, {:seconds, n, _multiple}) do
    %{dt | microsecond: {0, 0}, second: round_down_multiple(dt.second, n)}
  end

  defp round_down_to(dt, {:minutes, n, _multiple}) do
    %{dt | microsecond: {0, 0}, second: 0, minute: round_down_multiple(dt.minute, n)}
  end

  defp round_down_to(dt, {:hours, n, _multiple}) do
    %{dt | microsecond: {0, 0}, second: 0, minute: 0, hour: round_down_multiple(dt.hour, n)}
  end

  defp round_down_to(dt, {:days, 1, _multiple}) do
    %{dt | microsecond: {0, 0}, second: 0, minute: 0, hour: 0}
  end

  defp round_down_to(dt, {:days, n, _multiple}) do
    %{
      dt
      | microsecond: {0, 0},
        second: 0,
        minute: 0,
        hour: 0,
        day: round_down_multiple(dt.day, n) + 1
    }
  end

  defp round_down_to(dt, {:months, 1, _multiple}) do
    %{dt | microsecond: {0, 0}, second: 0, minute: 0, hour: 0, day: 1}
  end

  defp round_down_to(dt, {:months, n, _multiple}), do: round_down_month(dt, n)

  defp round_down_to(dt, {:years, 1, _multiple}) do
    %{dt | microsecond: {0, 0}, second: 0, minute: 0, hour: 0, day: 1, month: 1}
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
    %{dt | microsecond: {0, 0}, second: 0, minute: 0, hour: 0, day: day, month: month, year: year}
  end

  defp round_down_multiple(value, multiple), do: div(value, multiple) * multiple

  defp add_interval(dt, {:seconds, _interval_size, duration_msec}, count) do
    date_add(dt, duration_msec * count, :millisecond)
  end

  defp add_interval(dt, {:minutes, _interval_size, duration_msec}, count) do
    date_add(dt, duration_msec * count, :millisecond)
  end

  defp add_interval(dt, {:hours, _interval_size, duration_msec}, count) do
    date_add(dt, duration_msec * count, :millisecond)
  end

  defp add_interval(dt, {:days, _interval_size, duration_msec}, count) do
    date_add(dt, duration_msec * count, :millisecond)
  end

  defp add_interval(dt, {:months, interval_size, _duration}, count) do
    date_add(dt, interval_size * count, :months)
  end

  defp add_interval(dt, {:years, interval_size, _duration}, count) do
    date_add(dt, interval_size * count, :years)
  end

  defp date_add(dt, amount_to_add, :years), do: shift_by(dt, amount_to_add, :years)

  defp date_add(dt, amount_to_add, :months) do
    new_date = shift_by(dt, amount_to_add, :months)

    if is_last_day_of_month(dt) do
      ldom_new = :calendar.last_day_of_the_month(new_date.year, new_date.month)
      %{new_date | day: ldom_new}
    else
      new_date
    end
  end

  defp date_add(%DateTime{} = dt, amount_to_add, unit), do: DateTime.add(dt, amount_to_add, unit)

  defp date_add(%NaiveDateTime{} = dt, amount_to_add, unit),
    do: NaiveDateTime.add(dt, amount_to_add, unit)

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
