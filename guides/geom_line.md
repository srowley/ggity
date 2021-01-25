```
Examples.economics()
|> Plot.new(%{x: "date", y: "unemploy"})
|> Plot.geom_line()
|> Plot.plot()

```
![](assets/geom_line_1.svg)
```
Examples.economics_long()
|> Plot.new(%{x: "date", y: "value01", color: "variable"})
|> Plot.geom_line()
|> Plot.plot()

```
![](assets/geom_line_2.svg)
```
Examples.economics()
|> Plot.new(%{x: "date", y: "unemploy"})
|> Plot.geom_line(color: "red")
|> Plot.plot()

```
![](assets/geom_line_3.svg)
