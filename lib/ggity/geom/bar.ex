defmodule GGity.Geom.Bar do
  @moduledoc false

  alias GGity.{Draw, Geom, Plot}

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :count,
            position: :stack,
            key_glyph: :rect,
            fill: "black",
            alpha: 1,
            bar_padding: 5,
            bar_group_width: nil

  @spec new(mapping(), keyword()) :: Geom.Bar.t()
  def new(mapping, options \\ []) do
    struct(Geom.Bar, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Bar.t(), list(map()), Plot.t()) :: iolist()
  def draw(%Geom.Bar{} = geom_bar, data, plot) do
    geom_bar =
      struct(geom_bar,
        bar_group_width:
          (plot.width - (length(plot.scales.x.levels) - 1) * geom_bar.bar_padding) /
            length(plot.scales.x.levels)
      )

    bars(geom_bar, data, plot)
  end

  defp bars(%Geom.Bar{} = geom_bar, data, plot) do
    data
    |> Enum.reject(fn row -> row[geom_bar.mapping[:y]] == 0 end)
    |> Enum.group_by(fn row -> row[geom_bar.mapping[:x]] end)
    |> Enum.with_index()
    |> Enum.map(fn {{_x_value, group}, group_index} ->
      bar_group(geom_bar, group, group_index, plot)
    end)
  end

  defp bar_group(geom_bar, group_values, group_index, %Plot{scales: scales} = plot) do
    scale_transforms =
      geom_bar.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    transforms =
      geom_bar
      |> Map.take([:alpha, :fill])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    count_rows = length(group_values)

    sort_order =
      case geom_bar.position do
        :stack -> :desc
        :dodge -> :asc
        _unknown_adjustment -> :asc
      end

    group_values
    |> Enum.sort_by(fn row -> row[geom_bar.mapping[:fill]] end, sort_order)
    |> Enum.reduce({0, 0, []}, fn row, {total_width, total_height, rects} ->
      {
        total_width + geom_bar.bar_group_width / count_rows,
        total_height +
          transforms.y.(row[geom_bar.mapping[:y]]) / plot.aspect_ratio,
        [
          Draw.rect(
            x: position_adjust_x(geom_bar, row, group_index, total_width, plot),
            y:
              plot.area_padding + plot.width / plot.aspect_ratio -
                position_adjust_y(geom_bar, row, total_height, plot),
            width: position_adjust_bar_width(geom_bar, count_rows),
            height: transforms.y.(row[geom_bar.mapping[:y]]) / plot.aspect_ratio,
            fill: transforms.fill.(row[geom_bar.mapping[:fill]]),
            fill_opacity: transforms.alpha.(row[geom_bar.mapping[:alpha]])
          )
          | rects
        ]
      }
    end)
    |> elem(2)
  end

  defp position_adjust_x(
         %Geom.Bar{position: :stack} = geom_bar,
         _row,
         group_index,
         _total_width,
         plot
       ) do
    plot.area_padding + group_index * (geom_bar.bar_group_width + geom_bar.bar_padding)
  end

  defp position_adjust_x(
         %Geom.Bar{position: :dodge} = geom_bar,
         _row,
         group_index,
         total_width,
         plot
       ) do
    plot.area_padding + group_index * (geom_bar.bar_group_width + geom_bar.bar_padding) +
      total_width
  end

  defp position_adjust_y(%Geom.Bar{position: :stack} = geom_bar, row, total_height, plot) do
    total_height + plot.scales.y.transform.(row[geom_bar.mapping[:y]]) / plot.aspect_ratio
  end

  defp position_adjust_y(%Geom.Bar{position: :dodge} = geom_bar, row, _total_height, plot) do
    plot.scales.y.transform.(row[geom_bar.mapping[:y]]) / plot.aspect_ratio
  end

  defp position_adjust_bar_width(%Geom.Bar{position: :stack} = geom_bar, _count_rows) do
    geom_bar.bar_group_width
  end

  defp position_adjust_bar_width(%Geom.Bar{position: :dodge} = geom_bar, count_rows) do
    geom_bar.bar_group_width / count_rows
  end
end
