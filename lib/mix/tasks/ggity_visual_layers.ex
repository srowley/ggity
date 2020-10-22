defmodule Mix.Tasks.Ggity.Visual.Layers do
  @shortdoc "Launch a browser and draw sample plots with more than one layer."
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
          fixed_line_and_mapped_points(),
          two_mappings(),
          two_datasets()
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

    File.write!(test_file, "<html>\n#{plots}\n</html>")
    open_html_file(browser, test_file)
    Process.sleep(1000)
    File.rm(test_file)
  end

  defp open_html_file(browser, file) do
    System.cmd(browser, [file])
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
    |> Plot.theme(axis_text_x: GGity.Element.Text.element_text(angle: 45))
    |> Plot.labs(y: "City(blue) vs. Highway(green)")
    |> Plot.plot()
  end

  defp two_datasets do
    german =
      Enum.filter(Examples.mpg(), fn record ->
        record["manufacturer"] in ["audi", "volkswagen"]
      end)

    japanese =
      Enum.filter(Examples.mpg(), fn record -> record["manufacturer"] in ["honda", "toyota"] end)

    german
    |> Plot.new(%{x: "manufacturer", y: "cty"})
    |> Plot.labs(title: "Different Datasets")
    |> Plot.geom_point(color: "gold", shape: :triangle)
    |> Plot.geom_point(data: japanese, color: "red", shape: :circle)
    |> Plot.plot()
  end
end
