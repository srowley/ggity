defmodule GGity.Scale.Shape do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Shape

  @palette [:circle, :square, :diamond, :triangle]

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Shape.t()
  def new(options \\ []), do: struct(Shape, options)

  @spec train(Shape.t(), list(binary())) :: Shape.t()
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

    transform = fn value -> values_map[to_string(value)] end
    struct(scale, levels: levels, transform: transform)
  end

  @spec draw_legend(Shape.t(), binary(), number()) :: iolist()
  def draw_legend(%Shape{guide: :none}, _label, _key_height), do: []

  def draw_legend(%Shape{levels: [_]}, _label, _key_height), do: []

  def draw_legend(%Shape{levels: levels} = scale, label, key_height) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      Stream.with_index(levels)
      |> Enum.map(fn {level, index} -> draw_legend_item(scale, {level, index}, key_height) end)
    ]
  end

  defp draw_legend_item(scale, {level, index}, key_height) do
    [
      Draw.rect(
        x: "0",
        y: "#{key_height * index}",
        height: key_height,
        width: key_height,
        class: "gg-legend-key"
      ),
      Draw.marker(
        scale.transform.(level),
        {key_height / 2, key_height / 2 + key_height * index},
        key_height / 3,
        fill: "black",
        fill_opacity: "1"
      ),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "#{5 + key_height}",
        y: "#{10 + key_height * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end
end
