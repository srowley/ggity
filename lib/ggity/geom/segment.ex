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
            size: 1,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Segment.t()
  def new(mapping, options) do
    struct(Geom.Segment, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Segment.t(), list(map()), plot()) :: iolist()
  def draw(%Geom.Segment{} = geom_segment, data, plot), do: segments(geom_segment, data, plot)

  defp segments(%Geom.Segment{} = geom_segment, data, %Plot{scales: scales} = plot) do
    scale_transforms = fetch_scale_transforms(geom_segment.mapping, scales)
    fixed_aesthetics = fetch_fixed_aesthetics(geom_segment)
    all_transforms = Map.merge(fixed_aesthetics, scale_transforms)

    Enum.map(data, fn row -> segment(row, all_transforms, geom_segment, plot) end)
  end

  defp segment(row, transforms, geom_segment, plot) do
    [x, xend, y, yend, stroke_opacity, stroke, stroke_width] = [
      transforms.x.(row[geom_segment.mapping.x]),
      transforms.x.(row[geom_segment.mapping.xend]),
      transforms.y.(row[geom_segment.mapping.y]),
      transforms.y.(row[geom_segment.mapping.yend]),
      transforms.alpha.(row[geom_segment.mapping[:alpha]]),
      transforms.color.(row[geom_segment.mapping[:color]]),
      transforms.size.(row[geom_segment.mapping[:size]])
    ]

    x1 = x + plot.area_padding
    x2 = xend + plot.area_padding
    y1 = (plot.width - y) / plot.aspect_ratio + plot.area_padding
    y2 = (plot.width - yend) / plot.aspect_ratio + plot.area_padding

    custom_attributes = GGity.Layer.custom_attributes(geom_segment, plot, row)

    [
      x1: x1,
      x2: x2,
      y1: y1,
      y2: y2,
      stroke_opacity: stroke_opacity,
      stroke: stroke,
      stroke_width: stroke_width
    ]
    |> Keyword.merge(custom_attributes)
    |> Draw.line()
  end

  defp fetch_scale_transforms(mapping, scales) do
    for aes <- Map.keys(mapping), reduce: %{} do
      scale_transforms -> Map.put(scale_transforms, aes, scales[aes].transform)
    end
  end

  defp fetch_fixed_aesthetics(geom_segment) do
    geom_segment
    |> Map.take([:alpha, :color, :size])
    |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
      Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
  end
end
