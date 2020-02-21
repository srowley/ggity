defmodule GGity.Scale.Shape do
  @moduledoc false

  alias GGity.Draw
  alias GGity.Scale.Shape

  @palette [:circle, :square, :diamond, :triangle]

  defstruct transform: nil,
            levels: nil

  @type t() :: %__MODULE__{}

  @spec new(list(any()), keyword()) :: Shape.t()
  def new(values, _options \\ []) do
    levels =
      values
      |> Enum.sort()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.uniq()

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

    struct(Shape, levels: levels, transform: fn value -> values_map[to_string(value)] end)
  end

  @spec draw_legend(Shape.t(), binary()) :: iolist()
  def draw_legend(%Shape{levels: []}, _label), do: []

  def draw_legend(%Shape{levels: [_]}, _label), do: []

  def draw_legend(%Shape{levels: levels} = scale, label) do
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
      |> Enum.map(fn {level, index} -> draw_legend_item(scale.transform, {level, index}) end)
    ]
  end

  defp draw_legend_item(transform, {level, index}) do
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
        transform.(level),
        {7.5, 7.5 + 15 * index},
        5,
        fill: "black",
        fill_opacity: "1"
      ),
      Draw.text(
        "#{level}",
        x: "20",
        y: "#{10 + 15 * index}",
        font_size: "8",
        fill: "black",
        text_anchor: "left"
      )
    ]
  end

  @spec legend_height(Shape.t()) :: non_neg_integer()
  def legend_height(%Shape{levels: []}), do: 0

  def legend_height(%Shape{levels: [_]}), do: 0

  def legend_height(%Shape{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
