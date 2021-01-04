defmodule GGity.Element.Rect do
  @moduledoc """
  Defines the data and functions used to style non-geom rect elements.

  CSS presentation attributes:
  *  `:fill` - string: sets value of CSS `fill`

      Values must be valid CSS color names or hex values.

  *  `:color` - string: sets value of CSS `stroke`

      Values must be valid CSS color names or hex values.

  *  `:size` - number: sets value of CSS `stroke-width`


  Other attributes:
  *  `:height` - number: sets value of SVG `height` (height of the key glyph box)
  """

  import GGity.Color, only: [valid_color?: 1]
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

  defp attribute_for({_attribute, nil}), do: []

  defp attribute_for({:fill, value}) do
    if valid_color?(value), do: ["fill: ", value, ";"], else: []
  end

  defp attribute_for({:color, value}) do
    if valid_color?(value), do: ["stroke: ", value, ";"], else: []
  end

  defp attribute_for({:size, value}) when is_number(value) do
    ["stroke-width: ", to_string(value), ";"]
  end

  defp attribute_for(_element), do: []
end
