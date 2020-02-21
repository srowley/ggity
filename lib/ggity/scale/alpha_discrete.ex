defmodule GGity.Scale.Alpha.Discrete do
  @moduledoc false

  alias GGity.Draw
  alias GGity.Scale.Alpha

  @palette_min 0.1
  @palette_max 1.0
  @palette_range @palette_max - @palette_min

  defstruct transform: nil,
            levels: nil

  @type t() :: %__MODULE__{}

  @spec new(list(any()), keyword()) :: Alpha.Discrete.t()
  def new(values, options \\ [])

  def new([value], _options) do
    levels = [to_string(value)]
    transform = fn _value -> @palette_min + @palette_range / 2 end
    struct(Alpha.Discrete, levels: levels, transform: transform)
  end

  def new(values, _options) do
    levels =
      values
      |> Stream.map(&Kernel.to_string/1)
      |> Enum.uniq()
      |> Enum.sort()

    intervals = length(levels) - 1

    values_map =
      levels
      |> Enum.reverse()
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, @palette_max - index * @palette_range / intervals}
      end)
      |> Enum.into(%{})

    struct(Alpha.Discrete, levels: levels, transform: fn value -> values_map[to_string(value)] end)
  end

  @spec draw_legend(Alpha.Discrete.t(), binary()) :: iolist()
  def draw_legend(%Alpha.Discrete{levels: []}, _label), do: []

  def draw_legend(%Alpha.Discrete{levels: [_]}, _label), do: []

  def draw_legend(%Alpha.Discrete{levels: levels} = scale, label) do
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
        :circle,
        {7.5, 7.5 + 15 * index},
        5,
        fill: "black",
        fill_opacity: transform.(level)
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

  @spec legend_height(Alpha.Discrete.t()) :: non_neg_integer()
  def legend_height(%Alpha.Discrete{levels: []}), do: 0

  def legend_height(%Alpha.Discrete{levels: [_]}), do: 0

  def legend_height(%Alpha.Discrete{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
