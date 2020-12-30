defmodule GGity.Draw do
  @moduledoc false

  alias GGity.HTML

  @type options() :: keyword()

  @spec svg(iolist(), options()) :: iolist()
  def svg(elements, options \\ []) do
    [
      ~s|<svg xmlns="http://www.w3.org/2000/svg" |,
      options_to_attributes(options),
      ">",
      "\n",
      elements,
      "</svg>"
    ]
  end

  @spec g(iolist(), options()) :: iolist()
  def g(elements, options) do
    attributes = options_to_attributes(options)

    [
      "<g ",
      attributes,
      ">",
      "\n",
      elements,
      "</g>",
      "\n"
    ]
  end

  @spec rect(options()) :: iolist()
  def rect(options) do
    [
      "<rect ",
      options_to_attributes(options),
      ">",
      "</rect>",
      "\n"
    ]
  end

  @spec line(options()) :: iolist()
  def line(coord_list) do
    [
      "<line ",
      options_to_attributes(coord_list),
      ">",
      "</line>",
      "\n"
    ]
  end

  @spec text(binary(), options()) :: iolist()
  def text(text_element, options) do
    attributes = options_to_attributes(options)

    [
      "<text ",
      attributes,
      ">",
      HTML.escape_to_iodata(text_element),
      "</text>",
      "\n"
    ]
  end

  @spec marker(atom(), {number(), number()}, number(), keyword()) :: iolist()
  def marker(shape, coords, size, options \\ [])
  def marker(:triangle, coords, size, options), do: triangle(coords, size, options)
  def marker(:square, coords, size, options), do: square(coords, size, options)
  def marker(:diamond, coords, size, options), do: diamond(coords, size, options)
  def marker(:circle, coords, size, options), do: circle(coords, size / 2, options)

  def marker(character, coords, size, options) when is_binary(character) do
    {x, y} = coords

    text(character, [
      {:x, x},
      {:y, y},
      {:font_size, size},
      {:text_anchor, "middle"},
      {:dominant_baseline, "middle"} | options
    ])
  end

  @spec circle({number(), number()}, number(), keyword()) :: iolist()
  def circle({x, y}, radius, options) do
    [
      "<circle ",
      "cx=\"",
      to_string(x),
      "\" ",
      "cy=\"",
      to_string(y),
      "\" ",
      "r=\"",
      to_string(radius),
      "\" ",
      options_to_attributes(options),
      ">",
      "</circle>",
      "\n"
    ]
  end

  @spec polygon(binary(), keyword()) :: iolist()
  def polygon(points, options) do
    [
      "<polygon ",
      ~s|points="#{points}" |,
      options_to_attributes(options),
      "/>",
      "\n"
    ]
  end

  @spec polyline(list({number(), number()}), binary(), number(), number(), binary()) :: iolist()
  def polyline(coords, color, size, alpha, linetype) do
    coord_list = Enum.map(coords, fn {x, y} -> [to_string(x), ",", to_string(y), " "] end)

    [
      "<polyline ",
      "points=\"",
      coord_list,
      "\" ",
      "fill=\"none\" ",
      "stroke-width=\"",
      to_string(size),
      "\" ",
      "stroke=\"",
      color,
      "\" ",
      "stroke-opacity=\"",
      to_string(alpha),
      "\" ",
      "stroke-dasharray=\"",
      linetype,
      "\">",
      "</polyline>",
      "\n"
    ]
  end

  defp options_to_attributes(options) do
    Enum.map_join(options, " ", &option_to_attribute/1)
  end

  defp option_to_attribute({name, value}) do
    name =
      Atom.to_string(name)
      |> String.replace("_", "-")

    [
      name,
      "=\"",
      HTML.escape_to_iodata(to_string(value)),
      "\""
    ]
  end

  defp triangle({x, y}, size, options) do
    polygon("5,0 10,10 0,10", options)
    |> svg(
      viewBox: "0 0 10 10",
      x: x - size / 2,
      y: y - size / 2,
      height: to_string(size),
      width: to_string(size)
    )
  end

  defp square({x, y}, size, options) do
    Keyword.merge(options, height: "10", width: "10")
    |> rect()
    |> svg(
      viewBox: "0 0 10 10",
      x: x - size / 2,
      y: y - size / 2,
      height: to_string(size),
      width: to_string(size)
    )
  end

  defp diamond({x, y}, size, options) do
    polygon("5,0 10,5 5,10 0,5", options)
    |> svg(
      viewBox: "0 0 10 10",
      x: x - size / 2,
      y: y - size / 2,
      height: to_string(size),
      width: to_string(size)
    )
  end
end
