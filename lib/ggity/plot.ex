defmodule GGity.Plot do
  @moduledoc """
  Configures and generates an iolist representing an SVG plot.

  The Plot module is GGity's public interface. A Plot struct is created
  with `new/3`, specifying the data and aesthetic mappings to be used,
  along with options associated with the plot's general appearance.

  Data must be provided as a list of maps, where each map in the list
  represents an observation, and the map's keys represent variable names.
  **GGity does not perform any validation of the data**; data is assumed to be
  clean and not to have missing values.

      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})

  Mappings are specified using maps, where the map's keys are the names
  of supported aesthetics, and the values are the names of variables in
  the data.

      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point()

  A plot layer (represented as a struct that implements the `GGity.Geom` protocol)
  is added to the plot using functions such as `geom_point/3` or `geom_line/3`.

  As layers are assembled into a plot, the scales for each aesthetic are calculated
  using the data assigned to each aesthetic in each layer. Scales generate functions
  that transform data into an aesthetic value (e.g, an x coordinate or a color) and
  functions that transform an aesthetic value back into an observation (for the
  purpose of drawing axes or legends).

  The plot will assign default scales based on the type of data assigned to each
  aesthetic in each layer (by examining the value in the first row of the data),
  typically mapping numerical data to a continuous scale (if available) and binary
  data to a discrete scale. These assignments can be overridden by passing the Plot
  struct to a scale-setting function, e.g. `scale_[scale_type]/2`. For `x` values
  only, GGity will assign at date/datetime scale if the data mapped to the `:x`
  aesthetic is a `Date`, `DateTime` or `NaiveDateTime` struct.

      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point()
      |> Plot.plot()

  `plot/1` generates an iolist that represents the plot. Text elements (e.g. the
  plot title, axis labels, legend labels) are escaped using the logic from
  `Plug.HTML`, but other values are not, so users still need to be mindful of
  the risks of generating plots using user-supplied data or parameters.
  """

  alias __MODULE__
  alias GGity.{Axis, Draw, Geom, Layer, Legend, Scale, Stat, Theme}

  @type t() :: %__MODULE__{}
  @type column() :: list()
  @type name() :: binary() | atom()
  @type record() :: map()
  @type mapping() :: map()
  @type options() :: keyword()

  @continuous_scales [
    Scale.Alpha.Continuous,
    Scale.Size,
    Scale.X.Continuous,
    Scale.X.Date,
    Scale.X.DateTime,
    Scale.Y.Continuous
  ]

  defstruct data: [],
            mapping: %{},
            aspect_ratio: 1.5,
            title_margin: 15,
            layers: [%Geom.Blank{}],
            scales: %{},
            limits: %{x: {nil, nil}, y: {nil, nil}},
            labels: %{title: nil, x: nil, y: nil},
            y_label_padding: 20,
            breaks: 5,
            area_padding: 10,
            theme: %Theme{},
            margins: %{left: 30, top: 10, right: 10, bottom: 0},
            width: 200,
            combined_layers: []

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

  * `:area_padding` - amount of blank space before the first tick and after the last
  tick on each axis (same value applied to both axes) defaults to `10`.

  * `:aspect_ratio` - the ratio of the plot area height to `:width`. Defaults to `1.5.`

  * `:breaks` - the number of tick intervals on the x- and y axis (same value applied
  to both axes). This may be adjusted by the scale function based on the data. Defaults to `5`.

  * `:labels` - a map specifying the titles of the plot (`:title`), x and y-axes
  (`:x` and `:y`) or legend title for another aesthetic (e.g. `:color`). A `nil` value indicates
  no label. Defaults to `%{title: :nil, x: nil, y: nil}`.

  * `:margins` - a map with keys `:left`, `:top`, `:right` and `:bottom`, specifying the
  plot margins. Default is `%{left: 30, top: 10, right: 0, bottom: 0}`.

  * `:panel_background_color` - a string value (hex or CSS color name) for the panel background.
  Defaults to grey (`#eeeeee`)

  * `:y_label_padding` - vertical distance between the y axis and its label. Defaults to `20`.
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
    Scale.Size.new()
  end

  defp assign_scale(:x, %Date{}), do: Scale.X.Date.new()

  defp assign_scale(:x, %DateTime{}), do: Scale.X.DateTime.new()

  defp assign_scale(:x, value) when is_number(value) do
    Scale.X.Continuous.new()
  end

  defp assign_scale(:x, _value), do: Scale.X.Discrete.new()

  defp assign_scale(:y, _value), do: Scale.Y.Continuous.new()

  defp assign_scale(:y_max, _value), do: Scale.Y.Continuous.new()

  defp assign_scale(other, _value), do: Scale.Identity.new(other)

  @doc """
  Generates an iolist of SVG markup representing a `Plot`.

  SVG text elements (e.g. the plot title, axis labels, legend labels) are escaped using
  the logic from `Plug.HTML`, but other values are not, so users need to be mindful of
  the risks of generating plots using user-supplied data or parameters.

  The SVG's viewBox is set by the plot's `:width` and `:aspect_ratio` values.
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

    struct(plot, combined_layers: layers)
  end

  defp apply_stats(%Plot{} = plot) do
    layers =
      Enum.map(plot.combined_layers, fn layer ->
        {data, mapping} = apply(Stat, layer.stat, [layer.data || plot.data, layer.mapping])
        struct(layer, data: data, mapping: mapping)
      end)

    struct(plot, combined_layers: layers)
  end

  defp provide_default_axis_labels(%Plot{} = plot) do
    [x_label | y_labels] =
      plot.combined_layers
      |> hd()
      |> Map.get(:mapping)
      |> Map.take([:x, :y, :y_max])
      |> Map.values()

    labels =
      Map.merge(plot.labels, %{x: plot.labels.x || x_label, y: plot.labels.y || hd(y_labels)})

    struct(plot, labels: labels)
  end

  defp train_scales(%Plot{} = plot) do
    plot
    |> all_mapped_aesthetics()
    |> train_scales(plot)
  end

  defp all_mapped_aesthetics(%Plot{} = plot) do
    plot.combined_layers
    |> Enum.flat_map(fn layer -> Map.keys(layer.mapping) end)
    |> Enum.uniq()
  end

  defp train_scales(aesthetics, %Plot{} = plot) do
    trained_scales =
      Enum.reduce(aesthetics, %{}, fn aesthetic, scales_map ->
        Map.put(scales_map, aesthetic, train_scale(aesthetic, plot))
      end)

    scales =
      if :y_max in aesthetics do
        trained_scales
        |> Map.put(:y, trained_scales.y_max)
        |> Map.delete(:y_max)
      else
        trained_scales
      end

    struct(plot, scales: scales)
  end

  defp train_scale(:y_max, plot) do
    sample_layer =
      plot.combined_layers
      |> Enum.filter(fn layer -> layer.mapping[:y_max] end)
      |> hd()

    sample_value = hd(sample_layer.data)[sample_layer.mapping[:y_max]]

    scale = plot.scales[:y_max] || assign_scale(:y_max, sample_value)
    y_max_global_min_max = global_min_max(:y_max, plot, scale)

    global_min_max =
      if :y_min in all_mapped_aesthetics(plot) do
        y_min_global_min_max = global_min_max(:y_min, plot, scale)
        {elem(y_min_global_min_max, 0), elem(y_max_global_min_max, 1)}
      else
        y_max_global_min_max
      end

    Scale.train(scale, global_min_max)
  end

  defp train_scale(aesthetic, plot) do
    sample_layer =
      plot.combined_layers
      |> Enum.filter(fn layer -> layer.mapping[aesthetic] end)
      |> hd()

    sample_value = hd(sample_layer.data)[sample_layer.mapping[aesthetic]]

    scale = plot.scales[aesthetic] || assign_scale(aesthetic, sample_value)
    global_min_max = global_min_max(aesthetic, plot, scale)
    Scale.train(scale, global_min_max)
  end

  defp global_min_max(aesthetic, plot, %scale_type{}) when scale_type in @continuous_scales do
    {fixed_min, fixed_max} = plot.limits[aesthetic] || {nil, nil}

    plot.combined_layers
    |> Enum.filter(fn layer -> layer.mapping[aesthetic] end)
    |> Enum.map(fn layer -> layer_min_max(aesthetic, layer) end)
    |> Enum.reduce({fixed_min, fixed_max}, fn {layer_min, layer_max}, {global_min, global_max} ->
      {safe_min(fixed_min || layer_min, global_min || layer_min),
       safe_max(fixed_max || layer_max, global_max || layer_max)}
    end)
  end

  defp global_min_max(aesthetic, plot, _sample_value) do
    plot.combined_layers
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
    |> Enum.map(fn row -> to_string(row[layer.mapping[aesthetic]]) end)
    |> MapSet.new()
  end

  defp safe_min(%date_type{} = first, second)
       when date_type in [Date, DateTime, NaiveDateTime] do
    [first, second]
    |> min_max()
    |> elem(0)
  end

  defp safe_min(first, second), do: min(first, second)

  defp safe_max(%date_type{} = first, second)
       when date_type in [Date, DateTime, NaiveDateTime] do
    [first, second]
    |> min_max()
    |> elem(1)
  end

  defp safe_max(first, second), do: max(first, second)

  defp min_max([]), do: raise(Enum.EmptyError)

  defp min_max([single_value]), do: {single_value, single_value}

  defp min_max([%date_type{} | _rest] = dates)
       when date_type in [Date, DateTime, NaiveDateTime] do
    {Enum.min_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end),
     Enum.max_by(dates, & &1, date_type, fn -> raise(Enum.EmptyError) end)}
  end

  defp min_max(list), do: Enum.min_max(list)

  defp render(%Plot{} = plot) do
    legend = draw_legend_group(plot)
    # This is an arbitrary number that works for all the visual tests,
    # but user can make more room by increasing right margin
    legend_margin = if legend == [], do: 0, else: 80

    viewbox_width =
      plot.width + plot.y_label_padding + plot.area_padding * 2 + plot.margins.left +
        plot.margins.right + legend_margin

    # MAGIC NUMBERS
    # 45 is a magic number - think it is the height of x-axis label text plus
    # padding/margin that is hard-coded somewhere
    height_adjustment =
      title_margin(plot) + plot.margins.top + 45 + plot.area_padding * 2 +
        plot.theme.axis_text_x.angle / 90 * 20

    viewbox_height = plot.width / plot.aspect_ratio + height_adjustment

    id = "gg-#{System.unique_integer([:positive])}"

    Draw.svg(
      [
        Theme.to_stylesheet(plot.theme, id),
        draw_plot_background(),
        draw_panel(plot),
        draw_title(plot),
        legend
      ],
      id: id,
      viewBox: "0 0 #{viewbox_width} #{viewbox_height}"
      # viewBox: "0 0 #{viewbox_width} #{viewbox_width / plot.aspect_ratio}"
    )
  end

  defp draw_plot_background do
    ["<rect class=\"gg-plot-background\" width=\"100%\" height=\"100%\"></rect>"]
  end

  defp draw_panel(plot) do
    translate_for_title_and_y_axis(
      [
        draw_panel_background(plot),
        Axis.draw_x_axis(plot),
        Axis.draw_y_axis(plot),
        draw_layers(plot)
      ],
      plot
    )
  end

  defp draw_panel_background(%Plot{} = plot) do
    Draw.rect(
      x: "0",
      y: "0",
      height: to_string(plot.width / plot.aspect_ratio + plot.area_padding * 2),
      width: to_string(plot.width + plot.area_padding * 2),
      class: "gg-panel-background gg-panel-border"
    )
  end

  defp title_margin(%Plot{labels: %{title: title}} = plot) when is_binary(title),
    do: plot.title_margin

  defp title_margin(%Plot{}), do: 0

  defp draw_layers(%Plot{} = plot) do
    plot.combined_layers
    |> Enum.reverse()
    |> Enum.map(fn layer -> Layer.draw(layer, layer.data, plot) end)
  end

  defp draw_title(%Plot{labels: %{title: title}}) when not is_binary(title), do: ""

  defp draw_title(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding

    plot.labels.title
    |> Draw.text(
      x: "0",
      y: "#{margins.top}",
      dy: "0.71em",
      dx: "0",
      class: "gg-text gg-plot-title"
    )
    |> Draw.g(transform: "translate(#{left_shift}, 0)")
  end

  defp fixed_aesthetics(plot) do
    all_mappings = Enum.map(plot.combined_layers, fn layer -> Map.keys(layer.mapping) end)

    fixed_aesthetic_keys =
      Enum.reject(
        [:color, :fill, :linetype, :shape, :size, :alpha],
        fn key -> key in all_mappings end
      )

    plot.combined_layers
    |> Enum.map(fn layer -> Map.take(layer, fixed_aesthetic_keys) end)
    |> Enum.flat_map(fn aesthetics -> Map.to_list(aesthetics) end)
    |> Enum.uniq()
  end

  defp draw_legend_group(plot) do
    {legend_group, legend_group_height} =
      Enum.reduce(
        [:color, :fill, :linetype, :shape, :size, :alpha],
        {[], 0},
        fn aesthetic, {legends, offset_acc} ->
          {[draw_legend(plot, aesthetic, offset_acc, fixed_aesthetics(plot)) | legends],
           offset_acc + legend_height(plot, Map.get(plot.scales, aesthetic))}
        end
      )

    left_shift = plot.margins.left + plot.y_label_padding + plot.width + 25

    top_shift =
      plot.margins.top + title_margin(plot) + plot.width / plot.aspect_ratio / 2 + 10 -
        legend_group_height / 2 + 10

    case legend_group do
      [[], [], [], [], [], []] ->
        []

      legend_group ->
        Draw.g(legend_group, transform: "translate(#{left_shift}, #{top_shift})")
    end
  end

  defp draw_legend(
         %Plot{theme: %{legend_key: %{height: height}}} = plot,
         aesthetic,
         offset,
         fixed_aesthetics
       )
       when is_number(height) do
    scale = Map.get(plot.scales, aesthetic)

    if display_legend?(plot, scale) do
      label = plot.labels[aesthetic]
      key_glyph = key_glyph(plot, aesthetic)

      scale
      |> Legend.draw_legend(label, key_glyph, plot.theme.legend_key.height, fixed_aesthetics)
      |> Draw.g(transform: "translate(0, #{offset})")
    else
      []
    end
  end

  defp display_legend?(plot, scale), do: legend_height(plot, scale) > 0

  defp legend_height(_plot, %scale_type{})
       when scale_type in @continuous_scales and scale_type != Scale.Size do
    0
  end

  defp legend_height(_plot, %{guide: :none}), do: 0
  defp legend_height(_plot, %{levels: []}), do: 0
  defp legend_height(_plot, %{levels: [_]}), do: 0

  defp legend_height(plot, %scale_type{} = scale) when scale_type == Scale.Size do
    theme_height = plot.theme.legend_key.height

    scale.tick_values
    |> Enum.map(fn value ->
      shape_height = 2 * :math.sqrt(scale.transform.(value) / :math.pi())
      max(shape_height, theme_height)
    end)
    |> Enum.sum()
  end

  defp legend_height(plot, %{breaks: breaks}) do
    20 + plot.theme.legend_key.height * breaks
  end

  defp legend_height(plot, %{levels: levels}) do
    20 + plot.theme.legend_key.height * length(levels)
  end

  defp legend_height(_plot, _nil_or_other), do: 0

  defp translate_for_title_and_y_axis(element, %Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.y_label_padding
    top_shift = margins.top + title_margin(plot)
    Draw.g(element, transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp key_glyph(plot, aesthetic) do
    cond do
      mapped_to_layer?(plot, aesthetic) ->
        plot.layers
        |> Enum.filter(fn layer -> aesthetic in Map.keys(layer.mapping || %{}) end)
        |> hd()
        |> Map.get(:key_glyph)

      part_of_layer_geom?(plot, aesthetic) ->
        plot.layers
        |> Enum.filter(fn layer -> aesthetic in Map.keys(layer) end)
        |> hd()
        |> Map.get(:key_glyph)

      true ->
        hd(plot.layers).key_glyph
    end
  end

  defp mapped_to_layer?(plot, aesthetic) do
    not (plot.layers
         |> Enum.filter(fn layer -> aesthetic in Map.keys(layer.mapping || %{}) end)
         |> Enum.empty?())
  end

  defp part_of_layer_geom?(plot, aesthetic) do
    not (plot.layers
         |> Enum.filter(fn layer -> aesthetic in Map.keys(layer) end)
         |> Enum.empty?())
  end

  @doc """
  Adds geoms to a plot from raw data.

  `annotate/3` can be used to add annotations to a plot. The function
  takes a plot, a type of geom and a keyword list of values and options. The
  keyword list must include values for the aesthetics required to draw
  the geom, and can also include any other options that could be passed to
  constructor for that geom.

  Supported geoms and required aesthetics include:

  * `:text` - `:x`, `:y`, `:label`
  """
  @spec annotate(Plot.t(), atom(), keyword()) :: Plot.t()
  def annotate(%Plot{} = plot, geom_type, data) do
    geom = GGity.Annotate.annotate(geom_type, data)
    struct(plot, layers: [geom | plot.layers])
  end

  @doc """
  Adds a ribbon geom to the plot with the `position: :stack` option set.

  `geom_area/3` is a convenience alias for `geom_ribbon/3` that sets the
  `:position` option to `:stack` in order to create stacked area chart.

  See `geom_ribbon/3` for available aesthetics and options.

  Note that stacked ribbon charts are not yet supported - mappings to the
  `:y_min` aesthetic will be ignored.
  """
  @spec geom_area(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_area(plot, mapping \\ [], options \\ [])

  def geom_area(%Plot{} = plot, [], []) do
    geom_ribbon(plot, position: :stack)
  end

  def geom_area(%Plot{} = plot, mapping_or_options, []) when is_list(mapping_or_options) do
    options = Keyword.merge(mapping_or_options, position: :stack)
    geom_ribbon(plot, options)
  end

  def geom_area(%Plot{} = plot, mapping, options) do
    options = Keyword.merge(options, position: :stack)
    geom_ribbon(plot, mapping, options)
  end

  @doc """
  Adds a bar geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` mapping.

  Bar geoms support mapping data to the following aesthetics, which use the
  noted default scales:

  * `:x` (required)
  * `:y` (required to draw the geom, but not typically specified for bar geoms - see below)
  * `:alpha`
  * `:fill`

  Bar geoms also support providing fixed values (specified as options, e.g. `color: "blue"`)
  for the optional aesthetics above. A fixed value is assigned to the aesthetic
  for all observations.

  `geom_bar/3` uses the `:count` stat, which counts the number of
  observations in the data for each combination of mapped aesthetics and assigns
  that value to the `:y` aesthetic. To create a bar chart with bars tied values of
  a specific variable use specify `stat: :identity` or use `geom_col/3`,
  which is identical to calling `geom_bar/3` with the `stat: :identity`
  option. In either case, if `stat: :identity` is called, a variable in the data
  must be mapped to the `:y` aesthetic.

  Other supported options:

  * `:custom_attributes` - a function that takes two arguments: first, the Plot
  struct, and second, the data record (a map - note that this is the data AFTER the
  statistical transformation has been supplied) to be mapped to the bar geom. The function
  must return a keyword list of property-value pairs, which are added to the point
  element drawn in the generated SVG. This can be used to add Phoenix event handlers
  or any other attributes based on characteristic of the plot and the data being
  mapped to the geom. See `geom_point/3` for a more explanation of the
  `:custom_attributes` option.

  * `:key_glyph` - Type of glyph to use in the legend key. Available values are
  `:a`, `:point`, `:path`, `:rect` and `:timeseries`. Defaults to `:rect`.

  * `:position` - Available values are:
      * `:identity` (bars sit on top of each other; not recommended),
      * `:stack` (one bar per `:x` value)
      * `:dodge` (one bar per unique `:x`/`:fill` value pair).
      Defaults to `:stack`.

  * `:stat` - an atom referring to a statistical transformation function in the
  `GGity.Stat` module that is to be applied to the data. Defaults to `:count` (see above).
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

    fixed_max = stacked_y_axis_max(data, mapping, :y)

    scale_adjustment = position_adjusted_scale_min_max(bar_geom, plot, fixed_max)

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  def geom_bar(%Plot{} = plot, mapping, options) do
    updated_plot = add_geom(plot, Geom.Bar, mapping, options)
    bar_geom = hd(updated_plot.layers)

    {data, mapping} =
      apply(Stat, bar_geom.stat, [updated_plot.data, Map.merge(updated_plot.mapping, mapping)])

    fixed_max = stacked_y_axis_max(data, mapping, :y)

    scale_adjustment = position_adjusted_scale_min_max(bar_geom, plot, fixed_max)

    struct(updated_plot, limits: %{y: scale_adjustment})
  end

  @doc """
  Adds a boxplot geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` mapping, for example.

  Boxplot geoms support mapping data to the following aesthetics, which use the noted scales:

  * `:x` (required - should be a discrete variable)
  * `:y` (required - the value for which percentile statistics are calculated)
  * `:alpha`
  * `:color`
  * `:fill`

  `geom_boxplot/3` uses the `:boxplot` stat, which calculates the following for the variable
  mapped to the `:y` aesthetic:

  * 25th and 75th percentiles (the y-coordinates of the top and bottom of the box)
  * median (the y-coordinate of the line in the middle of the box)
  * "ymin" and "ymax" (the outlying y-coordinates of the vertical lines extending from the
  top and bottom of each box.

  "ymin" and "ymax" represent the range of values between the 25th/75th percentiles minus/plus
  1.58 multiplied by the interquartile range, respectively. The interquartile range is the
  difference between the 75th and 25th percentile values.

  Values mapped to `:y` that are less than "ymin" or greater than "ymax" ("outiers") are
  plotted as individual points.

  Other supported options:

  * `:custom_attributes` - a function that takes two arguments: first, the Plot
  struct, and second, the data record (a map - note that this is the data AFTER the
  statistical transformation has been supplied) to be mapped to the boxplot geom. The function
  must return a keyword list of property-value pairs, which are added to the point
  element drawn in the generated SVG. This can be used to add Phoenix event handlers
  or any other attributes based on characteristic of the plot and the data being
  mapped to the geom. See `geom_point/3` for a more explanation of the
  `:custom_attributes` option.

  * `:outlier_color` - color of outlier points.
    Defaults to `"black"`.

  * `:outlier_shape` - shape of outlier points (`:circle`, `:triangle`, `:square`, `:diamond`)
    Defaults to `:circle`. Setting this value to `:na` omits the outliers from the plot entirely.

  * `:outlier_size` - size of outlier points.
    Defaults to `2`.

  GGity uses method "Type 7" to calculate percentiles, in conformance with
  [the default used by R](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html).
  """
  @spec geom_boxplot(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_boxplot(plot, mapping \\ [], options \\ [])

  def geom_boxplot(%Plot{} = plot, [], []) do
    add_geom(plot, Geom.Boxplot)
  end

  def geom_boxplot(%Plot{} = plot, mapping_or_options, []) do
    add_geom(plot, Geom.Boxplot, mapping_or_options)
  end

  def geom_boxplot(%Plot{} = plot, mapping, options) do
    add_geom(plot, Geom.Boxplot, mapping, options)
  end

  @doc """
  Shorthand for `geom_bar(plot, stat: :identity)`.

  Produces a bar chart similar to `geom_bar/3`, but uses the values of
  observations mapped to the `:y` aesthetic (instead of observation counts) to
  calculate the height of the bars. See `geom_bar/3` for supported options.
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

  @doc """
  Adds a line geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings.

  Note that the line geom sorts the data by the values for the variable mapped
  to the `:x` aesthetic using Erlang default term ordering.

  Line geoms support mapping data to the following aesthetics, which use the
  noted default scales:

  * `:x` (required)
  * `:y` (required)
  * `:alpha`
  * `:color`
  * `:linetype`
  * `:size`

  Line geoms also support providing fixed values (specified as options, e.g. `color: "blue"`)
  for the optional aesthetics above. A fixed value is assigned to the aesthetic
  for all observations.

  Other supported options:

  * `:key_glyph` - Type of glyph to use in the legend key. Available values are
  `:path` and `:timeseries`. By default this value is assigned based on the type
  of the value in the first row of the data for the variable mapped to the `:x`
  aesthetic.
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
  Adds a layer with a point geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings.

  Point geoms support mapping data to the following aesthetics, which use the noted
  default scales:

  * `:x` (required)
  * `:y` (required)
  * `:alpha`
  * `:color`
  * `:shape`
  * `:size`

  Point geoms also support providing fixed values (specified as options, e.g. `color: "blue"`)
  for the optional aesthetics above. A fixed value is assigned to the aesthetic for
  all observations.

  Other supported options:

  * `:custom_attributes` - a function that takes two arguments: first, the Plot
  struct, and second, the data record (a map) to be mapped to the point geom. The function
  must return a keyword list of property-value pairs, which are added to the point
  element drawn in the generated SVG. This can be used to add Phoenix event handlers
  or any other attributes based on characteristic of the plot and the data being
  mapped to the geom.

  * `:key_glyph` - Type of glyph to use in the legend key. Available values are
  `:point`, `:path` and `:timeseries`; defaults to `:point`.

  * `:stat` - an atom referring to a statistical transformation function in the
  `GGity.Stat` module that is to be applied to the data. Defaults to `:identity`
  (i.e., no transformation).

  ## Custom Attributes

  Custom attributes are a powerful hook for interactivity. For example, to add a simple
  javascript alert based tooltip:

      Plot.new(data, %{x: "x", y: "y"})
      |> Plot.geom_point(
        custom_attributes: fn plot, row ->
          [onclick: "alert('\#{plot.labels.x}: \#{row["x"]}')"]
        end
      )
      # I hope the plot x-axis label is trusted data...

  or a Phoenix LiveView event handler:

      Plot.new(data, %{x: "x", y: "y"})
      |> Plot.geom_point(
        custom_attributes: fn _plot, row ->
          [phx_click: "filter_by_y", phx_value_y: row["y"]]
        end
      )

  The values (but not the keys) generated are HTML-escaped but otherwise not sanitized;
  users should be mindful of the risks of using untrusted data to generate custom
  attribute values.
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

  @doc """
  Adds a ribbon geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` mapping.

  Ribbon geoms support mapping data to the following aesthetics, which use the
  noted default scales:

  * `:x` (required)
  * `:y_max` (required) - defines the top boundary of the ribbon
  * `:y_min` - defines the bottom boundary of the ribbon; defaults to zero
  * `:alpha`
  * `:fill`

  A ribbon geom with no `:y_min` specified is essentially an area chart. To draw
  a stacked area chart, set the `:position` option to `:stack`, or use the `geom_area/3`
  convenience function.

  Ribbon geoms also support providing fixed values (specified as options, e.g. `fill: "blue"`)
  for the `:alpha` and `:fill` aesthetics above. A fixed value is assigned to the aesthetic
  for all observations. Fixed values can also be specified for:

  * `:color` - ribbon border color
  * `:size` - ribbon border color width

  Other supported options:

  * `:key_glyph` - Type of glyph to use in the legend key. Available values are
  `:a`, `:point`, `:path`, `:rect` and `:timeseries`. Defaults to `:rect`.

  * `:position` - Available values are:
      * `:identity` (ribbons overlay one another),
      * `:stack` (ribbons stacked on the y-axis; note )
      Defaults to `:identity`.

  Note that stacked ribbon charts are not yet supported - mappings to the
  `:y_min` aesthetic will be ignored is `:position` is set to `:stack`.
  """
  @spec geom_ribbon(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_ribbon(plot, mapping \\ [], options \\ [])

  def geom_ribbon(%Plot{} = plot, [], []) do
    plot = add_geom(plot, Geom.Ribbon)
    ribbon_geom = hd(plot.layers)

    scale_adjustment =
      case ribbon_geom.position do
        :stack -> {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
        _other_positions -> {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
      end

    struct(plot, limits: %{y_max: scale_adjustment})
  end

  def geom_ribbon(%Plot{} = plot, mapping_or_options, []) do
    plot = add_geom(plot, Geom.Ribbon, mapping_or_options)
    ribbon_geom = hd(plot.layers)

    fixed_max = stacked_y_axis_max(plot.data, plot.mapping, :y_max)

    scale_adjustment = position_adjusted_scale_min_max(ribbon_geom, plot, fixed_max)

    struct(plot, limits: %{y_max: scale_adjustment})
  end

  def geom_ribbon(%Plot{} = plot, mapping, options) do
    plot = add_geom(plot, Geom.Ribbon, mapping, options)
    ribbon_geom = hd(plot.layers)

    fixed_max = stacked_y_axis_max(plot.data, plot.mapping, :y_max)

    scale_adjustment = position_adjusted_scale_min_max(ribbon_geom, plot, fixed_max)

    struct(plot, limits: %{y_max: scale_adjustment})
  end

  @doc """
  Adds a layer with a text geom to the plot.

  Accepts an alternative dataset to be used; if one is not provided defaults to
  the plot dataset.

  A common use for text geoms is labelling of bar or point geoms. For bar chart
  labels in particular, it is important to specify the same stat and position
  adjustment for the text geom as that specified for the bar chart.

  Accepts a mapping and/or additional options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings.

  Text geoms support mapping data to the following aesthetics, which use the
  noted default scales:

  * `:x` (required)
  * `:y` (required)
  * `:label` (required - the text to be displayed)
  * `:group`
  * `:alpha`
  * `:color`
  * `:size`

  The `:group` aesthetic is generally needed for bar chart labelling, where the
  `:fill` or `:alpha` aesthetic is mapped to a value in the data, in those scenarios,
  the text geom position adjustment must match the bar, and the `:group` aesthetic for
  the text geom should be mapped to the variable mapped to `:fill` or `:alpha` on the
  bar chart layer. See the visual examples code for examples.

  Text geoms also support providing fixed values (specified as options, e.g. `color: "blue"`)
  for the optional aesthetics above. A fixed value is assigned to the aesthetic for
  all observations.

  Other supported options:

  * `:custom_attributes` - a function that takes two arguments: first, the Plot
  struct, and second, the data record (a map) to be mapped to the text geom. The function
  must return a keyword list of property-value pairs, which are added to the point
  element drawn in the generated SVG. This can be used to add Phoenix event handlers
  or any other attributes based on characteristic of the plot and the data being
  mapped to the geom. See `geom_point/3` for a more explanation of the
  `:custom_attributes` option.

  * `:family` - The font family used to display the text; equivalent to the
  SVG `font-family` attribute. Defaults to `"Helvetica, Arial, sans-serif"`.

  * `:fontface` - Equivalent to SVG `font-weight` attribute. Defaults to `:normal`.

  * `:hjust` - Horizontal alignment of the text relevant to element's `:x` value.
  Valid values are `:left`, `:center` and `:right`. Defaults to `:center`.

  * `:key_glyph` - Type of glyph to use in the legend key. Available values are
  `:a`, `:point`, `:path` and `:timeseries`. Defaults to `:a`.

  * `nudge_x`, `:nudge_y` - Adjust the x- or y-position value by the specified number
  of pixels. Both default to `0`.

  * `:position` - Available values are `:identity` (no adjustment), `:stack` (`:y` value
  represents cumulative value for a given `:x` value) or `:dodge` (one text element per
  unique pair of `:x` and other non-`:y` mapped aesthetics). Defaults to `:identity`.

  * `position_vjust` - Adjust `:y` position vertically; expressed as a percentage of
  the calculated `:y` value after taking into account the specified position adjustment.
  Defaults to `1`.

  * `:stat` - an atom referring to a statistical transformation function in the `GGity.Stat`
  module that is to be applied to the data. Defaults to `:identity` (i.e., no transformation).
  Supported values are `:count` and `:identity`. Where text geom is intended to serve as a
  label for another layer with the `:count` stat, the state for the text layer should

  * `:vjust` - Baseline of the text relevant to element's `:y` value. Valid values are
  `:top`, `:middle` and `:bottom`. Defaults to `:center`.
  """
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

    scale_adjustment =
      case geom.position do
        :stack ->
          fixed_max = stacked_y_axis_max(data, mapping, :y)

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

    scale_adjustment =
      case geom.position do
        :stack ->
          fixed_max = stacked_y_axis_max(data, mapping, :y)

          {min(0, elem(plot.limits.y, 0) || 0),
           max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

        _other_positions ->
          plot.limits.y
      end

    struct(updated_plot, limits: %{y: scale_adjustment})
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

  defp stacked_y_axis_max(data, mapping, y_aesthetic) do
    data
    |> Enum.group_by(
      fn item -> item[mapping[:x]] end,
      fn values -> values[mapping[y_aesthetic]] end
    )
    |> Enum.reduce(0, fn {_category, counts}, max_count -> max(Enum.sum(counts), max_count) end)
  end

  defp position_adjusted_scale_min_max(geom, plot, fixed_max) do
    case geom.position do
      :stack ->
        {min(0, elem(plot.limits.y, 0) || 0), max(fixed_max, fixed_max || elem(plot.limits.y, 1))}

      _other_positions ->
        {min(0, elem(plot.limits.y, 0) || 0), elem(plot.limits.y, 1)}
    end
  end

  @doc """
  Sets geom point opacity for continuous data.

  This scale defines a mapping function that assigns an opacity to be mapped to a given
  value of the mapped variable.

  This function takes the following options:

  - `:range` - a tuple with minimum (default - `0.1`) and maximum (default - `1`)
  values to be bound to the data
  """
  @spec scale_alpha_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_alpha_continuous(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :alpha, Scale.Alpha.Continuous.new(options)))
  end

  @doc """
  Sets geom point opacity for categorical data.

  For categorical data for which a linear mapping of values to opacity is not
  appropriate, this scale generates a palette of evenly spaced opacity values
  mapped to each unique value of the data. The palette is generated such that the
  difference between each opacity value is maximized. The set of unique data values
  are sorted for the purpose of assigning them to an opacity and ordering the legend.

  This function also takes the following options:

  - `:labels` - specifies how legend item names (levels of the scale) should be
  formatted. See `GGity.Labels` for valid values for this option.

  - `:range` - a tuple with minimum (default - `0.1`) and maximum (default - `1`)
  values to be bound to the data
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

  This scale defines a mapping function that assigns a shape area based on the  given
  value of the mapped variable.

  This function takes the following options:

  - `:range` - a tuple with minimum (default - `9`) and maximum (default - `100`)
  values to be bound to the data
  """
  @spec scale_size(Plot.t(), keyword()) :: Plot.t()
  def scale_size(%Plot{} = plot, options \\ []) do
    struct(plot, scales: Map.put(plot.scales, :size, Scale.Size.new(options)))
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
  - `:date_labels` - special formatting patterns for dates. If `:date_labels` is specified,
  the value of the `:labels` option will be overridden.

  `:date_labels` can be either a format string pattern that is accepted by [`NimbleStrftime`](https://hexdocs.pm/nimble_strftime/NimbleStrftime.html):

      data
      |> Plot.new(%{x: :date_variable, y: :other_variable})
      |> Plot.geom_line()
      |> Plot.scale_x_date(date_labels: "%b %d %Y") # Label format "Jan 01 2001"

  or a tuple `{format, options}` where `format` is the pattern and `options` is a keyword
  list of options accepted by `NimbleStrftime.format/3`:

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
  - `:date_labels` - special formatting patterns for dates. If `:date_labels` is specified,
  the value of the `:labels` option will be overridden.

  `:date_labels` can be either a format string pattern that is accepted by [`NimbleStrftime`](https://hexdocs.pm/nimble_strftime/NimbleStrftime.html):

  See `scale_x_date/2` for more usage examples.

      data
      |> Plot.new(%{x: :datetime_variable, y: :other_variable})
      |> Plot.geom_line()
      |> Plot.scale_x_datetime(date_labels: "%b %d H%H") # Label format "Jan 01 H01"

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
    Enum.reduce([:y, :y_max], plot, fn aesthetic, plot ->
      if plot.scales[aesthetic] do
        struct(plot, scales: Map.put(plot.scales, aesthetic, Scale.Y.Continuous.new(options)))
      else
        struct(plot, scales: Map.put(plot.scales, :y, Scale.Y.Continuous.new(options)))
      end
    end)
  end

  @doc """
  Updates the plot theme.

  GGity uses themes to style non-data plot elements. The default theme is similar
  to ggplot2's signature gray background/white gridline theme.

  `theme/2` is used to update on or more elements of the plot theme by passing
  a keyword list of new elements and values, which are merged with those of the
  current theme.

  For supported elements and values, see `GGity.Theme`.
  """
  @spec theme(Plot.t(), keyword()) :: Plot.t()
  def theme(%Plot{} = plot, elements) do
    elements = Enum.into(elements, %{})

    theme =
      Map.merge(plot.theme, elements, fn
        _key, _original_value, nil ->
          nil

        _key, nil, new_value ->
          new_value

        _key, original_value, new_value when is_map(original_value) ->
          Map.merge(original_value, new_value, fn
            _key, original, nil -> original
            _key, _original, new -> new
          end)

        _key, _original_value, new_value ->
          new_value
      end)

    struct(plot, theme: theme)
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
    labels = Map.merge(plot.labels, %{x: label})
    struct(plot, labels: labels)
  end

  @doc """
  Updates the plot y axis label.
  """
  @spec ylab(Plot.t(), binary()) :: Plot.t()
  def ylab(plot, label) do
    labels = Map.merge(plot.labels, %{y: label})
    struct(plot, labels: labels)
  end

  @doc """
  Manually sets the type of guide used for specified scales.

  Accepts a keyword list of aesthetics and values for the `:guide` options
  for the associated scales.

  Currently this is only used to turn legends on or off. Valid values are
  `:legend` (draw a legend) and `:none` (do not draw a legend).

  ## Example

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
  Convenience method that returns an IO List with an XML declaration, in order
  to support output to a standalone `.svg` file. `Plot.to_xml/2` takes a second
  argument specifying a fixed height for the SVG element. A fixed width is also
  added, equal to the height multiplied by the plot's aspect ration.
  """
  @spec to_xml(Plot.t()) :: iolist()
  def to_xml(%Plot{} = plot) do
    xml_declaration = ~s|<?xml version="1.0" encoding="utf-8"?>|
    [xml_declaration | Plot.plot(plot)]
  end

  @spec to_xml(Plot.t(), number()) :: iolist()
  def to_xml(%Plot{} = plot, height) do
    xml_declaration = ~s|<?xml version="1.0" encoding="utf-8"?>|
    dimensions = ~s| height="#{height}" width="#{height * plot.aspect_ratio}"|

    [first, second | tail] = Plot.plot(plot)
    [xml_declaration, first, second, dimensions | tail]
  end
end
