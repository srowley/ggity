defmodule Mix.Tasks.Ggity.Visual.Geom.Text do
  @shortdoc "Launch a browser and draw sample text geom plots."
  @moduledoc @shortdoc

  use Mix.Task

  alias GGity.{Examples, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any()
  def run([]), do: run([@default_browser])

  def run(argv) do
    plots =
      Enum.join(
        [
          basic(),
          bar_labels(),
          bar_stack(),
          col_stack(),
          bar_dodge(),
          col_dodge()
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

  defp basic do
    Examples.mtcars()
    |> Enum.filter(fn record ->
      String.contains?(record[:model], "Merc")
    end)
    |> Plot.new(%{x: :wt, y: :mpg, label: :model})
    |> Plot.geom_point()
    |> Plot.geom_text(%{alpha: :gear}, nudge_x: 5, hjust: :left, size: 8)
    |> Plot.scale_alpha_discrete(guide: :legend)
    |> Plot.xlab("Weight (tons)")
    |> Plot.ylab("Miles Per Gallon")
    |> Plot.plot()
  end

  defp bar_labels do
    Examples.mpg()
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar()
    |> Plot.geom_text(%{label: :count},
      position: :dodge,
      family: "Courier New",
      fontface: "bold",
      color: "cornflowerblue",
      stat: :count,
      size: 8,
      nudge_y: -5
    )
    |> Plot.plot()
  end

  defp bar_stack do
    Examples.mpg()
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer", label: :count, group: "class"})
    |> Plot.geom_bar(%{fill: "class"}, position: :stack)
    |> Plot.geom_text(
      color: "grey",
      stat: :count,
      position: :stack,
      position_vjust: 0.5,
      fontface: "bold",
      size: 6
    )
    |> Plot.scale_fill_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp col_stack do
    simple_bar_data()
    |> Plot.new(%{x: :week, y: :units, label: :units, group: :salesperson})
    |> Plot.geom_col(%{fill: :salesperson}, position: :stack)
    |> Plot.geom_text(
      color: "#BAAC6F",
      position: :stack,
      position_vjust: 0.5,
      fontface: "bold",
      size: 6
    )
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.plot()
  end

  defp bar_dodge do
    Examples.mpg()
    |> Enum.filter(fn record ->
      record["manufacturer"] in ["chevrolet", "audi", "ford", "nissan", "subaru"]
    end)
    |> Plot.new(%{x: "manufacturer", label: :count, group: "class"})
    |> Plot.geom_bar(%{fill: "class"}, position: :dodge)
    |> Plot.geom_text(%{y: :count},
      color: "grey",
      stat: :count,
      position: :dodge,
      position_vjust: 0.5,
      fontface: "bold",
      size: 6
    )
    |> Plot.scale_fill_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp col_dodge do
    simple_bar_data()
    |> Plot.new(%{x: :week, y: :units, label: :units, group: :salesperson})
    |> Plot.geom_col(%{fill: :salesperson}, position: :dodge)
    |> Plot.geom_text(
      color: "#BAAC6F",
      position: :dodge,
      fontface: "bold",
      position_vjust: 0.5,
      size: 6
    )
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.plot()
  end

  defp simple_bar_data do
    [
      %{salesperson: "Joe", week: "Week 1", units: 10},
      %{salesperson: "Jane", week: "Week 1", units: 15},
      %{salesperson: "Paul", week: "Week 1", units: 5},
      %{salesperson: "Joe", week: "Week 2", units: 4},
      %{salesperson: "Jane", week: "Week 2", units: 10},
      %{salesperson: "Paul", week: "Week 2", units: 8},
      %{salesperson: "Joe", week: "Week 3", units: 14},
      %{salesperson: "Paul", week: "Week 3", units: 8},
      %{salesperson: "Jane", week: "Week 3", units: 9},
      %{salesperson: "Joe", week: "Week 4", units: 14},
      %{salesperson: "Jane", week: "Week 4", units: 9}
    ]
  end
end
