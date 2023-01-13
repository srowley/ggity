defmodule GGityThemeTest do
  use ExUnit.Case, async: true

  import GGity.Element.{Line, Rect, Text}
  alias GGity.{Plot, Theme}

  setup do
    data = [
      %{a: 1, b: 2, c: 3, date: ~D[2001-01-01], datetime: ~N[2001-01-01 00:00:00]},
      %{a: 2, b: 4, c: 6, date: ~D[2001-01-03], datetime: ~N[2001-01-03 00:00:00]}
    ]

    mapping = %{x: :a, y: :b}

    plot =
      data
      |> Plot.new(mapping)
      |> Plot.geom_point()

    %{plot: plot}
  end

  describe "to_stylesheet/2" do
    test "generates stylesheet from theme", %{plot: plot} do
      stylesheet =
        plot.theme
        |> Theme.to_stylesheet("gg-1")
        |> IO.chardata_to_string()

      assert String.contains?(stylesheet, "<style")
      assert String.contains?(stylesheet, "#gg-1")
      assert String.contains?(stylesheet, ".gg-text {font-family: Helvetica")
      refute String.contains?(stylesheet, ".gg-axis-line")
      refute String.contains?(stylesheet, "height")
    end

    test "removes invalid data for line elements", %{plot: plot} do
      plot = Plot.theme(plot, axis_line: element_line(size: "'22'<script>hackety-hack</script>"))

      stylesheet =
        plot.theme
        |> Theme.to_stylesheet("gg-1")
        |> IO.chardata_to_string()

      refute String.contains?(stylesheet, "22")
      refute String.contains?(stylesheet, "script")
      refute String.contains?(stylesheet, "hack")
    end

    test "ignores invalid data for rect elements", %{plot: plot} do
      plot =
        Plot.theme(plot, panel_background: element_rect(fill: "'22'<script>hackety-hack</script>"))

      stylesheet =
        plot.theme
        |> Theme.to_stylesheet("gg-1")
        |> IO.chardata_to_string()

      refute String.contains?(stylesheet, "22")
      refute String.contains?(stylesheet, "script")
      refute String.contains?(stylesheet, "hack")
    end

    test "ignores invalid data for text elements", %{plot: plot} do
      plot = Plot.theme(plot, text: element_text(face: "'22'<script>hackety-hack</script>"))

      stylesheet =
        plot.theme
        |> Theme.to_stylesheet("gg-1")
        |> IO.chardata_to_string()

      refute String.contains?(stylesheet, "22")
      refute String.contains?(stylesheet, "script")
      refute String.contains?(stylesheet, "hack")
    end
  end
end
