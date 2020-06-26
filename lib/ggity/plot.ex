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
  alias GGity.{Draw, Geom, Legend, Scale}

  @type t() :: %__MODULE__{}
  @type column() :: list()
  @type name() :: binary() | atom()
  @type record() :: map()
  @type mapping() :: map()
  @type options() :: keyword()

  defstruct data: [],
            mapping: %{},
            width: 200,
            aspect_ratio: 1.5,
            plot_width: 500,
            labels: %{},
            panel_background_color: "#eeeeee",
            margins: %{left: 30, top: 10, right: 0, bottom: 0},
            geom: nil

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
  @spec new(list(record()), mapping(), options()) :: Plot.t()
  def new(data, %{x: x_name, y: y_name} = mapping, options \\ []) do
    geom =
      Keyword.get(options, :geom, Geom.Blank)
      |> struct()
      |> Geom.new(data, mapping, options)

    labels = %{title: nil, x: x_name, y: y_name}

    struct(Plot, options)
    |> struct(%{data: data, mapping: mapping, geom: geom, labels: labels})
  end

  @doc """
  Generates an iolist of SVG markup representing a `Plot`.

  The data is not sanitized; users should be mindful of the risks of generating a plot
  with user-defined data and parameters.

  The `Plot` struct's `:plot_width` and `:aspect_ratio` values are used to set the height
  and width properties of the SVG. The viewBox property is set by the plot's `:width` and
  `aspect_ratio` values.
  """
  @spec plot(Plot.t()) :: iolist()
  def plot(%Plot{} = plot) do
    viewbox_width = plot.width * 7 / 4

    [
      draw_background(plot),
      draw_geom(plot),
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

  @doc """
  Adds a point geom to the plot.

  Accepts a mapping and/or additonal options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings, for example, unless the intent is
  to override them.

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

  @doc """
  Adds a line geom to the plot.

  Accepts a mapping and/or additonal options to be used. The provided mapping
  is merged with the plot mapping for purposes of the geom - there is no need
  to re-specify the `:x` or `:y` mappings, for example, unless the intent is
  to override them.

  Line geoms only support mappings for the `:x` and `:y` aesthetics. By default,
  the `:x` aesthetic will use continuous number/`Date`/`DateTime` scales based on the
  type of value in first record.

  Note that the line geom sorts the data by the values for the variable mapped
  to the `:x` aesthetic using Erlang default term ordering.

  Fixed values for other aesthetics can be specified as options, e.g., `color: "blue"`.
  This fixed value is assigned to the aesthetic for all observations. Supported
  aesthetics include:

  * `:alpha`
  * `:color`
  * `:size`
  * `:linetype`

  Other supported options:

  * `:area_padding` - amount of blank space before the first tick and after the last
  tick on each axis (same value applied to both axes) defaults to `10`.
  * `:breaks` - the number of tick intervals on the x- and y axis (same value applied
  to both axes). This may be adjusted by the scale function based on the data. Defaults to `5`.
  * `:y_label_padding` - vertical distance between the y axis and its label. Defaults to `20`.
  """

  @spec geom_line(Plot.t(), map() | keyword(), keyword()) :: Plot.t()
  def geom_line(plot, mapping \\ [], options \\ [])

  def geom_line(%Plot{} = plot, [], []) do
    add_geom(plot, Geom.Line)
  end

  def geom_line(%Plot{} = plot, mapping_or_options, []) do
    add_geom(plot, Geom.Line, mapping_or_options)
  end

  def geom_line(%Plot{} = plot, mapping, options) do
    add_geom(plot, Geom.Line, mapping, options)
  end

  defp add_geom(%Plot{} = plot, geom_type) do
    geom =
      struct(geom_type)
      |> Geom.new(plot.data, plot.mapping, [])
      |> struct(labels: plot.labels)

    struct(plot, geom: geom)
  end

  defp add_geom(%Plot{} = plot, geom_type, mapping) when is_map(mapping) do
    mapping = Map.merge(plot.mapping, mapping)

    geom =
      struct(geom_type)
      |> Geom.new(plot.data, mapping, [])
      |> struct(labels: plot.labels)

    struct(plot, geom: geom)
  end

  defp add_geom(%Plot{} = plot, geom_type, options) when is_list(options) do
    geom =
      struct(geom_type)
      |> Geom.new(plot.data, plot.mapping, options)
      |> struct(labels: plot.labels)

    struct(plot, geom: geom)
  end

  defp add_geom(%Plot{} = plot, geom_type, mapping, options) do
    mapping = Map.merge(plot.mapping, mapping)

    geom =
      struct(geom_type)
      |> Geom.new(plot.data, mapping, options)
      |> struct(labels: plot.labels)

    struct(plot, geom: geom)
  end

  @doc """
  Sets geom point opacity for continuous data.

  This scale defines a mapping function that assigns an opacity value between
  `0.1` and `1` to a given value of the mapped variable.
  """
  @spec scale_alpha_continuous(Plot.t(), keyword()) :: Plot.t()
  def scale_alpha_continuous(%Plot{} = plot, options \\ []) do
    alpha_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:alpha]) end)
      |> Scale.Alpha.Continuous.new(options)

    updated_geom = struct(plot.geom, alpha_scale: alpha_scale)
    struct(plot, geom: updated_geom)
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
    alpha_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:alpha]) end)
      |> Scale.Alpha.Discrete.new(options)

    updated_geom = struct(plot.geom, alpha_scale: alpha_scale)
    struct(plot, geom: updated_geom)
  end

  @doc """
  Sets geom point opacity using the value of the data mapped to the `:alpha` aesthetic.
  Can be used to manually assign opacity to individual data points by including an
  value with each observation.

  See `scale_color_identity/1` for an example of identity scale use.
  """
  @spec scale_alpha_identity(Plot.t()) :: Plot.t()
  def scale_alpha_identity(%Plot{} = plot) do
    updated_geom = struct(plot.geom, alpha_scale: Scale.Identity.new(plot, :alpha))
    struct(plot, geom: updated_geom)
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
    updated_geom = struct(plot.geom, color_scale: Scale.Identity.new(plot, :color))
    struct(plot, geom: updated_geom)
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
    color_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:color]) end)
      |> Scale.Color.Viridis.new(options)

    updated_geom = struct(plot.geom, color_scale: color_scale)
    struct(plot, geom: updated_geom)
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
    shape_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:size]) end)
      |> Scale.Shape.new(options)

    updated_geom = struct(plot.geom, shape_scale: shape_scale)
    struct(plot, geom: updated_geom)
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
    size_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:size]) end)
      |> Scale.Size.Continuous.new(options)

    updated_geom = struct(plot.geom, size_scale: size_scale)
    struct(plot, geom: updated_geom)
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
    size_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:size]) end)
      |> Scale.Size.Discrete.new(options)

    updated_geom = struct(plot.geom, size_scale: size_scale)
    struct(plot, geom: updated_geom)
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
    updated_geom = struct(plot.geom, size_scale: Scale.Identity.new(plot, :size))
    struct(plot, geom: updated_geom)
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
    x_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:x]) end)
      |> Scale.X.Continuous.new(options)

    updated_geom = struct(plot.geom, x_scale: x_scale)
    struct(plot, geom: updated_geom)
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
    x_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:x]) end)
      |> Scale.X.Date.new(options)

    updated_geom = struct(plot.geom, x_scale: x_scale)
    struct(plot, geom: updated_geom)
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
    x_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:x]) end)
      |> Scale.X.DateTime.new(options)

    updated_geom = struct(plot.geom, x_scale: x_scale)
    struct(plot, geom: updated_geom)
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
    y_scale =
      plot.data
      |> Enum.map(fn row -> Map.get(row, plot.geom.mapping[:y]) end)
      |> Scale.Y.Continuous.new(options)

    updated_geom = struct(plot.geom, y_scale: y_scale)
    struct(plot, geom: updated_geom)
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
  def xlab(plot, label) do
    labels =
      plot.geom.labels
      |> Map.merge(%{x: label})

    geom =
      plot.geom
      |> Map.put(:labels, labels)

    struct(plot, labels: Map.merge(plot.labels, labels), geom: geom)
  end

  @doc """
  Updates the plot y axis label.
  """
  @spec ylab(Plot.t(), binary()) :: Plot.t()
  def ylab(plot, label) do
    labels =
      plot.geom.labels
      |> Map.merge(%{y: label})

    geom =
      plot.geom
      |> Map.put(:labels, labels)

    struct(plot, labels: Map.merge(plot.labels, labels), geom: geom)
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
    updated_scales =
      Keyword.take(guides, [:alpha, :color, :size, :shape])
      |> Enum.reduce([], fn {aesthetic, value}, scales_list ->
        new_scale =
          plot
          |> scale_for_aesthetic(aesthetic)
          |> struct(guide: value)

        [{scale_key_for_aesthetic(aesthetic), new_scale} | scales_list]
      end)

      %Plot{plot | geom: struct(plot.geom, updated_scales)}
  end

  defp scale_for_aesthetic(plot, aesthetic) do
    Map.get(plot.geom, scale_key_for_aesthetic(aesthetic))
  end

  defp scale_key_for_aesthetic(aesthetic) do
    Atom.to_string(aesthetic) <> "_scale"
    |> String.to_existing_atom()
  end

  @doc """
  Saves the plot to a file at the given path.
  """
  @spec to_file(Plot.t(), list(binary)) :: :ok
  def to_file(%Plot{} = plot, path) do
    File.write!(path, plot(plot))
  end

  defp draw_background(%Plot{margins: margins, geom: geom} = plot) do
    left_shift = margins.left + geom.y_label_padding
    top_shift = margins.top + title_margin(plot)

    Draw.rect(
      x: "0",
      y: "0",
      height: to_string(plot.width / plot.aspect_ratio + geom.area_padding * 2),
      width: to_string(plot.width + geom.area_padding * 2),
      fill: plot.panel_background_color
    )
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp title_margin(%Plot{labels: %{title: title}}) when is_binary(title), do: 10

  defp title_margin(%Plot{}), do: 0

  defp draw_title(%Plot{labels: %{title: title}}) when not is_binary(title), do: ""

  defp draw_title(%Plot{margins: margins, geom: geom} = plot) do
    left_shift = margins.left + geom.y_label_padding
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

  defp draw_geom(%Plot{margins: margins} = plot) do
    left_shift = margins.left + plot.geom.y_label_padding
    top_shift = margins.top + title_margin(plot)

    Geom.draw(plot.geom, plot.data)
    |> Draw.g(transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_legend_group(%Plot{geom: %Geom.Line{}}), do: []

  defp draw_legend_group(plot) do
    {legend_group, legend_group_height} =
      Enum.reduce(
        [:alpha_scale, :color_scale, :shape_scale, :size_scale],
        {[], 0},
        fn scale, {legends, offset_acc} ->
          {[draw_legend(plot, scale, offset_acc) | legends],
           offset_acc + Legend.legend_height(Map.get(plot.geom, scale))}
        end
      )

    left_shift = plot.margins.left + plot.geom.y_label_padding + plot.width + 25

    top_shift =
      plot.margins.top + title_margin(plot) + plot.width / plot.aspect_ratio / 2 + 10 -
        legend_group_height / 2 + 10

    Draw.g(legend_group, transform: "translate(#{left_shift}, #{top_shift})")
  end

  defp draw_legend(%Plot{} = plot, scale, offset) do
    aesthetic =
      Atom.to_string(scale)
      |> String.split("_")
      |> hd()
      |> String.to_existing_atom()

    label = plot.labels[aesthetic] || plot.geom.mapping[aesthetic]
    scale = Map.get(plot.geom, scale)

    case Legend.legend_height(scale) do
      0 ->
        []

      _positive ->
        Legend.draw_legend(scale, label)
        |> Draw.g(transform: "translate(0, #{offset})")
    end
  end
end
