defmodule Mix.Tasks.Ggity.Visual.Geom.Bar do
  @shortdoc "Launch a browser and draw sample bar geom plots."
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
          stack(),
          dodge(),
          geom_col()
        ],
        "\n"
      )

    Mix.Tasks.Ggity.Visual.display(plots, browser)
  end

  defp basic do
    manufacturer_subset()
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar(
      custom_attributes: fn plot, row ->
        [onclick: "alert('#{plot.labels.y}: #{row["count"]}')"]
      end
    )
    |> Plot.scale_y_continuous(labels: &floor/1)
    |> Plot.plot()
  end

  defp stack do
    manufacturer_subset()
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar(
      %{fill: "class"},
      custom_attributes: fn plot, row ->
        [onclick: "alert('#{plot.labels.y}: #{row["count"]}')"]
      end
    )
    |> Plot.scale_fill_viridis(option: :inferno)
    |> Plot.plot()
  end

  defp dodge do
    manufacturer_subset()
    |> Plot.new(%{x: "manufacturer"})
    |> Plot.geom_bar(%{fill: "class"}, position: :dodge)
    |> Plot.plot()
  end

  defp geom_col do
    [
      %{"salesperson" => "Joe", "week" => "Week 1", "units" => 10},
      %{"salesperson" => "Jane", "week" => "Week 1", "units" => 15},
      %{"salesperson" => "Joe", "week" => "Week 2", "units" => 4},
      %{"salesperson" => "Jane", "week" => "Week 2", "units" => 10},
      %{"salesperson" => "Joe", "week" => "Week 3", "units" => 14},
      %{"salesperson" => "Jane", "week" => "Week 3", "units" => 9}
    ]
    |> Explorer.DataFrame.new()
    |> Plot.new(%{x: "week", y: "units", fill: "salesperson"})
    |> Plot.geom_col(position: :dodge, alpha: 0.7)
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.plot()
  end

  defp manufacturer_subset do
    manufacturers =
      Explorer.Series.from_list(["chevrolet", "audi", "ford", "nissan", "subaru"])
    Explorer.DataFrame.filter_with(Examples.mpg(), &Explorer.Series.in(&1["manufacturer"], manufacturers))
  end
end
