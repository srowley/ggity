defmodule GGity.Geom.Line do
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
            linetype_scale: nil,
            labels: %{x: nil, y: nil},
            y_label_padding: 20,
            breaks: 5,
            area_padding: 10

  @spec new(list(record()), mapping(), keyword()) :: Geom.Line.t()
  def new(data, %{x: x_name, y: y_name} = mapping, options \\ []) do
    [x_values, y_values, _size_values, _alpha_values, _color_values] =
      data
      |> Enum.map(fn row ->
        {row[x_name], row[y_name], row[mapping[:size]], row[mapping[:alpha]],
         row[mapping[:color]]}
      end)
      |> List.zip()
      |> Enum.map(&Tuple.to_list/1)

    fixed_scale_aesthetics = [:color, :size, :alpha, :linetype]
    fixed_scales = Keyword.take(options, fixed_scale_aesthetics)

    struct(Geom.Line, Keyword.drop(options, fixed_scale_aesthetics))
    |> struct(%{mapping: mapping})
    |> assign_x_scale(x_values)
    |> assign_y_scale(y_values)
    |> assign_alpha_scale(fixed_scales)
    |> assign_color_scale(fixed_scales)
    |> assign_linetype_scale(fixed_scales)
    |> assign_size_scale(fixed_scales)
  end

  defp assign_x_scale(geom_line, values) do
    scale =
      case hd(values) do
        %Date{} ->
          Scale.X.Date.new(values)

        %date_time{} when date_time in [DateTime, NaiveDateTime] ->
          Scale.X.DateTime.new(values)

        _value ->
          Scale.X.Continuous.new(values)
      end

    %{geom_line | x_scale: scale}
  end

  defp assign_y_scale(geom_line, values) do
    %{geom_line | y_scale: Scale.Y.Continuous.new(values)}
  end

  defp assign_alpha_scale(geom_line, fixed_scales) do
    scale =
      case Keyword.get(fixed_scales, :alpha) do
        nil ->
          Scale.Alpha.Manual.new()

        alpha ->
          Scale.Alpha.Manual.new(alpha)
      end

    %{geom_line | alpha_scale: scale}
  end

  defp assign_color_scale(geom_line, fixed_scales) do
    scale =
      case Keyword.get(fixed_scales, :color) do
        nil ->
          Scale.Color.Manual.new()

        color ->
          Scale.Color.Manual.new(color)
      end

    %{geom_line | color_scale: scale}
  end

  defp assign_linetype_scale(geom_line, fixed_scales) do
    scale =
      case Keyword.get(fixed_scales, :linetype) do
        nil ->
          Scale.Linetype.Manual.new()

        linetype ->
          Scale.Linetype.Manual.new(linetype)
      end

    %{geom_line | linetype_scale: scale}
  end

  defp assign_size_scale(geom_line, fixed_scales) do
    scale =
      case Keyword.get(fixed_scales, :size) do
        nil ->
          Scale.Size.Manual.new(1)

        size ->
          Scale.Size.Manual.new(size)
      end

    %{geom_line | size_scale: scale}
  end

  @spec draw(Geom.Line.t(), list(map())) :: iolist()
  def draw(%Geom.Line{} = geom_line, data) do
    [
      x_axis(geom_line),
      y_axis(geom_line),
      line(geom_line, data)
    ]
  end

  @spec line(Geom.Line.t(), list(map())) :: iolist()
  def line(%Geom.Line{} = geom_line, data) do
    coords =
      data
      |> sort_by_x(geom_line)
      |> Stream.map(fn row ->
        [
          geom_line.x_scale.transform.(row[geom_line.mapping.x]),
          geom_line.y_scale.transform.(row[geom_line.mapping.y])
        ]
      end)
      |> Stream.map(fn row -> Map.new(Enum.zip([:x, :y], row)) end)
      |> Stream.map(fn row ->
        Map.put(row, :y, (geom_line.width - row.y) / geom_line.aspect_ratio)
      end)
      |> Enum.map(fn row -> {row.x + geom_line.area_padding, row.y + geom_line.area_padding} end)

    {color, size, alpha, linetype} = {
      geom_line.color_scale.transform.(nil),
      geom_line.size_scale.transform.(nil),
      geom_line.alpha_scale.transform.(nil),
      geom_line.linetype_scale.transform.(nil)
    }

    Draw.polyline(coords, color, size, alpha, linetype)
  end

  @spec sort_by_x(list(map()), Geom.Line.t()) :: list(map())
  def sort_by_x(data, %Geom.Line{} = geom_line) do
    case hd(data)[geom_line.mapping.x] do
      %Date{} ->
        Enum.sort_by(data, fn row -> row[geom_line.mapping.x] end, Date)

      _number ->
        Enum.sort_by(data, fn row -> row[geom_line.mapping.x] end)
    end
  end

  defp x_axis(%Geom.Line{} = geom_line) do
    [
      x_ticks(geom_line),
      draw_x_label(geom_line)
    ]
  end

  defp y_axis(%Geom.Line{} = geom_line) do
    [
      y_ticks(geom_line),
      draw_y_label(geom_line)
    ]
  end

  defp x_ticks(%Geom.Line{x_scale: x_scale} = geom_line) do
    top_shift = geom_line.width / geom_line.aspect_ratio + geom_line.area_padding * 2

    [first, second] =
      Enum.slice(x_scale.tick_values, 0..1)
      |> Enum.map(x_scale.inverse)

    interval = (second - first) / 2

    x_scale.tick_values
    |> Enum.map(&x_tick(geom_line, &1, interval))
    |> Draw.g(
      transform: "translate(#{geom_line.area_padding},#{top_shift})",
      font_size: "10",
      text_anchor: "middle"
    )
  end

  defp draw_x_label(%Geom.Line{labels: %{x: nil}}), do: ""

  defp draw_x_label(%Geom.Line{labels: labels} = geom_line) do
    x_position = (geom_line.width + geom_line.area_padding * 2) / 2
    y_position = geom_line.width / geom_line.aspect_ratio + geom_line.area_padding * 2 + 35

    ~s|<text x="#{x_position}" y="#{y_position}" font-size="10" fill="black" text-anchor="middle">#{
      labels.x
    }</text>\n|
  end

  defp draw_y_label(%Geom.Line{labels: %{y: nil}}), do: ""

  defp draw_y_label(%Geom.Line{labels: labels} = geom_line) do
    ~s|<text x="-#{110 / geom_line.aspect_ratio}" y="-40" font-size="10" fill="black" text-anchor="middle" transform="rotate(-90)">#{
      labels.y
    }</text>\n|
  end

  defp x_tick(%Geom.Line{} = geom_line, value, interval) do
    gridline_length = geom_line.width / geom_line.aspect_ratio + geom_line.area_padding * 2
    coord = geom_line.x_scale.inverse.(value)

    [
      Draw.line(y2: "-#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        y2: "-#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(#{interval}, 0)"
      ),
      Draw.text(Labels.format(geom_line.x_scale, value),
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

  defp y_ticks(%Geom.Line{y_scale: y_scale} = geom_line) do
    [first, second] =
      Enum.slice(y_scale.tick_values, 0..1)
      |> Enum.map(y_scale.inverse)

    interval = (second - first) / 2 / geom_line.aspect_ratio

    y_scale.tick_values
    |> Enum.map(&y_tick(geom_line, &1, interval))
    |> Draw.g(transform: "translate(0, 0)", font_size: "10", text_anchor: "end")
  end

  defp y_tick(%Geom.Line{} = geom_line, value, interval) do
    gridline_length = geom_line.width + geom_line.area_padding * 2
    top_shift = geom_line.width / geom_line.aspect_ratio + geom_line.area_padding
    coord = geom_line.y_scale.inverse.(value) / geom_line.aspect_ratio

    [
      Draw.line(x2: "#{gridline_length}", stroke: "white", stroke_width: "1"),
      Draw.line(
        x2: "#{gridline_length}",
        stroke: "white",
        stroke_width: "0.5",
        transform: "translate(0, -#{interval})"
      ),
      Draw.text(Labels.format(geom_line.y_scale, value),
        fill: "gray",
        x: "-9",
        dy: "0.32em",
        font_size: "8"
      )
    ]
    |> Draw.g(opacity: "1", transform: "translate(0,#{top_shift - coord})")
  end
end
