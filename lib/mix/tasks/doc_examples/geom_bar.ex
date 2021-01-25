defmodule GGity.Docs.Geom.Bar do
  @moduledoc false

  @doc false
  @spec examples() :: iolist()
  def examples do
    [
      """
      Examples.mpg()
      |> Plot.new(%{x: "class"})
      |> Plot.geom_bar()
      """,
      """
      Examples.mpg()
      |> Plot.new(%{x: "class"})
      |> Plot.geom_bar(%{fill: "drv"})
      """
    ]
  end
end
