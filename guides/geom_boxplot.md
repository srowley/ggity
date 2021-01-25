```
Examples.mpg()
|> Plot.new(%{x: "class", y: "hwy"})
|> Plot.geom_boxplot()
|> Plot.plot()

```
![](assets/geom_boxplot_1.svg)
```
Examples.mpg()
|> Plot.new(%{x: "class", y: "hwy"})
|> Plot.geom_boxplot(fill: "white", color: "#3366FF")
|> Plot.plot()

```
![](assets/geom_boxplot_2.svg)
```
Examples.mpg()
|> Plot.new(%{x: "class", y: "hwy"})
|> Plot.geom_boxplot(outlier_color: "red")
|> Plot.plot()

```
![](assets/geom_boxplot_3.svg)
```
Examples.mpg()
|> Plot.new(%{x: "class", y: "hwy"})
|> Plot.geom_boxplot(%{color: "drv"})
|> Plot.plot()

```
![](assets/geom_boxplot_4.svg)
