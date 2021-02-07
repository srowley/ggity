```
Examples.mtcars()
|> Plot.new(%{x: :wt, y: :mpg})
|> Plot.geom_point()
|> Plot.plot()

```
![](assets/geom_point_1.svg)
```
# Add aesthetic mapping to color
Examples.mtcars()
|> Plot.new(%{x: :wt, y: :mpg})
|> Plot.geom_point(%{color: :cyl})
|> Plot.plot()

```
![](assets/geom_point_2.svg)
```
# Add aesthetic mapping to shape
Examples.mtcars()
|> Plot.new(%{x: :wt, y: :mpg})
|> Plot.geom_point(%{shape: :cyl})
|> Plot.plot()

```
![](assets/geom_point_3.svg)
```
# Add aesthetic mapping to size (for circles, a bubble chart)
Examples.mtcars()
|> Plot.new(%{x: :wt, y: :mpg})
|> Plot.geom_point(%{size: :qsec})
|> Plot.plot()

```
![](assets/geom_point_4.svg)
```
# Set aesthetics to fixed value
Examples.mtcars()
|> Plot.new(%{x: :wt, y: :mpg})
|> Plot.geom_point(color: "red", size: 5)
|> Plot.plot()

```
![](assets/geom_point_5.svg)
```
# Varying alpha is useful for large datasets
Examples.diamonds()
|> Plot.new(%{x: "carat", y: "price"})
|> Plot.geom_point(alpha: 1/50)
|> Plot.plot()

```
![](assets/geom_point_6.svg)
