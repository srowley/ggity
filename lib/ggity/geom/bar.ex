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
            count_levels: 0,
            bar_padding: 5,
            bar_width: 5,
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
    [x_values, fill_values] =
      data
      |> Enum.map(fn row ->
        {row[x_name], row[mapping[:fill]]}
      end)
      |> List.zip()
      |> Enum.map(&Tuple.to_list/1)

    fixed_scale_aesthetics = [:fill, :alpha]
    fixed_scales = Keyword.take(options, fixed_scale_aesthetics)
    geom_bar = struct(Geom.Bar, Keyword.drop(options, fixed_scale_aesthetics))

    x_levels = Enum.uniq(x_values)
    fill_levels = Enum.uniq(fill_values)

    # TODO: feels like you could get the count in the comprehension
    # but my first efforst failed
    permutations = for x <- x_levels, fill <- fill_levels, do: {x, fill}

    stat_count =
      Enum.reduce(permutations, [], fn {x_value, fill_value}, stat ->
        [
          Map.new([
            {mapping[:x], x_value},
            {mapping[:fill], fill_value},
            {:count,
             Enum.count(data, fn row ->
               {row[mapping[:x]], row[mapping[:fill]]} == {x_value, fill_value}
             end)}
          ])
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)

    count_levels = length(permutations)

    bar_width =
      case geom_bar.position do
        :stack ->
          (geom_bar.width - (length(x_levels) - 1) * geom_bar.bar_padding) / length(x_levels)

        :dodge ->
          (geom_bar.width - (length(x_levels) - 1) * geom_bar.bar_padding) / count_levels
      end

    geom_bar
    |> struct(%{
      mapping: mapping,
      stat_count: stat_count,
      count_levels: count_levels,
      bar_width: bar_width
    })
    |> assign_x_scale(x_values)
    |> assign_y_scale(stat_count)
    |> assign_fill_scale(fixed_scales, fill_values)
  end

  defp assign_x_scale(%Geom.Bar{} = geom_bar, values) do
    %{geom_bar | x_scale: Scale.X.Discrete.new(values)}
  end

  defp assign_y_scale(%Geom.Bar{} = geom_bar, stat) do
    case geom_bar.position do
      :stack ->
        category_max =
          stat
          |> Enum.group_by(fn item -> item[geom_bar.mapping[:x]] end)
          |> Enum.map(fn {_category, values} -> Enum.map(values, fn value -> value.count end) end)
          |> Enum.map(fn counts -> Enum.sum(counts) end)
          |> Enum.max()

        %{geom_bar | y_scale: Scale.Y.Continuous.new([0, category_max])}

      :dodge ->
        %{
          geom_bar
          | y_scale: Scale.Y.Continuous.new([0 | Enum.map(stat, fn row -> row.count end)])
        }
    end
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
    position_transform =
      case geom_bar.position do
        :stack -> &stack/3
        :dodge -> &dodge/3
      end

    geom_bar.stat_count
    |> Enum.group_by(fn item -> item[geom_bar.mapping[:x]] end)
    |> Enum.reduce({0, []}, fn {_group, group_values}, {group_rank, group_data} ->
      {
        group_rank + 1,
        position_transform.(geom_bar, group_values, group_rank) ++ group_data
      }
    end)
    |> elem(1)
    |> Enum.map(fn row ->
      Draw.rect(
        x: row[:x],
        y: (geom_bar.width - row[:y]) / geom_bar.aspect_ratio + geom_bar.area_padding,
        height: row[:y] / geom_bar.aspect_ratio,
        width: geom_bar.bar_width,
        fill: row[:fill]
      )
    end)
  end

  defp stack(geom_bar, group_values, group_rank) do
    group_values
    |> Enum.sort_by(fn row -> row[geom_bar.mapping[:fill]] end)
    |> Enum.reduce({0, []}, fn row, {total_height, data} ->
      {
        total_height + geom_bar.y_scale.transform.(row.count),
        [
          [
            x: geom_bar.area_padding + group_rank * (geom_bar.bar_width + geom_bar.bar_padding),
            y: total_height + geom_bar.y_scale.transform.(row.count),
            fill: geom_bar.fill_scale.transform.(row[geom_bar.mapping[:fill]])
          ]
          | data
        ]
      }
    end)
    |> elem(1)
  end

  defp dodge(geom_bar, group_values, group_rank) do
    group_values
    |> Enum.sort_by(fn row -> row[geom_bar.mapping[:fill]] end)
    |> Enum.reduce({0, []}, fn row, {bar_rank, data} ->
      {
        bar_rank + 1,
        [
          [
            x:
              geom_bar.area_padding + bar_rank * geom_bar.bar_width +
                group_rank * (length(group_values) * geom_bar.bar_width + geom_bar.bar_padding),
            y: geom_bar.y_scale.transform.(row.count),
            fill: geom_bar.fill_scale.transform.(row[geom_bar.mapping[:fill]])
          ]
          | data
        ]
      }
    end)
    |> elem(1)
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
    |> Enum.reduce({0, []}, fn {group, group_values}, {group_rank, group_data} ->
      group_adjustment =
        case geom_bar.position do
          :stack -> 1
          :dodge -> length(group_values)
        end

      {
        group_rank + 1,
        [
          [
            group: group,
            x_coord:
              geom_bar.area_padding + geom_bar.bar_width * group_adjustment * 0.5 +
                group_rank * (geom_bar.bar_width * group_adjustment + geom_bar.bar_padding)
          ]
          | group_data
        ]
      }
    end)
    |> elem(1)
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
