# Roadmap

## v0.2 
* [COMPLETE] Better formatting of axis numbers and dates
* [COMPLETE] Allow selective inclusion of legends (for some scales and not others)
* [COMPLETE] Bar charts
* [COMPLETE] Allow text to be used as shape <s>(i.e., geom_text)</s>
* [COMPLETE] Support grouping, legends for line charts 

## v0.3 
* [COMPLETE] Internal overhaul to implement layers and split out stats (at least) from the geom context
* Add `geom_text` to support data point labeling
* Support CSS styling (use themes, but via inline CSS to allow overrides via custom stylesheet)
* Add other non-fillable shapes to shapes palette
* Add fillable shapes to shapes palette
* Draw legend on any side of the plot (top/left/bottom/right)
* Support faceting
* Publish to Hex

## v0.4
* Area charts
* Boxplots
* Continuous color scale (including legends)
* Implement x_lim/y_lim
* ggplot2-ify gridlines approach (breaks, minor breaks)
* Support general annotation drawing

## v0.5
* Support a LiveView sample app
* Implement a method for rendering new points and updating scales only

## Beyond
* Would an SVG diffing tool help with development?