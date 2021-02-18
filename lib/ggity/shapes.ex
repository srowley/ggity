defmodule GGity.Shapes do
  @moduledoc false
  alias GGity.Draw

  @shape_names %{
    square_open: 0,
    circle_open: 1,
    triangle_open: 2,
    plus: 3,
    cross: 4,
    diamond_open: 5,
    triangle_down_open: 6,
    square_cross: 7,
    asterisk: 8,
    diamond_plus: 9,
    circle_plus: 10,
    star: 11,
    square_plus: 12,
    circle_cross: 13,
    square_triangle: 14,
    triangle_square: 14,
    square: 15,
    circle_small: 16,
    triangle: 17,
    diamond: 18,
    circle: 19,
    bullet: 20,
    circle_filled: 21,
    square_filled: 22,
    diamond_filled: 23,
    triangle_filled: 24,
    triangle_down_filled: 25
  }

  @doc false
  @spec draw(binary() | atom() | non_neg_integer(), {number(), number()}, number(), keyword()) ::
          iolist()
  def draw(character, {x, y}, size, options) when is_binary(character) do
    options =
      if Keyword.has_key?(options, :color) do
        options
        |> Keyword.put(:fill, options[:color])
        |> Keyword.delete(:color)
      end

    Draw.text(character, [
      {:x, x},
      {:y, y},
      {:font_size, :math.sqrt(size)},
      {:text_anchor, "middle"},
      {:dominant_baseline, "middle"} | options
    ])
  end

  def draw(name, {x, y}, area, attributes) when is_map_key(@shape_names, name) do
    draw(@shape_names[name], {x, y}, area, attributes)
  end

  def draw(0, {x, y}, area, attributes) do
    attributes
    |> make_transparent()
    |> replace_color_with_stroke()
    |> square()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(1, {x, y}, area, attributes) do
    attributes
    |> make_transparent()
    |> replace_color_with_stroke()
    |> circle()
    |> wrap_svg({x, y}, size_for(:circle, area))
  end

  def draw(2, {x, y}, area, attributes) do
    attributes
    |> make_transparent()
    |> replace_color_with_stroke()
    |> triangle()
    |> wrap_svg({x, y}, size_for(:triangle, area))
  end

  def draw(3, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> plus()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(4, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> cross()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(5, {x, y}, area, attributes) do
    attributes
    |> make_transparent()
    |> replace_color_with_stroke()
    |> diamond()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(6, {x, y}, area, attributes) do
    attributes
    |> make_transparent()
    |> replace_color_with_stroke()
    |> flip()
    |> triangle()
    |> wrap_svg({x, y}, size_for(:triangle, area))
  end

  def draw(7, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    square = square(attributes)
    cross = cross(attributes)

    wrap_svg([square, cross], {x, y}, size_for(:square, area))
  end

  def draw(8, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    cross = cross(attributes)
    plus = plus(attributes)

    wrap_svg([cross, plus], {x, y}, size_for(:square, area))
  end

  def draw(9, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    diamond = diamond(attributes)
    plus = plus(attributes)

    wrap_svg([diamond, plus], {x, y}, size_for(:square, area))
  end

  def draw(10, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    circle = circle(attributes)
    plus = plus(attributes)

    wrap_svg([circle, plus], {x, y}, size_for(:circle, area))
  end

  def draw(11, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    triangle = triangle([{:transform, "translate(0, -1)"} | attributes])

    triangle_down =
      attributes
      |> flip()
      |> triangle()

    size = size_for(:triangle, area)

    Draw.svg(
      [triangle, triangle_down],
      viewBox: "0 -1 10 11",
      x: x,
      y: y,
      height: to_string(size),
      width: to_string(size)
    )
  end

  def draw(12, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    square = square(attributes)
    plus = plus(attributes)

    wrap_svg([square, plus], {x, y}, size_for(:square, area))
  end

  def draw(13, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    circle = circle(attributes)
    cross = cross(attributes)

    wrap_svg([circle, cross], {x, y}, size_for(:circle, area))
  end

  def draw(14, {x, y}, area, attributes) do
    attributes =
      attributes
      |> make_transparent()
      |> replace_color_with_stroke()

    square = square(attributes)
    triangle = triangle(attributes)

    wrap_svg([square, triangle], {x, y}, size_for(:square, area))
  end

  def draw(15, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_fill()
    |> square()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(16, {x, y}, area, attributes) do
    # MAGIC NUMBER - I don't know how exactly 16 vs. 19 vs. 20 relate
    attributes
    |> replace_color_with_fill()
    |> circle()
    |> wrap_svg({x, y}, size_for(:circle, area) * 0.8)
  end

  def draw(17, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_fill()
    |> triangle()
    |> wrap_svg({x, y}, size_for(:triangle, area))
  end

  def draw(18, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_fill()
    |> diamond()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(19, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_fill()
    |> circle()
    |> wrap_svg({x, y}, size_for(:circle, area))
  end

  def draw(20, {x, y}, area, attributes) do
    # MAGIC NUMBER - I don't know how exactly 16 vs. 19 vs. 20 relate
    attributes
    |> replace_color_with_fill()
    |> circle()
    |> wrap_svg({x, y}, size_for(:circle, area) * 0.5)
  end

  def draw(21, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> circle()
    |> wrap_svg({x, y}, size_for(:circle, area))
  end

  def draw(22, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> square()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(23, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> diamond()
    |> wrap_svg({x, y}, size_for(:square, area))
  end

  def draw(24, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> Keyword.put(:size, :math.sqrt(area * 2))
    |> triangle()
    |> wrap_svg({x, y}, size_for(:triangle, area))
  end

  def draw(25, {x, y}, area, attributes) do
    attributes
    |> replace_color_with_stroke()
    |> flip()
    |> triangle()
    |> wrap_svg({x, y}, size_for(:triangle, area))
  end

  defp square(attributes) do
    attributes
    |> Keyword.merge(height: "10", width: "10")
    |> Draw.rect()
  end

  defp circle(attributes) do
    Draw.circle({5, 5}, 4, attributes)
  end

  defp triangle(attributes) do
    Draw.polygon("5,0 10,10 0,10", attributes)
  end

  defp plus(attributes) do
    horizontal_line_points = [x1: "0", x2: "10", y1: "5", y2: "5"]
    vertical_line_points = [y1: "0", y2: "10", x1: "5", x2: "5"]
    horizontal = horizontal_line_points ++ attributes
    vertical = vertical_line_points ++ attributes
    [Draw.line(horizontal), Draw.line(vertical)]
  end

  defp cross(attributes) do
    bottom_left_line = [x1: "0", x2: "10", y1: "10", y2: "0"]
    top_left_line = [x1: "0", x2: "10", y1: "0", y2: "10"]
    bottom_left = bottom_left_line ++ attributes
    top_left = top_left_line ++ attributes
    [Draw.line(bottom_left), Draw.line(top_left)]
  end

  defp diamond(attributes) do
    Draw.polygon("5,0 10,5 5,10 0,5", attributes)
  end

  defp make_transparent(attributes) do
    Keyword.merge(attributes, fill_opacity: 0)
  end

  defp replace_color_with_stroke(attributes) do
    attributes
    |> Keyword.merge(stroke: attributes[:color])
    |> Keyword.delete(:color)
  end

  defp replace_color_with_fill(attributes) do
    attributes
    |> Keyword.merge(fill: attributes[:color])
    |> Keyword.delete(:color)
  end

  defp flip(attributes) do
    Keyword.merge(attributes, transform: "rotate(180, 5, 5)")
  end

  defp wrap_svg(shapes, {x, y}, size) do
    Draw.svg(
      shapes,
      viewBox: "0 0 10 10",
      x: x - size / 2,
      y: y - size / 2,
      height: to_string(size),
      width: to_string(size)
    )
  end

  defp size_for(_shape, area) do
    :math.sqrt(area)
  end

  # defp size_for(:square, area) do
  #   :math.sqrt(area)
  # end

  # defp size_for(:triangle, area) do
  #   :math.sqrt(area)
  # end

  # defp size_for(:circle, area) do
  #   2 * :math.sqrt(area / :math.pi())
  # end
end
