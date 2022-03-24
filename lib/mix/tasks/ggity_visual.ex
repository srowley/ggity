defmodule Mix.Tasks.Ggity.Visual do
  @shortdoc "Launch a browser and display all sample pages."
  @moduledoc @shortdoc

  use Mix.Task

  alias Mix.Tasks.Ggity.Visual

  @doc false
  @spec run(list(any)) :: any
  def run(argv) do
    Enum.each(
      [
        Visual.Annotate,
        Visual.Geom.Point,
        Visual.Geom.Line,
        Visual.Geom.Bar,
        Visual.Geom.Text,
        Visual.Geom.Ribbon,
        Visual.Geom.Boxplot,
        Visual.Layers,
        Visual.Scale.Color.Viridis
      ],
      fn module -> apply(module, :run, [argv]) end
    )
  end
end
