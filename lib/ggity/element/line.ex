defmodule GGity.Element.Line do
  @moduledoc """
  Defines the data and functions used to style non-geom line elements.
  """

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

  Calling `element_line(attributes) is equivalent to `struct(GGity.Element.Line, attributes)`.
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

  defp attribute_for({_attribute, nil}), do: ""

  defp attribute_for({:color, value}) do
    "stroke: #{value};"
  end

  defp attribute_for({:size, value}) do
    "stroke-width: #{value};"
  end

  defp attribute_for(_element), do: ""
end
