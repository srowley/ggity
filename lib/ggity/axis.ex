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

    plot.scales.x
    |> Labels.format(value)
    |> to_string()
    |> Draw.text(
      [
        y: "#{9 + tick_length}",
        class: "gg-text gg-axis-text gg-axis-text-x"
      ] ++ attributes_for_angle(plot.theme.axis_text_x.angle, tick_length)
    )
    |> Draw.g(opacity: "1", transform: "translate(#{coord},0)")
  end

  defp attributes_for_angle(0, _tick_length) do
    [text_anchor: "middle"]
  end

  defp attributes_for_angle(angle, tick_length) when angle > 0 and angle <= 90 do
    x_adjust = angle / 10 * -1
    y_adjust = (angle - 45) / 15

    [
      text_anchor: "end",
      transform: "translate(#{x_adjust}, #{y_adjust + tick_length}),rotate(-#{angle})"
    ]
  end

  defp attributes_for_angle(_angle, tick_length) do
    attributes_for_angle(0, tick_length)
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
    # MAGIC NUMBERS
    top_padding = 35 + plot.theme.axis_text_x.angle / 90 * 20
    x_position = (plot.width + plot.area_padding * 2) / 2
    y_position = plot.width / plot.aspect_ratio + plot.area_padding * 2 + top_padding

    Draw.text(to_string(labels.x),
      x: x_position,
      y: y_position,
      class: "gg-text gg-axis-title",
      text_anchor: "middle"
    )
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
    transformed_tick_values =
      Enum.slice(scales.y.tick_values, 0..1)
      |> Enum.map(scales.y.inverse)

    interval =
      case transformed_tick_values do
        [_just_one_y_value] ->
          plot.width / plot.aspect_ratio

        [first, second] ->
          (second - first) / 2 / plot.aspect_ratio
      end

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

    plot.scales.y
    |> Labels.format(value)
    |> to_string()
    |> Draw.text(
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
    # MAGIC NUMBERS
    x_position = -1 * (plot.width + plot.area_padding * 2) / 2 / plot.aspect_ratio
    y_position = -40

    Draw.text(to_string(labels.y),
      x: x_position,
      y: y_position,
      class: "gg-text gg-axis-title",
      text_anchor: "middle",
      transform: "rotate(-90)"
    )
  end
end
