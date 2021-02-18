defmodule GGity.Scale.Size do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.{Continuous, Size}

  @base_intervals [0.1, 0.2, 0.25, 0.4, 0.5, 0.75, 1.0, 2.0, 2.5, 4.0, 5.0, 7.5, 10]

  defstruct range: {1, 6},
            breaks: 4,
            labels: :waivers,
            tick_values: [],
            inverse: nil,
            transform: nil,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Size.t()
  def new(options \\ []), do: struct(Size, options)

  @spec train(Size.t(), {number(), number()}) :: Size.t()
  def train(scale, {min, max}) when is_number(min) and is_number(max) do
    range = max - min
    struct(scale, transformations(range, min, max, scale))
  end

  defp transformations(range, min, max, %Size{} = scale) do
    raw_interval_size = range / (scale.breaks - 1)
    order_of_magnitude = :math.ceil(:math.log10(raw_interval_size) - 1)
    power_of_ten = :math.pow(10, order_of_magnitude)
    adjusted_interval_size = axis_interval_lookup(raw_interval_size / power_of_ten) * power_of_ten
    adjusted_min = adjusted_interval_size * Float.floor(min / adjusted_interval_size)
    adjusted_max = adjusted_interval_size * Float.ceil(max / adjusted_interval_size)

    adjusted_interval_count =
      round(1.0001 * (adjusted_max - adjusted_min) / adjusted_interval_size)

    # TODO - generalize/fix this so it is not different from other continuous scales
    tick_values =
      Enum.map(
        1..(adjusted_interval_count + 1),
        &(adjusted_min + &1 * adjusted_interval_size)
        # &(adjusted_min + (&1 - 1) * adjusted_interval_size)
      )

    # This does not seem like it is exactly right depending on the shape
    # But it appears to be what ggplot2 does:
    # https://github.com/tidyverse/ggplot2/blob/master/R/scale-size.r
    # https://github.com/r-lib/scales/blob/master/R/pal-area.r
    domain_min = :math.pow(elem(scale.range, 0), 2)
    domain_max = :math.pow(elem(scale.range, 1), 2)
    transform = Continuous.transform({adjusted_min, adjusted_max}, {domain_min, domain_max})

    [
      tick_values: tick_values,
      inverse: transform,
      transform: transform
    ]
  end

  defp axis_interval_lookup(value) do
    Enum.find(@base_intervals, &(&1 >= value))
  end

  @spec draw_legend(Size.t(), binary(), atom(), number(), keyword()) :: iolist()
  def draw_legend(%Size{guide: :none}, _label, _key_glyph, _key_height, _fixed_aesthetics), do: []

  def draw_legend(%Size{} = scale, label, key_glyph, key_height, fixed_aesthetics) do
    max_value = Enum.max(scale.tick_values)
    key_width = max(key_height, 2 * :math.sqrt(scale.transform.(max_value) / :math.pi()))

    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      scale.tick_values
      |> Enum.map_reduce(0, fn value, y_position ->
        draw_legend_item(
          scale,
          value,
          key_glyph,
          key_height,
          key_width,
          y_position,
          fixed_aesthetics
        )
      end)
      |> elem(0)
    ]
  end

  defp draw_legend_item(
         scale,
         value,
         key_glyph,
         key_height,
         key_width,
         y_position,
         fixed_aesthetics
       ) do
    key_height = max(key_height, 2 * :math.sqrt(scale.transform.(value) / :math.pi()))

    {
      [
        Draw.rect(
          x: "0",
          y: "#{y_position}",
          height: key_height,
          width: key_width,
          class: "gg-legend-key"
        ),
        draw_key_glyph(
          scale,
          value,
          key_glyph,
          key_height,
          key_width,
          y_position,
          fixed_aesthetics
        ),
        Draw.text(
          "#{Labels.format(scale, value)}",
          x: "#{5 + key_width}",
          y: "#{key_height / 2 + y_position}",
          class: "gg-text gg-legend-text",
          text_anchor: "left",
          dominant_baseline: "middle"
        )
      ],
      y_position + key_height
    }
  end

  defp draw_key_glyph(scale, value, :a, key_height, key_width, y_position, fixed_aesthetics) do
    Draw.text(
      "a",
      x: "#{key_width / 2}",
      y: "#{key_height / 2 + y_position}",
      font_size: "#{scale.transform.(value)}pt",
      fill: fixed_aesthetics[:color],
      text_anchor: "left"
    )
  end

  defp draw_key_glyph(
         scale,
         value,
         _key_glyph,
         key_height,
         key_width,
         y_position,
         fixed_aesthetics
       ) do
    GGity.Shapes.draw(
      fixed_aesthetics[:shape],
      {key_width / 2, key_height / 2 + y_position},
      scale.inverse.(value),
      color: fixed_aesthetics[:color],
      fill_opacity: fixed_aesthetics[:alpha]
    )
  end
end

# The process here needs to be:

# For each variable
# 1) for each layer
# 2) if that variable is mapped to one or more aesthetics with a legend as a guide
# 3) get the breaks for the legend

# You don't need to merge aesthetics across layers, you just draw glyphs on top of one another
#  What data do I need?
#  --A list of all the variables mapped to something with a legend
#  --Groups of layers, one for each variable
#  -- For each group, need the layers, the scale

# For first layer - is there mapping to a variable with a legend as a guide?
# If yes, note that and get the fixed aesthetics mapped for that layer
# Go through the rest of the layers and do the same thing
# With that list, for each break in the scale draw a glyph for each layer

# So what have we learned
# A legend displays specific values (breaks) and a glyph mapping that value to the applicable aesthetic
# A colorbar is not a legend, it is a thing that draws a gradient over the range of the color aesthetic with tick
# marks at the breaks
# There is also a guide_bins, which displays the cutoffs for each bin on each side (top/bottom) of the glyph
# for that bin
# ggplot2 doesn't try to merge different kinds of guides
