defmodule GGity.Geom.Segment do
  @moduledoc false

  alias GGity.{Draw, Geom, Plot}

  @type t() :: %__MODULE__{}
  @type plot() :: %Plot{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :identity,
            position: :identity,
            key_glyph: :line,
            alpha: 1,
            color: "black",
            size: 0,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Segment.t()
  def new(mapping, options) do
    struct(Geom.Segment, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Segment.t(), list(map()), plot()) :: iolist()
  def draw(%Geom.Segment{} = geom_segment, data, plot), do: segments(geom_segment, data, plot)

  defp segments(%Geom.Segment{} = geom_segment, data, %Plot{scales: scales} = plot) do
    scale_transforms =
      geom_segment.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    transforms =
      geom_segment
      |> Map.take([:alpha, :color, :size])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    Enum.map(data, fn row -> segment(row, transforms, geom_segment, plot) end)
  end

  defp segment(row, transforms, geom_segment, plot) do
    transformed_values = [
      transforms.x.(row[geom_segment.mapping.x]),
      transforms.x.(row[geom_segment.mapping.xend]),
      transforms.y.(row[geom_segment.mapping.y]),
      transforms.y.(row[geom_segment.mapping.yend]),
      transforms.alpha.(row[geom_segment.mapping[:alpha]]),
      transforms.color.(row[geom_segment.mapping[:color]]),
      transforms.size.(row[geom_segment.mapping[:size]])
    ]

    labelled_values =
      Enum.zip(
        [:x, :xend, :y, :yend, :stroke_opacity, :stroke, :fill, :stroke_width],
        transformed_values
      )

    options = Keyword.drop(labelled_values, [:x, :xend, :y, :yend])
    x1 = labelled_values[:x] + plot.area_padding
    x2 = labelled_values[:xend] + plot.area_padding
    y1 = (plot.width - labelled_values[:y]) / plot.aspect_ratio + plot.area_padding
    y2 = (plot.width - labelled_values[:yend]) / plot.aspect_ratio + plot.area_padding

    custom_attributes = GGity.Layer.custom_attributes(geom_segment, plot, row)

    Draw.line([{:x1, x1}, {:x2, x2}, {:y1, y1}, {:y2, y2} | options] ++ custom_attributes)
  end
end
