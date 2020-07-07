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
  def new(options \\ []), do: struct(Shape.Manual, options)

  # Note - this is not entirely consistent with the protocol but seems to work anyway
  @spec train(Shape.Manual.t(), binary() | list()) :: Shape.Manual.t()
  def train(scale, shape) when is_binary(shape) do
    train(scale, [String.first(shape)])
  end

  def train(scale, levels) when is_list(levels) do
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
        font_size: "9",
        fill: "black",
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
        height: "15",
        width: "15",
        fill: "#eeeeee",
        stroke: "#eeeeee",
        stroke_width: "0.5"
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
        font_size: "8",
        fill: "black",
        text_anchor: "left"
      )
    ]
  end

  @spec legend_height(Shape.Manual.t()) :: non_neg_integer()
  def legend_height(%Shape.Manual{guide: :none}), do: 0

  def legend_height(%Shape.Manual{levels: []}), do: 0

  def legend_height(%Shape.Manual{levels: [_]}), do: 0

  def legend_height(%Shape.Manual{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
