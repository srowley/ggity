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
    scale_transforms = fetch_scale_transforms(geom_point.mapping, scales)
    fixed_aesthetics = fetch_fixed_aesthetics(geom_point)
    all_transforms = Map.merge(fixed_aesthetics, scale_transforms)

    Enum.map(data, fn row -> point(row, all_transforms, geom_point, plot) end)
  end

  defp point(row, transforms, geom_point, plot) do
    mapping = geom_point.mapping

    [x, y, alpha, color, shape, size] = [
      transforms.x.(row[mapping.x]),
      transforms.y.(row[mapping.y]),
      transforms.alpha.(row[mapping[:alpha]]),
      transforms.color.(row[mapping[:color]]),
      transforms.shape.(row[mapping[:shape]]),
      transforms.size.(row[mapping[:size]])
    ]

    adjusted_x = x + plot.area_padding
    adjusted_y = (plot.width - y) / plot.aspect_ratio + plot.area_padding

    custom_attributes = GGity.Layer.custom_attributes(geom_point, plot, row)

    options = [{:color, color}, {:fill_opacity, alpha} | custom_attributes]

    GGity.Shapes.draw(shape, {adjusted_x, adjusted_y}, size, options)
  end

  defp fetch_scale_transforms(mapping, scales) do
    for aes <- Map.keys(mapping), reduce: %{} do
      scale_transforms -> Map.put(scale_transforms, aes, scales[aes].transform)
    end
  end

  defp fetch_fixed_aesthetics(geom_point) do
    geom_point
    |> Map.take([:alpha, :color, :shape, :size])
    |> Enum.reduce(%{}, fn
      {:size, fixed_value}, fixed ->
        Map.put(fixed, :size, fn _value -> :math.pow(fixed_value, 2) end)

      {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
  end
end
