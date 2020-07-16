defmodule GGityScaleLineTypeDiscreteTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.Scale.Linetype

  setup do
    %{
      scale:
        Linetype.Discrete.new()
        |> Linetype.Discrete.train(["beef", "chicken", "deer", "fish", "gator", "lamb", "shrimp"])
    }
  end

  describe "new/2" do
    test "returns a proper scale for discrete values", %{scale: scale} do
      assert scale.transform.("beef") == ""
      assert scale.transform.("chicken") == "4"
      assert scale.transform.("deer") == "1"
      assert scale.transform.("fish") == "6 2"
      assert scale.transform.("gator") == "1 2 3 2"
      assert scale.transform.("lamb") == "2 2 6 2"
      assert scale.transform.("shrimp") == ""
    end
  end

  describe "draw_legend/2" do
    test "returns an empty list if scale has one level" do
      assert [] ==
               Linetype.Discrete.new()
               |> Linetype.Discrete.train(["fish"])
               |> Linetype.Discrete.draw_legend("Nothing Here", :path)
    end

    test "returns a legend if scale has two or more levels", %{scale: scale} do
      legend =
        Linetype.Discrete.draw_legend(scale, "Fine Meats", :path)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      assert xpath(legend, ~x"//text/text()"ls) == [
               "Fine Meats",
               "beef",
               "chicken",
               "deer",
               "fish",
               "gator",
               "lamb",
               "shrimp"
             ]

      assert xpath(legend, ~x"//line"l) |> length() == 7
    end
  end
end
