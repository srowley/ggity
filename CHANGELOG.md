# Changelog

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased
### Added
- Added `:custom_attributes` to the `Bar`, `Boxplot`, `Point`, `Rect`,
`Segment` and `Text` geoms. This option can contain a function that takes
the plot and a row of data and returns a keyword list of custom attribute/value
pairs that are then added to the the SVG element representing that data on
the plot. Custom attributes could be data attributes, Phoenix LiveView event
handlers or Alpine.js snippets, for example.
- Boxplot geoms with `Plot.geom_boxplot/3`
- Added `Plot.annotate/2`, which supports adding text, rectangle and line
(`:segment`) annotations
- Added `Geom.Rect` and `Geom.Segment`. These geoms can be added to a plot
indirectly using annotations (for a single row of data) or by creating a
a layer using `Layer.new/3` and prepending it to the list contained in the
`:layers` value for a `Plot` struct. `Plot.geom_rect/3` and
`Plot.geom_segment/3` as well as visual tests for the conventional approach
will come, but most of the time these geoms are best suited for annotations
as opposed to mapping multiple rows of data to a plot.

### Changed
- Replaced `Plot.to_file/2` with `Plot.to_xml/1`. The former returned a file;
the new version simply adds an XML declaration and allows the user to pass
the IO List to `File.write!/3` or otherwise. `Plot.to_xml/2` takes the plot
height as a second argument and adds a fixed height and width to the SVG
element. Width is calculated using the plot's aspect ratio. This is helpful
for generating files where there is no control over dimensions of the parent
element (e.g., Markdown-generated documentation).
- Text that is rendered in a SVG `<text>` element is escaped using the code
from Plug.HTML. This includes plot/axis/legend labels and `Geom.Text`
elements.
- Values for attributes in the inline stylesheet generated from a theme
are validated. Numerical attributes are confirmed to be numbers, values
for colors are confirmed to be hex values or valid CSS color names, and
the value for `:face` is checked against a list of allowed values. 
Invalid property-value pairs are not included in the rendered stylesheet.

    The only attribute not validated is `:family`. This value is HTML-escaped,
but still poses a security risk if it is set with untrusted data.
- Replaced interpolated strings with IO Lists in various parts of the stylesheet
generation function chain.
- Changed some default theme values to improve quality of sample charts.
- Added top and right default margins to improve quality of sample charts.

### Fixed
- Y-coordinate scale and axis functions properly handle dataset
with no range (same min and max value, or only one value).
- A theme's `:face` property sets the value of the CSS `font-weight`
attribute in conformance with the ggplot2 API.
- `:nudge_y` property sign for `Geom.Text` reversed to conform to ggplot2 API.

## v0.3.1 - 2020-12-08
### Fixed
- Fixed visual test error for new cloned repos
- Miscellaneous doc updates

## v0.3 - 2020-11-25
### Added
- Plots can display multiple layers, with each layer supplying its own data and
mapping. Each layer is added using the applicable `Plot.geom_*` function.
The plot expands the extents of ("trains") the scale used for each aesthetic to
include the combined domain of the data mapped to that aesthetic. Mappings
and data still default to the plot mapping and data. Updating the mapping for a
layer is unchanged (the passed map is merged with the plot mapping). A
layer-specific data set can be provided by passing the `data` option with a
dataset to `Plot.geom_*`. Run `mix ggity.visual.layers` for examples.
- Added `Geom.Text`; helpful for labelling bar plots
- Added theme support. Each plot has a Theme struct that stores the attributes
of non-data elements of the plot (titles, borders, backgrouns and more). A
plot's theme can be updated using `Plot.theme/2`. Attributes that are also 
CSS presentation attributes are implemented via custom classes that can also be
styled with an external stylesheet.
- Added ribbon geoms. These are primarily useful for drawing area/stacked area
charts, but are also good for drawing a confidence interval around a line.
- Added support for rotating x-axis tick labels.
- Discrete alpha and size scales accept a tuple with min/max values for 
creating a palette.

### Changed
- Substantial overhaul of plot, geom and scale internals in order to
accommodate layers
- No longer set an SVG width/height (remove Plot `:plot_width` attribute). This
is unnecessary and messes up scaling
- No longer document Plot `:width` attribute (setting the panel width); this
number should not be changed from its default value 
- Date/DateTime tick intervals are now nice time multiples thanks to Contex
- Discrete size scale now draws a legend
- Size scales map to area, not radius
- Removed legend whitespace if no legend is drawn
- Bars sort by alpha, not just fill
- Change min/max options for size/alpha continuous scales to conform to ggplot2 API
- Moved axis drawing code to separate (private) Axis module
- `Geom.Line.sort_by_x/2` is fully private (was never part of the public API)
- `Geom.Point.points/2` is fully private (was never part of the public API)
- `Geom.Line.lines/2` is fully private (was never part of the public API)

### Fixed
- Fixed bug related to training of date/datetime scales
- `mix.ggity.visual --wsl` no longer fails if a browser is open. Instead
it opens tabs and as a bonus stops blocking the terminal process. If no
window is open it works as before.

## v0.2.1 - 2020-07-06
### Added
- License information for matplotlib (viridis) and cividis color palettes

### Fixed
- Continuous scales can handle zero-length domains

## v0.2 - 2020-07-05
### Added

- Bar charts (i.e., `Plot.geom_bar/3` and `Plot.geom_col/3`)
- Visual tests for `Geom.Bar`
- `Stat` to support count transformation for bar charts
- Default grouping for line charts applied to all applicable scales
- `Scale.Linetype.Discrete` for line charts
- Additional legend key glyphs
- `economics_long` dataset to support testing of line chart grouping
- Initial support for bar charts in stacked or dodged position, fill mapping and stat_count only
- `Scale.Fill.Viridis` to support bar chart aesthetic
- `Scale.X.Discrete`, a prerequisite for implementing bar charts
- Legends can be toggled on and off with `Plot.guides/2` or by passing `guide: :none`/`guide: :legend`
to a scale constructor
- Robust axis and legend item label formatting via `:labels` option passed to scale constructors. This
supports the same options as the ggplot2 scales except for passing a vector (list) of values
to replace the calculated labels
- Dependency on NimbleStrftime (expected to be removed when this module is added to Elixir 1.11)
- Support for date_label formatting via the `:date_labels` option. This option can be a pattern
accepted by NimbleStrftime, or a tuple with a pattern and a keyword list of options used by NimbleStrftime

### Changed

- Various minor documentation improvements.
- `Geom.Blank` returns an empty list instead of a list with an unnecessary empty string

### Removed 

- An extra list traversal in `Scale.Color.Viridis`
- Rogue comment in `Scale.Alpha.Continuous`
- Rogue comment in `mix.exs`
- Unnecessary `geom()` type from `Scale.Color.Viridis`
