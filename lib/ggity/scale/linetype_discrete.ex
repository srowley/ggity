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

  @spec draw_legend(Linetype.Discrete.t(), binary(), atom(), number()) :: iolist()
  def draw_legend(%Linetype.Discrete{guide: :none}, _label, _key_glyph, _key_height), do: []

  def draw_legend(%Linetype.Discrete{levels: [_]}, _label, _key_glyph, _key_height), do: []

  def draw_legend(%Linetype.Discrete{levels: levels} = scale, label, key_glyph, key_height) do
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
        x: "#{key_height + 5}",
        y: "#{10 + key_height * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end

  defp draw_key_glyph(scale, level, index, :path, key_height) do
    Draw.line(
      x1: 1,
      y1: key_height / 2 + key_height * index,
      x2: key_height - 1,
      y2: key_height / 2 + key_height * index,
      stroke: "black",
      stroke_dasharray: "#{scale.transform.(level)}",
      stroke_opacity: "1"
    )
  end

  defp draw_key_glyph(scale, level, index, :timeseries, key_height) do
    offset = key_height * index

    Draw.polyline(
      [
        {1, key_height - 1 + offset},
        {key_height / 5 * 2, key_height / 5 * 2 + offset},
        {key_height / 5 * 3, key_height / 5 * 3 + offset},
        {key_height - 1, 1 + offset}
      ],
      "black",
      1,
      1,
      scale.transform.(level)
    )
  end
end
