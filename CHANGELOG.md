# Changelog

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Added

- Added `Scale.X.Discrete`, a prerequisite for implementing bar charts.
- Legends can be toggled on and off with `Plot.guides/2` or by passing `guide: :none`/`guide: :legend`
to a scale constructor.
- Added robust axis and legend item label formatting via `:labels` option passed to scale constructors. This
supports the same options as the ggplot2 scales except for passing a vector (list) of values
to replace the calculated labels.
- Added dependency on NimbleStrftime (expected to be removed when this module is added to Elixir 1.11)
- Added support for date_label formatting via the `:date_labels` option. This option can be a pattern
accepted by NimbleStrftime, or a tuple with a pattern and a keyword list of options used by NimbleStrftime. 

### Changed

- Various minor documentation improvements.
- Eliminated an extra list traversal in `Scale.Color.Viridis`
- `Geom.Blank` returns an empty list instead of a list with an unnecessary empty string

### Removed 

- Deleted rogue comment in `Scale.Alpha.Continuous`
- Deleted rogue comment in `mix.exs`
- Removed unnecessary `geom()` type from `Scale.Color.Viridis`
