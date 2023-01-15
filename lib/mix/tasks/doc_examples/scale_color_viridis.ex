defmodule GGity.Docs.Scale.Color.Viridis do
  @moduledoc false

  @doc false
  @spec examples() :: iolist()
  def examples do
    [
      """
      # The viridis scale is the default color scale
      Examples.diamonds()
      |> Explorer.DataFrame.sample(1000, seed: 100)
      |> Plot.new(%{x: "carat", y: "price"})
      |> Plot.geom_point(%{color: "clarity"})
      """,
      """
      # Use the :option option to select a palette
      cities = Explorer.Series.from_list([
        "Houston",
        "Fort Worth",
        "San Antonio",
        "Dallas",
        "Austin"
      ])

      Examples.tx_housing()
      |> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities))
      |> Plot.new(%{x: "sales", y: "median"})
      |> Plot.geom_point(%{color: "city"})
      |> Plot.scale_color_viridis(option: :plasma)
      """,
      """
      cities = Explorer.Series.from_list([
        "Houston",
        "Fort Worth",
        "San Antonio",
        "Dallas",
        "Austin"
      ])

      Examples.tx_housing()
      |> Explorer.DataFrame.filter_with(&Explorer.Series.in(&1["city"], cities))
      |> Plot.new(%{x: "sales", y: "median"})
      |> Plot.geom_point(%{color: "city"})
      |> Plot.scale_color_viridis(option: :inferno)
      """
    ]
  end
end
