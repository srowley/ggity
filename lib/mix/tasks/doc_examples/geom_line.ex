defmodule GGity.Docs.Geom.Line do
  @moduledoc false

  @doc false
  @spec examples() :: iolist()
  def examples do
    [
      """
      Examples.economics()
      |> Plot.new(%{x: "date", y: "unemploy"})
      |> Plot.geom_line()
      """,
      """
      Examples.economics_long()
      |> Plot.new(%{x: "date", y: "value01", color: "variable"})
      |> Plot.geom_line()
      """,
      """
      Examples.economics()
      |> Plot.new(%{x: "date", y: "unemploy"})
      |> Plot.geom_line(color: "red")
      """
    ]
  end
end
