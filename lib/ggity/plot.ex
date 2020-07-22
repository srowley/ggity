defmodule GGity.Plot do
  @moduledoc """
  Configures and generates an iolist representing an SVG plot.

  The Plot module is GGity's public interface. A Plot struct is created
  with `new/3`, specifying the data and aesthetic mappings to be used,
  along with options associated with the plot's general appearance.

  Data must be provided as a list of maps, where each map in the list
  represents an observation, and the map's keys represent variable names.
  GGity does not perform any validation of the data; data is assumed to be
  clean and not to have missing values.

  ```
    Examples.mtcars()
    |> Plot.new(%{x: :wt, y: :mpg})
  ```

  Mappings are specified using maps, where the map's keys are the names
  of supported aesthetics, and the values are the names of variables in
  the data. The mapping must include assignments for the `:x` and `:y`
  aesthetics.

  ```
    Examples.mtcars()
    |> Plot.new(%{x: :wt, y: :mpg})
    |> Plot.geom_point()
  ```

  A geom struct (GGity supports points and lines in this version) is added
  to the plot using using `geom_point/3` or `geom_line/3`. The
  geom struct contains the scales for each variable assigned to an aesthetic.
  Scales generate functions that transform data into an aesthetic value (e.g,
  an x coordinate or a color) and functions that transform an aesthetic value
  back into an observation (for the purpose of drawing axes or legends).integer()

  Each geom uses default scales, but these can be overridden by passing the Plot
  struct to `scale[scale_type]/2`. With respect to x values, GGity will
  try to guess if the data is numeric or date/datetime-typed and assign a
  scale accordingly.

  ```
    Examples.mtcars()
    |> Plot.new(%{x: :wt, y: :mpg})
    |> Plot.geom_point()
    |> Plot.plot()
  ```

  `plot/1` generates an iolist that represents the plot. None of the data
  is sanitized, so users will need to be mindful of the risks of generating
  plots using user-supplied data or parameters.
  """

  alias __MODULE__
  alias GGity.{Axis, Draw, Geom, Layer, Legend, Scale, Stat}

  @type t() :: %__MODULE__{}
  @type column() :: list()
  @type name() :: binary() | atom()
  @type record() :: map()
  @type mapping() :: map()
  @type options() :: keyword()

  @continuous_scales [
    Scale.Alpha.Continuous,
    Scale.Size.Continuous,
    Scale.X.Continuous,
    Scale.X.Date,
    Scale.X.DateTime,
    Scale.Y.Continuous
  ]

  defstruct data: [],
            mapping: %{},
            width: 200,
            aspect_ratio: 1.5,
            plot_width: 500,
            layers: [%Geom.Blank{}],
            scales: %{},
            limits: %{x: {nil, nil}, y: {nil, nil}},
            labels: %{title: nil, x: nil, y: nil},
            y_label_padding: 20,
            breaks: 5,
            area_padding: 10,
            panel_background_color: "#eeeeee",
            margins: %{left: 30, top: 10, right: 0, bottom: 0}

  @doc """
  Generates a Plot struct with provided data and aesthetic mappings.

  `data` must be passed in the form of a list of maps, where each map represents
  an observation or record, the map keys are variable names, and the map values
  represent the measurement of that variable for that observation.integer()

  Mappings tie variables to aesthetics, i.e. visual characteristics of the plot.
  A mapping is specified using a map, with key-value pairs representing the assignment of
  variables to available aesthetics. Mappings passed to `new/3` must include key-value
  pairs for the `:x` aesthetic and the `:y` aesthetic.

  `new/3` also supports several options that shortcut plot creation or alter the
  appearance of the plot. All graphical size units are in pixels.

  * `:width` - the width of the plot area. Defaults to `200`.

  * `:plot_width` - the width of the SVG inclusive of axes and legends. Defaults to `500.`

  * `:aspect_ratio` - the ratio of the plot area height to `:width`. Defaults to `1.5.`

  * `:labels` - a map specifying the titles of the plot (`:title`), x and y-axes
  (`:x` and `:y`) or legend title for another aesthetic (e.g. `:color`).

  * `:panel_background_color` - a string value (hex or CSS color name) for the panel background.
  Defaults to grey (`#eeeeee`)

  * `:margins` - a map with keys `:left`, `:top`, `:right` and `:bottom`, specifying the
  plot margins. Default is `%{left: 30, top: 10, right: 0, bottom: 0}`.
  """
  @spec new(list(record()), mapping(), keyword()) :: Plot.t()
  def new([first_row | _rest] = data, mapping \\ %{}, options \\ []) do
    scales = assign_scales(mapping, first_row)

    Plot
    |> struct(options)
    |> struct(data: data, mapping: mapping, scales: scales)
  end

  defp assign_scales(mapping, record) do
    mapping
    |> Map.keys()
    |> Enum.reduce(%{}, fn aesthetic, scale_map ->
      Map.put(scale_map, aesthetic, assign_scale(aesthetic, record[mapping[aesthetic]]))
    end)
  end

  defp assign_scale(:alpha, value) when is_number(value) do
    Scale.Alpha.Continuous.new()
  end

  defp assign_scale(:alpha, _value), do: Scale.Alpha.Discrete.new()

  defp assign_scale(:color, _value), do: Scale.Color.Viridis.new()

  defp assign_scale(:fill, _value), do: Scale.Fill.Viridis.new()

  defp assign_scale(:linetype, _value), do: Scale.Linetype.Discrete.new()

  defp assign_scale(:shape, _value), do: Scale.Shape.new()

  defp assign_scale(:size, value) when is_number(value) do
    Scale.Size.Continuous.new()
  end

  defp assign_scale(:size, _value), do: Scale.Size.Discrete.new()

  defp assign_scale(:x, %Date{}), do: Scale.X.Date.new()

  defp assign_scale(:x, %DateTime{}), do: Scale.X.DateTime.new()

  defp assign_scale(:x, value) when is_number(value) do
    Scale.X.Continuous.new()
  end

  defp assign_scale(:x, _value), do: Scale.X.Discrete.new()

  defp assign_scale(:y, _value), do: Scale.Y.Continuous.new()

  defp assign_scale(other, _value), do: Scale.Identity.new(other)

  @doc """
  Generates an iolist of SVG markup representing a `Plot`.

  The data is not sanitized; users should be mindful of the risks of generating a plot
  with user-defined data and parameters.

  The `Plot` struct's `:plot_width` and `:aspect_ratio` values are used to set the height
  and width properties of the SVG. The viewBox property is set by the plot's `:width` and
  `:aspect_ratio` values.
  """
  @spec plot(Plot.t()) :: iolist()
  def plot(%Plot{} = plot) do
    plot
    |> map_aesthetics()
    |> apply_stats()
    |> provide_default_axis_labels()
    |> train_scales()
    |> render()
  end

  defp map_aesthetics(%Plot{} = plot) do
    layers =
      Enum.map(plot.layers, fn layer ->
        struct(layer, mapping: Map.merge(plot.mapping, layer.mapping || %{}))
      end)

    struct(plot, layers: layers)
  end

  defp apply_stats(%Plot{} = plot) do
    layers =
      Enum.map(plot.layers, fn layer ->
        {data, mapping} = apply(Stat, layer.stat, [layer.data || plot.data, layer.mapping])
        struct(layer, data: data, mapping: mapping)
      end)

    struct(plot, layers: layers)
  end

  defp provide_default_axis_labels(%Plot{} = plot) do
    [x_label, y_label] =
      plot.layers
      |> hd()
      |> Map.get(:mapping)
      |> Map.take([:x, :y])
      |> Map.values()

    labels = %{title: plot.labels.title, x: plot.labels.x || x_label, y: plot.labels.y || y_label}
    struct(plot, labels: labels)
  end

  defp train_scales(%Plot{} = plot) do
    plot
    |> all_mapped_aesthetics()
    |> train_scales(plot)
  end

  defp all_mapped_aesthetics(%Plot{} = plot) do
    plot.layers
    |> Enum.flat_map(fn layer -> Map.keys(layer.mapping) end)
    |> Enum.uniq()
  end

  defp train_scales(aesthetics, %Plot{} = plot) do
    scales =
      Enum.reduce(aesthetics, %{}, fn aesthetic, scales_map ->
        Map.put(scales_map, aesthetic, train_scale(aesthetic, plot))
      end)

    struct(plot, scales: scales)
  end

  defp train_scale(aesthetic, plot) do
    sample_layer =
      plot.layers
      |> Enum.filter(fn layer -> layer.mapping[aesthetic] end)
      |> hd()

    sample_value = hd(sample_layer.data)[sample_layer.mapping[aesthetic]]

    scale = plot.scales[aesthetic] || assign_scale(aesthetic, sample_value)
    global_parameters = global_parameters(aesthetic, plot, scale)
    Scale.train(scale, global_parameters)
  end

  defp global_parameters(aesthetic, plot, %scale_type{}) when scale_type in @continuous_scales do
    {fixed_min, fixed_max} = plot.limits[aesthetic] || {nil, nil}

    plot.layers
    |> Enum.filter(fn layer -> layer.mapping[aesthetic] end)
    |> Enum.map(fn layer -> layer_min_max(aesthetic, layer) end)
    |> Enum.reduce({fixed_min, fixed_max}, fn {layer_min, layer_max}, {global_min, global_max} ->
      {min(fixed_min || layer_min, global_min || layer_min),
       max(fixed_max || layer_max, global_max || layer_max)}
    end)
  end

  defp global_parameters(aesthetic, plot, _sample_value) do
    plot.layers
    |> Enum.filter(fn layer -> layer.mapping[aesthetic] end)
    |> Enum.reduce(MapSet.new(), fn layer, levels ->
      MapSet.union(levels, layer_value_set(aesthetic, layer))
    end)
    |> Enum.sort()
  end

  defp layer_min_max(aesthetic, layer) do
    layer.data
    |> Enum.map(fn row -> row[layer.mapping[aesthetic]] end)
    |> min_max()
  end

  defp layer_value_set(aesthetic, layer) do
    layer.data
    |> Enum.map(fn row -> row[layer.mapping[aesthetic]] end)
    |> Enum.map(&Kernel.to_string/1)
    |> MapSet.new()
  end

  defp min_max([]), do: raise(Enum.EmptyError)

  defp min_max([single_value]), do: {single_value, single_value}

  defp min_max([%date_type{} | _rest] = dates) when date_type in [DateTime, NaiveDateTime] do
    {Enum.min_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end),
     Enum.max_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end)}
  end

  defp min_max(list), do: Enum.min_max(list)

  defp render(%Plot{} = plot) do
    viewbox_width = plot.width * 7 / 4

    [
      draw_background(plot),
      draw_x_axis(plot),
      draw_y_axis(plot),
      draw_layers(plot),
      draw_title(plot),
      draw_legend_group(plot)
    ]
    |> Draw.svg(
      width: to_string(plot.plot_width),
      height: to_string(plot.plot_width / plot.aspect_ratio),
      viewBox: "0 0 #{viewbox_width} #{viewbox_width / plot.aspect_ratio}",
      font_family: "Helvetica, Arial, sans-serif"
    )
  end

  defp draw_background(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)

    Draw.rect(
      x: "0",
      y: "0",
      height: to_string(plot.width / plot.aspect_ratio + plot.area_padding * 2),
      width: to_string(plot.width + plot.area_padding * 2),
      fill: plot.panel_background_color
    )
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp title_margin(%Plot{labels: %{title: title}}) when is_binary(title), do: 10

  defp title_margin(%Plot{}), do: 0

  defp draw_x_axis(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)

    Axis.draw_x_axis(plot)
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_y_axis(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)

    Axis.draw_y_axis(plot)
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_layers(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)

    plot.layers
    |> Enum.reverse()
    |> Enum.map(fn layer -> Layer.draw(layer, layer.data, plot) end)
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_title(%Plot{labels: %{title: title}}) when not is_binary(title), do: ""

  defp draw_title(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)

    plot.labels.title
    |> Draw.text(
      x: "0",
      y: "-15",
      dy: "0.71em",
      dx: "0",
      font_size: "12"
    )
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_legend_group(plot) do
    {legend_group, legend_group_height} =
      Enum.reduce(
        [:color, :fill, :linetype, :shape, :size, :alpha],
        {[], 0},
        fn aesthetic, {legends, offset_acc} ->
          {[draw_legend(plot, aesthetic, offset_acc) | legends],
           offset_acc + Legend.legend_height(Map.get(plot.scales, aesthetic))}
        end
      )

    left_shift = plot.margins.left + plot.y_label_padding + plot.width + 25

    top_shift =
      plot.margins.top + title_margin(plot) + plot.width / plot.aspect_ratio / 2 + 10 -
        legend_group_height / 2 + 10

    Draw.g(legend_group, transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_legend(%Plot{} = plot, aesthetic, offset) do
    scale = Map.get(plot.scales, aesthetic)
    label = plot.labels[aesthetic]
    key_glyph = key_glyph(plot, aesthetic)

    case Legend.legend_height(scale) do
      0 ->
        []

      _positive ->
        Legend.draw_legend(scale, label, key_glyph)
        |> Draw.g(transform: "translate(0, #{offset})")
    end
  end

  defp key_glyph(plot, aesthetic) do
    layers =
      plot.layers
      |> Enum.filter(fn layer -> aesthetic in Map.keys(layer.mapping || %{}) end)

    case layers do
      [] -> hd(plot.layers).key_glyph
      [first | _rest] -> first.key_glyph
    end
  end

  @doc """
  Adds a point geom to the plot.

  Accepts a mapping and/or additonal options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings.

  Point geoms support the following aesthetics, which use the noted default scales:

  * `:x` (required - continuous number/`Date`/`DateTime` scale based on type of value in first record)
  * `:y` (required) - continuous (must be a number)
  * `:alpha` - continuous
  * `:color` - discrete (viridis palette)
  * `:shape` - discrete
  * `:size` - continuous

  Fixed values for aesthetics can also be specified as options, e.g., `color: "blue"`.
  This fixed value is assigned to the aesthetic for all observations.

  Other supported options:

  * `:area_padding` - amount of blank space before the first tick and after the last
  tick on each axis (same value applied to both axes) defaults to `10`.
  * `:breaks` - the number of tick intervals on the x- and y axis (same value applied
  to both axes). This may be adjusted by the scale function based on the data. Defaults to `5`.
  * `:key_glyph` - Type of glyph to use in the legend key. currently only supported for the
  `:color` aesthetic. Available values are `:point`, `:path` and `:timeseries`; defaults to `:point`.
  * `:y_label_padding` - vertical distance between the y axis and its label. Defaults to `20`.
  """
  @spec geom_point(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_point(plot, mapping \\ [], options \\ [])

  def geom_point(%Plot{} = plot, [], []) do
    add_geom(plot, Geom.Point)
  end

  def geom_point(%Plot{} = plot, mapping_or_options, []) do
    add_geom(plot, Geom.Point, mapping_or_options)
  end

  def geom_point(%Plot{} = plot, mapping, options) do
    add_geom(plot, Geom.Point, mapping, options)
  end

  @spec geom_text(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_text(plot, mapping \\ [], options \\ [])

  def geom_text(%Plot{} = plot, [], []) do
    updated_plot = add_geom(plot, Geom.Text)
    geom = hd(updated_plot.layers)

    scale_adjustment =
      case geom.position do
        :stack -> {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
        _other_positions -> plot.limits.y
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  def geom_text(%Plot{} = plot, mapping_or_options, []) do
    updated_plot = add_geom(plot, Geom.Text, mapping_or_options)
    geom = hd(updated_plot.layers)

    {data, mapping} = apply(Stat, geom.stat, [updated_plot.data, updated_plot.mapping])

    fixed_max =
      data
      |> Enum.group_by(fn item -> item[mapping[:x]] end)
      |> Enum.map(fn {_category, values} ->
        Enum.map(values, fn value -> value[mapping[:y]] end)
      end)
      |> Enum.map(fn counts -> Enum.sum(counts) end)
      |> Enum.max()

    scale_adjustment =
      case geom.position do
        :stack ->
          {min(0, elem(plot.limits.y, 0) || 0),
           max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

        _other_positions ->
          plot.limits.y
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  def geom_text(%Plot{} = plot, mapping, options) do
    updated_plot = add_geom(plot, Geom.Text, mapping, options)
    geom = hd(updated_plot.layers)

    {data, mapping} =
      apply(Stat, geom.stat, [updated_plot.data, Map.merge(updated_plot.mapping, mapping)])

    fixed_max =
      data
      |> Enum.group_by(fn item -> item[mapping[:x]] end)
      |> Enum.map(fn {_category, values} ->
        Enum.map(values, fn value -> value[mapping[:y]] end)
      end)
      |> Enum.map(fn counts -> Enum.sum(counts) end)
      |> Enum.max()

    scale_adjustment =
      case geom.position do
        :stack ->
          {min(0, elem(plot.limits.y, 0) || 0),
           max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

        _other_positions ->
          plot.limits.y
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  @doc """
  Adds a line geom to the plot.

  Accepts a mapping and/or additonal options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings.

  By default, the `:x` aesthetic will use continuous number/`Date`/`DateTime`
  scales based on the type of value in first record.

  Note that the line geom sorts the data by the values for the variable mapped
  to the `:x` aesthetic using Erlang default term ordering.

  Supported aesthetics include:

  * `:alpha`
  * `:color`
  * `:size`
  * `:linetype`

  The `:linetype` and `:color` aesthetics can be mapped to a variable. Only fixed values
  can be assigned to `:alpha` and `:size`.

  Other supported options:

  * `:area_padding` - amount of blank space before the first tick and after the last
  tick on each axis (same value applied to both axes) defaults to `10`.
  * `:breaks` - the number of tick intervals on the x- and y axis (same value applied
  to both axes). This may be adjusted by the scale function based on the data. Defaults to `5`.
  * `:key_glyph` - Type of glyph to use in the legend key. currently only supported for the
  `:color` aesthetic. Available values are `:point`, `:path` and `:timeseries`; default values are
  assigned based on the x value scale type.
  * `:y_label_padding` - vertical distance between the y axis and its label. Defaults to `20`.
  """
  @spec geom_line(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_line(plot, mapping \\ [], options \\ [])

  def geom_line(%Plot{} = plot, [], []) do
    add_geom(plot, Geom.Line, key_glyph: line_key_glyph(plot))
  end

  def geom_line(%Plot{} = plot, mapping, []) when is_map(mapping) do
    add_geom(plot, Geom.Line, mapping, key_glyph: line_key_glyph(plot, mapping))
  end

  def geom_line(%Plot{} = plot, options, []) when is_list(options) do
    key_glyph = options[:key_glyph] || line_key_glyph(plot, options)
    add_geom(plot, Geom.Line, [{:key_glyph, key_glyph} | options])
  end

  def geom_line(%Plot{} = plot, mapping, options) do
    key_glyph = options[:key_glyph] || line_key_glyph(plot, mapping, options)
    add_geom(plot, Geom.Line, mapping, [{:key_glyph, key_glyph} | options])
  end

  defp line_key_glyph(%Plot{scales: %{x: %Date{}}}), do: :timeseries
  defp line_key_glyph(%Plot{scales: %{x: %DateTime{}}}), do: :timeseries
  defp line_key_glyph(_plot), do: :path

  defp line_key_glyph(%Plot{} = plot, mapping) when is_map(mapping) do
    mapping = Map.merge(plot.mapping, mapping)

    case hd(plot.data)[mapping[:x]] do
      %type{} when type in [Date, DateTime] -> :timeseries
      _type -> :path
    end
  end

  defp line_key_glyph(%Plot{} = plot, options) when is_list(options) do
    case hd(options[:data] || plot.data)[plot.mapping[:x]] do
      %type{} when type in [Date, DateTime] -> :timeseries
      _type -> :path
    end
  end

  defp line_key_glyph(%Plot{} = plot, mapping, options) do
    mapping = Map.merge(plot.mapping, mapping)

    case hd(options[:data] || plot.data)[mapping[:x]] do
      %type{} when type in [Date, DateTime] -> :timeseries
      _type -> :path
    end
  end

  @doc """
  Adds a bar geom to the plot.

  Accepts a mapping and/or additonal options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` mapping.

  Currently bar geoms only support `:stat_count`, meaning that the `:y` value is mapped
  to the number of observations with given `:x` (and `:fill`, if mapped) values,
  rather than representing the mapping of a variable in the data to the y axis.
  This means that the only mappings that are needed or used are the `:x` and `:fill`
  aesthetics. The `:x` variable is treated as discrete.

  Other supported options:

  * `:area_padding` - amount of blank space before the first tick and after the last
  tick on each axis (same value applied to both axes) defaults to `10`.
  * `:position` - Available values are `:stack` (one bar per `:x` value) or `:dodge` (one bar
  per unique `:x`/`:fill` value pair). Defaults to `:stack`.
  * `:y_label_padding` - vertical distance between the y axis and its label. Defaults to `20`.
  """
  @spec geom_bar(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_bar(plot, mapping \\ [], options \\ [])

  def geom_bar(%Plot{} = plot, [], []) do
    updated_plot = add_geom(plot, Geom.Bar)
    bar_geom = hd(updated_plot.layers)

    scale_adjustment =
      case bar_geom.position do
        :stack -> {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
        _other_positions -> {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  def geom_bar(%Plot{} = plot, mapping_or_options, []) do
    updated_plot = add_geom(plot, Geom.Bar, mapping_or_options)
    bar_geom = hd(updated_plot.layers)

    {data, mapping} = apply(Stat, bar_geom.stat, [updated_plot.data, updated_plot.mapping])

    fixed_max =
      data
      |> Enum.group_by(fn item -> item[mapping[:x]] end)
      |> Enum.map(fn {_category, values} ->
        Enum.map(values, fn value -> value[mapping[:y]] end)
      end)
      |> Enum.map(fn counts -> Enum.sum(counts) end)
      |> Enum.max()

    scale_adjustment =
      case bar_geom.position do
        :stack ->
          {min(0, elem(plot.limits.y, 0) || 0),
           max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

        _other_positions ->
          {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  def geom_bar(%Plot{} = plot, mapping, options) do
    updated_plot = add_geom(plot, Geom.Bar, mapping, options)
    bar_geom = hd(updated_plot.layers)

    {data, mapping} =
      apply(Stat, bar_geom.stat, [updated_plot.data, Map.merge(updated_plot.mapping, mapping)])

    fixed_max =
      data
      |> Enum.group_by(fn item -> item[mapping[:x]] end)
      |> Enum.map(fn {_category, values} ->
        Enum.map(values, fn value -> value[mapping[:y]] end)
      end)
      |> Enum.map(fn counts -> Enum.sum(counts) end)
      |> Enum.max()

    scale_adjustment =
      case bar_geom.position do
        :stack ->
          {min(0, elem(plot.limits.y, 0) || 0),
           max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

        _other_positions ->
          {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  @doc """
  Shorthand for `geom_bar(plot, stat: :identity)`.

  Produces a bar chart similar to `geom_bar/3`, but uses the values of observations
  mapped to the `:y` aesthetic (instead of observation counts) to calculate the height
  of the bars. See `geom_bar/3` for supported options.
  """
  @spec geom_col(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_col(plot, mapping \\ [], options \\ [])

  def geom_col(%Plot{} = plot, [], []) do
    geom_bar(plot, stat: :identity)
  end

  def geom_col(%Plot{} = plot, mapping_or_options, []) when is_list(mapping_or_options) do
    options = Keyword.merge(mapping_or_options, stat: :identity, limits: %{y: {0, nil}})
    geom_bar(plot, options)
  end

  def geom_col(%Plot{} = plot, mapping, options) do
    options = Keyword.merge(options, stat: :identity, limits: %{y: {0, nil}})
    geom_bar(plot, mapping, options)
  end

  defp add_geom(%Plot{} = plot, geom_type) do
    layer = Layer.new(struct(geom_type), %{}, [])
    struct(plot, layers: [layer | plot.layers])
  end

  defp add_geom(%Plot{} = plot, geom_type, mapping) when is_map(mapping) do
    layer = Layer.new(struct(geom_type), mapping, [])
    struct(plot, layers: [layer | plot.layers], labels: Map.merge(plot.labels, mapping))
  end

  defp add_geom(%Plot{} = plot, geom_type, options) when is_list(options) do
    layer = Layer.new(struct(geom_type), %{}, options)
    struct(plot, layers: [layer | plot.layers])
  end

  defp add_geom(%Plot{} = plot, geom_type, mapping, options) do
    layer = Layer.new(struct(geom_type), mapping, options)
    struct(plot, layers: [layer | plot.layers], labels: Map.merge(plot.labels, mapping))
  end

  @doc """
  Sets geom point opacity for continuous data.

  This scale defines a mapping function that assigns an opacity value between
  `0.1` and `1` to a given value of the mapped variable.
  """
  @spec scale_alpha_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_alpha_continuous(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :alpha, Scale.Alpha.Continuous.new(options)))
  end

  @doc """
  Sets geom point opacity for categorical data.

  For categorical data for which a linear mapping of values to opacity is not
  appropriate, this scale generates a palette of evenly spaced opacity values
  between `0.1` and `1.0` that are mapped to each unique value of the data. The
  palette is generated such that the difference between each opacity value is
  maximized. The set of unique data values are sorted for the purpose of assigning
  them to an opacity and ordering the legend.

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_alpha_discrete(Plot.t(), keyword()) :: Plot.t()
  def scale_alpha_discrete(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :alpha, Scale.Alpha.Discrete.new(options)))
  end

  @doc """
  Sets geom point opacity using the value of the data mapped to the `:alpha` aesthetic.
  Can be used to manually assign opacity to individual data points by including an
  value with each observation.

  See `scale_color_identity/1` for an example of identity scale use.
  """
  @spec scale_alpha_identity(Plot.t()) :: Plot.t()
  def scale_alpha_identity(%Plot{} = plot) do
    struct(plot, scales: Map.put(plot.scales, :alpha, Scale.Identity.new(:alpha)))
  end

  @doc """
  Sets geom point color using the value of the data mapped to
  the color aesthetic. Can be used to manually assign colors to
  individual data points by including a color value with each observation.
  Such color values must be provided as a hex value or CSS color name.

  For example, with the dataset below, one could render points for
  `:weight` values as `"blue"` for low weights and `"red"` for high weights
  by assigning a value to the `:point_color` variable accordingly.
  ```
  [
    %{weight: 6, age: 4, point_color: "blue"},
    %{weight: 5, age: 3, point_color: "blue"},
    %{weight: 8, age: 4, point_color: "red"},
    %{weight: 7, age: 4, point_color: "red"},
  ]
  |> Plot.new(%{x: :weight, y: :age})
  |> Plot.geom_point(%{color: :point_color})
  |> Plot.scale_color_identity()
  |> Plot.plot
  ```
  """
  @spec scale_color_identity(Plot.t()) :: Plot.t()
  def scale_color_identity(%Plot{} = plot) do
    struct(plot, scales: Map.put(plot.scales, :color, Scale.Identity.new(:color)))
  end

  @spec scale_label_identity(Plot.t()) :: Plot.t()
  def scale_label_identity(%Plot{} = plot) do
    struct(plot, scales: Map.put(plot.scales, :color, Scale.Identity.new(:label)))
  end

  @doc """
  Sets geom point colour using the Viridis color palettes. Viridis
  is used by ggplot2 and other libraries in part because it is optimized
  to maintain contrast when viewed by those with various types of
  color blindess.

  The scale is discrete - it is intended to map colors to categorical data.
  The scale generates a palette of evenly spaced values from the Viridis color palette
  and these are mapped to each unique value of the data. The palette is generated such
  that the visual difference between each color value is maximized. The set of unique
  data values are sorted for the purpose of assigning them to a color and ordering the
  legend.

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the data mapped to the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  - `:option` - specifies which palette to use. Available palettes are  `:magma`, `:inferno`,
  `:plasma`, `:viridis` (the default) and `:cividis`. These palettes can also be specified via their
  letter codes - `:a`, `:b`, `:c`, `:d` and `:e`, respectively.

  Examples of each color palette option can be generated using `mix ggity.visual.scale_color_viridis`.
  """
  @spec scale_color_viridis(Plot.t(), keyword()) :: Plot.t()
  def scale_color_viridis(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :color, Scale.Color.Viridis.new(options)))
  end

  @doc """
  Sets fill color for fillable shapes (e.g., bars).

  Accepts the same options as `scale_color_viridis/2`.
  """
  @spec scale_fill_viridis(Plot.t(), keyword()) :: Plot.t()
  def scale_fill_viridis(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :fill, Scale.Fill.Viridis.new(options)))
  end

  @doc """
  Sets type of line for categorical data in line charts.

  This scale uses a palette of six line types (`:solid`, `:dashed`, `:dotted`, `:longdash`,
  `:dotdash` and `:twodash`) that are mapped to each unique value of the data. The
  set of unique data values are sorted for the purpose of assigning them to a line type
  (in the same order as listed above) and ordering the legend.

  If there are more than six unique values in the data, the line types are recycled
  per the order above.

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_linetype_discrete(Plot.t(), keyword()) :: Plot.t()
  def scale_linetype_discrete(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :linetype, Scale.Linetype.Discrete.new(options)))
  end

  @doc """
  Sets geom point marker shape for categorical data.

  This scale uses a palette of four marker types (`:circle`, `:square`, `:diamond`
  and `:triangle`) that are mapped to each unique value of the data. The set of unique
  data values are sorted for the purpose of assigning them to a size (using the shape
  order above) and ordering the legend.

  If there are greater than four unique values in the data, the shapes are recycled
  per the order above.

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_shape(Plot.t(), keyword()) :: Plot.t()
  def scale_shape(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :shape, Scale.Shape.new(options)))
  end

  @doc """
  Sets geom point marker shape for categorical data using a custom palette.

  This scale requires a `:values` option be passed, which must contain a list
  of characters or valid shape names (`:circle`, `:square`, `:diamond` or `:triangle`)
  to be used as markers. These values are mapped to the unique values of the mapped variable
  in term order. The list must have as many values as there are unique values in the data.

  This function also takes the following (optional) options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.

  ```
  [
    %{x: 6, y: 4, mood: "happy"},
    %{x: 5, y: 3, mood: "ok"},
    %{x: 8, y: 4, mood: "sad"},
    %{x: 7, y: 4, mood: "sad"},
  ]
  |> Plot.new(%{x: :x, y: :y})
  |> Plot.geom_point(%{shape: :mood}, size: 7)
  |> Plot.scale_shape_manual(values: ["😀", "😐", "☹️"])
  |> Plot.plot()
  ```
  """
  @spec scale_shape_manual(Plot.t(), keyword()) :: Plot.t()
  def scale_shape_manual(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :shape, Scale.Shape.Manual.new(options)))
  end

  @doc """
  Sets geom point size for continuous data.

  This scale defines a mapping function that assigns an opacity value between
  `4` and `14` to a given value of the mapped variable.

  Note that "size" is the marker diameter, not marker area (which is generally
  preferable but not yet implemented).
  """
  @spec scale_size_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_size_continuous(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :size, Scale.Size.Continuous.new(options)))
  end

  @doc """
  Sets geom point size for categorical data.

  For categorical data for which a linear mapping of values to marker size is not
  appropriate, this scale generates a palette of evenly spaced size values
  between `2` and `8` that are mapped to each unique value of the data. The
  palette is generated such that the difference between each size value is
  maximized. The set of unique data values are sorted for the purpose of assigning
  them to a size and ordering the legend.

  Note that "size" is the marker diameter, not marker area (which is generally
  preferable but not yet implemented).

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_size_discrete(Plot.t(), keyword()) :: Plot.t()
  def scale_size_discrete(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :size, Scale.Size.Discrete.new(options)))
  end

  @doc """
  Sets geom point size using the value of the data mapped to the size aesthetic.
  Can be used to manually assign size to individual data points by including an
  value with each observation.

  Note that "size" is the marker diameter, not marker area (which is generally
  preferable but not yet implemented).

  See `scale_color_identity/1` for an example of identity scale use.
  """
  @spec scale_size_identity(Plot.t()) :: Plot.t()
  def scale_size_identity(%Plot{} = plot) do
    struct(plot, scales: Map.put(plot.scales, :size, Scale.Identity.new(:size)))
  end

  @doc """
  Sets geom x coordinate for continuous numerical data.

  This scale defines a mapping function that assigns a coordinate on the x axis
  to the value of the mapped variable. The scale also defines an inverse of this
  function that is used to generate axis tick labels.

  This function also takes the following options:

  - `:labels` - specifies how break names (tick labels calculated by the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_x_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_x_continuous(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :x, Scale.X.Continuous.new(options)))
  end

  @doc """
  Sets geom x coordinate for continuous `Date` data.

  This scale defines a mapping function that assigns a coordinate on the x axis
  to the value of the mapped variable. The scale also defines an inverse of this
  function that is used to generate axis tick labels.

  This function also takes the following options:

  - `:labels` - specifies how break names (tick labels calculated by the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  -`:date_labels` - special formatting patterns for dates. If `:date_labels` is specified,
  the value of the `:labels` option will be overridden.

  `:date_labels` can be either a format string pattern that is accepted by [`NimbleStrftime`](https://hexdocs.pm/nimble_strftime/NimbleStrftime.html):

  ```
    data
    |> Plot.new(%{x: :date_variable, y: :other_variable})
    |> Plot.geom_line()
    |> Plot.scale_x_date(date_labels: "%b %d %Y") # Label format "Jan 01 2001"
  ```

  or a tuple `{format, options}` where `format` is the pattern and `options` is a keyword
  list of options accepted by `NimbleStrftime.format/3`:

  ```
    rename_weekdays = fn day_of_week ->
                    {
                      "Monday",
                      "Tuesday",
                      "Hump Day",
                      "Thursday",
                      "Friday",
                      "Saturday",
                      "Sunday"
                    }
                    |> elem(day_of_week - 1)
                  end
    data
    |> Plot.new(%{x: :date_variable, y: :other_variable})
    |> Plot.geom_line()
    |> Plot.scale_x_date(date_labels: {"%A", day_of_week_names: rename_weekdays})
    # Ticks are just weekday names, Wednesday is Hump Day
  ```

  """
  @spec scale_x_date(Plot.t(), keyword()) :: Plot.t()
  def scale_x_date(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :x, Scale.X.Date.new(options)))
  end

  @doc """
  Sets geom x coordinate for continuous `DateTime` data.

  This scale defines a mapping function that assigns a coordinate on the x axis
  to the value of the mapped variable. The scale also defines an inverse of this
  function that is used to generate axis tick labels.

  This function also takes the following options:

  - `:labels` - specifies how break names (tick labels calculated by the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  -`:date_labels` - special formatting patterns for dates. If `:date_labels` is specified,
  the value of the `:labels` option will be overridden.

  `:date_labels` can be either a format string pattern that is accepted by [`NimbleStrftime`](https://hexdocs.pm/nimble_strftime/NimbleStrftime.html):

  See `scale_x_date/2` for more usage examples.

  ```
    data
    |> Plot.new(%{x: :datetime_variable, y: :other_variable})
    |> Plot.geom_line()
    |> Plot.scale_x_datetime(date_labels: "%b %d H%H") # Label format "Jan 01 H01"
  ```
  """
  @spec scale_x_datetime(Plot.t(), keyword()) :: Plot.t()
  def scale_x_datetime(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :x, Scale.X.DateTime.new(options)))
  end

  @doc """
  Sets geom x coordinate for discrete (categorical) data.

  This scale defines a mapping function that assigns a coordinate on the x axis
  to the value of the mapped variable. In the discrete case, this is equivalent to
  evenly distributing geoms across the x axis.

  This function also takes the following options:

  - `:labels` - specifies how break names (tick labels calculated by the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_x_discrete(Plot.t(), keyword()) :: Plot.t()
  def scale_x_discrete(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :x, Scale.X.Discrete.new(options)))
  end

  @doc """
  Sets geom y coordinate for continuous numerical data.

  This scale defines a mapping function that assigns a coordinate on the y axis
  to the value of the mapped variable. The scale also defines an inverse of this
  function that is used to generate axis tick labels.

  This function also takes the following options:

  - `:labels` - specifies how break names (tick labels calculated by the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.
  """
  @spec scale_y_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_y_continuous(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :y, Scale.Y.Continuous.new(options)))
  end

  @doc """
  Updates plot title, axis and legend labels.

  Accepts a keyword list where the keys are `:title` and/or the aesthetic(s)
  tied to the axes/legends to be labelled.
  """
  @spec labs(Plot.t(), keyword()) :: Plot.t()
  def labs(plot, labels) do
    labels = Map.merge(plot.labels, Enum.into(labels, %{}))
    struct(plot, labels: labels)
  end

  @doc """
  Updates the plot x axis label.
  """
  @spec xlab(Plot.t(), binary()) :: Plot.t()
  def xlab(%Plot{} = plot, label) do
    labels =
      plot.labels
      |> Map.merge(%{x: label})

    struct(plot, labels: labels)
  end

  @doc """
  Updates the plot y axis label.
  """
  @spec ylab(Plot.t(), binary()) :: Plot.t()
  def ylab(plot, label) do
    labels =
      plot.labels
      |> Map.merge(%{y: label})

    struct(plot, labels: labels)
  end

  @doc """
  Manually sets the type of guide used for specified scales.

  Accepts a keyword list of aesthetics and values for the `:guide` options
  for the associated scales.

  Currently this is only used to turn legends on or off. Valid values are
  `:legend` (draw a legend) and `:none` (do not draw a legend).

  ## Example

  ```
  Plot.new(%{x: "x", y: "y"})
  |> Plot.geom_point(color: "color", shape: "shape", size: "size")
  # By default all three legends will be drawn
  |> Plot.guides(shape: :none, size: :none) # Plot will only draw a legend for the color scale
  """
  @spec guides(Plot.t(), keyword()) :: Plot.t()
  def guides(plot, guides) do
    scales =
      guides
      |> Keyword.keys()
      |> Enum.reduce(%{}, fn aesthetic, new_scales ->
        scale = plot.scales[aesthetic] || assign_scale(aesthetic, "a string")
        Map.put(new_scales, aesthetic, struct(scale, guide: guides[aesthetic]))
      end)

    struct(plot, scales: Map.merge(plot.scales, scales))
  end

  @doc """
  Saves the plot to a file at the given path.
  """
  @spec to_file(Plot.t(), list(binary)) :: :ok
  def to_file(%Plot{} = plot, path) do
    File.write!(path, plot(plot))
  end
end
