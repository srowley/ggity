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

  @spec lines(Geom.Line.t(), plot()) :: iolist()
  def lines(%Geom.Line{} = geom_line, plot) do
    (geom_line.data || plot.data)
    |> Enum.group_by(fn row ->
      {
        row[geom_line.mapping[:alpha]],
        row[geom_line.mapping[:color]],
        row[geom_line.mapping[:linetype]],
        row[geom_line.mapping[:size]]
      }
    end)
    |> Enum.map(fn {_value, group} -> line(geom_line, group, plot) end)
  end

  defp line(%Geom.Line{} = geom_line, data, %Plot{scales: scales} = plot) do
    scale_transforms =
      geom_line.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    transforms =
      geom_line
      |> Map.take([:alpha, :color, :linetype, :size])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    coords =
      data
      |> sort_by_x(geom_line)
      |> Stream.map(fn row ->
        [
          transforms.x.(row[geom_line.mapping.x]),
          transforms.y.(row[geom_line.mapping.y])
        ]
      end)
      |> Stream.map(fn row -> Map.new(Enum.zip([:x, :y], row)) end)
      |> Stream.map(fn row ->
        Map.put(row, :y, (plot.width - row.y) / plot.aspect_ratio)
      end)
      |> Enum.map(fn row -> {row.x + plot.area_padding, row.y + plot.area_padding} end)

    row = hd(data)

    [alpha, color, linetype, size] = [
      transforms.alpha.(row[geom_line.mapping[:alpha]]),
      transforms.color.(row[geom_line.mapping[:color]]),
      transforms.linetype.(row[geom_line.mapping[:linetype]]),
      transforms.size.(row[geom_line.mapping[:size]])
    ]

    Draw.polyline(coords, color, size, alpha, linetype)
  end

  defp sort_by_x(data, %Geom.Line{} = geom_line) do
    case hd(data)[geom_line.mapping.x] do
      %Date{} ->
        Enum.sort_by(data, fn row -> row[geom_line.mapping.x] end, Date)

      _number ->
        Enum.sort_by(data, fn row -> row[geom_line.mapping.x] end)
    end
  end
end
