defmodule GGity.Geom.Point do
  @moduledoc false

  alias GGity.{Geom, Plot}

  @type t() :: %__MODULE__{}
  @type plot() :: %Plot{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :identity,
            position: :identity,
            key_glyph: :point,
            alpha: 1,
            color: "black",
            shape: :circle,
            size: 6,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Point.t()
  def new(mapping, options) do
    struct(Geom.Point, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Point.t(), list(map()), plot()) :: iolist()
  def draw(%Geom.Point{} = geom_point, data, plot), do: points(geom_point, data, plot)

  defp points(%Geom.Point{} = geom_point, data, %Plot{scales: scales} = plot) do
    scale_transforms =
      geom_point.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    transforms =
      geom_point
      |> Map.take([:alpha, :color, :shape, :size])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    Enum.map(data, fn row -> point(row, transforms, geom_point, plot) end)
  end

  defp point(row, transforms, geom_point, plot) do
    mapping = geom_point.mapping

    custom_attributes = GGity.Layer.custom_attributes(geom_point, plot, row)

    transformed_values = [
      transforms.x.(row[mapping.x]),
      transforms.y.(row[mapping.y]),
      transforms.alpha.(row[mapping[:alpha]]),
      transforms.color.(row[mapping[:color]]),
      transforms.shape.(row[mapping[:shape]]),
      transforms.size.(row[mapping[:size]])
    ]

    labelled_values = Enum.zip([:x, :y, :fill_opacity, :color, :shape, :size], transformed_values)

    GGity.Shapes.draw(
      labelled_values[:shape],
      {labelled_values[:x] + plot.area_padding,
       (plot.width - labelled_values[:y]) / plot.aspect_ratio + plot.area_padding},
      :math.pow(labelled_values[:size], 2),
      Keyword.take(labelled_values, [:color, :fill_opacity]) ++ custom_attributes
    )
  end
end
