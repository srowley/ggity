defmodule GGity.Geom.Line do
  @moduledoc false

  alias GGity.{Draw, Geom, Plot}

  @type t() :: %__MODULE__{}
  @type plot() :: %GGity.Plot{}
  @type record() :: map()
  @type mapping() :: map()

  @linetype_specs %{
    solid: "",
    dashed: "4",
    dotted: "1",
    longdash: "6 2",
    dotdash: "1 2 3 2",
    twodash: "2 2 6 2"
  }

  defstruct data: nil,
            mapping: nil,
            stat: :identity,
            position: :identity,
            key_glyph: :path,
            alpha: 1,
            color: "black",
            linetype: "",
            size: 1

  @spec new(mapping(), keyword()) :: Geom.Line.t()
  def new(mapping, options \\ []) do
    linetype_name = Keyword.get(options, :linetype, :solid)

    options =
      options
      |> Keyword.drop([:linetype])
      |> Keyword.merge(mapping: mapping, linetype: @linetype_specs[linetype_name])

    struct(Geom.Line, options)
  end

  @spec draw(Geom.Line.t(), list(map()), plot()) :: iolist()
  def draw(%Geom.Line{} = geom_line, _data, plot), do: lines(geom_line, plot)

  defp lines(%Geom.Line{} = geom_line, %Plot{} = plot) do
    scale_transforms = scale_transforms_for(geom_line, plot.scales)

    transforms =
      scale_transforms
      |> Map.put(:x, fn row ->
        transform_and_pad_x(row, scale_transforms.x, geom_line.mapping[:x], plot.area_padding)
      end)
      |> Map.put(:y, fn row ->
        transform_and_pad_y(
          row,
          scale_transforms.y,
          geom_line.mapping[:y],
          plot.area_padding,
          plot.aspect_ratio,
          plot.width
        )
      end)

    (geom_line.data || plot.data)
    |> Enum.group_by(fn row ->
      %{
        alpha: row[geom_line.mapping[:alpha]],
        color: row[geom_line.mapping[:color]],
        linetype: row[geom_line.mapping[:linetype]],
        size: row[geom_line.mapping[:size]]
      }
    end)
    |> Enum.map(fn {values, group} -> line(values, group, transforms) end)
  end

  defp scale_transforms_for(geom_line, scales) do
    scale_transforms = fetch_scale_transforms(geom_line.mapping, scales)
    fixed_aesthetics = fetch_fixed_aesthetics(geom_line)
    Map.merge(fixed_aesthetics, scale_transforms)
  end

  defp fetch_scale_transforms(mapping, scales) do
    for aes <- Map.keys(mapping), aes in [:x, :y, :color, :linetype, :size], reduce: %{} do
      scale_transforms -> Map.put(scale_transforms, aes, scales[aes].transform)
    end
  end

  defp fetch_fixed_aesthetics(geom_line) do
    geom_line
    |> Map.take([:alpha, :color, :linetype, :size])
    |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
      Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
  end

  defp transform_and_pad_x(row, x_transform, x_mapping, area_padding) do
    x_transform.(row[x_mapping]) + area_padding
  end

  defp transform_and_pad_y(row, y_transform, y_mapping, area_padding, aspect_ratio, width) do
    (width - y_transform.(row[y_mapping])) / aspect_ratio + area_padding
  end

  defp line(values, data, transforms) do
    coords =
      data
      |> Enum.map(fn row -> {transforms.x.(row), transforms.y.(row)} end)
      |> Enum.sort_by(fn {x, _y} -> x end)

    [alpha, color, linetype, size] = [
      transforms.alpha.(values.alpha),
      transforms.color.(values.color),
      transforms.linetype.(values.linetype),
      transforms.size.(values.size)
    ]

    Draw.polyline(coords, color, size, alpha, linetype)
  end
end
