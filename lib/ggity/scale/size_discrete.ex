defmodule GGity.Scale.Size.Discrete do
  @moduledoc false

  alias GGity.{Draw, Labels}
  alias GGity.Scale.Size

  @palette_min 2
  @palette_max 8
  @palette_range @palette_max - @palette_min

  defstruct transform: nil,
            levels: nil,
            labels: :waivers

  @type t() :: %__MODULE__{}

  @spec new(list(any()), keyword()) :: Size.Discrete.t()
  def new(values, options \\ [])

  def new([value], options) do
    levels = [to_string(value)]
    transform = fn _value -> @palette_min + @palette_range / 2 end
    struct(Size.Discrete, [{:levels, levels}, {:transform, transform} | options])
  end

  def new(values, options) do
    levels =
      values
      |> Enum.sort()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.uniq()

    intervals = length(levels) - 1

    values_map =
      levels
      |> Enum.reverse()
      |> Stream.with_index()
      |> Stream.map(fn {level, index} ->
        {level, @palette_max - index * @palette_range / intervals}
      end)
      |> Enum.into(%{})

    options = [
      {:levels, levels},
      {:transform, fn value -> values_map[to_string(value)] end} | options
    ]

    struct(Size.Discrete, options)
  end

  @spec draw_legend(Size.Discrete.t(), binary()) :: iolist()
  def draw_legend(%Size.Discrete{levels: []}, _label), do: []

  def draw_legend(%Size.Discrete{levels: [_]}, _label), do: []

  def draw_legend(%Size.Discrete{levels: levels} = scale, label) do
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
        scale.transform.(level),
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

  @spec legend_height(Size.Discrete.t()) :: non_neg_integer()
  def legend_height(%Size.Discrete{levels: []}), do: 0

  def legend_height(%Size.Discrete{levels: [_]}), do: 0

  def legend_height(%Size.Discrete{} = scale) do
    20 + 15 * length(scale.levels)
  end
end
