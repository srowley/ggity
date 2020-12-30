defmodule GGity.Geom.Rect do
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
            key_glyph: :rect,
            alpha: 1,
            fill: "black",
            color: "black",
            size: 0,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Rect.t()
  def new(mapping, options) do
    struct(Geom.Rect, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Rect.t(), list(map()), plot()) :: iolist()
  def draw(%Geom.Rect{} = geom_rect, data, plot), do: rects(geom_rect, data, plot)

  defp rects(%Geom.Rect{} = geom_rect, data, %Plot{scales: scales} = plot) do
    scale_transforms =
      geom_rect.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    transforms =
      geom_rect
      |> Map.take([:alpha, :color, :fill, :size])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    Enum.map(data, fn row -> rect(row, transforms, geom_rect, plot) end)
  end

  defp rect(row, transforms, geom_rect, plot) do
    transformed_values = [
      transforms.x.(row[geom_rect.mapping.xmin]),
      transforms.x.(row[geom_rect.mapping.xmax]),
      transforms.y.(row[geom_rect.mapping.ymin]),
      transforms.y.(row[geom_rect.mapping.ymax]),
      transforms.alpha.(row[geom_rect.mapping[:alpha]]),
      transforms.color.(row[geom_rect.mapping[:color]]),
      transforms.fill.(row[geom_rect.mapping[:fill]]),
      transforms.size.(row[geom_rect.mapping[:size]])
    ]

    labelled_values =
      Enum.zip(
        [:xmin, :xmax, :ymin, :ymax, :fill_opacity, :stroke, :fill, :stroke_width],
        transformed_values
      )

    options = Keyword.drop(labelled_values, [:xmin, :xmax, :ymin, :ymax])
    x = labelled_values[:xmin] + plot.area_padding
    y = (plot.width - labelled_values[:ymax]) / plot.aspect_ratio + plot.area_padding
    height = (labelled_values[:ymax] - labelled_values[:ymin]) / plot.aspect_ratio
    width = labelled_values[:xmax] - labelled_values[:xmin]

    custom_attributes = GGity.Layer.custom_attributes(geom_rect, plot, row)

    Draw.rect(
      [{:x, x}, {:y, y}, {:height, height}, {:width, width} | options] ++ custom_attributes
    )
  end
end
