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
    scale_transforms = fetch_scale_transforms(geom_rect.mapping, scales)
    fixed_aesthetics = fetch_fixed_aesthetics(geom_rect)
    transforms = Map.merge(fixed_aesthetics, scale_transforms)

    Enum.map(data, fn row -> rect(row, transforms, geom_rect, plot) end)
  end

  defp fetch_scale_transforms(mapping, scales) do
    for aes <- Map.keys(mapping), reduce: %{} do
      scale_transforms -> Map.put(scale_transforms, aes, scales[aes].transform)
    end
  end

  defp fetch_fixed_aesthetics(geom_rect) do
    geom_rect
    |> Map.take([:alpha, :color, :fill, :size])
    |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
      Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
  end

  defp rect(row, transforms, geom_rect, plot) do
    mapping = geom_rect.mapping

    attributes = [
      x: transforms.x.(row[mapping.xmin]) + plot.area_padding,
      y: (plot.width - transforms.y.(row[mapping.ymax])) / plot.aspect_ratio + plot.area_padding,
      height:
        (transforms.y.(row[mapping.ymax]) - transforms.y.(row[geom_rect.mapping.ymin])) /
          plot.aspect_ratio,
      width: transforms.x.(row[mapping.xmax]) - transforms.x.(row[mapping.xmin]),
      fill_opacity: transforms.alpha.(row[geom_rect.mapping[:alpha]]),
      stroke: transforms.color.(row[geom_rect.mapping[:color]]),
      fill: transforms.fill.(row[geom_rect.mapping[:fill]]),
      stroke_width: transforms.size.(row[geom_rect.mapping[:size]])
    ]

    geom_rect
    |> GGity.Layer.custom_attributes(plot, row)
    |> Keyword.merge(attributes)
    |> Draw.rect()
  end
end
