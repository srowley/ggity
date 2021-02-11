defmodule GGity.Docs.Geom.Point do
  @moduledoc false

  @doc false
  @spec examples() :: iolist()
  def examples do
    [
      """
      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point()
      """,
      """
      # Add aesthetic mapping to color
      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point(%{color: :cyl})
      """,
      """
      # Add aesthetic mapping to shape
      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point(%{shape: :cyl})
      """,
      """
      # Add aesthetic mapping to size (for circles, a bubble chart)
      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point(%{size: :qsec})
      """,
      """
      # Set aesthetics to fixed value
      Examples.mtcars()
      |> Plot.new(%{x: :wt, y: :mpg})
      |> Plot.geom_point(color: "red", size: 5)
      """
    ]
  end
end
