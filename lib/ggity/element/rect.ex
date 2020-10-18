defmodule GGity.Element.Rect do
  @moduledoc """
  Defines the data and functions used to style non-geom rect elements.

  CSS presentation attributes:
  *  `:fill` sets value of CSS `fill`
  *  `:color` sets value of CSS `stroke`
  *  `:size` sets value of CSS `stroke-width`

  Other attributes:
  *  `:height` sets value of SVG `height` (height of the key glyph box)
  """

  alias GGity.Element

  @derive [Element]
  defstruct [
    :fill,
    :color,
    :size,
    # :linetype,
    :height
  ]

  @type t() :: %__MODULE__{}

  @doc """
  Constructor for a Rect element.

  Setting the value of an attributed to `nil` will remove that property
  from the generated stylesheet altogether.

  Calling `element_rect(attributes)` is equivalent to `struct(GGity.Element.Line, attributes)`.
  """
  @spec element_rect(keyword()) :: Element.Line.t()
  def element_rect(attributes) do
    struct(Element.Rect, attributes)
  end

  @doc false
  @spec attributes_for(Element.Rect.t()) :: iolist()
  def attributes_for(element) do
    element
    |> Map.from_struct()
    |> Enum.map(&attribute_for/1)
  end

  defp attribute_for({_attribute, nil}), do: ""

  defp attribute_for({:fill, value}) do
    "fill: #{value};"
  end

  defp attribute_for({:color, value}) do
    "stroke: #{value};"
  end

  defp attribute_for({:size, value}) do
    "stroke-width: #{value};"
  end

  defp attribute_for(_element), do: ""
end
