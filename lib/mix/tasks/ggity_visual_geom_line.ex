defmodule Mix.Tasks.Ggity.Visual.Geom.Line do
  @shortdoc "Launch a browser and draw sample line geom plots."
  @moduledoc @shortdoc

  use Mix.Task

  alias GGity.{Examples, Plot}

  @default_browser "firefox"

  @doc false
  @spec run(list(any)) :: any
  def run([]), do: run([@default_browser])

  def run(argv) do
    plots =
      Enum.join(
        [
          basic(),
          fixed_line_and_mapped_points(),
          fixed_aesthetics(),
          date_time(),
          group_by_color(),
          group_by_linetype()
        ],
        "\n"
      )

    test_file = "test/visual/visual_test.html"

    browser =
      case argv do
        ["--wsl"] ->
          "/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

        [browser] ->
          browser
      end

    File.write!(test_file, "<html><body #{grid_style()}>\n#{plots}\n</body></html>")
    open_html_file(browser, test_file)
    Process.sleep(1000)
    File.rm(test_file)
  end

  defp open_html_file(browser, file) do
    System.cmd(browser, [file])
  end

  defp grid_style do
    "style='display: grid;grid-template-columns: repeat(3, 1fr)'"
  end

  defp basic do
    Examples.economics()
    |> Plot.new(%{x: "date", y: "unemploy"})
    |> Plot.geom_line(size: 1)
    |> Plot.labs(title: "Date data")
    |> Plot.scale_x_date(breaks: 11, date_labels: "%Y")
    |> Plot.plot()
  end

  defp fixed_line_and_mapped_points do
    Examples.mtcars()
    |> Plot.new(%{x: :wt, y: :mpg})
    |> Plot.labs(title: "Fixed linetype: :twodash", x: "Weight")
    |> Plot.geom_line(linetype: :twodash, size: 1)
    |> Plot.plot()
  end

  defp fixed_aesthetics do
    Examples.economics()
    |> Plot.new(%{x: "date", y: "unemploy"})
    |> Plot.geom_line(color: "red", size: 1)
    |> Plot.labs(title: "Fixed color: \"red\"")
    |> Plot.scale_x_date(breaks: 6, date_labels: "%m/%d/%Y")
    |> Plot.theme(axis_text_x: GGity.Element.Text.element_text(angle: 30))
    |> Plot.plot()
  end

  defp date_time do
    [
      %{date_time: ~N[2001-01-01 00:00:00], price: 0.13},
      %{date_time: ~N[2001-01-01 03:00:00], price: 0.5},
      %{date_time: ~N[2001-01-01 06:00:00], price: 0.9},
      %{date_time: ~N[2001-01-01 09:00:00], price: 0.63},
      %{date_time: ~N[2001-01-01 12:00:00], price: 0.45},
      %{date_time: ~N[2001-01-01 15:00:00], price: 0.25},
      %{date_time: ~N[2001-01-01 18:00:00], price: 0.12},
      %{date_time: ~N[2001-01-01 21:00:00], price: 0.13},
      %{date_time: ~N[2001-01-02 00:00:00], price: 0.24},
      %{date_time: ~N[2001-01-02 03:00:00], price: 0.74},
      %{date_time: ~N[2001-01-02 06:00:00], price: 0.77},
      %{date_time: ~N[2001-01-02 09:00:00], price: 0.63},
      %{date_time: ~N[2001-01-02 12:00:00], price: 0.23},
      %{date_time: ~N[2001-01-02 15:00:00], price: 0.53},
      %{date_time: ~N[2001-01-02 21:00:00], price: 0.26},
      %{date_time: ~N[2001-01-03 00:00:00], price: 0.27},
      %{date_time: ~N[2001-01-03 03:00:00], price: 0.03},
      %{date_time: ~N[2001-01-03 06:00:00], price: 0.79},
      %{date_time: ~N[2001-01-03 09:00:00], price: 0.78},
      %{date_time: ~N[2001-01-03 12:00:00], price: 0.08}
    ]
    |> Plot.new(%{x: :date_time, y: :price})
    |> Plot.geom_line(size: 1)
    |> Plot.scale_x_datetime(date_labels: "%b %d H%H")
    |> Plot.labs(title: "DateTime data")
    |> Plot.plot()
  end

  def group_by_color do
    Examples.economics_long()
    |> Plot.new(%{x: "date", y: "value01"})
    |> Plot.labs(title: "Mapped to color")
    |> Plot.geom_line(%{color: "variable"})
    |> Plot.scale_x_date(breaks: 6, date_labels: "%Y")
    |> Plot.plot()
  end

  def group_by_linetype do
    Examples.economics_long()
    |> Plot.new(%{x: "date", y: "value01"})
    |> Plot.labs(title: "Mapped to linetype, custom glyph")
    |> Plot.geom_line(%{linetype: "variable"}, key_glyph: :path)
    |> Plot.scale_x_date(breaks: 6, date_labels: "%Y")
    |> Plot.plot()
  end
end
