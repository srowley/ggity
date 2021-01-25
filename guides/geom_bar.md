```
Examples.mpg()
|> Plot.new(%{x: "class"})
|> Plot.geom_bar()
|> Plot.plot()

```
![](assets/geom_bar_1.svg)
```
Examples.mpg()
|> Plot.new(%{x: "class"})
|> Plot.geom_bar(%{fill: "drv"})
|> Plot.plot()

```
![](assets/geom_bar_2.svg)
