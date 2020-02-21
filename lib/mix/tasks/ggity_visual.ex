defmodule Mix.Tasks.Ggity.Visual do
  @shortdoc "Launch a browser and display all sample pages."
  @moduledoc @shortdoc

  use Mix.Task

  alias Mix.Tasks.Ggity.Visual

  @doc false
  @spec run(list(any)) :: any
  def run(argv) do
    Visual.Geom.Point.run(argv)
    Visual.Geom.Line.run(argv)
    Visual.Scale.Color.Viridis.run(argv)
  end
end
