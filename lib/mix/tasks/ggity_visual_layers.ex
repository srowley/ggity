defmodule Mix.Tasks.Ggity.Visual.Layers do
  @shortdoc "Launch a browser and draw sample plots with more than one layer."
  @moduledoc @shortdoc

  use Mix.Task

  alias GGity.{Examples, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any
  def run([]), do: run([@default_browser])

  def run([browser]) do
    plots =
      Enum.join(
        [
          fixed_line_and_mapped_points(),
          two_mappings(),
          two_datasets()
        ],
        "\n"
      )

    Mix.Tasks.Ggity.Visual.display(plots, browser)
  end

  defp fixed_line_and_mapped_points do
    Examples.mtcars()
    |> Plot.new(%{x: :wt, y: :mpg})
    |> Plot.labs(title: "Different Geoms")
    |> Plot.geom_line(linetype: :twodash, size: 1)
    |> Plot.geom_point(%{color: :cyl})
    |> Plot.labs(color: "Cylinders")
    |> Plot.plot()
  end

  defp two_mappings do
    Examples.mpg()
    |> Plot.new(%{x: "manufacturer", y: "cty"})
    |> Plot.labs(title: "Different Mappings")
    |> Plot.geom_point(color: "blue")
    |> Plot.geom_point(%{y: "hwy"}, color: "green")
    |> Plot.theme(axis_text_x: GGity.Element.Text.element_text(angle: 90))
    |> Plot.labs(y: "City(blue) vs. Highway(green)")
    |> Plot.plot()
  end

  defp two_datasets do
    german_cars()
    |> Plot.new(%{x: "manufacturer", y: "cty"})
    |> Plot.labs(title: "Different Datasets")
    |> Plot.geom_point(color: "gold", shape: :triangle)
    |> Plot.geom_point(data: japanese_cars(), color: "red", shape: :circle)
    |> Plot.plot()
  end

  defp german_cars do
    germans = Explorer.Series.from_list(["audi", "volkswagen"])
    Explorer.DataFrame.filter_with(Examples.mpg(), &Explorer.Series.in(&1["manufacturer"], germans))
  end

  defp japanese_cars do
    japanese = Explorer.Series.from_list(["honda", "toyota"])
    Explorer.DataFrame.filter_with(Examples.mpg(), &Explorer.Series.in(&1["manufacturer"], japanese))
  end
end
