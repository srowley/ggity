defmodule GGityGeomLineTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.{Examples, Geom, Scale}

  setup do
    %{data: Examples.mtcars()}
  end

  describe "new/3" do
    test "constructs basic geom with x and y values", %{data: data} do
      geom = Geom.Line.new(data, %{x: :wt, y: :mpg})
      assert geom.mapping == %{x: :wt, y: :mpg}
      assert %Scale.X.Continuous{} = geom.x_scale
      assert %Scale.Y.Continuous{} = geom.y_scale
      assert %Scale.Color.Manual{} = geom.color_scale
      assert %Scale.Size.Manual{} = geom.size_scale
      assert %Scale.Alpha.Manual{} = geom.alpha_scale
      assert %Scale.Linetype.Manual{} = geom.linetype_scale
    end

    test "adds fixed aesthetics specified as options", %{data: data} do
      geom = Geom.Line.new(data, %{x: :wt, y: :mpg}, linetype: :dashed, color: "red")
      assert geom.color_scale.transform.("meat") == "red"
      assert geom.linetype_scale.transform.("meat") == "4"
    end

    test "adds aesthetics mapped to data", %{data: data} do
      geom = Geom.Point.new(data, %{x: :wt, y: :mpg, color: :cyl})
      assert %Scale.Color.Viridis{} = geom.color_scale
      assert geom.color_scale.transform.(6) == "#208F8C"
    end
  end

  describe "draw/2" do
    setup %{data: data} do
      geom_markup =
        Geom.Line.new(data, %{x: :wt, y: :mpg})
        |> Geom.Line.draw(data)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      %{data: data, geom_markup: geom_markup}
    end

    test "draws all the points on the line", %{data: data, geom_markup: geom_markup} do
      number_of_points =
        geom_markup
        |> xpath(~x"//polyline/@points"s)
        |> String.split()
        |> length()

      assert number_of_points == length(data)
    end

    test "draws labels and gridlines", %{geom_markup: geom_markup} do
      number_of_gridlines =
        geom_markup
        |> xpath(~x"//line"l)
        |> length()

      number_of_labels =
        geom_markup
        |> xpath(~x"//text"l)
        |> length()

      # one major and one minor gridline per label
      assert number_of_labels == div(number_of_gridlines, 2)
    end
  end

  describe "lines/2" do
    test "draws the line correctly", %{data: data} do
      line =
        Geom.Line.new(data, %{x: :wt, y: :mpg}, linetype: :dashed)
        |> Geom.Line.lines(data)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")
        |> xpath(~x"//polyline"l,
          points: ~x"./@points"s,
          stroke_width: ~x"./@stroke-width"s,
          stroke_opacity: ~x"./@stroke-opacity"s,
          stroke_dash_array: ~x"./@stroke-dasharray"s
        )
        |> hd()

      assert line.stroke_width == "1"
      assert line.stroke_opacity == "1"
      assert line.stroke_dash_array == "4"
      assert hd(String.split(line.points)) == "30,42.0"
    end
  end
end
