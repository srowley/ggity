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

  @doc false
  @spec display(String.t(), String.t()) :: :ok | {:error, :file.posix()}
  def display(plots, browser) do
    test_file = "test/visual/visual_test.html"

    browser =
      case browser do
        "--wsl" -> "sensible-browser"
        browser -> browser
      end

    File.write!(test_file, "<html><body #{grid_style()}>\n#{plots}\n</body></html>")
    System.cmd(browser, [test_file])
    Process.sleep(1000)
    File.rm(test_file)
  end

  defp grid_style do
    "style='display: grid;grid-template-columns: repeat(3, 1fr)'"
  end
end
