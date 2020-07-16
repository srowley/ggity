defmodule GGity.Geom.Point do
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
            key_glyph: :point,
            alpha: 1,
            color: "black",
            shape: :circle,
            size: 4

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

    data
    |> Stream.map(fn row ->
      [
        transforms.x.(row[geom_point.mapping.x]),
        transforms.y.(row[geom_point.mapping.y]),
        transforms.alpha.(row[geom_point.mapping[:alpha]]),
        transforms.color.(row[geom_point.mapping[:color]]),
        transforms.shape.(row[geom_point.mapping[:shape]]),
        transforms.size.(row[geom_point.mapping[:size]])
      ]
    end)
    |> Stream.map(fn row -> Enum.zip([:x, :y, :fill_opacity, :fill, :shape, :size], row) end)
    |> Enum.map(fn row ->
      Draw.marker(
        row[:shape],
        {row[:x] + plot.area_padding,
         (plot.width - row[:y]) / plot.aspect_ratio + plot.area_padding},
        row[:size],
        Keyword.take(row, [:fill, :fill_opacity])
      )
    end)
  end
end
