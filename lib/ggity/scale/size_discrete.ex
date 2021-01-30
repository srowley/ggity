defmodule GGity.Scale.Size.Discrete do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Size

  defstruct transform: nil,
            range: {9, 100},
            levels: nil,
            labels: :waivers,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Size.Discrete.t()
  def new(options \\ []), do: struct(Size.Discrete, options)

  @spec train(Size.Discrete.t(), list(binary())) :: Size.Discrete.t()
  def train(scale, [value] = levels) when is_binary(value) do
    {palette_min, palette_max} = scale.range
    palette_range = palette_max - palette_min
    transform = fn _value -> :math.sqrt(palette_min + palette_range / 2) end
    struct(scale, levels: levels, transform: transform)
  end

  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    {palette_min, palette_max} = scale.range
    palette_range = palette_max - palette_min

    intervals = length(levels) - 1

    values_map =
      levels
      |> Enum.reverse()
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, :math.sqrt(palette_max - palette_range / intervals * index)}
      end)
      |> Enum.into(%{})

    transform = fn value -> values_map[to_string(value)] end
    struct(scale, levels: levels, transform: transform)
  end

  @spec draw_legend(Size.Discrete.t(), binary(), atom(), number()) :: iolist()
  def draw_legend(%Size.Discrete{guide: :none}, _label, _key_glyph, _key_height), do: []

  def draw_legend(%Size.Discrete{levels: [_]}, _label, _key_glyph, _key_height), do: []

  def draw_legend(%Size.Discrete{levels: levels} = scale, label, key_glyph, key_height) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      Stream.with_index(levels)
      |> Enum.map(fn {level, index} ->
        draw_legend_item(scale, {level, index}, key_glyph, key_height)
      end)
    ]
  end

  defp draw_legend_item(scale, {level, index}, key_glyph, key_height) do
    [
      Draw.rect(
        x: "0",
        y: "#{key_height * index}",
        height: key_height,
        width: key_height,
        class: "gg-legend-key"
      ),
      draw_key_glyph(scale, level, index, key_glyph, key_height),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "#{5 + key_height}",
        y: "#{10 + key_height * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end

  defp draw_key_glyph(scale, level, index, :a, key_height) do
    Draw.text(
      "a",
      x: "#{key_height / 2}",
      y: "#{key_height / 2 + key_height * index}",
      font_size: "#{scale.transform.(level)}pt",
      fill: "black",
      text_anchor: "left"
    )
  end

  defp draw_key_glyph(scale, level, index, _key_glyph, key_height) do
    GGity.Shapes.draw(
      :circle,
      {key_height / 2, key_height / 2 + key_height * index},
      :math.pow(1 + scale.transform.(level), 2),
      color: "black",
      fill_opacity: "1"
    )
  end
end
