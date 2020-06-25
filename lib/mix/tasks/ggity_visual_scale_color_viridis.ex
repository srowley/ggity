defmodule Mix.Tasks.Ggity.Visual.Scale.Color.Viridis do
  @shortdoc "Launch a browser and draw sample plots using the Viridis color scale."
  @moduledoc @shortdoc

  use Mix.Task

  alias GGity.{Examples, Labels, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any
  def run([]), do: run([@default_browser])

  def run(argv) do
    plots =
      Enum.join(
        [
          default(),
          plasma(),
          inferno(),
          magma(),
          cividis()
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
    File.rm(test_file)
  end

  defp open_html_file(browser, file) do
    System.cmd(browser, [file])
  end

  defp default do
    Examples.tx_housing()
    |> Enum.filter(fn record ->
      record["city"] in ["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"]
    end)
    |> Plot.new(%{x: "sales", y: "median"})
    |> Plot.labs(title: "Default - Viridis")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.plot()
  end

  defp plasma do
    Examples.tx_housing()
    |> Enum.filter(fn record ->
      record["city"] in ["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"]
    end)
    |> Plot.new(%{x: "sales", y: "median"})
    |> Plot.labs(title: "Plasma")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.scale_color_viridis(option: :plasma)
    |> Plot.plot()
  end

  defp inferno do
    Examples.tx_housing()
    |> Enum.filter(fn record ->
      record["city"] in ["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"]
    end)
    |> Plot.new(%{x: "sales", y: "median"})
    |> Plot.labs(title: "Inferno")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.scale_color_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp magma do
    Examples.tx_housing()
    |> Enum.filter(fn record ->
      record["city"] in ["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"]
    end)
    |> Plot.new(%{x: "sales", y: "median"})
    |> Plot.labs(title: "Custom labels, fixed alpha")
    |> Plot.geom_point(%{color: "city"}, alpha: 0.4)
    |> Plot.scale_x_continuous(labels: :commas)
    |> Plot.scale_y_continuous(labels: fn value -> "$#{Labels.commas(round(value / 1000))}K" end)
    |> Plot.scale_color_viridis(option: :magma, labels: fn value -> "#{value}!!!" end)
    |> Plot.plot()
  end

  defp cividis do
    Examples.tx_housing()
    |> Enum.filter(fn record ->
      record["city"] in ["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"]
    end)
    |> Plot.new(%{x: "sales", y: "median"})
    |> Plot.labs(title: "Cividis, size: 2")
    |> Plot.geom_point(%{color: "city"}, size: 2)
    |> Plot.scale_color_viridis(option: :cividis)
    |> Plot.plot()
  end
end
