defmodule GGityScaleColorViridisTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.Scale.Color

  setup do
    %{scale: Color.Viridis.new() |> Color.Viridis.train(["0", "1", "2"])}
  end

  defp to_hex(rgb) do
    rgb
    |> Stream.map(fn element -> floor(element * 255) end)
    |> Stream.map(fn element -> Integer.to_string(element, 16) end)
    |> Stream.map(fn element -> String.pad_leading(element, 2, "0") end)
    |> Enum.join("")
    |> String.pad_leading(7, "#")
  end

  describe "train/2" do
    test "returns a correct scale given default options", %{scale: scale} do
      assert scale.transform.("0") == to_hex([0.267004, 0.004874, 0.329415])
      assert scale.transform.("1") == to_hex([0.128729, 0.563265, 0.551229])
      assert scale.transform.("2") == to_hex([0.983868, 0.904867, 0.136897])
    end
  end

  describe "draw_legend/2" do
    test "returns an empty list if scale has one level" do
      assert [] ==
               Color.Viridis.new()
               |> Color.Viridis.train(["fish"])
               |> Color.Viridis.draw_legend("Nothing Here", :point, 15)
    end

    test "returns a legend if scale has two or more levels", %{scale: scale} do
      legend =
        Color.Viridis.draw_legend(scale, "Fine Meats", :point, 15)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      assert xpath(legend, ~x"//text/text()"ls) == ["Fine Meats", "0", "1", "2"]

      assert xpath(legend, ~x"//circle/@fill"ls) ==
               Enum.map(scale.levels, fn value -> scale.transform.(value) end)
    end
  end
end
