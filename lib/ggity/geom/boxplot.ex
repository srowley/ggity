defmodule GGity.Geom.Boxplot do
  @moduledoc false

  alias GGity.{Draw, Geom, Plot, Shapes}

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :boxplot,
            position: :dodge,
            key_glyph: :boxplot,
            outlier_color: nil,
            outlier_fill: nil,
            outlier_shape: :circle,
            outlier_size: 5,
            color: "black",
            fill: "white",
            alpha: 1,
            box_group_width: nil,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Boxplot.t()
  def new(mapping, options \\ []) do
    struct(Geom.Boxplot, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Boxplot.t(), list(map()), Plot.t()) :: iolist
  def draw(%Geom.Boxplot{} = geom_boxplot, data, plot) do
    number_of_levels = length(plot.scales.x.levels)
    group_width = (plot.width - number_of_levels * (plot.scales.x.padding - 1)) / number_of_levels
    geom_boxplot = struct(geom_boxplot, box_group_width: group_width)
    boxplots(geom_boxplot, data, plot)
  end

  defp boxplots(%Geom.Boxplot{} = geom_boxplot, data, plot) do
    data
    |> Enum.group_by(fn row -> row[geom_boxplot.mapping[:x]] end)
    |> Enum.with_index()
    |> Enum.map(fn {{_x_value, group_values}, group_index} ->
      boxplot_group(geom_boxplot, group_values, group_index, plot)
    end)
  end

  defp boxplot_group(geom_boxplot, group_values, group_index, %Plot{scales: scales} = plot) do
    mapping = geom_boxplot.mapping
    scale_transforms = fetch_scale_transforms(mapping, scales)
    fixed_aesthetics = fetch_fixed_aesthetics(geom_boxplot)
    transforms = Map.merge(fixed_aesthetics, scale_transforms)

    count_rows = length(group_values)

    group_values
    |> Enum.sort_by(
      fn row ->
        {row[mapping[:fill]], row[mapping[:color]], row[mapping[:alpha]]}
      end,
      :asc
    )
    |> Enum.reduce({0, []}, fn row, {total_width, rects} ->
      box_left = position_adjust_x(geom_boxplot, row, group_index, total_width, plot)
      box_width = position_adjust_bar_width(geom_boxplot, count_rows)
      box_right = box_left + box_width
      box_middle = box_left + box_width / 2

      {
        total_width + geom_boxplot.box_group_width / count_rows,
        [
          Draw.rect(
            [
              x: box_left,
              y:
                plot.area_padding + plot.width / plot.aspect_ratio -
                  position_adjust_y(row, plot),
              width: box_width,
              height:
                (transforms.y.(row[:upper]) - transforms.y.(row[:lower])) / plot.aspect_ratio,
              fill: transforms.fill.(row[mapping[:fill]]),
              fill_opacity: transforms.alpha.(row[mapping[:alpha]]),
              stroke: transforms.color.(row[mapping[:color]]),
              stroke_width: 0.5
            ] ++ GGity.Layer.custom_attributes(geom_boxplot, plot, row)
          ),
          draw_median(box_left, box_right, row, transforms, mapping, plot),
          draw_top_whisker(box_middle, row, transforms, mapping, plot),
          draw_bottom_whisker(box_middle, row, transforms, mapping, plot),
          for outlier <- row.outliers do
            draw_outlier(outlier, box_middle, row, geom_boxplot, transforms, plot)
          end
          | rects
        ]
      }
    end)
    |> elem(1)
  end

  defp fetch_scale_transforms(mapping, scales) do
    for aes <- Map.keys(mapping), reduce: %{} do
      scale_transforms -> Map.put(scale_transforms, aes, scales[aes].transform)
    end
  end

  defp fetch_fixed_aesthetics(geom_boxplot) do
    geom_boxplot
    |> Map.take([:alpha, :color, :fill])
    |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
      Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
  end

  defp draw_median(box_left, box_right, row, transforms, mapping, plot) do
    Draw.line(
      x1: box_left,
      x2: box_right,
      y1: transform_and_adjust_y(row, :middle, plot),
      y2: transform_and_adjust_y(row, :middle, plot),
      stroke: transforms.color.(row[mapping[:color]])
    )
  end

  defp draw_top_whisker(box_middle, row, transforms, mapping, plot) do
    Draw.line(
      x1: box_middle,
      x2: box_middle,
      y1: transform_and_adjust_y(row, :upper, plot),
      y2: transform_and_adjust_y(row, :ymax, plot),
      stroke: transforms.color.(row[mapping[:color]]),
      stroke_width: 0.5
    )
  end

  defp draw_bottom_whisker(box_middle, row, transforms, mapping, plot) do
    Draw.line(
      x1: box_middle,
      x2: box_middle,
      y1: transform_and_adjust_y(row, :lower, plot),
      y2: transform_and_adjust_y(row, :ymin, plot),
      stroke: transforms.color.(row[mapping[:color]]),
      stroke_width: 0.5
    )
  end

  defp transform_and_adjust_y(row, aes, plot) do
    plot.area_padding + plot.width / plot.aspect_ratio -
      plot.scales.y.transform.(row[aes]) / plot.aspect_ratio
  end

  defp draw_outlier(value, box_middle, row, geom_boxplot, transforms, plot) do
    y_coord = plot.area_padding + (200 - plot.scales.y.transform.(value)) / plot.aspect_ratio
    fill = geom_boxplot.outlier_fill || transforms.color.(row[geom_boxplot.mapping[:color]])
    color = geom_boxplot.outlier_color || transforms.color.(row[geom_boxplot.mapping[:color]])

    # This will break when we have fillable shapes
    case geom_boxplot.outlier_shape do
      :na ->
        []

      :circle ->
        Shapes.draw(:circle, {box_middle, y_coord}, :math.pow(geom_boxplot.outlier_size, 2),
          fill: fill,
          color: color
        )

      shape ->
        Shapes.draw(shape, {box_middle, y_coord}, :math.pow(geom_boxplot.outlier_size, 2),
          fill: fill,
          color: color
        )
    end
  end

  defp position_adjust_x(
         %Geom.Boxplot{position: :dodge} = geom_boxplot,
         _row,
         group_index,
         total_width,
         plot
       ) do
    plot.area_padding + group_index * (geom_boxplot.box_group_width + plot.scales.x.padding) +
      total_width
  end

  defp position_adjust_y(row, plot) do
    plot.scales.y.transform.(row[:upper]) / plot.aspect_ratio
  end

  defp position_adjust_bar_width(%Geom.Boxplot{position: :dodge} = geom_box, count_rows) do
    geom_box.box_group_width / count_rows
  end
end
