defmodule Mix.Tasks.Ggity.Visual.Geom.Ribbon do
  @shortdoc "Launch a browser and draw sample area and ribbion geom plots."
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
          area(),
          complicated_ribbon_with_line()
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
    Examples.economics()
    |> Plot.new(%{x: "date", y_max: "unemploy"})
    |> Plot.geom_ribbon()
    |> Plot.labs(title: "Basic Area Chart")
    |> Plot.plot()
  end

  defp area do
    Examples.economics_long()
    |> Enum.filter(fn row -> row["variable"] in ["psavert", "uempmed"] end)
    |> Plot.new(%{x: "date", y_max: "value01"})
    |> Plot.geom_area(%{fill: "variable"})
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.scale_y_continuous(labels: fn value -> Float.round(value, 2) end)
    |> Plot.labs(title: "Stacked Area Chart")
    |> Plot.plot()
  end

  defp complicated_ribbon_with_line do
    Examples.economics_long()
    |> Enum.filter(fn row -> row["variable"] in ["pop", "pce", "psavert"] end)
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      Map.put(row, "more", Map.get(row, "value01") + index * 0.0001)
    end)
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      Map.put(row, "less", Map.get(row, "value01") - index * 0.0001)
    end)
    |> Plot.new(%{x: "date", y_max: "more", y_min: "less", fill: "variable"})
    |> Plot.geom_ribbon(alpha: 1)
    |> Plot.scale_y_continuous(labels: fn value -> Float.round(value, 2) end)
    |> Plot.scale_fill_viridis(option: :plasma)
    |> Plot.geom_line(%{x: "date", y: "value01"},
      color: "grey",
      size: 0.5,
      data: Enum.filter(Examples.economics_long(), &(&1["variable"] == "psavert"))
    )
    |> Plot.labs(title: "Fancy Ribbons")
    |> Plot.plot()
  end
end
