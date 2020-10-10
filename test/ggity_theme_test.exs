defmodule GGityThemeTest do
  use ExUnit.Case

  alias GGity.{Plot, Theme}

  setup do
    data = [
      %{a: 1, b: 2, c: 3, date: ~D[2001-01-01], datetime: ~N[2001-01-01 00:00:00]},
      %{a: 2, b: 4, c: 6, date: ~D[2001-01-03], datetime: ~N[2001-01-03 00:00:00]}
    ]

    mapping = %{x: :a, y: :b}

    plot =
      Plot.new(data, mapping)
      |> Plot.geom_point()

    %{plot: plot}
  end

  describe "to_stylesheet/2" do
    test "generates stylesheet from theme", %{plot: plot} do
      stylesheet = Theme.to_stylesheet(plot.theme, "gg-1") |> IO.chardata_to_string()
      assert String.contains?(stylesheet, "<style")
      assert String.contains?(stylesheet, "#gg-1")
      assert String.contains?(stylesheet, ".gg-text {font-family: Helvetica")
      refute String.contains?(stylesheet, ".gg-axis-line")
      refute String.contains?(stylesheet, "height")
    end
  end
end
