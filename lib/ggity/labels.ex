defmodule GGity.Labels do
  @moduledoc """
  Common functions for transforming axis tick labels.

  Break (i.e. axis tick or legend item) labels are formatted based on a
  scale's `:labels` option. This option can be provided in several forms:

  - `nil` - No labels are drawn
  - `:waivers` - drawn using the default formatting (`Kernel.to_string/1`)
  - a function that takes a single argument representing the break value and returns a binary
  - an atom, representing the name of a built-in formatting function (e.g., `commas/1`)

  Note that the built-in formatting functions are not intended to be robust. One option for
  finely-tuned formatting would be to pass functions from the [Cldr family of packages](https://hexdocs.pm/ex_cldr) (must be
  added as a separate dependency).
  ## Examples

  ```
  data
  |> Plot.new(%{x: "x", y: "y"})
  |> Plot.geom_point()
  |> Plot.scale_x_continuous(labels: nil)
  # value 1000 is printed as an empty string
  ```

  ```
  data
  |> Plot.new(%{x: "x", y: "y"})
  |> Plot.geom_point()
  |> Plot.scale_x_continuous() # This is equivalant to Plot.scale_x_continuous(labels: :waivers)
  # value 1000 (integer) is printed as "1000"
  # value 1000.0 (float) is printed as "1.0e3"

  ```

  ```
  data
  |> Plot.new(%{x: "x", y: "y", c: "color"})
  |> Plot.geom_point()
  |> Plot.scale_color_viridis(labels: fn value -> value  <> "!" end)
  # value "First Item" is printed as "First Item!"
  ```

  ```
  data
  |> Plot.new(%{x: "x", y: "y"})
  |> Plot.geom_point()
  |> Plot.scale_x_continuous(labels: :commas)
  # value 1000 (integer) is printed as "1,000"
  # value 1000 (float) is printed as "1,000"
  ```

  Date scales (e.g., `GGity.Scale.X.Date`) are a special case.
  For those scales, if a value for `:date_labels` has been specified, that
  pattern overrides any value for the `:labels` option. See
  `GGity.Plot.scale_x_date/2` for more information regarding
  date labels.
  """

  alias GGity.{Labels, Scale}

  @type tick_value() :: %Date{} | %DateTime{} | number()

  @doc false
  @spec format(map(), tick_value()) :: String.t()
  def format(%scale_type{date_labels: {pattern, options}}, value)
      when scale_type in [Scale.X.Date, Scale.X.DateTime] do
    NimbleStrftime.format(value, pattern, options)
  end

  def format(%scale_type{date_labels: pattern}, value)
      when scale_type in [Scale.X.Date, Scale.X.DateTime] and is_binary(pattern) do
    NimbleStrftime.format(value, pattern)
  end

  def format(%{labels: :waivers}, value), do: to_string(value)

  def format(%{labels: nil}, _value), do: ""

  def format(%{labels: built_in_function}, value) when is_atom(built_in_function) do
    apply(Labels, built_in_function, [value])
  end

  def format(%{labels: formatter}, value) when is_function(formatter) do
    formatter.(value)
  end

  @doc """
  Applies a comma separator to a number and converts it to a string.

  If the number is a float, it is first rounded using `Kernel.to_string/1`.

  Note that simple floating point arithmetic is used; the various issues/errors
  associated with floating point values apply.

      iex> GGity.Labels.commas(5000.0)
      "5,000"

      iex> GGity.Labels.commas(1000.6)
      "1,001"

      iex> GGity.Labels.commas(100.0)
      "100"

      iex> GGity.Labels.commas(10_000_000)
      "10,000,000"
  """
  @spec commas(number()) :: String.t()
  def commas(value) when is_number(value) do
    value
    |> round()
    |> to_charlist()
    |> Enum.reverse()
    |> comma_separate([])
    |> to_string()
  end

  defp comma_separate([first, second, third | []], acc) do
    [third, second, first | acc]
  end

  defp comma_separate([first, second, third | tail], acc) do
    acc = [',', third, second, first | acc]
    comma_separate(tail, acc)
  end

  defp comma_separate([first | [second]], acc), do: [second, first | acc]
  defp comma_separate([first], acc), do: [first | acc]
  defp comma_separate([], acc), do: acc

  @doc """
  Formats a number in U.S. dollars and cents.

  If the value is greater than or equal to 100,000 rounds to the nearest
  dollar and does not display cents.

  Note that simple floating point arithmetic is used; the various issues/errors
  associated with floating point values apply.

      iex> GGity.Labels.dollar(5000.0)
      "$5,000.00"

      iex> GGity.Labels.dollar(1000.6)
      "$1,000.60"

      iex> GGity.Labels.dollar(100.0)
      "$100.00"

      iex> GGity.Labels.dollar(10_000_000)
      "$10,000,000"
  """
  @spec dollar(number()) :: String.t()
  def dollar(value) when is_float(value) do
    cents =
      ((Float.round(value, 2) - floor(value)) * 100)
      |> round()
      |> Integer.digits()
      |> Enum.take(2)
      |> Enum.join()
      |> String.pad_trailing(2, "0")

    case value do
      value when value >= 100_000 ->
        "$" <> commas(floor(value))

      value ->
        "$#{commas(floor(value))}.#{cents}"
    end
  end

  def dollar(value) when is_integer(value) do
    dollar(value * 1.0)
  end

  @doc """
  Formats a number as a percent.

  Accepts a `:precision` option specifying the number of decimal places
  to be displayed.

  Note that simple floating point arithmetic is used; the various issues/errors
  associated with floating point values apply.

      iex> GGity.Labels.percent(0.5)
      "50%"

      iex> GGity.Labels.percent(0.111)
      "11%"

      iex> GGity.Labels.percent(0.015, precision: 1)
      "1.5%"

      iex> GGity.Labels.percent(10)
      "1000%"
  """
  @spec percent(number(), keyword()) :: String.t()
  def percent(value, options \\ [precision: 0])

  def percent(value, precision: precision) when is_float(value) do
    percent_value =
      (value * 100)
      |> Float.round(precision)

    rounded_value =
      case precision do
        0 -> round(percent_value)
        _other -> percent_value
      end

    to_string(rounded_value) <> "%"
  end

  def percent(value, _options) when is_integer(value) do
    to_string(value * 100) <> "%"
  end
end
