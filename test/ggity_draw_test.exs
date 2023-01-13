defmodule GGityDrawTest do
  use ExUnit.Case, async: true

  alias GGity.Draw

  describe "svg/2" do
    test "wraps given IO list in <svg> tags" do
      svg =
        ["foo", "bar"]
        |> Draw.svg(viewBox: "0 0 500 500")
        |> IO.chardata_to_string()

      assert svg ==
               ~s|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">\nfoobar</svg>|
    end
  end

  describe "g/2" do
    test "wraps given elements in <g> tags with given attributes" do
      g =
        Draw.text("meat", fill: "black", fill_opacity: 0.5)
        |> Draw.g(transform: "translate(0,0)")
        |> IO.chardata_to_string()

      assert g ==
               ~s|<g transform="translate(0,0)">\n<text fill="black" fill-opacity="0.5">meat</text>\n</g>\n|
    end
  end

  describe "rect/1" do
    test "draws rect with coordinates, height, width and options" do
      rect =
        [x: "0", y: "0", height: "10", width: "10", fill: "grey"]
        |> Draw.rect()
        |> IO.chardata_to_string()

      assert rect == ~s|<rect x="0" y="0" height="10" width="10" fill="grey"></rect>\n|
    end
  end

  describe "line/1" do
    test "draws line with provided coordinates" do
      line =
        [x1: "1", y1: "2", x2: "3", y2: "4"]
        |> Draw.line()
        |> IO.chardata_to_string()

      assert line == ~s|<line x1="1" y1="2" x2="3" y2="4"></line>\n|
    end
  end

  describe "text/2" do
    test "draws text element with given value and attributes" do
      text =
        "foo"
        |> Draw.text(text_anchor: "middle")
        |> IO.chardata_to_string()

      assert text == ~s|<text text-anchor="middle">foo</text>\n|
    end
  end
end
