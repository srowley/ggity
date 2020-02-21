defmodule GGityDrawTest do
  use ExUnit.Case

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
        Draw.marker(:circle, {0, 0}, 3, fill: "black", fill_opacity: 0.5)
        |> Draw.g(transform: "translate(0,0)")
        |> IO.chardata_to_string()

      assert g ==
               ~s|<g transform="translate(0,0)">\n<circle cx="0" cy="0" r="1.5" fill="black" fill-opacity="0.5"></circle>\n</g>\n|
    end
  end

  describe "rect/1" do
    test "draws rect with coordinates, height, width and options" do
      rect =
        IO.chardata_to_string(Draw.rect(x: "0", y: "0", height: "10", width: "10", fill: "grey"))

      assert rect == ~s|<rect x="0" y="0" height="10" width="10" fill="grey"></rect>\n|
    end
  end

  describe "line/1" do
    test "draws line with provided coordinates" do
      line = IO.chardata_to_string(Draw.line(x1: "1", y1: "2", x2: "3", y2: "4"))
      assert line == ~s|<line x1="1" y1="2" x2="3" y2="4"></line>\n|
    end
  end

  describe "text/2" do
    test "draws text element with given value and attributes" do
      text = IO.chardata_to_string(Draw.text("foo", text_anchor: "middle"))
      assert text == ~s|<text text-anchor="middle">foo</text>\n|
    end
  end

  describe "marker/3" do
    test "draws a marker with given params" do
      diamond =
        :diamond
        |> Draw.marker({0, 0}, 3, fill: "black", fill_opacity: 0.5)
        |> IO.chardata_to_string()

      assert diamond ==
               ~s|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" x="-1.5" y="-1.5" height="3" width="3">\n<polygon points="5,0 10,5 5,10 0,5" fill="black" fill-opacity="0.5"/>\n</svg>|
    end
  end
end
