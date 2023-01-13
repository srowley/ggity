defmodule GGity.Scale.Fill.Viridis do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.{Color, Fill}

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :legend,
            option: :viridis

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Fill.Viridis.t()
  def new(options \\ []), do: struct(Fill.Viridis, options)

  @spec train(Fill.Viridis.t(), list(binary())) :: Fill.Viridis.t()
  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    color_struct =
      Color.Viridis
      |> struct(Map.from_struct(scale))
      |> Color.Viridis.train(levels)

    struct(Fill.Viridis, Map.from_struct(color_struct))
  end

  @spec draw_legend(Fill.Viridis.t(), binary(), atom(), number(), keyword()) :: iolist()
  def draw_legend(
        %Fill.Viridis{guide: :none},
        _label,
        _key_glyph,
        _key_height,
        _fixed_aesthetics
      ),
      do: []

  def draw_legend(%Fill.Viridis{levels: [_]}, _label, _key_glyp, _key_heighth, _fixed_aesthetics),
    do: []

  def draw_legend(
        %Fill.Viridis{levels: levels} = scale,
        label,
        key_glyph,
        key_height,
        fixed_aesthetics
      ) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      Enum.with_index(levels, fn level, index ->
        draw_legend_item(scale, {level, index}, key_glyph, key_height, fixed_aesthetics)
      end)
    ]
  end

  defp draw_legend_item(scale, {level, index}, key_glyph, key_height, fixed_aesthetics) do
    [
      draw_key_glyph(scale, level, index, key_glyph, key_height, fixed_aesthetics),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "#{5 + key_height}",
        y: "#{10 + key_height * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end

  defp draw_key_glyph(scale, level, index, :rect, key_height, fixed_aesthetics) do
    Draw.rect(
      x: "0",
      y: "#{key_height * index}",
      height: key_height,
      width: key_height,
      style: "fill:#{scale.transform.(level)}; fill-opacity:#{fixed_aesthetics[:alpha]};",
      class: "gg-legend-key"
    )
  end
end
