defmodule GGity.Scale.Shape.Manual do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Shape

  @type t() :: %__MODULE__{}

  defstruct levels: nil,
            transform: nil,
            labels: :waivers,
            guide: :legend,
            values: []

  @spec new(keyword()) :: Shape.Manual.t()
  def new(options) do
    values =
      options
      |> Keyword.get(:values)
      |> set_values()

    options = Keyword.put_new(options, :values, values)
    struct(Shape.Manual, options)
  end

  defp set_values(nil),
    do: raise(ArgumentError, "Manual scales must be passed a :values option with scale values.")

  defp set_values([value | _other_values] = values) when is_binary(value) do
    values
  end

  @spec train(Shape.Manual.t(), list(binary())) :: Shape.Manual.t()
  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    number_of_levels = length(levels)

    palette =
      scale.values
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

    struct(scale, levels: levels, transform: fn value -> values_map[to_string(value)] end)
  end

  @spec draw_legend(Shape.Manual.t(), binary(), number()) :: iolist()
  def draw_legend(%Shape.Manual{guide: :none}, _label, _key_height), do: []

  def draw_legend(%Shape.Manual{levels: []}, _labe, _key_heightl), do: []

  def draw_legend(%Shape.Manual{levels: [_]}, _label, _key_height), do: []

  def draw_legend(%Shape.Manual{levels: levels} = scale, label, key_height) do
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
    marker = scale.transform.(level)

    size =
      case marker do
        character when is_binary(character) -> 7 / 15 * key_height
        _otherwise -> key_height / 3
      end

    [
      Draw.rect(
        x: "0",
        y: "#{key_height * index}",
        height: key_height,
        width: key_height,
        class: "gg-legend-key"
      ),
      GGity.Shapes.draw(
        marker,
        {key_height / 2, key_height / 2 + key_height * index},
        :math.pow(1 + size, 2),
        fill: "black",
        color: "black",
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
