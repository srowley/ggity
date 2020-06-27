defmodule GGity.Scale.Shape.Manual do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Shape

  @default_shape :circle
  @valid_shapes [:circle, :square, :diamond, :triangle]

  @type t() :: %__MODULE__{}

  defstruct levels: nil,
            transform: nil,
            labels: :waivers,
            guide: :legend

  @spec new(atom() | binary()) :: Shape.Manual.t()
  def new(shape \\ @default_shape)

  def new(shape) when shape in @valid_shapes do
    struct(Shape.Manual, levels: [], transform: fn _shape -> shape end)
  end

  def new(shape) when is_binary(shape) do
    struct(Shape.Manual, transform: fn _shape -> String.first(shape) end)
  end

  @spec new(list(), keyword()) :: Shape.Manual.t()
  def new(values, options) when is_list(values) do
    levels =
      Enum.map(values, &to_string/1)
      |> Enum.uniq()
      |> Enum.sort()

    number_of_levels = length(levels)

    palette =
      Keyword.get(options, :values)
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

    options = [
      {:levels, levels},
      {:transform, fn value -> values_map[to_string(value)] end}
    ]

    struct(Shape.Manual, options)
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
