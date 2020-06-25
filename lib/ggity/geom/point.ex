defmodule GGity.Geom.Point do
  @moduledoc false

  alias GGity.{Draw, Geom, Labels, Scale}

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct mapping: nil,
            width: 200,
            aspect_ratio: 1.5,
            x_scale: nil,
            y_scale: nil,
            color_scale: nil,
            size_scale: nil,
            alpha_scale: nil,
            shape_scale: nil,
            labels: %{x: nil, y: nil},
            y_label_padding: 20,
            breaks: 5,
            area_padding: 10

  @spec new(list(record()), mapping(), keyword()) :: Geom.Point.t()
  def new(data, %{x: x_name, y: y_name} = mapping, options \\ []) do
    [x_values, y_values, size_values, alpha_values, color_values, shape_values] =
      data
      |> Enum.map(fn row ->
        {row[x_name], row[y_name], row[mapping[:size]], row[mapping[:alpha]],
         row[mapping[:color]], row[mapping[:shape]]}
      end)
      |> List.zip()
      |> Enum.map(&Tuple.to_list/1)

    fixed_scale_aesthetics = [:color, :size, :alpha, :shape]
    fixed_scales = Keyword.take(options, fixed_scale_aesthetics)

    struct(Geom.Point, Keyword.drop(options, fixed_scale_aesthetics))
    |> struct(%{mapping: mapping})
    |> assign_x_scale(x_values)
    |> assign_y_scale(y_values)
    |> assign_alpha_scale(fixed_scales, alpha_values)
    |> assign_color_scale(fixed_scales, color_values)
    |> assign_shape_scale(fixed_scales, shape_values)
    |> assign_size_scale(fixed_scales, size_values)
  end

  defp assign_x_scale(geom_point, values) do
    scale =
      case hd(values) do
        %Date{} ->
          Scale.X.Date.new(values)

        %date_time{} when date_time in [DateTime, NaiveDateTime] ->
          Scale.X.DateTime.new(values)

        _value ->
          Scale.X.Continuous.new(values)
      end

    %{geom_point | x_scale: scale}
  end

  defp assign_y_scale(geom_point, values) do
    %{geom_point | y_scale: Scale.Y.Continuous.new(values)}
  end

  defp assign_alpha_scale(geom_point, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Alpha.Continuous.new(values)

        Keyword.get(fixed_scales, :alpha) == nil ->
          Scale.Alpha.Manual.new()

        true ->
          Keyword.get(fixed_scales, :alpha)
          |> Scale.Alpha.Manual.new()
      end

    %{geom_point | alpha_scale: scale}
  end

  defp assign_color_scale(geom_point, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Color.Viridis.new(values)

        Keyword.get(fixed_scales, :color) == nil ->
          Scale.Color.Manual.new()

        true ->
          Keyword.get(fixed_scales, :color)
          |> Scale.Color.Manual.new()
      end

    %{geom_point | color_scale: scale}
  end

  defp assign_shape_scale(geom_point, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Shape.new(values)

        Keyword.get(fixed_scales, :shape) == nil ->
          Scale.Shape.Manual.new()

        true ->
          Keyword.get(fixed_scales, :shape)
          |> Scale.Shape.Manual.new()
      end

    %{geom_point | shape_scale: scale}
  end

  defp assign_size_scale(geom_point, fixed_scales, values) do
    scale =
      cond do
        hd(values) != nil ->
          Scale.Size.Continuous.new(values)

        Keyword.get(fixed_scales, :size) == nil ->
          Scale.Size.Manual.new()

        true ->
          Keyword.get(fixed_scales, :size)
          |> Scale.Size.Manual.new()
      end

    %{geom_point | size_scale: scale}
  end

  @spec draw(Geom.Point.t(), list(map())) :: iolist()
  def draw(%Geom.Point{} = geom_point, data) do
    [
      x_axis(geom_point),
      y_axis(geom_point),
      points(geom_point, data)
    ]
  end

  @spec points(Geom.Point.t(), list(map)) :: iolist()
  def points(%Geom.Point{} = geom_point, data) do
    data
    |> Stream.map(fn row ->
      [
        geom_point.x_scale.transform.(row[geom_point.mapping.x]),
        geom_point.y_scale.transform.(row[geom_point.mapping.y]),
        geom_point.color_scale.transform.(row[geom_point.mapping[:color]]),
        geom_point.size_scale.transform.(row[geom_point.mapping[:size]]),
        geom_point.alpha_scale.transform.(row[geom_point.mapping[:alpha]]),
        geom_point.shape_scale.transform.(row[geom_point.mapping[:shape]])
      ]
    end)
    |> Stream.map(fn row -> Enum.zip([:x, :y, :fill, :size, :fill_opacity, :shape], row) end)
    |> Enum.map(fn row ->
      Draw.marker(
        row[:shape],
        {row[:x] + geom_point.area_padding,
         (geom_point.width - row[:y]) / geom_point.aspect_ratio + geom_point.area_padding},
        row[:size],
        Keyword.take(row, [:fill, :fill_opacity])
      )
    end)
  end

  defp x_axis(%Geom.Point{} = geom_point) do
    [
      x_ticks(geom_point),
      draw_x_label(geom_point)
    ]
  end

  defp y_axis(%Geom.Point{} = geom_point) do
    [
      y_ticks(geom_point),
      draw_y_label(geom_point)
    ]
  end

  defp x_ticks(%Geom.Point{x_scale: x_scale} = geom_point) do
    top_shift = geom_point.width / geom_point.aspect_ratio + geom_point.area_padding * 2

    [first, second] =
      Enum.slice(x_scale.tick_values, 0..1)
      |> Enum.map(x_scale.inverse)

    interval = (second - first) / 2

    x_scale.tick_values
    |> Enum.map(&x_tick(geom_point, &1, interval))
    |> Draw.g(
      transform: "translate(#{geom_point.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp draw_x_label(%Geom.Point{labels: %{x: nil}}), do: ""

  defp draw_x_label(%Geom.Point{labels: labels} = geom_point) do
    x_position = (geom_point.width + geom_point.area_padding * 2) / 2
    y_position = geom_point.width / geom_point.aspect_ratio + geom_point.area_padding * 2 + 35

    ~s|<text x="#{x_position}" y="#{y_position}" font-size="10" fill="black" text-anchor="middle">#{
      labels.x
    }</text>\n|
  end

  defp draw_y_label(%Geom.Point{labels: %{y: nil}}), do: ""

  defp draw_y_label(%Geom.Point{labels: labels} = geom_point) do
    ~s|<text x="-#{110 / geom_point.aspect_ratio}" y="-40" font-size="10" fill="black" text-anchor="middle" transform="rotate(-90)">#{
      labels.y
    }</text>\n|
  end

  defp x_tick(%Geom.Point{} = geom_point, value, interval) do
    gridline_length = geom_point.width / geom_point.aspect_ratio + geom_point.area_padding * 2
    coord = geom_point.x_scale.inverse.(value)

    [
      Draw.line(y2: "-#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        y2: "-#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(#{interval}, 0)"
      ),
      Draw.text(Labels.format(geom_point.x_scale, value),
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

  defp y_ticks(%Geom.Point{y_scale: y_scale} = geom_point) do
    [first, second] =
      Enum.slice(y_scale.tick_values, 0..1)
      |> Enum.map(y_scale.inverse)

    interval = (second - first) / 2 / geom_point.aspect_ratio

    y_scale.tick_values
    |> Enum.map(&y_tick(geom_point, &1, interval))
    |> Draw.g(transform: "translate(0, 0)", font_size: "10", text_anchor: "end")
  end

  defp y_tick(%Geom.Point{} = geom_point, value, interval) do
    gridline_length = geom_point.width + geom_point.area_padding * 2
    top_shift = geom_point.width / geom_point.aspect_ratio + geom_point.area_padding
    coord = geom_point.y_scale.inverse.(value) / geom_point.aspect_ratio

    [
      Draw.line(x2: "#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        x2: "#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(0, -#{interval})"
      ),
      Draw.text(Labels.format(geom_point.y_scale, value),
        fill: "gray",
        x: "-9",
        dy: "0.32em",
        font_size: "8"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end
end
