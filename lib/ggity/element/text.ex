defmodule GGity.Element.Text do
  @moduledoc """
  Defines the data and functions used to style non-geom text elements.

  CSS presentation attributes:
  *  `:family` - string: sets value of CSS `font-family`

  *  `:face` - string or integer: sets value of CSS `font-weight`

      Valid values:
      * `"normal"`
      * `"bold"`
      * `"bolder"`
      * `"lighter"`
      * `"initial"`
      * `"inherit"`
      * A multiple of 100 between 100 and 900

  *  `:color` - string: sets value of CSS `fill`

      Values must be valid CSS color names or hex values.

  *  `:size` - number: sets value of CSS `font-size` in pixels

  Other attributes:
  *  `:angle` - number (between 0 and 90): sets the value passed to
  `transform: rotate()` for the purpose of rotating x axis tick
  labels (has no effect when set for other theme elements)
  """

  import GGity.Color, only: [valid_color?: 1]
  alias GGity.{Element, HTML}

  @valid_font_weights List.flatten([
                        "normal",
                        "bold",
                        "bolder",
                        "lighter",
                        "initial",
                        "inherit",
                        Enum.map(1..9, fn number -> [number * 100, to_string(number * 100)] end)
                      ])

  @derive [Element]
  defstruct [
    :family,
    :face,
    :color,
    :size,
    :angle
    # :hjust,
    # :vjust,
    # :lineheight,
    # :margin
  ]

  @type t() :: %__MODULE__{}

  @doc """
  Constructor for a Text element.

  Setting the value of an attributed to `nil` will remove that property
  from the generated stylesheet altogether.

  Calling `element_text(attributes)` is equivalent to `struct(GGity.Element.Text, attributes)`.
  """
  @spec element_text(keyword()) :: Element.Text.t()
  def element_text(attributes) do
    struct(Element.Text, attributes)
  end

  @doc false
  @spec attributes_for(Element.Text.t()) :: iolist()
  def attributes_for(element) do
    element
    |> Map.from_struct()
    |> Enum.map(&attribute_for/1)
  end

  defp attribute_for({_attribute, nil}), do: []

  defp attribute_for({:family, value}) do
    ["font-family: ", HTML.escape_to_iodata(value), ";"]
  end

  defp attribute_for({:face, value}) when value in @valid_font_weights do
    ["font-weight: ", value, ";"]
  end

  defp attribute_for({:color, value}) when is_binary(value) do
    if valid_color?(value), do: ["fill: ", value, ";"]
  end

  defp attribute_for({:size, value}) when is_number(value) do
    ["font-size: ", to_string(value), "px;"]
  end

  defp attribute_for(_element), do: []
end
