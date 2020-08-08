defmodule GGity.Element.Text do
  @moduledoc """
  Defines the data and functions used to style non-geom text elements.
  """

  alias GGity.Element

  @derive [Element]
  defstruct [
    :family,
    :face,
    :color,
    :size
    # :hjust,
    # :vjust,
    # :angle,
    # :lineheight,
    # :margin
  ]

  @type t() :: %__MODULE__{}

  @doc """
  Constructor for a Text element.

  Calling `element_text(attributes) is equivalent to `struct(GGity.Element.Line, attributes)`.
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

  defp attribute_for({_attribute, nil}), do: ""

  defp attribute_for({:family, value}) do
    "font-family: #{value};"
  end

  defp attribute_for({:face, value}) do
    "font-face: #{value};"
  end

  defp attribute_for({:color, value}) do
    "fill: #{value};"
  end

  defp attribute_for({:size, value}) do
    "font-size: #{value};"
  end

  defp attribute_for(_element), do: ""
end
