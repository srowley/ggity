# Roadmap

## v0.2 
* [COMPLETE] Better formatting of axis numbers and dates
* [COMPLETE] Allow selective inclusion of legends (for some scales and not others)
* [Partially Complete] Bar charts (supports fill aesthetic and `stat_count`; other aesthetics and `stat_identity` pending)
* [COMPLETE] Allow text to be used as shape <s>(i.e., geom_text)</s>
* [COMPLETE] Support grouping, legends for line charts 
* Internal overhaul to implement layers and split out stats (at least) from the geom context

## v0.3 
* Add other non-fillable shapes to shapes palette
* Add fillable shapes to shapes palette
* Draw legend on any side of the plot (top/left/bottom/right)
* Support faceting
* Support CSS styling
* Publish to Hex

## v0.4
* Area charts
* Continuous color scale
* Legends for continuous scales
* Implement x_lim/y_lim
* Use viewBox to resize titles, tick labels, etc. for space
* ggplot2-ify gridlines approach (breaks, minor breaks)
* Support general annotation drawing

## v0.5
* Support a LiveView sample app
* Implement a method for rendering new points and updating scales only

## Beyond
* Would an SVG diffing tool help with development?