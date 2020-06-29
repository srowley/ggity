defmodule Mix.Tasks.Ggity.Visual do
  @shortdoc "Launch a browser and display all sample pages."
  @moduledoc @shortdoc

  use Mix.Task

  alias Mix.Tasks.Ggity.Visual

  @doc false
  @spec run(list(any)) :: any
  def run(argv) do
    [
      Visual.Geom.Point,
      Visual.Geom.Line,
      Visual.Geom.Bar,
      Visual.Scale.Color.Viridis
    ]
    |> Enum.each(fn module -> apply(module, :run, [argv]) end)
  end
end
