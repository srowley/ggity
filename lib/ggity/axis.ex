defmodule GGity.Axis do
  @moduledoc false

  alias GGity.{Draw, Labels, Plot, Scale}

  @spec draw_x_axis(Plot.t()) :: iolist()
  def draw_x_axis(%Plot{} = plot) do
    [x_ticks(plot), draw_x_label(plot)]
  end

  defp x_ticks(%Plot{scales: scales} = plot) do
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding * 2

    # TODO: This fails to match on a discrete x axis with only one level.
    [first, second] =
      Enum.slice(scales.x.tick_values, 0..1)
      |> Enum.map(scales.x.inverse)

    interval = (second - first) / 2

    scales.x.tick_values
    |> Enum.map(&x_tick(plot, &1, interval))
    |> Draw.g(
      transform: "translate(#{plot.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp x_tick(%Plot{} = plot, value, interval) do
    gridline_length = plot.width / plot.aspect_ratio + plot.area_padding * 2
    coord = plot.scales.x.inverse.(value)
    %scale_type{} = plot.scales.x

    minor_break =
      if scale_type == Scale.X.Discrete do
        []
      else
        Draw.line(
          y2: "-#{gridline_length}",
          stroke: "white",
          stroke_width: "0.5",
          transform: "translate(#{interval}, 0)"
        )
      end

    [
      Draw.line(y2: "-#{gridline_length}", stroke: "white", stroke_width: "1"),
      minor_break,
      Draw.text(Labels.format(plot.scales.x, value),
        fill: "gray",
        y: "9",
        dy: "0.71em",
        dx: "0",
        font_size: "8",
        text_anchor: "middle"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(#{coord},0)")
  end

  defp draw_x_label(%Plot{labels: %{x: nil}}), do: ""

  defp draw_x_label(%Plot{labels: labels} = plot) do
    x_position = (plot.width + plot.area_padding * 2) / 2
    y_position = plot.width / plot.aspect_ratio + plot.area_padding * 2 + 35

    ~s|<text x="#{x_position}" y="#{y_position}" font-size="10" fill="black" text-anchor="middle">#{
      labels.x
    }</text>\n|
  end

  @spec draw_y_axis(Plot.t()) :: iolist()
  def draw_y_axis(%Plot{} = plot) do
    [y_ticks(plot), draw_y_label(plot)]
  end

  defp y_ticks(%Plot{scales: scales} = plot) do
    [first, second] =
      Enum.slice(scales.y.tick_values, 0..1)
      |> Enum.map(scales.y.inverse)

    interval = (second - first) / 2 / plot.aspect_ratio

    scales.y.tick_values
    |> Enum.map(&y_tick(plot, &1, interval))
    |> Draw.g(transform: "translate(0, 0)", font_size: "10", text_anchor: "end")
  end

  defp y_tick(%Plot{} = plot, value, interval) do
    gridline_length = plot.width + plot.area_padding * 2
    top_shift = plot.width / plot.aspect_ratio + plot.area_padding
    coord = plot.scales.y.inverse.(value) / plot.aspect_ratio

    [
      Draw.line(x2: "#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        x2: "#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(0, -#{interval})"
      ),
      Draw.text(Labels.format(plot.scales.y, value),
        fill: "gray",
        x: "-9",
        dy: "0.32em",
        font_size: "8"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end

  defp draw_y_label(%Plot{labels: %{y: nil}}), do: ""

  defp draw_y_label(%Plot{labels: labels} = plot) do
    ~s|<text x="-#{110 / plot.aspect_ratio}" y="-40" font-size="10" fill="black" text-anchor="middle" transform="rotate(-90)">#{
      labels.y
    }</text>\n|
  end
end
