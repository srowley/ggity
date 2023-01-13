defmodule Mix.Tasks.Ggity.Visual.Geom.Ribbon do
  @shortdoc "Launch a browser and draw sample area and ribbion geom plots."
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
          area(),
          complicated_ribbon_with_line()
        ],
        "\n"
      )

    Mix.Tasks.Ggity.Visual.display(plots, browser)
  end

  defp basic do
    Examples.economics()
    |> Plot.new(%{x: "date", y_max: "unemploy"})
    |> Plot.geom_ribbon()
    |> Plot.labs(title: "Basic Area Chart")
    |> Plot.plot()
  end

  defp area do
    data = Examples.economics_long()
    mask1 = Explorer.Series.equal(data["variable"], "psavert")
    mask2 = Explorer.Series.equal(data["variable"], "uempmed")
    mask = Explorer.Series.or(mask1, mask2)

    data
    |> Explorer.DataFrame.mask(mask)
    |> Plot.new(%{x: "date", y_max: "value01"})
    |> Plot.geom_area(%{fill: "variable"})
    |> Plot.scale_fill_viridis(option: :cividis)
    |> Plot.scale_y_continuous(labels: fn value -> Float.round(value, 2) end)
    |> Plot.labs(title: "Stacked Area Chart")
    |> Plot.plot()
  end

  defp complicated_ribbon_with_line do
    Examples.economics_long()
    |> Explorer.DataFrame.to_rows()
    |> Enum.filter(fn row -> row["variable"] in ["pop", "pce", "psavert"] end)
    |> Enum.with_index(fn row, index ->
      row
      |> Map.put("more", Map.get(row, "value01") + index * 0.0001)
      |> Map.put("less", Map.get(row, "value01") - index * 0.0001)
    end)
    |> Plot.new(%{x: "date", y_max: "more", y_min: "less", fill: "variable"})
    |> Plot.geom_ribbon(alpha: 1)
    |> Plot.scale_y_continuous(labels: fn value -> Float.round(value, 2) end)
    |> Plot.scale_fill_viridis(option: :plasma)
    |> Plot.geom_line(%{x: "date", y: "value01"},
      color: "grey",
      size: 0.5,
      data: supp_data()
    )
    |> Plot.labs(title: "Fancy Ribbons")
    |> Plot.plot()
  end

  defp supp_data do
    Explorer.DataFrame.filter_with(
      Examples.economics_long(),
      &Explorer.Series.equal(&1["variable"], "psavert")
    )
  end
end
