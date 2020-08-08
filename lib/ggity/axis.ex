defmodule GGity.Axis do
  @moduledoc false

  alias GGity.{Draw, Labels, Plot, Scale}

  @spec draw_x_axis(Plot.t()) :: iolist()
  def draw_x_axis(%Plot{} = plot) do
    [x_axis_line(plot), x_ticks(plot), x_gridlines(plot), draw_x_axis_label(plot)]
  end

  defp x_axis_line(%Plot{} = plot) do
    length = plot.width + plot.area_padding * 2
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2

    Draw.line(x2: "#{length}", class: "gg-axis-line gg-axis-line-x")
    |> Draw.g(opacity: "1", transform: "translate(0, #{top_shift})")
  end

  defp x_ticks(%Plot{scales: %{x: %{tick_values: [single_tick | []]}}} = plot) do
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2
    x_tick = draw_x_tick(plot, single_tick)

    Draw.g(x_tick,
      transform: "translate(#{plot.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp x_ticks(%Plot{scales: scales} = plot) do
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2

    scales.x.tick_values
    |> Enum.reverse()
    |> Enum.map(&draw_x_tick(plot, &1))
    |> Draw.g(
      transform: "translate(#{plot.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp x_gridlines(%Plot{scales: %{x: %{tick_values: [single_tick | []]}}} = plot) do
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2
    tick_label = draw_x_tick_label(plot, single_tick)
    major_gridline = draw_x_major_gridline(plot, single_tick)

    Draw.g([tick_label, major_gridline],
      transform: "translate(#{plot.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp x_gridlines(%Plot{scales: scales} = plot) do
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2

    [first, second] =
      Enum.slice(scales.x.tick_values, 0..1)
      |> Enum.map(scales.x.inverse)

    interval = (second - first) / 2

    [_last_tick | all_but_last_tick] = ticks = Enum.reverse(scales.x.tick_values)
    minor_gridlines = Enum.map(all_but_last_tick, &draw_x_minor_gridline(plot, &1, interval))
    tick_labels = Enum.map(ticks, &draw_x_tick_label(plot, &1))
    major_gridlines = Enum.map(ticks, &draw_x_major_gridline(plot, &1))

    Draw.g(
      [tick_labels, major_gridlines, minor_gridlines],
      transform: "translate(#{plot.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp draw_x_tick_label(%Plot{} = plot, value) do
    tick_length = plot.theme.axis_ticks_length_x || plot.theme.axis_ticks_length
    coord = plot.scales.x.inverse.(value)

    Draw.text(Labels.format(plot.scales.x, value),
      y: "#{9 + tick_length}",
      # dy: "0.71em",
      # dx: "0",
      class: "gg-text gg-axis-text gg-axis-text-x"
      # text_anchor: "middle"
    )
    |> Draw.g(opacity: "1", transform: "translate(#{coord},0)")
  end

  defp draw_x_tick(%Plot{} = plot, value) do
    tick_length = plot.theme.axis_ticks_length_x || plot.theme.axis_ticks_length
    coord = plot.scales.x.inverse.(value)

    Draw.line(y2: "#{tick_length}", class: "gg-axis-ticks gg-axis-ticks-x")
    |> Draw.g(opacity: "1", transform: "translate(#{coord},0)")
  end

  defp draw_x_major_gridline(%Plot{} = plot, value) do
    gridline_length = plot.width / plot.aspect_ratio + plot.area_padding * 2
    coord = plot.scales.x.inverse.(value)

    Draw.line(y2: "-#{gridline_length}", class: "gg-panel-grid gg-panel-grid-major")
    |> Draw.g(opacity: "1", transform: "translate(#{coord},0)")
  end

  defp draw_x_minor_gridline(%Plot{} = plot, value, interval) do
    gridline_length = plot.width / plot.aspect_ratio + plot.area_padding * 2
    coord = plot.scales.x.inverse.(value)
    %scale_type{} = plot.scales.x

    gridline =
      if scale_type == Scale.X.Discrete do
        []
      else
        Draw.line(
          y2: "-#{gridline_length}",
          class: "gg-panel-grid gg-panel-grid-minor",
          transform: "translate(#{interval}, 0)"
        )
      end

    Draw.g(gridline, opacity: "1", transform: "translate(#{coord},0)")
  end

  defp draw_x_axis_label(%Plot{labels: %{x: nil}}), do: ""

  defp draw_x_axis_label(%Plot{labels: labels} = plot) do
    x_position = (plot.width + plot.area_padding * 2) / 2
    y_position = plot.width / plot.aspect_ratio + plot.area_padding * 2 + 35

    ~s|<text x="#{x_position}" y="#{y_position}" class="gg-text gg-axis-title" text-anchor="middle">#{
      labels.x
    }</text>\n|
  end

  @spec draw_y_axis(Plot.t()) :: iolist()
  def draw_y_axis(%Plot{} = plot) do
    [y_axis_line(plot), y_ticks(plot), y_gridlines(plot), draw_y_axis_label(plot)]
  end

  defp y_axis_line(%Plot{} = plot) do
    length = plot.width / plot.aspect_ratio + plot.area_padding * 2

    Draw.line(y2: "#{length}", class: "gg-axis-line gg-axis-line-y")
    |> Draw.g(transform: "translate(0, 0)")
  end

  defp y_ticks(%Plot{scales: scales} = plot) do
    scales.y.tick_values
    |> Enum.reverse()
    |> Enum.map(&draw_y_tick(plot, &1))
    |> Draw.g(
      transform: "translate(0, 0)",
      font_size: "10",
      text_anchor: "end"
    )
  end

  defp y_gridlines(%Plot{scales: scales} = plot) do
    [first, second] =
      Enum.slice(scales.y.tick_values, 0..1)
      |> Enum.map(scales.y.inverse)

    interval = (second - first) / 2 / plot.aspect_ratio

    [_last_tick | all_but_last_tick] = ticks = Enum.reverse(scales.y.tick_values)
    minor_gridlines = Enum.map(all_but_last_tick, &draw_y_minor_gridline(plot, &1, interval))
    tick_labels = Enum.map(ticks, &draw_y_tick_label(plot, &1))
    major_gridlines = Enum.map(ticks, &draw_y_major_gridline(plot, &1))

    Draw.g([tick_labels, major_gridlines, minor_gridlines],
      transform: "translate(0, 0)",
      font_size: "10",
      text_anchor: "end"
    )
  end

  defp draw_y_tick_label(%Plot{} = plot, value) do
    tick_length = plot.theme.axis_ticks_length_y || plot.theme.axis_ticks_length
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding
    coord = plot.scales.y.inverse.(value) / plot.aspect_ratio

    Draw.text(Labels.format(plot.scales.y, value),
      x: "-#{9 + tick_length}",
      dy: "0.32em",
      class: "gg-text gg-axis-text gg-axis-text-y"
    )
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end

  defp draw_y_tick(%Plot{} = plot, value) do
    tick_length = plot.theme.axis_ticks_length_y || plot.theme.axis_ticks_length
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding
    coord = plot.scales.y.inverse.(value) / plot.aspect_ratio

    Draw.line(x2: "-#{tick_length}", class: "gg-axis-ticks gg-axis-ticks-y")
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end

  defp draw_y_major_gridline(%Plot{} = plot, value) do
    gridline_length = plot.width + plot.area_padding * 2
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding
    coord = plot.scales.y.inverse.(value) / plot.aspect_ratio

    Draw.line(x2: "#{gridline_length}", class: "gg-panel-grid gg-panel-grid-major")
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end

  defp draw_y_minor_gridline(%Plot{} = plot, value, interval) do
    gridline_length = plot.width + plot.area_padding * 2
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding
    coord = plot.scales.y.inverse.(value) / plot.aspect_ratio

    Draw.line(
      x2: "#{gridline_length}",
      class: "gg-panel-grid gg-panel-grid-minor",
      transform: "translate(0, -#{interval})"
    )
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end

  defp draw_y_axis_label(%Plot{labels: %{y: nil}}), do: ""

  defp draw_y_axis_label(%Plot{labels: labels} = plot) do
    ~s|<text x="-#{110 / plot.aspect_ratio}" y="-40" class= "gg-text gg-axis-title" text-anchor="middle" transform="rotate(-90)">#{
      labels.y
    }</text>\n|
  end
end
