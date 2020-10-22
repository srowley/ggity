defmodule Mix.Tasks.Ggity.Visual.Geom.Bar do
  @shortdoc "Launch a browser and draw sample bar geom plots."
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
          stack(),
          dodge(),
          geom_col()
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
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar()
    |> Plot.plot()
  end

  defp stack do
    Examples.mpg()
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar(%{fill: "class"})
    |> Plot.scale_fill_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp dodge do
    Examples.mpg()
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar(%{fill: "class"}, position: :dodge)
    |> Plot.plot()
  end

  defp geom_col do
    [
      %{salesperson: "Joe", week: "Week 1", units: 10},
      %{salesperson: "Jane", week: "Week 1", units: 15},
      %{salesperson: "Joe", week: "Week 2", units: 4},
      %{salesperson: "Jane", week: "Week 2", units: 10},
      %{salesperson: "Joe", week: "Week 3", units: 14},
      %{salesperson: "Jane", week: "Week 3", units: 9}
    ]
    |> Plot.new(%{x: :week, y: :units, fill: :salesperson})
    |> Plot.geom_col(position: :dodge)
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.plot()
  end
end
