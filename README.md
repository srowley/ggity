# GGity

[![Module Version](https://img.shields.io/hexpm/v/ggity.svg)](https://hex.pm/packages/ggity)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ggity/)
[![Total Download](https://img.shields.io/hexpm/dt/ggity.svg)](https://hex.pm/packages/ggity)
[![License](https://img.shields.io/hexpm/l/ggity.svg)](https://github.com/srowley/ggity/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/srowley/ggity.svg)](https://github.com/srowley/ggity/commits/master)

GGity brings the familiar interface of R's ggplot2 library to SVG charting in Elixir.

## Overview

GGity brings a subset of the functionality of ggplot2 to creating data visualizations in Elixir.

As such constructing a plot in GGity is based on the same priniciples - a plot is composed of one or more layers,
where each layer includes:

* Data - in GGity, data is represented using [Explorer](https://hexdocs.pm/explorer/Explorer.html) dataframes.
Plots can also be created from a list of maps; GGity will convert the list to a dataframe. GGity does not yet 
handle missing values or fancy values like `:nan` or `:infinity`.

* Geom - a visible shape/object (such a point, a bar or a line), the characteristics of which will be determined based on
the values of the data (e.g., the x-coordinate mapped to one variable, the y-coordinate to another, the color of a point
to a third variable).

* Mapping - a map that indicates which characteristics (aesthetics, in ggplot2 parlance) will be tied to which variables.

* Position adjustment - a method for adjusting the position of overlapping geoms. For example, a stacked bar chart maps
x-coordinates and colors based on variables, but the y-coordinates for each part of the stack need to be adjusted in order
to avoid placing all of the bars for one x value on top of one another.

* Stat (statistical transformation) - sometimes we do not actually want to map the data to shapes on plot. Instead we
want to perform some calculations on the data and plot that. For example, a histogram plots the number of observations
of a given value for a given variable organized into groups based on ranges of values ("bins"). Given a dataset, the plot
is mapping those ranges and value counts to shapes, not the raw data. The calculation of those transformed values is
a stat.

## Example

```elixir
cities = Explorer.Series.from_list(["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"])

# GGity includes several sample datasets in the Examples module
Examples.tx_housing()
|> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities)) # Only plot specific cities

# Plot sales (x) by median price (y)
|> Plot.new(%{x: "sales", y: "median"})

# Add a title
|> Plot.labs(title: "Texas Home Values")

# Add a scatterplot layer; point color by city, with 40% opacity
|> Plot.geom_point(%{color: "city"}, alpha: 0.4)

# Use built-in label formatter for the x-axis labels
|> Plot.scale_x_continuous(labels: :commas)

# Custom format y-axis labels
|> Plot.scale_y_continuous(labels: fn value -> "$#{Labels.commas(round(value / 1000))}K" end)

# Choose color palette for color scale and custom format legend labels
|> Plot.scale_color_viridis(option: :magma, labels: fn value -> "#{value}!!!" end)

# Generate SVG chart as an IO list for use in a Phoenix template or string
|> Plot.plot()
```
![](guides/assets/geom_point_custom.svg)

GGity supports scatterplots, bar charts, line charts, area/ribbon charts and boxplots. The GGity documentation includes
guides for each geom and other key concepts with several examples of code and output. The plot background, axes, legends
and other non-geom elements can be styled using the ```Theme``` interface (useful when there could be dynamic changes) or
with an external stylesheet (plots generated by GGity include custom classes on these elements for this purpose).

## LiveView

GGity supports custom attributes, whereby each layer includes a function to which the row of data
used to draw an individual geom is passed (along with the plot itself). This function must return a keyword list of values
that will be added to the SVG element drawn for that data point. Custom attributes let the developer embed `phx-` event
handlers, Alpine.js directives, or even plain Javascript to each shape drawn on the plot, tied to the data represented by
that shape. 

For example:

```elixir
data
|> Plot.new(%{x: "x", y: "y"})
|> Plot.geom_point(
  custom_attributes: fn _plot, row ->
    [phx_click: "filter_by_y", phx_value_y: row["y"]]
  end
)
```

Draws a scatterplot where each `<circle>` element (which represents one row in the dataset) will include a `phx-click` handler
and a `phx-value-y` data attribute with the value of the y variable for the shape clicked on. The event handler for that event
could return a new plot with a dataset filtered to show only points within some specified range of the points clicked.

## Goals

I am interested in data visualization and after learning a lot from the work being done on [Contex](https://github.com/mindok/contex), I decided that starting to write a basic clone of ggplot2 would help me learn more about the grammar of graphics, ggplot2 and how to develop a reasonably nontrivial library for Elixir.

GGity's core design principle is that, if GGity supports a ggplot2 feature, it should be obvious to someone familiar with ggplot2 how to
access that feature in the GGity API. Hewing as closely as possible to ggplot2 also has the benefit of keeping the API more stable. To the
extent GGity supports features that extend or differ from the ggplot2 API, those interfaces are more likely to change. Extensions (things ggplot2 doesn't do, such as custom attributes) are likely to persist but could change as issues/improvements are discovered. Differences (things ggplot2 does, but in a different way) are almost always driven by my lack of figuring out how to implement a feature in a way that conforms to the ggplot2 approach. Those will change if/when I figure out how to do so.

## Warning and Invitation

I code as a hobby, so this is not something that is getting used frequently or in a production environment. I would love for people to try the library and provide feedback nonetheless.

## Alternatives

[Contex](https://github.com/mindok/contex) - Contex is simpler and well-suited for dashboards, for example. GGity is intended to be more oriented towards statistical graphics. Those who just want to draw a simple bar chart and are not familiar with grammar of graphics concepts will likely find Contex easier to use. 

## Visual tests

GGity has decent unit test coverage, but given the domain, a picture is worth a thousand words. The test suite includes 
several livebooks that represent the primary testing tools. 

## Build Process

The library includes an alias (```mix checks```) that runs Credo, the formatter and all the visual tests in sequence. I prefer to have all of those things in order before committing a change.

GGity also includes guides that serve as a sort of visual doctest - the guides include several code examples, and those code examples are used to generate the graphics in the documents (so as a user you know that the code in the example will definitely generate the graphic in the documentation). Before pushing a new feature, the docs are rebuilt using ```mix build_docs```. I am still working out how best to do this without making the commit history somewhat messy.

## Acknowledgements

I am very grateful to @mindok, the author of Contex, who graciously accepted and provided feedback on contributions to that library, which in turn inspired me to write this (and flat out copy some a few parts of Contex in so doing). I do not view GGity as a replacement for Contex; it is a personal opportunity for me to learn a lot at my own pace. I made it public in case it might be helpful to others as an example.

Acknowledgement is due to Hadley Wickham and others who have built [ggplot2](https://ggplot2.tidyverse.org/); the library is great, but Wickham's grammar of graphics is really an excellent piece of academic work in its own right. Along with Edward Tufte's book I think it is safe to say a golden age of visualization ensued.

I also want to recognize contributors to the [Explorer](https://github.com/elixir-nx/explorer) library, which to some degree inspired me to pick this back up again after a period of dormancy.

## Installation

Add `:ggity` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:ggity, "~> 0.5.0"}
  ]
end
```

GGity requires Elixir 1.14.

## License

This source code is licensed under the MIT license. Copyright (c) 2020-present, Steve Rowley.
