defmodule Mix.Tasks.Ggity.Visual.Geom.Boxplot do
  @shortdoc "Launch a browser and draw sample boxplot geom plots."
  @moduledoc @shortdoc

  use Mix.Task

  alias GGity.{Examples, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any
  def run([]), do: run([@default_browser])

  def run(argv) do
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

    test_file = "test/visual/visual_test.html"

    browser =
      case argv do
        ["--wsl"] ->
          "/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

        [browser] ->
          browser
      end

    File.write!(test_file, "<html><body #{grid_style()}>\n#{plots}\n</body></html>")
    open_html_file(browser, test_file)
    Process.sleep(1000)
    File.rm(test_file)
  end

  defp open_html_file(browser, file) do
    System.cmd(browser, [file])
  end

  defp grid_style do
    "style='display: grid;grid-template-columns: repeat(3, 1fr)'"
  end

  defp basic do
    Examples.mpg()
    |> Plot.new(%{x: "class", y: "hwy"})
    |> Plot.geom_boxplot()
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
    |> Plot.geom_boxplot(outlier_shape: :na)
    |> Plot.geom_point(color: "red", size: 2)
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
