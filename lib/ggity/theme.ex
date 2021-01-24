defmodule GGity.Theme do
  @moduledoc """
  Themes store style and other attributes of non-geom elements of a plot.

  GGity generates an embedded stylesheet for the CSS presentation
  attributes of these elements that ties the specified styles to custom
  CSS classes that are automatically generated for each type of element.

  Classes are generated irrespective of theme values, thereby allowing for
  the use of external stylesheets. To avoid overriding a style in an external
  stylesheet, set the value of the attribute(s) styled externally to `nil` in
  a plot's theme - GGity will not include a style in the embedded stylesheet
  for an attribute with a `nil` value.

  Each key of a Theme struct represents a class. Allowed types for each item include:

  * `nil` - no selector or styles are generated for that class
  * `%Element.Line{}` struct - generates styles for a line element
  * `%Element.Rect{}` struct - generates styles for a rect element
  * `%Element.Text{}` struct - generates styles for a text element
  * An integer - for non-CSS attributes of a given element, e.g.,
  `:axis_ticks_length`, which sets the value of the `length` attribute

  See the documentation for each element type for allowed keys and values. Keys conform
  to the ggplot2 API, which means that a given attribute does not necessarily
  correspond to the CSS attribute of the same name. For example, `:size` means
  CSS `stroke-width` for lines and rectangles, and CSS `font-size` for text.

  Element structs can be generated using the constructor function for that
  element type:

  ```
  import GGity.Element.Text
  alias GGity.Plot

  Plot.theme(plot, axis_text: element_text(color: "green", size: 12))
  #=> equivalent to Plot.theme(plot, axis_text: %GGity.Element.Text{color: "green", size 12})
  ```

  The following attributes are supported:

  * `:text` style for all non-data text; overriden by other text attributes (`Element.Text`)
  * `:axis_line` x- and y axes lines (`Element.Line`)
  * `:axis_line_x` x axis; overrides `:axis_line` (`Element.Line`)
  * `:axis_line_y` y axis; overrides `:axis_line` (`Element.Line`)
  * `:axis_text` x- and y axis tick label text (`Element.Text`)
  * `:axis_text_x` x axis tick label text; overrides `:axis_text` (`Element.Text`)
  * `:axis_text_y` y axis tick label text; overrides `:axis_text` (`Element.Text`)
  * `:axis_ticks` x- and y axis ticks (`Element.Line`)
  * `:axis_line_x` x axis ticks; overrides `:axis_ticks` (`Element.Line`)
  * `:axis_line_y` y axis ticks; overrides `:axis_ticks` (`Element.Line`)
  * `:axis_ticks_length` length of x- and y axis ticks (`Integer` - non-CSS attribute)
  * `:axis_ticks_x_length` length of x axis tick; overrides `:axis_tick_length` (`Integer`)
  * `:axis_ticks_y_length` length of y axis tick; overrides `:axis_tick_length` (`Integer`)
  * `:axis_title` x- and y axis title text (`Element.Text`)
  * `:axis_title_x` x axis title text; overrides `:axis_title` (`Element.Text`)
  * `:axis_title_y` y axis title text; overrides `:axis_title` (`Element.Text`)
  * `:legend_key` legend key glyph box (`Element.Rect`)
  * `:legend_text` legend item text (`Element.Text`)
  * `:legend_title` legend title text (`Element.Text`)
  * `:panel_background` panel (area bounded by axes) background (`Element.Rect`)
  * `:panel_border` panel border (`Element.Line`)
  * `:panel_grid` minor and major gridlines (`Element.Line`)
  * `:panel_grid_major` major gridlines; overrides `panel_grid` (`Element.Line`)
  * `:panel_grid_minor` minor gridlines; overrides `panel_grid` (`Element.Line`)
  * `:plot_title` plot title text (`Element.Text`)
  * `:plot_background` plot (entire SVG element) background (`Element.Rect`)

  ## Security Considerations

  There is a [significant security literature](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.md)
  highlighting the risk associated with using embedded stylesheets. As a GGity user,
  you can address this risk in a few ways:

  1) Do not use GGity themes at all, by setting the `:theme` attribute of the `Plot`
  struct to `nil`. Use an external stylesheet that takes advantage of
  the classes that GGity attaches to elements of the plot. This option works well if
  plot styles do not need to be updated dynamically or stored in the same file as the
  SVG document. An external stylesheet also eliminates the overhead associated with
  generating and transmitting an embedded stylesheet every time the plot is rendered.

  2) Do not pass untrusted data (directly or indirectly) to `Plot.theme/2`. Depending
  on your use case, this may or may not be difficult to enforce with confidence.

  If neither of these approaches are an option, GGity attempts to mitigate risk by
  HTML-escaping data that is rendered in a `<text>` element and by validating the values
  in each kind of `Element` struct prior to rendering. Most `Element` struct attributes
  are either colors (represented with strings) or numbers. GGity will not render those
  attributes if the value is invalid (colors must be a valid CSS color name or a hex
  value). Similarly, the `:face` attribute of an `Element.Text` struct is compared
  against a list of acceptable values.

  This leaves the `:family` attribute of an `Element.Text` struct. These values are HTML-escaped,
  but are not otherwise sanitized and should not be set using untrusted data.
  """

  import GGity.Element.{Line, Rect, Text}

  alias GGity.{Element, Theme}

  @type t() :: %__MODULE__{}

  defstruct text: element_text(family: "Helvetica, Arial, sans-serif"),
            axis_line: nil,
            axis_line_x: nil,
            axis_line_y: nil,
            axis_text: element_text(color: "#808080", size: 6),
            axis_text_x: element_text(color: "#808080", size: 6, angle: 0),
            axis_text_y: nil,
            axis_ticks: element_line(color: "#000000"),
            axis_ticks_x: nil,
            axis_ticks_y: nil,
            axis_ticks_length: 2,
            axis_ticks_length_x: nil,
            axis_ticks_length_y: nil,
            axis_title: element_text(color: "#000000", size: 8),
            axis_title_x: nil,
            axis_title_y: nil,
            legend_key:
              element_rect(
                fill: "#EEEEEE",
                color: "#EEEEEE",
                size: 0.5,
                height: 15
              ),
            legend_text: element_text(fill: "#000000", size: 6),
            legend_title: element_text(fill: "#000000", size: 8),
            panel_background: element_rect(fill: "#EEEEEE"),
            panel_border: element_line(color: "none"),
            panel_grid: element_line(color: "#FFFFFF"),
            panel_grid_major: element_line(size: 1),
            panel_grid_minor: element_line(size: 0.5),
            plot_background: element_rect(fill: "#FFFFFF"),
            plot_title: element_text(size: 12)

  @doc false
  @spec to_stylesheet(Theme.t() | nil, binary()) :: iolist()
  def to_stylesheet(nil, _id), do: []

  def to_stylesheet(%Theme{} = theme, id) do
    [
      "<style type=\"text/css\"><![CDATA[",
      theme_to_stylesheet(theme, id),
      "]]></style>"
    ]
  end

  defp theme_to_stylesheet(%Theme{} = theme, id) do
    theme
    |> Map.from_struct()
    |> Enum.map(fn attribute -> generate_attribute_style(theme, attribute, id) end)
  end

  defp generate_attribute_style(theme, {attribute, element}, id) when is_struct(element) do
    ["#", id, " ", Element.to_css(Map.get(theme, attribute), gg_class(attribute)), " "]
  end

  defp generate_attribute_style(_theme_, _attribute, _id), do: []

  defp gg_class(key) when is_atom(key) do
    attribute =
      key
      |> Atom.to_string()
      |> String.replace("_", "-")

    "gg-" <> attribute
  end
end
