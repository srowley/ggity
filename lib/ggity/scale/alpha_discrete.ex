defmodule GGity.Scale.Alpha.Discrete do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Alpha

  @palette_min 0.1
  @palette_max 1.0
  @palette_range @palette_max - @palette_min

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :legend

  @type t() :: %__MODULE__{}

  @spec new(keyword()) :: Alpha.Discrete.t()
  def new(options \\ []), do: struct(Alpha.Discrete, options)

  @spec train(Alpha.Discrete.t(), list()) :: Alpha.Discrete.t()
  def train(scale, [_value] = levels) do
    transform = fn _value -> @palette_min + @palette_range / 2 end
    struct(scale, levels: levels, transform: transform)
  end

  def train(scale, levels) do
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

  @spec draw_legend(Alpha.Discrete.t(), binary()) :: iolist()
  def draw_legend(%Alpha.Discrete{guide: :none}, _label), do: []

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
      |> Enum.map(fn {level, index} -> draw_legend_item(scale, {level, index}) end)
    ]
  end

  defp draw_legend_item(scale, {level, index}) do
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
        fill_opacity: scale.transform.(level)
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

  @spec legend_height(Alpha.Discrete.t()) :: non_neg_integer()
  def legend_height(%Alpha.Discrete{guide: :none}), do: 0

  def legend_height(%Alpha.Discrete{levels: []}), do: 0

  def legend_height(%Alpha.Discrete{levels: [_]}), do: 0

  def legend_height(%Alpha.Discrete{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
