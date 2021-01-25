defmodule Mix.Tasks.Ggity.Docs do
  @shortdoc "Generates guides documentation."
  @moduledoc @shortdoc

  use Mix.Task
  alias GGity.Docs

  @examples [
    Docs.Geom.Point,
    Docs.Geom.Line,
    Docs.Geom.Bar,
    Docs.Geom.Boxplot,
    Docs.Geom.Text,
    Docs.Scale.Color.Viridis,
    Docs.Theme,
    Docs.Annotate
  ]

  @aliases "alias GGity.{Examples, Plot}\n"

  @element_import "import GGity.Element.{Line, Rect, Text}\n"

  @docs_code """
  |> Plot.plot()
  """

  @to_file_code """
  |> Plot.to_xml(550)
  """

  @doc false
  @spec run(list(any)) :: list(:ok)
  def run(_argv) do
    for example <- @examples, do: guides_for(example)
  end

  defp guides_for(example) do
    [_elixir, _ggity, _docs | example_module] =
      example
      |> Atom.to_string()
      |> String.downcase()
      |> String.split(".")

    name = Enum.join(example_module, "_")

    guide_content =
      example
      |> apply(:examples, [])
      |> Enum.with_index(1)
      |> Enum.map(fn example -> generate_example(name, example) end)

    File.write!("guides/#{name}.md", guide_content)
  end

  defp generate_example(name, {example, index}) do
    image_example(name, example, index)
    doc_example(name, example <> @docs_code, index)
  end

  defp image_example(name, example, index) do
    full_code = @aliases <> @element_import <> example <> @to_file_code
    {image, _mystery_list} = Code.eval_string(full_code)
    file = "guides/assets/#{name}_#{index}.svg"
    File.write!(file, image)
  end

  defp doc_example(name, example, index) do
    """
    ```
    #{example}
    ```
    ![](assets/#{name}_#{index}.svg)
    """
  end
end
