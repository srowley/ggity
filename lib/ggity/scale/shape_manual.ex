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

  @spec draw_legend(Shape.Manual.t(), binary()) :: iolist()
  def draw_legend(%Shape.Manual{guide: :none}, _label), do: []

  def draw_legend(%Shape.Manual{levels: []}, _label), do: []

  def draw_legend(%Shape.Manual{levels: [_]}, _label), do: []

  def draw_legend(%Shape.Manual{levels: levels} = scale, label) do
    [
      Draw.text(
        "#{label}",
        x: "0",
        y: "-5",
        class: "gg-text gg-legend-title",
        text_anchor: "left"
      ),
      Stream.with_index(levels)
      |> Enum.map(fn {level, index} -> draw_legend_item(scale, {level, index}) end)
    ]
  end

  defp draw_legend_item(scale, {level, index}) do
    marker = scale.transform.(level)

    size =
      case marker do
        character when is_binary(character) -> 7
        _otherwise -> 5
      end

    [
      Draw.rect(
        x: "0",
        y: "#{15 * index}",
        height: 15,
        width: 15,
        class: "gg-legend-key"
      ),
      Draw.marker(
        marker,
        {7.5, 7.5 + 15 * index},
        size,
        fill: "black",
        fill_opacity: "1"
      ),
      Draw.text(
        "#{Labels.format(scale, level)}",
        x: "20",
        y: "#{10 + 15 * index}",
        class: "gg-text gg-legend-text",
        text_anchor: "left"
      )
    ]
  end
end
