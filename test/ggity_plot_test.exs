defmodule GGityPlotTest do
  use ExUnit.Case

  alias GGity.{Element, Examples, Geom, Labels, Plot, Scale}

  setup do
    data = [
      %{a: 1, b: 2, c: 3, date: ~D[2001-01-01], datetime: ~N[2001-01-01 00:00:00]},
      %{a: 2, b: 4, c: 6, date: ~D[2001-01-03], datetime: ~N[2001-01-03 00:00:00]}
    ]

    zero_domain_data = [%{a: 1, b: 2, c: 3}, %{a: 1, b: 2, c: 3}]
    mapping = %{x: :a, y: :b}

    plot =
      Plot.new(data, mapping)
      |> Plot.geom_point()

    %{plot: plot, data: data, mapping: mapping, zero_domain_data: zero_domain_data}
  end

  describe "new/3" do
    test "creates a plot with defaults", %{data: data, mapping: mapping} do
      plot = Plot.new(data, mapping)
      assert plot.mapping == mapping
      assert plot.data == data
      assert %Geom.Blank{} = hd(plot.layers)
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
    end
  end

  describe "xlab/1" do
    test "sets the x-axis label", %{data: data, mapping: mapping} do
      plot =
        Plot.new(data, mapping)
        |> Plot.xlab("X Axis")
        |> Plot.geom_point()

      assert plot.labels.x == "X Axis"
    end
  end

  describe "ylab/1" do
    test "sets the y-axis label", %{data: data, mapping: mapping} do
      plot =
        Plot.new(data, mapping)
        |> Plot.ylab("Y Axis")
        |> Plot.geom_point()

      assert plot.labels.y == "Y Axis"
    end
  end

  describe "geom_area/3" do
    setup %{data: data} do
      mapping = %{x: :date, y_max: :a, fill: :b}
      %{plot: Plot.new(data, mapping)}
    end

    test "adds a ribbon geom with position :stack", %{plot: plot} do
      mapping = %{alpha: :c}
      plot = Plot.geom_area(plot, mapping)
      geom = hd(plot.layers)
      assert geom.mapping == %{alpha: :c}
      assert geom.stat == :identity
      assert geom.position == :stack
      assert %Geom.Ribbon{} = hd(plot.layers)
    end
  end

  describe "geom_bar/3" do
    setup %{data: data} do
      mapping = %{x: :a}
      %{plot: Plot.new(data, mapping)}
    end

    test "adds a bar geom with stat count by default, sets plot y limit", %{plot: plot} do
      plot = Plot.geom_bar(plot)
      assert %Geom.Bar{stat: :count} = hd(plot.layers)
      assert plot.limits.y == {0, nil}
    end

    test "adds a bar geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_bar(plot, %{fill: :c})
      assert %Geom.Bar{mapping: %{fill: :c}} = hd(plot.layers)
    end

    test "adds a bar geom with specified stat and dodge options", %{plot: plot} do
      plot = Plot.geom_bar(plot, %{y: :b, fill: :c}, stat: :identity, position: :dodge)
      geom = hd(plot.layers)
      assert %Geom.Bar{} = geom
      assert geom.mapping == %{y: :b, fill: :c}
      assert geom.stat == :identity
      assert geom.position == :dodge
    end
  end

  describe "geom_boxplot/3" do
    setup do
      data = Examples.mpg()
      mapping = %{x: "class", y: "hwy"}
      %{data: data, mapping: mapping, plot: Plot.new(data, mapping)}
    end

    test "adds a boxplot geom with stat boxplot by default", %{plot: plot} do
      plot = Plot.geom_boxplot(plot)
      assert %Geom.Boxplot{stat: :boxplot} = hd(plot.layers)
    end

    test "adds a boxplot geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_boxplot(plot, %{fill: "drv"})
      assert %Geom.Boxplot{mapping: %{fill: "drv"}} = hd(plot.layers)
    end
  end

  describe "geom_col/3" do
    test "adds a bar geom with y mapping and stat identity", %{data: data, mapping: mapping} do
      plot =
        data
        |> Plot.new(mapping)
        |> Plot.geom_col(%{fill: :c}, stat: :identity)

      geom = hd(plot.layers)
      assert %Geom.Bar{} = geom
      assert geom.mapping == %{fill: :c}
      assert geom.stat == :identity
      assert geom.position == :stack
    end
  end

  describe "geom_point/2" do
    setup %{data: data, mapping: mapping} do
      %{plot: Plot.new(data, mapping)}
    end

    test "adds a point geom with no additional mapping or options", %{plot: plot} do
      geom =
        plot
        |> Plot.geom_point()
        |> Map.get(:layers)
        |> hd()

      assert %Geom.Point{} = geom
    end

    test "adds a point geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_point(plot, %{color: :c})
      geom = hd(plot.layers)
      assert %Geom.Point{} = geom
      assert geom.mapping == %{color: :c}
    end

    test "adds a point geom with specified options", %{plot: plot} do
      plot = Plot.geom_point(plot, color: "red")
      geom = hd(plot.layers)
      assert %Geom.Point{} = geom
      assert geom.color == "red"
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

      geom = hd(plot.layers)
      assert %Geom.Point{} = geom
      assert geom.mapping == %{y: :c}
      assert geom.color == "red"
    end
  end

  describe "geom_line/2" do
    setup %{data: data, mapping: mapping} do
      %{plot: Plot.new(data, mapping)}
    end

    test "adds a line geom with no additional mapping or options", %{plot: plot} do
      plot = Plot.geom_line(plot)
      geom = hd(plot.layers)
      assert %Geom.Line{} = geom
    end

    test "adds a line geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_line(plot, %{color: :c})
      geom = hd(plot.layers)
      assert %Geom.Line{} = geom
      assert geom.mapping == %{color: :c}
    end

    test "adds a line geom with specified options", %{plot: plot} do
      plot = Plot.geom_line(plot, color: "red")
      geom = hd(plot.layers)
      assert %Geom.Line{} = geom
      assert geom.color == "red"
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

      geom = hd(plot.layers)
      assert %Geom.Line{} = geom
      assert geom.mapping == %{y: :c}
      assert geom.color == "red"
    end
  end

  describe "geom_ribbon/3" do
    setup %{data: data} do
      mapping = %{x: :date, y_max: :a}
      %{plot: Plot.new(data, mapping)}
    end

    test "adds a ribbon geom", %{plot: plot} do
      plot = Plot.geom_ribbon(plot)
      assert %Geom.Ribbon{} = hd(plot.layers)
    end

    test "adds a ribbon geom with specified mapping", %{plot: plot} do
      plot = Plot.geom_ribbon(plot, %{fill: :c})
      assert %Geom.Ribbon{mapping: %{fill: :c}} = hd(plot.layers)
    end

    test "adds a ribbon geom with position adjustment", %{plot: plot} do
      plot = Plot.geom_ribbon(plot, %{y: :b, fill: :c}, position: :stack)
      geom = hd(plot.layers)
      assert %Geom.Ribbon{} = geom
      assert geom.mapping == %{y: :b, fill: :c}
      assert geom.stat == :identity
      assert geom.position == :stack
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

      assert %Scale.Alpha.Continuous{} = plot.scales.alpha
    end
  end

  describe "scale_alpha_discrete/1" do
    setup %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :alpha, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()

      %{plot: plot}
    end

    test "sets the alpha scale on the plot geom to an discrete scale", %{plot: plot} do
      plot = Plot.scale_alpha_discrete(plot)
      assert %Scale.Alpha.Discrete{} = plot.scales.alpha
    end

    test "labels legend breaks using custom function", %{plot: plot} do
      plot = Plot.scale_alpha_discrete(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.alpha, 1.0) == "foo"
    end

    test "sets legend labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_alpha_discrete(plot, labels: nil)
      assert Labels.format(plot.scales.alpha, 1.0) == ""
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

      assert %Scale.Identity{} = plot.scales.alpha
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

      assert %Scale.Identity{} = plot.scales.color
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

      assert %Scale.Color.Viridis{} = plot.scales.color
    end

    test "labels legend breaks using custom function", %{plot: plot} do
      plot = Plot.scale_color_viridis(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.color, 1.0) == "foo"
    end

    test "sets legend labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_color_viridis(plot, labels: nil)
      assert Labels.format(plot.scales.color, 1.0) == ""
    end
  end

  describe "scale_linetype_discrete/2" do
    setup %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :linetype, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_line()

      %{plot: plot}
    end

    test "sets the linetype scale on the plot geom", %{plot: plot} do
      plot = Plot.scale_linetype_discrete(plot)
      assert %Scale.Linetype.Discrete{} = plot.scales.linetype
    end

    test "labels legend breaks using custom function", %{plot: plot} do
      plot = Plot.scale_linetype_discrete(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.linetype, 1.0) == "foo"
    end

    test "sets legend labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_linetype_discrete(plot, labels: nil)
      assert Labels.format(plot.scales.linetype, 1.0) == ""
    end
  end

  describe "scale_shape/2" do
    setup %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :shape, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()

      %{plot: plot}
    end

    test "sets the shape scale on the plot geom", %{plot: plot} do
      plot = Plot.scale_shape(plot)
      assert %Scale.Shape{} = plot.scales.shape()
    end

    test "labels legend breaks using custom function", %{plot: plot} do
      plot = Plot.scale_shape(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.shape, 1.0) == "foo"
    end

    test "sets legend labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_shape(plot, labels: nil)
      assert Labels.format(plot.scales.shape, 1.0) == ""
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

      assert %Scale.Size.Continuous{} = plot.scales.size()
    end
  end

  describe "scale_size_discrete/2" do
    setup %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :size, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()

      %{plot: plot}
    end

    test "sets the size scale on the plot geom to an discrete scale", %{plot: plot} do
      plot = Plot.scale_size_discrete(plot)
      assert %Scale.Size.Discrete{} = plot.scales.size()
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

      assert %Scale.Identity{} = plot.scales.size()
    end
  end

  describe "scale_x_continuous/2" do
    test "sets the x scale on the plot geom to continuous", %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :x, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_x_continuous()

      assert %Scale.X.Continuous{} = plot.scales.x
    end

    test "labels x breaks using built-in function", %{plot: plot} do
      plot = Plot.scale_x_continuous(plot, labels: :dollar)
      assert Labels.format(plot.scales.x, 1.0) == "$1.00"
    end

    test "labels x breaks using custom function", %{plot: plot} do
      plot = Plot.scale_x_continuous(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.x, 1.0) == "foo"
    end

    test "sets labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_x_continuous(plot, labels: nil)
      assert Labels.format(plot.scales.x, 1.0) == ""
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
        |> Plot.scale_x_date(date_labels: "%b %d %Y")

      assert %Scale.X.Date{} = plot.scales.x

      assert plot
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

      assert %Scale.X.Date{} = plot.scales.x

      assert plot
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
        |> Plot.scale_x_datetime(date_labels: "%b %d H%H")

      assert %Scale.X.DateTime{} = plot.scales.x

      assert plot
             |> Plot.plot()
             |> IO.chardata_to_string()
             |> String.contains?("Jan 01 H1")
    end
  end

  describe "scale_x_discrete/2" do
    test "sets the x scale on the plot geom to continuous", %{data: data, mapping: mapping} do
      mapping = Map.put(mapping, :x, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_x_discrete()

      assert %Scale.X.Discrete{} = plot.scales.x
    end

    test "labels x breaks using built-in function", %{plot: plot} do
      plot = Plot.scale_x_discrete(plot, labels: :dollar)
      assert Labels.format(plot.scales.x, 1.0) == "$1.00"
    end

    test "labels x breaks using custom function", %{plot: plot} do
      plot = Plot.scale_x_discrete(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.x, 1.0) == "foo"
    end

    test "sets labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_x_discrete(plot, labels: nil)
      assert Labels.format(plot.scales.x, 1.0) == ""
    end
  end

  describe "scale_y_continuous/2" do
    test "sets the y scale on the plot geom to continuous", %{
      data: data,
      mapping: mapping
    } do
      mapping = Map.put(mapping, :y, :c)

      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point()
        |> Plot.scale_y_continuous()

      assert %Scale.Y.Continuous{} = plot.scales.y
    end

    test "labels y breaks using built-in function", %{plot: plot} do
      plot = Plot.scale_y_continuous(plot, labels: :dollar)
      assert Labels.format(plot.scales.y, 1.0) == "$1.00"
    end

    test "labels y breaks using custom function", %{plot: plot} do
      plot = Plot.scale_y_continuous(plot, labels: fn _value -> "foo" end)
      assert Labels.format(plot.scales.y, 1.0) == "foo"
    end

    test "sets labels to blank when labels value is nil", %{plot: plot} do
      plot = Plot.scale_y_continuous(plot, labels: nil)
      assert Labels.format(plot.scales.y, 1.0) == ""
    end
  end

  describe "theme/2" do
    test "replaces theme elements that are nil with values", %{plot: plot} do
      plot = Plot.theme(plot, axis_line: Element.Line.element_line(color: "black", size: 1))
      assert plot.theme.axis_line == %Element.Line{color: "black", size: 1}
    end

    test "replaces theme elements that have values with values", %{plot: plot} do
      plot = Plot.theme(plot, panel_background: Element.Rect.element_rect(fill: "white"))
      assert plot.theme.panel_background == %Element.Rect{fill: "white"}
    end

    test "replaces theme elements that have values with nil", %{plot: plot} do
      plot = Plot.theme(plot, axis_ticks: nil)
      assert plot.theme.axis_ticks == nil
    end

    test "merges theme elements that are structs with existing struct", %{plot: plot} do
      plot = Plot.theme(plot, legend_key: Element.Rect.element_rect(fill: "white", size: 1))

      assert plot.theme.legend_key == %Element.Rect{
               fill: "white",
               size: 1,
               color: "#EEEEEE",
               height: 15
             }
    end

    test "replaces theme elements that have non-map values", %{plot: plot} do
      plot = Plot.theme(plot, axis_ticks_length: 10)
      assert plot.theme.axis_ticks_length == 10
    end
  end

  describe "to_file/1" do
    test "returns an IO List with xml declaration at the top", %{plot: plot} do
      assert hd(Plot.to_xml(plot)) == ~s|<?xml version="1.0" encoding="utf-8"?>|
    end
  end

  describe "to_file/2" do
    test "returns an IO List with xml declaration at the top", %{plot: plot} do
      assert hd(Plot.to_xml(plot, 666)) == ~s|<?xml version="1.0" encoding="utf-8"?>|
    end

    test "sets the height and width of the parent SVG element", %{plot: plot} do
      xml =
        plot
        |> Plot.to_xml(666)
        |> IO.chardata_to_string()

      assert String.contains?(xml, "height=\"666\" width=\"999.0\"")
    end
  end

  describe "guides/2" do
    test "sets the legends for the specified scales", %{
      data: data,
      mapping: mapping
    } do
      plot =
        Plot.new(data, mapping)
        |> Plot.geom_point(%{color: :c, size: :c})
        |> Plot.scale_size_discrete()

      assert plot.scales.size.guide == :legend

      neither_legend = Plot.guides(plot, color: :none, size: :none)
      assert neither_legend.scales.color.guide == :none
      assert neither_legend.scales.size.guide == :none

      color_only = Plot.guides(neither_legend, color: :legend)
      assert color_only.scales.color.guide == :legend
      assert color_only.scales.size.guide == :none
    end
  end
end
