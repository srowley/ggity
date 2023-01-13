defmodule Mix.Tasks.Ggity.Visual.Geom.Boxplot do
  @shortdoc "Launch a browser and draw sample boxplot geom plots."
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
          basic(),
          fixed_color(),
          outlier_color(),
          no_outliers(),
          mapped_color()
        ],
        "\n"
      )

    Mix.Tasks.Ggity.Visual.display(plots, browser)
  end

  defp basic do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot(
      custom_attributes: fn _plot, row -> [onclick: "alert('Median: #{row["middle"]}')"] end
    )
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end

  defp fixed_color do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot(color: "blue")
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end

  defp outlier_color do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot(outlier_color: "red")
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end

  defp no_outliers do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot(outlier_size: 6, outlier_color: "red", outlier_shape: 1)
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end

  defp mapped_color do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot(%{color: "drv"})
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end
end
