defmodule GGityScaleShapeTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.Scale.Shape

  setup do
    %{
      scale: Shape.new() |> Shape.train(["beef", "chicken", "fish", "lamb", "scallops", "shrimp"])
    }
  end

  describe "new/2" do
    test "returns a proper scale for discrete values", %{scale: scale} do
      assert scale.transform.("beef") == :circle
      assert scale.transform.("chicken") == :triangle
      assert scale.transform.("fish") == :square
      assert scale.transform.("lamb") == :plus
      assert scale.transform.("scallops") == :square_cross
      assert scale.transform.("shrimp") == :circle
    end
  end

  describe "draw_legend/2" do
    test "returns an empty list if scale has one level" do
      assert [] ==
               Shape.new()
               |> Shape.train(["fish"])
               |> Shape.draw_legend("Nothing Here", 15, [])
    end

    test "returns a legend if scale has two or more levels", %{scale: scale} do
      legend =
        Shape.draw_legend(scale, "Fine Meats", 15, [])
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      assert xpath(legend, ~x"//text/text()"ls) == [
               "Fine Meats",
               "beef",
               "chicken",
               "fish",
               "lamb",
               "scallops",
               "shrimp"
             ]

      assert xpath(legend, ~x"//circle"l) |> length() == 2
      assert xpath(legend, ~x"//polygon"l) |> length() == 1
      assert xpath(legend, ~x"//rect"l) |> length() == 8
    end
  end
end
