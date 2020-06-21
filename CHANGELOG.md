# Changelog

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Added

- Date/DateTime tick values on the x axis can be formatted by passing a pattern
to `Plot.scale_x_[date | datetime]`.
- Added dependency on NimbleStrftime (expected to be removed when this module is added to Elixir 1.11)

### Changed

- Fixed typos in README, `Scale.X.Continuous`
- Eliminated an extra list traversal in `Scale.Color.Viridis`
- `Geom.Blank` returns an empty list instead of a list with an unnecessary empty string

### Removed 

- Deleted rogue comment in `Scale.Alpha.Continuous`
- Deleted rogue comment in `mix.exs`
- Removed unnecessary `geom()` type from `Scale.Color.Viridis`
