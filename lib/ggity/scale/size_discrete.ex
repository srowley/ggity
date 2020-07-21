defmodule GGity.Scale.Size.Discrete do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Size

  @palette_min 2
  @palette_max 8
  @palette_range @palette_max - @palette_min

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Size.Discrete.t()
  def new(options \\ []), do: struct(Size.Discrete, options)

  @spec train(Size.Discrete.t(), list(binary())) :: Size.Discrete.t()
  def train(scale, [value] = levels) when is_binary(value) do
    transform = fn _value -> @palette_min + @palette_range / 2 end
    struct(scale, levels: levels, transform: transform)
  end

  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    intervals = length(levels) - 1

    values_map =
      levels
      |> Enum.reverse()
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, @palette_max - index * @palette_range / intervals}
      end)
      |> Enum.into(%{})

    transform = fn value -> values_map[to_string(value)] end
    struct(scale, levels: levels, transform: transform)
  end

  @spec draw_legend(Size.Discrete.t(), binary(), atom()) :: iolist()
  def draw_legend(%Size.Discrete{guide: :none}, _label, _key_glyph), do: []

  def draw_legend(%Size.Discrete{levels: [_]}, _label, _key_glyph), do: []

  def draw_legend(%Size.Discrete{levels: levels} = scale, label, key_glyph) do
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
      Draw.rect(
        x: "0",
        y: "#{15 * index}",
        height: "15",
        width: "15",
        fill: "#eeeeee",
        stroke: "#eeeeee",
        stroke_width: "0.5"
      ),
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

  defp draw_key_glyph(scale, level, index, :a) do
    Draw.text(
      "a",
      x: "7.5",
      y: "#{7.5 + 15 * index}",
      font_size: "#{scale.transform.(level)}pt",
      fill: "black",
      text_anchor: "left"
    )
  end

  defp draw_key_glyph(scale, level, index, _key_glyph) do
    Draw.marker(
      :circle,
      {7.5, 7.5 + 15 * index},
      scale.transform.(level),
      fill: "black",
      fill_opacity: "1"
    )
  end

  @spec legend_height(Size.Discrete.t()) :: non_neg_integer()
  def legend_height(%Size.Discrete{guide: :none}), do: 0

  def legend_height(%Size.Discrete{levels: []}), do: 0

  def legend_height(%Size.Discrete{levels: [_]}), do: 0

  def legend_height(%Size.Discrete{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
