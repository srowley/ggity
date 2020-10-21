defmodule GGityScaleSizeDiscreteTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.Scale.Size

  setup do
    %{scale: Size.Discrete.new() |> Size.Discrete.train(["beef", "chicken", "fish", "lamb"])}
  end

  describe "new/2" do
    test "returns a proper scale for discrete values", %{scale: scale} do
      assert_in_delta scale.transform.("beef"), 2, 0.000001
      assert_in_delta scale.transform.("chicken"), 4, 0.000001
      assert_in_delta scale.transform.("fish"), 6, 0.000001
      assert_in_delta scale.transform.("lamb"), 8, 0.000001
    end
  end

  describe "draw_legend/2" do
    test "returns an empty list if scale has one level" do
      assert [] ==
               Size.Discrete.new()
               |> Size.Discrete.train(["fish"])
               |> Size.Discrete.draw_legend("Nothing Here", :point, 15)
    end

    test "returns a legend if scale has two or more levels", %{scale: scale} do
      legend =
        Size.Discrete.draw_legend(scale, "Fine Meats", :point, 15)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      assert xpath(legend, ~x"//text/text()"ls) == [
               "Fine Meats",
               "beef",
               "chicken",
               "fish",
               "lamb"
             ]

      assert xpath(legend, ~x"//circle/@r"lf) ==
               Enum.map(scale.levels, fn value -> scale.transform.(value) / 2 end)
    end
  end
end
