defmodule GGity.Geom.Bar do
  @moduledoc false

  alias GGity.{Draw, Geom, Labels, Scale}

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct mapping: nil,
            width: 200,
            aspect_ratio: 1.5,
            key_glyph: :rect,
            stat_count: %{},
            bar_padding: 5,
            bar_group_width: nil,
            position: :stack,
            x_scale: nil,
            y_scale: nil,
            fill_scale: nil,
            size_scale: nil,
            alpha_scale: nil,
            labels: %{x: nil, y: nil},
            y_label_padding: 20,
            breaks: 5,
            area_padding: 10

  @spec new(list(record()), mapping(), keyword()) :: Geom.Bar.t()
  def new(data, %{x: x_name} = mapping, options \\ []) do
    [x_values, alpha_values, fill_values] =
      data
      |> Enum.map(fn row ->
        {row[x_name], row[mapping[:alpha]], row[mapping[:fill]]}
      end)
      |> List.zip()
      |> Enum.map(&Tuple.to_list/1)

    fixed_scale_aesthetics = [:fill, :alpha]
    fixed_scales = Keyword.take(options, fixed_scale_aesthetics)
    geom_bar = struct(Geom.Bar, Keyword.drop(options, fixed_scale_aesthetics))

    x_levels = Enum.uniq(x_values)
    fill_levels = Enum.uniq(fill_values)
    alpha_levels = Enum.uniq(alpha_values)

    # TODO: feels like you could get the count in the comprehension
    # but my first efforst failed
    permutations =
      for x <- x_levels, fill <- fill_levels, alpha <- alpha_levels, do: {x, fill, alpha}

    stat_count =
      Enum.reduce(permutations, [], fn {x_value, fill_value, alpha_value}, stat ->
        [
          Map.new([
            {mapping[:x], x_value},
            {mapping[:fill], fill_value},
            {mapping[:alpha], alpha_value},
            {:count,
             Enum.count(data, fn row ->
               {row[mapping[:x]], row[mapping[:fill]], row[mapping[:alpha]]} ==
                 {x_value, fill_value, alpha_value}
             end)}
          ])
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)

    bar_group_width =
      (geom_bar.width - (length(x_levels) - 1) * geom_bar.bar_padding) / length(x_levels)

    geom_bar
    |> struct(%{
      mapping: mapping,
      stat_count: stat_count,
      bar_group_width: bar_group_width
    })
    |> assign_x_scale(x_values)
    |> assign_y_scale(stat_count)
    |> assign_fill_scale(fixed_scales, fill_values)
    |> assign_alpha_scale(fixed_scales, alpha_values)
  end

  defp assign_x_scale(%Geom.Bar{} = geom_bar, values) do
    %{geom_bar | x_scale: Scale.X.Discrete.new(values)}
  end

  defp assign_y_scale(%Geom.Bar{position: :stack} = geom_bar, stat) do
    category_max =
      stat
      |> Enum.group_by(fn item -> item[geom_bar.mapping[:x]] end)
      |> Enum.map(fn {_category, values} -> Enum.map(values, fn value -> value.count end) end)
      |> Enum.map(fn counts -> Enum.sum(counts) end)
      |> Enum.max()

    %{geom_bar | y_scale: Scale.Y.Continuous.new([0, category_max])}
  end

  defp assign_y_scale(%Geom.Bar{position: :dodge} = geom_bar, stat) do
    %{geom_bar | y_scale: Scale.Y.Continuous.new([0 | Enum.map(stat, fn row -> row.count end)])}
  end

  defp assign_alpha_scale(%Geom.Bar{} = geom_bar, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Alpha.Discrete.new(values)

        Keyword.get(fixed_scales, :color) == nil ->
          Scale.Alpha.Manual.new()

        true ->
          Keyword.get(fixed_scales, :color)
          |> Scale.Alpha.Manual.new()
      end

    %{geom_bar | alpha_scale: scale}
  end

  defp assign_fill_scale(%Geom.Bar{} = geom_bar, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Fill.Viridis.new(values)

        Keyword.get(fixed_scales, :color) == nil ->
          Scale.Color.Manual.new()

        true ->
          Keyword.get(fixed_scales, :color)
          |> Scale.Color.Manual.new()
      end

    %{geom_bar | fill_scale: scale}
  end

  @spec draw(Geom.Bar.t(), list(map())) :: iolist()
  def draw(%Geom.Bar{} = geom_bar, _data) do
    [
      x_axis(geom_bar),
      y_axis(geom_bar),
      bars(geom_bar)
    ]
  end

  @spec bars(Geom.Bar.t()) :: iolist()
  def bars(%Geom.Bar{} = geom_bar) do
    geom_bar.stat_count
    |> Enum.reject(fn row -> row.count == 0 end)
    |> Enum.group_by(fn row -> row[geom_bar.mapping[:x]] end)
    |> Enum.with_index()
    |> Enum.map(fn {{_x_value, group}, group_index} -> bar_group(geom_bar, group, group_index) end)
  end

  defp bar_group(geom_bar, group_values, group_index) do
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
        total_height + geom_bar.y_scale.transform.(row.count) / geom_bar.aspect_ratio,
        [
          Draw.rect(
            x: position_adjust_x(geom_bar, row, group_index, total_width),
            y:
              geom_bar.area_padding + geom_bar.width / geom_bar.aspect_ratio -
                position_adjust_y(geom_bar, row, total_height),
            width: position_adjust_bar_width(geom_bar, count_rows),
            height: geom_bar.y_scale.transform.(row.count) / geom_bar.aspect_ratio,
            fill: geom_bar.fill_scale.transform.(row[geom_bar.mapping[:fill]]),
            fill_opacity: geom_bar.alpha_scale.transform.(row[geom_bar.mapping[:alpha]])
          )
          | rects
        ]
      }
    end)
    |> elem(2)
  end

  defp position_adjust_x(%Geom.Bar{position: :stack} = geom_bar, _row, group_index, _total_width) do
    geom_bar.area_padding + group_index * (geom_bar.bar_group_width + geom_bar.bar_padding)
  end

  defp position_adjust_x(%Geom.Bar{position: :dodge} = geom_bar, _row, group_index, total_width) do
    geom_bar.area_padding + group_index * (geom_bar.bar_group_width + geom_bar.bar_padding) +
      total_width
  end

  defp position_adjust_y(%Geom.Bar{position: :stack} = geom_bar, row, total_height) do
    total_height + geom_bar.y_scale.transform.(row.count) / geom_bar.aspect_ratio
  end

  defp position_adjust_y(%Geom.Bar{position: :dodge} = geom_bar, row, _total_height) do
    geom_bar.y_scale.transform.(row.count) / geom_bar.aspect_ratio
  end

  defp position_adjust_bar_width(%Geom.Bar{position: :stack} = geom_bar, _count_rows) do
    geom_bar.bar_group_width
  end

  defp position_adjust_bar_width(%Geom.Bar{position: :dodge} = geom_bar, count_rows) do
    geom_bar.bar_group_width / count_rows
  end

  defp x_axis(%Geom.Bar{} = geom_bar) do
    [
      x_ticks(geom_bar),
      draw_x_label(geom_bar)
    ]
  end

  defp y_axis(%Geom.Bar{} = geom_bar) do
    [
      y_ticks(geom_bar),
      draw_y_label(geom_bar)
    ]
  end

  defp x_ticks(%Geom.Bar{} = geom_bar) do
    top_shift = geom_bar.width / geom_bar.aspect_ratio + geom_bar.area_padding * 2

    geom_bar.stat_count
    |> Enum.group_by(fn row -> row[geom_bar.mapping[:x]] end)
    |> Enum.with_index()
    |> Enum.map(fn {{group, _group_data}, group_rank} ->
      [
        group: group,
        x_coord:
          geom_bar.area_padding + geom_bar.bar_group_width * 0.5 +
            group_rank * (geom_bar.bar_group_width + geom_bar.bar_padding)
      ]
    end)
    |> Enum.map(&x_tick(geom_bar, &1[:group], &1[:x_coord]))
    |> Draw.g(
      transform: "translate(0, #{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp x_tick(%Geom.Bar{} = geom_bar, value, x_coord) do
    gridline_length = geom_bar.width / geom_bar.aspect_ratio + geom_bar.area_padding * 2

    [
      Draw.line(y2: "-#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.text(Labels.format(geom_bar.x_scale, value),
        fill: "gray",
        y: "9",
        dy: "0.71em",
        dx: "0",
        font_size: "8",
        text_anchor: "middle"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(#{x_coord},0)")
  end

  defp draw_x_label(%Geom.Bar{labels: %{x: nil}}), do: ""

  defp draw_x_label(%Geom.Bar{labels: labels} = geom_bar) do
    x_position = (geom_bar.width + geom_bar.area_padding * 2) / 2
    y_position = geom_bar.width / geom_bar.aspect_ratio + geom_bar.area_padding * 2 + 35

    ~s|<text x="#{x_position}" y="#{y_position}" font-size="10" fill="black" text-anchor="middle">#{
      labels.x
    }</text>\n|
  end

  defp draw_y_label(%Geom.Bar{labels: %{y: nil}}), do: ""

  defp draw_y_label(%Geom.Bar{labels: labels} = geom_bar) do
    ~s|<text x="-#{110 / geom_bar.aspect_ratio}" y="-40" font-size="10" fill="black" text-anchor="middle" transform="rotate(-90)">#{
      labels.y
    }</text>\n|
  end

  defp y_ticks(%Geom.Bar{y_scale: y_scale} = geom_bar) do
    [first, second] =
      Enum.slice(y_scale.tick_values, 0..1)
      |> Enum.map(y_scale.inverse)

    interval = (second - first) / 2 / geom_bar.aspect_ratio

    y_scale.tick_values
    |> Enum.map(&y_tick(geom_bar, &1, interval))
    |> Draw.g(transform: "translate(0, 0)", font_size: "10", text_anchor: "end")
  end

  defp y_tick(%Geom.Bar{} = geom_bar, value, interval) do
    gridline_length = geom_bar.width + geom_bar.area_padding * 2
    top_shift = geom_bar.width / geom_bar.aspect_ratio + geom_bar.area_padding
    coord = geom_bar.y_scale.inverse.(value) / geom_bar.aspect_ratio

    [
      Draw.line(x2: "#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        x2: "#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(0, -#{interval})"
      ),
      Draw.text(Labels.format(geom_bar.y_scale, value),
        fill: "gray",
        x: "-9",
        dy: "0.32em",
        font_size: "8"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end
end
