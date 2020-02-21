defmodule GGityGeomPointTest do
  use ExUnit.Case

  import SweetXml

  alias GGity.{Examples, Geom, Scale}

  setup do
    %{data: Examples.mtcars()}
  end

  describe "new/3" do
    test "constructs basic geom with x and y values", %{data: data} do
      geom = Geom.Point.new(data, %{x: :wt, y: :mpg})
      assert geom.mapping == %{x: :wt, y: :mpg}
      assert %Scale.X.Continuous{} = geom.x_scale
      assert %Scale.Y.Continuous{} = geom.y_scale
      assert %Scale.Color.Manual{} = geom.color_scale
      assert %Scale.Size.Manual{} = geom.size_scale
      assert %Scale.Alpha.Manual{} = geom.alpha_scale
      assert %Scale.Shape.Manual{} = geom.shape_scale
    end

    test "adds fixed aesthetics specified as options", %{data: data} do
      geom = Geom.Point.new(data, %{x: :wt, y: :mpg}, alpha: 0.5, color: "red")
      assert geom.color_scale.transform.("meat") == "red"
      assert geom.alpha_scale.transform.("meat") == 0.5
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
        Geom.Point.new(data, %{x: :wt, y: :mpg})
        |> Geom.Point.draw(data)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")

      %{data: data, geom_markup: geom_markup}
    end

    test "draws all the points", %{data: data, geom_markup: geom_markup} do
      number_of_points =
        geom_markup
        |> xpath(~x"//circle"l)
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

  describe "points/2" do
    test "draws the markers correctly", %{data: data} do
      points_map =
        Geom.Point.new(data, %{x: :wt, y: :mpg})
        |> Geom.Point.points(data)
        |> IO.chardata_to_string()
        |> String.replace_prefix("", "<svg>")
        |> String.replace_suffix("", "</svg>")
        |> xpath(~x"//circle"l,
          cx: ~x"./@cx"s,
          cy: ~x"./@cy"s,
          r: ~x"./@r"s,
          fill: ~x"./@fill"s,
          fill_opacity: ~x"./@fill-opacity"s
        )

      assert length(points_map) == length(points_map)

      assert %{
               cx: "74",
               cy: "83.33333333333333",
               r: "2.0",
               fill: "black",
               fill_opacity: "1"
             } in points_map
    end
  end
end
