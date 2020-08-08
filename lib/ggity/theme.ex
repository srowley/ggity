defmodule GGity.Theme do
  @moduledoc false

  import GGity.Element.{Line, Rect, Text}

  alias GGity.{Element, Theme}

  @type t() :: %__MODULE__{}

  defstruct text: element_text(family: "Helvetica, Arial, sans-serif"),
            axis_line: nil,
            axis_line_x: nil,
            axis_line_y: nil,
            axis_ticks: element_line(color: "#000000"),
            axis_ticks_x: nil,
            axis_ticks_y: nil,
            axis_ticks_length: 2,
            axis_ticks_length_x: nil,
            axis_ticks_length_y: nil,
            axis_title: element_text(color: "#000000", size: 10),
            axis_title_x: nil,
            axis_title_y: nil,
            axis_text: element_text(color: "#808080", size: 8),
            axis_text_x: nil,
            axis_text_y: nil,
            legend_key:
              element_rect(
                fill: "#EEEEEE",
                color: "#EEEEEE",
                size: 0.5,
                height: 15
              ),
            legend_text: element_text(fill: "#000000", size: 8),
            legend_title: element_text(fill: "#000000", size: 9),
            panel_background: element_rect(fill: "#EEEEEE"),
            panel_border: element_line(color: "none"),
            panel_grid: element_line(color: "#FFFFFF"),
            panel_grid_major: element_line(size: 1),
            panel_grid_minor: element_line(size: 0.5),
            plot_background: element_rect(fill: "#FFFFFF"),
            plot_title: element_text(size: 12)

  @doc false
  @spec to_stylesheet(Theme.t() | nil, String.t()) :: iolist()
  def to_stylesheet(nil, _id), do: []

  def to_stylesheet(%Theme{} = theme, id) do
    [
      "<style type=\"text/css\"><![CDATA[",
      theme_to_stylesheet(theme, id),
      "]]></style>"
    ]
  end

  defp theme_to_stylesheet(%Theme{} = theme, id) do
    theme
    |> Map.from_struct()
    |> Enum.map(fn attribute -> generate_attribute_style(theme, attribute, id) end)
  end

  defp generate_attribute_style(theme, {attribute, element}, id) when is_struct(element) do
    "##{id} #{Element.to_css(Map.get(theme, attribute), gg_class(attribute))}"
  end

  defp generate_attribute_style(_theme_, _attribute, _id), do: ""

  defp gg_class(key) when is_atom(key) do
    attribute =
      key
      |> Atom.to_string()
      |> String.replace("_", "-")

    "gg-" <> attribute
  end
end
