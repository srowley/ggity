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

  @spec train(Fill.Viridis.t(), list()) :: Fill.Viridis.t()
  def train(scale, levels) do
    color_struct =
      Color.Viridis
      |> struct(Map.from_struct(scale))
      |> Color.Viridis.train(levels)

    struct(Fill.Viridis, Map.from_struct(color_struct))
  end

  @spec draw_legend(Fill.Viridis.t(), binary(), atom()) :: iolist()
  def draw_legend(%Fill.Viridis{guide: :none}, _label, _key_glyph), do: []

  def draw_legend(%Fill.Viridis{levels: []}, _label, _key_glyph), do: []

  def draw_legend(%Fill.Viridis{levels: [_]}, _label, _key_glyph), do: []

  def draw_legend(%Fill.Viridis{levels: levels} = scale, label, key_glyph) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        font_size: "9",
        fill: "black",
        text_anchor: "left"
      ),
      Stream.with_index(levels)
      |> Enum.map(fn {level, index} -> draw_legend_item(scale, {level, index}, key_glyph) end)
    ]
  end

  defp draw_legend_item(scale, {level, index}, key_glyph) do
    [
      draw_key_glyph(scale, level, index, key_glyph),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "20",
        y: "#{10 + 15 * index}",
        font_size: "8",
        fill: "black",
        text_anchor: "left"
      )
    ]
  end

  defp draw_key_glyph(scale, level, index, :rect) do
    Draw.rect(
      x: "0",
      y: "#{15 * index}",
      height: "15",
      width: "15",
      fill: "#{scale.transform.(level)}",
      stroke: "white",
      stroke_width: "0.5"
    )
  end

  @spec legend_height(Fill.Viridis.t()) :: non_neg_integer()
  def legend_height(%Fill.Viridis{guide: :none}), do: 0

  def legend_height(%Fill.Viridis{levels: []}), do: 0

  def legend_height(%Fill.Viridis{levels: [_]}), do: 0

  def legend_height(%Fill.Viridis{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
