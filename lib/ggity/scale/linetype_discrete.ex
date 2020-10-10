defmodule GGity.Scale.Linetype.Discrete do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Linetype

  @linetype_specs %{
    solid: "",
    dashed: "4",
    dotted: "1",
    longdash: "6 2",
    dotdash: "1 2 3 2",
    twodash: "2 2 6 2"
  }

  @palette [:solid, :dashed, :dotted, :longdash, :dotdash, :twodash]

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Linetype.Discrete.t()
  def new(options \\ []), do: struct(Linetype.Discrete, options)

  @spec train(Linetype.Discrete.t(), list(binary())) :: Linetype.Discrete.t()
  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    number_of_levels = length(levels)

    palette =
      @palette
      |> Stream.cycle()
      |> Enum.take(number_of_levels)
      |> List.to_tuple()

    values_map =
      levels
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, elem(palette, index)}
      end)
      |> Enum.into(%{})

    transform = fn value -> @linetype_specs[values_map[value]] end

    struct(scale, levels: levels, transform: transform)
  end

  @spec draw_legend(Linetype.Discrete.t(), binary(), atom()) :: iolist()
  def draw_legend(%Linetype.Discrete{guide: :none}, _label, _key_glyph), do: []

  def draw_legend(%Linetype.Discrete{levels: [_]}, _label, _key_glyph), do: []

  def draw_legend(%Linetype.Discrete{levels: levels} = scale, label, key_glyph) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      Stream.with_index(levels)
      |> Enum.map(fn {level, index} -> draw_legend_item(scale, {level, index}, key_glyph) end)
    ]
  end

  defp draw_legend_item(scale, {level, index}, key_glyph) do
    [
      Draw.rect(
        x: "0",
        y: "#{15 * index}",
        height: 15,
        width: 15,
        class: "gg-legend-key"
      ),
      draw_key_glyph(scale, level, index, key_glyph),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "20",
        y: "#{10 + 15 * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end

  defp draw_key_glyph(scale, level, index, :path) do
    Draw.line(
      x1: 1,
      y1: 7.5 + 15 * index,
      x2: 14,
      y2: 7.5 + 15 * index,
      stroke: "black",
      stroke_dasharray: "#{scale.transform.(level)}",
      stroke_opacity: "1"
    )
  end

  defp draw_key_glyph(scale, level, index, :timeseries) do
    offset = 15 * index

    Draw.polyline(
      [{1, 14 + offset}, {6, 6 + offset}, {9, 9 + offset}, {14, 1 + offset}],
      "black",
      1,
      1,
      scale.transform.(level)
    )
  end
end
