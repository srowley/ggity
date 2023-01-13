defmodule GGity.Geom.Text do
  @moduledoc false

  alias GGity.{Draw, Geom, Layer, Plot, Scale}

  @hjust_anchor_map %{left: "start", center: "middle", right: "end"}
  @vjust_anchor_map %{top: "baseline", middle: "middle", bottom: "hanging"}

  @type t() :: %__MODULE__{}
  @type plot() :: %Plot{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :identity,
            position: :identity,
            position_vjust: 1,
            group_width: nil,
            group_padding: 5,
            key_glyph: :a,
            alpha: 1,
            color: "black",
            size: 8,
            family: "Helvetica, Arial, sans-serif",
            fontface: "normal",
            hjust: :center,
            vjust: :middle,
            nudge_x: 0,
            nudge_y: 0,
            custom_attributes: nil

  @spec new(mapping(), keyword()) :: Geom.Text.t()
  def new(mapping, options) do
    struct(Geom.Text, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Text.t(), list(map()), Plot.t()) :: iolist()
  def draw(%Geom.Text{} = geom_text, data, %Plot{scales: %{x: %Scale.X.Discrete{}}} = plot) do
    number_of_levels = length(plot.scales.x.levels)
    group_width = (plot.width - number_of_levels * (plot.scales.x.padding - 1)) / number_of_levels
    mapping = Map.new(geom_text.mapping, fn {k, v} -> {k, to_string(v)} end)
    geom_text = struct(geom_text, mapping: mapping, group_width: group_width)
    words(geom_text, data, plot)
  end

  def draw(%Geom.Text{} = geom_text, data, plot) do
    mapping = Map.new(geom_text.mapping, fn {k, v} -> {k, to_string(v)} end)
    geom_text = struct(geom_text, mapping: mapping)
    words(geom_text, data, plot)
  end

  defp words(%Geom.Text{} = geom_text, data, %Plot{scales: %{x: %Scale.X.Discrete{}}} = plot) do
    data
    |> Enum.reject(fn row -> row[geom_text.mapping[:y]] == 0 end)
    |> Enum.group_by(fn row -> row[geom_text.mapping[:x]] end)
    |> Enum.with_index(fn {_x_value, group}, group_index ->
      group(geom_text, group, group_index, plot)
    end)
  end

  defp words(%Geom.Text{} = geom_text, data, %Plot{scales: scales} = plot) do
    transforms = transforms(geom_text, scales)

    Enum.map(data, fn row ->
      row
      |> apply_scale_transform(transforms, geom_text.mapping)
      |> map_to_svg_attributes()
      |> draw_word(geom_text, plot)
    end)
  end

  defp apply_scale_transform(row, transforms, mapping) do
    [
      transforms.x.(row[mapping.x]),
      transforms.y.(row[mapping.y]),
      transforms.label.(row[mapping[:label]]),
      transforms.alpha.(row[mapping[:alpha]]),
      transforms.color.(row[mapping[:color]]),
      transforms.size.(row[mapping[:size]])
    ]
  end

  defp map_to_svg_attributes(row) do
    Enum.zip([:x, :y, :label, :fill_opacity, :fill, :size], row)
  end

  defp draw_word(row, geom_text, plot) do
    Draw.text(
      to_string(row[:label]),
      [
        x: row[:x] + plot.area_padding,
        y: (plot.width - row[:y]) / plot.aspect_ratio + plot.area_padding,
        fill: row[:fill],
        fill_opacity: row[:fill_opacity],
        font_size: "#{row[:size]}px",
        text_anchor: @hjust_anchor_map[geom_text.hjust],
        dominant_baseline: @vjust_anchor_map[geom_text.vjust],
        dx: geom_text.nudge_x,
        dy: -1 * geom_text.nudge_y,
        font_family: geom_text.family,
        font_weight: geom_text.fontface
      ] ++ Layer.custom_attributes(geom_text, plot, row)
    )
  end

  defp group(geom_text, group_values, group_index, %Plot{scales: scales} = plot) do
    transforms = transforms(geom_text, scales)
    count_rows = length(group_values)

    sort_order =
      case geom_text.position do
        :stack -> :desc
        :dodge -> :asc
        _unknown_adjustment -> :asc
      end

    group_values
    |> Enum.sort_by(fn row -> row[plot.mapping[:group]] end, sort_order)
    |> Enum.reduce({count_rows, 0, 0, []}, fn row,
                                              {number_of_groups, total_width, total_height, text} ->
      {
        number_of_groups,
        total_width + geom_text.group_width / count_rows,
        total_height +
          transforms.y.(row[geom_text.mapping[:y]]) / plot.aspect_ratio,
        [
          Draw.text(
            to_string(row[geom_text.mapping[:label]]),
            [
              x:
                position_adjust_x(
                  geom_text,
                  row,
                  group_index,
                  total_width,
                  plot,
                  number_of_groups
                ),
              y:
                plot.area_padding + plot.width / plot.aspect_ratio -
                  position_adjust_y(geom_text, row, total_height, plot),
              fill: geom_text.color,
              fill_opacity: geom_text.alpha,
              font_size: "#{transforms.size.(row[geom_text.mapping[:size]])}pt",
              text_anchor: @hjust_anchor_map[geom_text.hjust],
              dominant_baseline: @vjust_anchor_map[geom_text.vjust],
              dx: geom_text.nudge_x,
              dy: -1 * geom_text.nudge_y,
              font_family: geom_text.family,
              font_weight: geom_text.fontface
            ] ++ Layer.custom_attributes(geom_text, plot, row)
          )
          | text
        ]
      }
    end)
    |> elem(3)
  end

  defp transforms(geom, scales) do
    scale_transforms =
      geom.mapping
      |> Map.keys()
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(scales[aesthetic], :transform))
      end)

    geom
    |> Map.take([:alpha, :color, :shape, :size])
    |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
      Map.put(fixed, aesthetic, fn _value -> fixed_value end)
    end)
    |> Map.merge(scale_transforms)
  end

  defp position_adjust_x(
         %Geom.Text{position: :identity},
         row,
         _group_index,
         _total_width,
         plot,
         _number_of_groups
       ) do
    plot.scales.x.transform.(row[plot.mapping[:x]])
  end

  defp position_adjust_x(
         %Geom.Text{position: :stack} = geom_text,
         _row,
         group_index,
         _total_width,
         plot,
         _number_of_groups
       ) do
    plot.area_padding + geom_text.group_width / 2 +
      group_index * (geom_text.group_width + plot.scales.x.padding)
  end

  defp position_adjust_x(
         %Geom.Text{position: :dodge} = geom_text,
         _row,
         group_index,
         total_width,
         plot,
         number_of_groups
       ) do
    plot.area_padding + geom_text.group_width / 2 / number_of_groups +
      group_index * (geom_text.group_width + plot.scales.x.padding) +
      total_width
  end

  defp position_adjust_y(%Geom.Text{position: :identity} = geom_text, row, _total_height, plot) do
    plot.scales.y.transform.(row[geom_text.mapping[:y]]) / plot.aspect_ratio
  end

  defp position_adjust_y(%Geom.Text{position: :stack} = geom_text, row, total_height, plot) do
    total_height +
      plot.scales.y.transform.(row[geom_text.mapping[:y]]) / plot.aspect_ratio *
        geom_text.position_vjust
  end

  defp position_adjust_y(%Geom.Text{position: :dodge} = geom_text, row, _total_height, plot) do
    plot.scales.y.transform.(row[geom_text.mapping[:y]]) / plot.aspect_ratio *
      geom_text.position_vjust
  end
end
