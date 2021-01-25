defmodule GGity.Docs.Geom.Boxplot do
  @moduledoc false

  @doc false
  @spec examples() :: iolist()
  def examples do
    [
      """
      Examples.mpg()
      |> Plot.new(%{x: "class", y: "hwy"})
      |> Plot.geom_boxplot()
      """,
      """
      Examples.mpg()
      |> Plot.new(%{x: "class", y: "hwy"})
      |> Plot.geom_boxplot(fill: "white", color: "#3366FF")
      """,
      """
      Examples.mpg()
      |> Plot.new(%{x: "class", y: "hwy"})
      |> Plot.geom_boxplot(outlier_color: "red")
      """,
      """
      Examples.mpg()
      |> Plot.new(%{x: "class", y: "hwy"})
      |> Plot.geom_boxplot(%{color: "drv"})
      """
    ]
  end
end
