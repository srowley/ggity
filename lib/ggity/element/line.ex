defmodule GGity.Element.Line do
  @moduledoc """
  Defines the data and functions used to style non-geom line elements.

  CSS presentation attributes:
  *  `:color` sets value of CSS `stroke`
  *  `:size` sets value of CSS `stroke-width`
  """

  import GGity.Color, only: [valid_color?: 1]
  alias GGity.Element

  @derive [Element]
  defstruct [
    :color,
    :size
    # :linetype,
    # :lineend,
    # :arrow
  ]

  @type t() :: %__MODULE__{}

  @doc """
  Constructor for a Line element.

  Setting the value of an attributed to `nil` will remove that property
  from the generated stylesheet altogether.

  Calling `element_line(attributes)` is equivalent to `struct(GGity.Element.Line, attributes)`.
  """
  @spec element_line(keyword()) :: Element.Line.t()
  def element_line(attributes) do
    struct(Element.Line, attributes)
  end

  @doc false
  @spec attributes_for(Element.Line.t()) :: iolist()
  def attributes_for(element) do
    element
    |> Map.from_struct()
    |> Enum.map(&attribute_for/1)
  end

  defp attribute_for({_attribute, nil}), do: []

  defp attribute_for({:color, value}) do
    if valid_color?(value), do: ["stroke: ", value, ";"], else: []
  end

  defp attribute_for({:size, value}) when is_number(value) do
    ["stroke-width: ", to_string(value), ";"]
  end

  defp attribute_for({:size, _value}), do: []

  defp attribute_for(_element), do: []
end
