defmodule GGityScaleShapeTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.Scale.Shape

  setup do
    %{scale: Shape.new(["beef", "chicken", "lamb", "fish", "shrimp"])}
  end

  describe "new/2" do
    test "returns a proper scale for discrete values", %{scale: scale} do
      assert scale.transform.("beef") == :circle
      assert scale.transform.("chicken") == :square
      assert scale.transform.("fish") == :diamond
      assert scale.transform.("lamb") == :triangle
      assert scale.transform.("shrimp") == :circle
    end
  end

  describe "draw_legend/2" do
    test "returns an empty list if scale has one or zero levels" do
      assert [] ==
               Shape.new([])
               |> Shape.draw_legend("Nothing Here")

      assert [] ==
               Shape.new(["fish"])
               |> Shape.draw_legend("Nothing Here")
    end

    test "returns a legend if scale has two or more levels", %{scale: scale} do
      legend =
        Shape.draw_legend(scale, "Fine Meats")
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      assert xpath(legend, ~x"//text/text()"ls) == [
               "Fine Meats",
               "beef",
               "chicken",
               "fish",
               "lamb",
               "shrimp"
             ]

      assert xpath(legend, ~x"//circle"l) |> length() == 2
      assert xpath(legend, ~x"//polygon"l) |> length() == 2
      assert xpath(legend, ~x"//rect"l) |> length() == 6
    end
  end
end
