# Changelog

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased
### Added
- Plots can display multiple layers, with each layer supplying its own data and
mapping. Each layer is added using the applicable `Plot.geom_*` function.
The plot expands the extents of ("trains") the scale used for each aesthetic to
include the combined domain of the data mapped to that aesthetic. Mappings
and data still default to the plot mapping and data. Updating the mapping for a
layer is unchanged (the passed map is merged with the plot mapping). A
layer-specific data set can be provided by passing the `data` option with a
dataset to `Plot.geom_*`. Run `mix ggity.visual.layers` for examples.

### Changed
- No breaking changes to the public API
- Substantial overhaul of plot, geom and scale internals in order to
accommodate layers
- Moved axis drawing code to separate (private) Axis module
- `Geom.Line.sort_by_x/2` is private
- `Geom.Point.points/2` is private
- `Geom.Line.lines/2` is private

### Fixed
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
