defmodule Mix.Tasks.Ggity.Visual.Scale.Color.Viridis do
  @shortdoc "Launch a browser and draw sample plots using the Viridis color scale."
  @moduledoc @shortdoc

  use Mix.Task

  import GGity.Element.{Line, Rect}
  alias GGity.{Examples, Labels, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any
  def run([]), do: run([@default_browser])

  def run([browser]) do
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

    Mix.Tasks.Ggity.Visual.display(plots, browser)
  end

  defp default do
    sales_for_city_subset_plot()
    |> Plot.labs(title: "Default - Viridis")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.plot()
  end

  defp plasma do
    sales_for_city_subset_plot()
    |> Plot.labs(title: "Plasma")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.scale_color_viridis(option: :plasma)
    |> Plot.plot()
  end

  defp inferno do
    sales_for_city_subset_plot()
    |> Plot.labs(title: "Inferno")
    |> Plot.geom_point(%{color: "city"})
    |> Plot.scale_color_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp magma do
    sales_for_city_subset_plot()
    |> Plot.labs(title: "Custom labels, fixed alpha")
    |> Plot.geom_point(%{color: "city"}, alpha: 0.4)
    |> Plot.scale_x_continuous(labels: :commas)
    |> Plot.scale_y_continuous(labels: fn value -> "$#{Labels.commas(round(value / 1000))}K" end)
    |> Plot.scale_color_viridis(option: :magma, labels: fn value -> "#{value}!!!" end)
    |> Plot.plot()
  end

  defp cividis do
    sales_for_city_subset_plot()
    |> Plot.labs(title: "Cividis, size: 2")
    |> Plot.geom_point(%{color: "city"}, size: 2)
    |> Plot.scale_color_viridis(option: :cividis)
    |> Plot.theme(
      axis_ticks: nil,
      legend_key: element_rect(fill: "white", size: 1),
      panel_background: element_rect(fill: "white"),
      panel_border: element_line(color: "lightgray", size: 0.5),
      panel_grid: element_line(color: "lightgray"),
      panel_grid_major: element_line(size: 0.5)
    )
    |> Plot.plot()
  end

  defp sales_for_city_subset_plot do
    cities =
      Explorer.Series.from_list(["Houston", "Fort Worth", "San Antonio", "Dallas", "Austin"])

    Examples.tx_housing()
    |> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities))
    |> Plot.new(%{x: "sales", y: "median"})
  end
end
