```
# The viridis scale is the default color scale
Examples.diamonds()
|> Explorer.DataFrame.sample(1000, seed: 100)
|> Plot.new(%{x: "carat", y: "price"})
|> Plot.geom_point(%{color: "clarity"})
|> Plot.plot()

```
![](assets/scale_color_viridis_1.svg)
```
# Use the :option option to select a palette
cities = Explorer.Series.from_list([
  "Houston",
  "Fort Worth",
  "San Antonio",
  "Dallas",
  "Austin"
])

Examples.tx_housing()
|> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities))
|> Plot.new(%{x: "sales", y: "median"})
|> Plot.geom_point(%{color: "city"})
|> Plot.scale_color_viridis(option: :plasma)
|> Plot.plot()

```
![](assets/scale_color_viridis_2.svg)
```
cities = Explorer.Series.from_list([
  "Houston",
  "Fort Worth",
  "San Antonio",
  "Dallas",
  "Austin"
])

Examples.tx_housing()
|> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities))
|> Plot.new(%{x: "sales", y: "median"})
|> Plot.geom_point(%{color: "city"})
|> Plot.scale_color_viridis(option: :inferno)
|> Plot.plot()

```
![](assets/scale_color_viridis_3.svg)
