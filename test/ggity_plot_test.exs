defmodule GGityPlotTest do
  use ExUnit.Case

  alias GGity.{Geom, Plot, Scale}

  setup do
    data = [
      %{a: 1, b: 2, c: 3, date: ~D[2001-01-01], datetime: ~N[2001-01-01 00:00:00]},
      %{a: 2, b: 4, c: 6, date: ~D[2001-01-03], datetime: ~N[2001-01-03 00:00:00]}
    ]

    # TODO: Use this fixture to test zero-length data range
    # data = [%{a: 1, b: 2, c: 3}, %{a: 1, b: 2, c: 3}]
    mapping = %{x: :a, y: :b}
    %{data: data, mapping: mapping}
  end

  describe "new/3" do
    test "creates a plot with defaults", %{data: data, mapping: mapping} do
      plot = Plot.new(data, mapping)
      assert plot.mapping == mapping
      assert plot.data == data
      assert %Geom.Blank{} = plot.geom
    end

    test "sets provided options only if valid", %{data: data, mapping: mapping} do
      plot = Plot.new(data, mapping, width: 300, meat: "meat")
      assert plot.width == 300
      assert_raise(KeyError, fn -> plot.meat end)
    end
  end

  describe "labs/2" do
    test "sets the labels on the plot and geom", %{data: data, mapping: mapping} do
      plot =
        Plot.new(data, mapping)
        |> Plot.labs(title: "Title", x: "X Axis")
        |> Plot.geom_point()

      assert plot.labels.title == "Title"
      assert plot.labels.x == "X Axis"

      assert plot.geom.labels.title == "Title"
      assert plot.geom.labels.x == "X Axis"
    end
  end

  describe "xlab/1" do
    test "sets the x-axis label", %{data: data, mapping: mapping} do
      plot =
        Plot.new(data, mapping)
        |> Plot.xlab("X Axis")
        |> Plot.geom_point()

      assert plot.labels.x == "X Axis"
      assert plot.geom.labels.x == "X Axis"
    end
  end

  describe "ylab/1" do
    test "sets the y-axis label", %{data: data, mapping: mapping} do
      plot =
        Plot.new(data, mapping)
        |> Plot.ylab("Y Axis")
        |> Plot.geom_point()

      assert plot.labels.y == "Y Axis"
      assert plot.geom.labels.y == "Y Axis"
    end
  end

  describe "geom_point/2" do
    setup %{data: data, mapping: mapping} do
      %{plot: Plot.new(data, mapping)}
    end

    # TODO This fails when x or y points are all the same because x and y range
    # is 0 and scale functions use logarithms to determine transformation function
    test "adds a point geom with no additional mapping or options", %{plot: plot} do
      plot = Plot.geom_point(plot)
      assert %Geom.Point{} = plot.geom
      assert plot.geom.mapping == plot.mapping
    end

    test "adds a point geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_point(plot, %{color: :c})
      assert %Geom.Point{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :b, color: :c}
    end

    test "adds a point geom with specified options", %{plot: plot} do
      plot = Plot.geom_point(plot, color: "red")
      assert %Geom.Point{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :b}
      assert plot.geom.color_scale == Scale.Color.Manual.new("red")
    end
  end

  describe "geom_point/3" do
    test "adds a point geom with both specified mapping and options", %{
      data: data,
      mapping: mapping
    } do
      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point(%{y: :c}, color: "red")

      assert %Geom.Point{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :c}
      assert plot.geom.color_scale == Scale.Color.Manual.new("red")
    end
  end

  describe "geom_line/2" do
    setup %{data: data, mapping: mapping} do
      %{plot: Plot.new(data, mapping)}
    end

    # TODO This fails when x or y points are all the same because x and y range
    # is 0 and scale functions use logarithms to determine transformation function
    test "adds a line geom with no additional mapping or options", %{plot: plot} do
      plot = Plot.geom_line(plot)
      assert %Geom.Line{} = plot.geom
      assert plot.geom.mapping == plot.mapping
    end

    test "adds a line geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_line(plot, %{color: :c})
      assert %Geom.Line{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :b, color: :c}
    end

    test "adds a line geom with specified options", %{plot: plot} do
      plot = Plot.geom_line(plot, color: "red")
      assert %Geom.Line{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :b}
      assert plot.geom.color_scale == Scale.Color.Manual.new("red")
    end
  end

  describe "geom_line/3" do
    test "adds a line geom with both specified mapping and options", %{
      data: data,
      mapping: mapping
    } do
      plot =
        Plot.new(data, mapping)
        |> Plot.geom_line(%{y: :c}, color: "red")

      assert %Geom.Line{} = plot.geom
      assert plot.geom.mapping == %{x: :a, y: :c}
      assert plot.geom.color_scale == Scale.Color.Manual.new("red")
    end
  end

  describe "scale_alpha_continuous/1" do
    test "sets the alpha scale on the plot geom to continuous", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :alpha, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_alpha_continuous()

      assert %Scale.Alpha.Continuous{} = plot.geom.alpha_scale()
    end
  end

  describe "scale_alpha_discrete/1" do
    test "sets the alpha scale on the plot geom to an discrete scale", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :alpha, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_alpha_discrete()

      assert %Scale.Alpha.Discrete{} = plot.geom.alpha_scale()
    end
  end

  describe "scale_alpha_identity/1" do
    test "sets the alpha scale on the plot geom to an identity scale", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :alpha, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_alpha_identity()

      assert %Scale.Identity{} = plot.geom.alpha_scale()
    end
  end

  describe "scale_color_identity/1" do
    test "sets the color scale on the plot geom to an identity scale", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :color, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_color_identity()

      assert %Scale.Identity{} = plot.geom.color_scale()
    end
  end

  describe "scale_color_viridis/2" do
    test "sets the color scale on the plot geom to discrete viridis", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :color, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_color_viridis()

      assert %Scale.Color.Viridis{} = plot.geom.color_scale()
    end
  end

  describe "scale_shape/2" do
    test "sets the shape scale on the plot geom", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :shape, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_shape()

      assert %Scale.Shape{} = plot.geom.shape_scale()
    end
  end

  describe "scale_size_continuous/2" do
    test "sets the size scale on the plot geom to continuous", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :size, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_size_continuous()

      assert %Scale.Size.Continuous{} = plot.geom.size_scale()
    end
  end

  describe "scale_size_discrete/2" do
    test "sets the size scale on the plot geom to an discrete scale", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :size, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_size_discrete()

      assert %Scale.Size.Discrete{} = plot.geom.size_scale()
    end
  end

  describe "scale_size_identity/1" do
    test "sets the size scale on the plot geom to an identity scale", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :alpha, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_size_identity()

      assert %Scale.Identity{} = plot.geom.size_scale()
    end
  end

  describe "scale_x_continuous/2" do
    test "sets the x scale on the plot geom to continuous", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :x, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_x_continuous()

      assert %Scale.X.Continuous{} = plot.geom.x_scale()
    end
  end

  describe "scale_x_date/2" do
    test "sets the x scale on the plot geom to continuous for Date data", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :x, :date)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_line()
        |> Plot.scale_x_date()

      assert %Scale.X.Date{} = plot.geom.x_scale()
      assert plot.geom.x_scale.tick_values == [~D[2001-01-01], ~D[2001-01-02], ~D[2001-01-03]]

      assert plot
             |> Plot.scale_x_date(date_labels: "%b %d %Y")
             |> Plot.plot()
             |> IO.chardata_to_string()
             |> String.contains?("Jan 01 2001")
    end

    test "passes date_label options to NimbleStrftime if passed a date_label tuple", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :x, :date)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_line()
        |> Plot.scale_x_date()

      assert %Scale.X.Date{} = plot.geom.x_scale()
      assert plot.geom.x_scale.tick_values == [~D[2001-01-01], ~D[2001-01-02], ~D[2001-01-03]]

      assert plot
             |> Plot.scale_x_date(
               date_labels:
                 {"%A",
                  day_of_week_names: fn day_of_week ->
                    {
                      "Monday",
                      "Tuesday",
                      "Hump Day",
                      "Thursday",
                      "Friday",
                      "Saturday",
                      "Sunday"
                    }
                    |> elem(day_of_week - 1)
                  end}
             )
             |> Plot.plot()
             |> IO.chardata_to_string()
             |> String.contains?("Hump Day")
    end
  end

  describe "scale_x_datetime/2" do
    test "sets the x scale on the plot geom to continuous for DateTime data", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :x, :datetime)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_x_datetime()

      assert %Scale.X.DateTime{} = plot.geom.x_scale()

      assert plot.geom.x_scale.tick_values() ==
               [
                 ~N[2001-01-01 00:00:00],
                 ~N[2001-01-01 12:00:00],
                 ~N[2001-01-02 00:00:00],
                 ~N[2001-01-02 12:00:00],
                 ~N[2001-01-03 00:00:00]
               ]

      assert plot
             |> Plot.scale_x_datetime(date_labels: "%b %d H%H")
             |> Plot.plot()
             |> IO.chardata_to_string()
             |> String.contains?("Jan 01 H1")
    end
  end

  describe "scale_y_continuous/2" do
    test "sets the x scale on the plot geom to continuous", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :y, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_y_continuous()

      assert %Scale.Y.Continuous{} = plot.geom.y_scale()
    end
  end
end
