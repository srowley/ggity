defmodule GGity.Geom.Ribbon do
  @moduledoc false

  alias GGity.{Draw, Geom, Plot}

  @type t() :: %__MODULE__{}
  @type record() :: map()
  @type mapping() :: map()

  defstruct data: nil,
            mapping: nil,
            stat: :identity,
            position: :identity,
            key_glyph: :rect,
            fill: "black",
            alpha: 1,
            color: nil,
            size: nil

  @spec new(mapping(), keyword()) :: Geom.Ribbon.t()
  def new(mapping, options \\ []) do
    struct(Geom.Ribbon, [{:mapping, mapping} | options])
  end

  @spec draw(Geom.Ribbon.t(), list(map()), Plot.t()) :: iolist()
  def draw(%Geom.Ribbon{} = geom_ribbon, _data, plot) do
    ribbons(geom_ribbon, plot)
  end

  defp ribbons(%Geom.Ribbon{position: :stack} = geom_ribbon, plot) do
    mapping = geom_ribbon.mapping
    plot_height = plot.width / plot.aspect_ratio

    ribbons =
      (geom_ribbon.data || plot.data)
      |> Enum.group_by(fn row ->
        {
          row[mapping[:alpha]],
          row[mapping[:fill]]
        }
      end)
      |> Enum.sort_by(fn {value, _group} -> value end, :desc)
      |> Enum.map(fn {_value, group} -> ribbon(geom_ribbon, group, plot) end)

    stacked_coords =
      ribbons
      |> Enum.map(fn group -> group.coords end)
      |> stack_coordinates(plot_height)
      |> Enum.reverse()

    :lists.zipwith(
      fn ribbon, stacked_coords -> Map.put(ribbon, :coords, stacked_coords) end,
      ribbons,
      stacked_coords
    )
    |> Enum.map(fn ribbon ->
      ribbon.coords
      |> Enum.map_join(" ", fn row ->
        "#{row.x + plot.area_padding},#{row.y_max + plot.area_padding}"
      end)
      |> Draw.polygon(
        stroke: ribbon.color,
        stroke_width: ribbon.size,
        fill: ribbon.fill,
        fill_opacity: ribbon.alpha
      )
    end)
    |> Enum.reverse()
  end

  defp ribbons(%Geom.Ribbon{} = geom_ribbon, plot) do
    ribbons =
      (geom_ribbon.data || plot.data)
      |> Enum.group_by(fn row ->
        {
          row[geom_ribbon.mapping[:alpha]],
          row[geom_ribbon.mapping[:fill]]
        }
      end)
      |> Enum.map(fn {_value, group} -> ribbon(geom_ribbon, group, plot) end)

    Enum.map(ribbons, fn ribbon ->
      ribbon.coords
      |> Enum.map_join(" ", fn row ->
        "#{row.x + plot.area_padding},#{row.y_max + plot.area_padding}"
      end)
      # |> Enum.join(" ")
      |> Draw.polygon(
        stroke: ribbon.color,
        stroke_width: ribbon.size,
        fill: ribbon.fill,
        fill_opacity: ribbon.alpha
      )
    end)
  end

  defp ribbon(%Geom.Ribbon{} = geom_ribbon, data, plot) do
    plot_height = plot.width / plot.aspect_ratio

    scale_transforms =
      geom_ribbon.mapping
      |> Map.keys()
      |> List.insert_at(0, :y)
      |> List.delete(:y_max)
      |> Enum.reduce(%{}, fn aesthetic, mapped ->
        Map.put(mapped, aesthetic, Map.get(plot.scales[aesthetic], :transform))
      end)

    transforms =
      geom_ribbon
      |> Map.take([:alpha, :color, :fill, :size])
      |> Enum.reduce(%{}, fn {aesthetic, fixed_value}, fixed ->
        Map.put(fixed, aesthetic, fn _value -> fixed_value end)
      end)
      |> Map.merge(scale_transforms)

    row = hd(data)

    [alpha, color, fill, size] = [
      transforms.alpha.(row[geom_ribbon.mapping[:alpha]]),
      transforms.color.(row[geom_ribbon.mapping[:color]]),
      transforms.fill.(row[geom_ribbon.mapping[:fill]]),
      transforms.size.(row[geom_ribbon.mapping[:size]])
    ]

    y_max_coords = format_coordinates(:y_max, geom_ribbon, data, plot)

    all_coords =
      if geom_ribbon.mapping[:y_min] do
        y_min_coords =
          :y_min
          |> format_coordinates(geom_ribbon, data, plot)
          |> Enum.reverse()

        [y_max_coords, y_min_coords]
      else
        first_x = List.first(y_max_coords)[:x]
        last_x = List.last(y_max_coords)[:x]
        [y_max_coords, %{x: last_x, y_max: plot_height}, %{x: first_x, y_max: plot_height}]
      end

    %{fill: fill, alpha: alpha, color: color, size: size, coords: List.flatten(all_coords)}
  end

  defp format_coordinates(y_aesthetic, geom, data, plot) do
    data
    |> sort_by_x(geom)
    |> Stream.map(fn row ->
      [
        plot.scales.x.transform.(row[geom.mapping[:x]]),
        plot.scales.y.transform.(row[geom.mapping[y_aesthetic]])
      ]
    end)
    |> Stream.map(fn row -> Map.new(Enum.zip([:x, :y_max], row)) end)
    |> Enum.map(fn row ->
      Map.put(row, :y_max, (plot.width - row.y_max) / plot.aspect_ratio)
    end)
  end

  defp sort_by_x(data, %Geom.Ribbon{} = geom_ribbon) do
    case hd(data)[geom_ribbon.mapping.x] do
      %Date{} ->
        Enum.sort_by(data, fn row -> row[geom_ribbon.mapping.x] end, Date)

      _number ->
        Enum.sort_by(data, fn row -> row[geom_ribbon.mapping.x] end)
    end
  end

  defp stack_coordinates([only_group | []], _plot_height), do: only_group

  defp stack_coordinates([first_group, next_group | rest_of_groups], plot_height) do
    stack_coordinates(
      rest_of_groups,
      sum_ymax_coordinates(first_group, next_group, plot_height),
      [first_group],
      plot_height
    )
  end

  defp stack_coordinates([], updated_group, stacked_coords, _plot_height) do
    [updated_group | stacked_coords]
  end

  defp stack_coordinates(
         [next_group | rest_of_groups],
         updated_group,
         stacked_coords,
         plot_height
       ) do
    stack_coordinates(
      rest_of_groups,
      sum_ymax_coordinates(next_group, updated_group, plot_height),
      [updated_group | stacked_coords],
      plot_height
    )
  end

  defp sum_ymax_coordinates(first_list, second_list, plot_height) do
    :lists.zipwith(
      fn first_row, second_row ->
        %{x: first_row.x, y_max: first_row.y_max + second_row.y_max - plot_height}
      end,
      first_list,
      second_list
    )
  end
end
