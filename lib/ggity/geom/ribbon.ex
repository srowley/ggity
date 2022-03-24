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
    plot_height = plot.width / plot.aspect_ratio

    ribbons =
      geom_ribbon
      |> group_by_aesthetics(plot)
      |> Enum.sort_by(fn {value, _group} -> value end, :desc)
      |> Enum.map(fn {_value, group} -> ribbon(geom_ribbon, group, plot) end)

    ribbons
    |> Enum.map(fn group -> group.coords end)
    |> stack_coordinates(plot_height)
    |> Enum.zip_with(ribbons, fn stacked_coords, ribbon ->
      Map.put(ribbon, :coords, stacked_coords)
    end)
    |> Enum.map(fn ribbon -> draw_ribbon(ribbon, plot.area_padding) end)
  end

  defp ribbons(%Geom.Ribbon{} = geom_ribbon, plot) do
    geom_ribbon
    |> group_by_aesthetics(plot)
    |> Enum.map(fn {_value, group} ->
      geom_ribbon
      |> ribbon(group, plot)
      |> draw_ribbon(plot.area_padding)
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

  defp group_by_aesthetics(geom, plot) do
    data = geom.data || plot.data

    Enum.group_by(data, fn row ->
      {
        row[geom.mapping[:alpha]],
        row[geom.mapping[:fill]]
      }
    end)
  end

  defp draw_ribbon(ribbon, area_padding) do
    ribbon.coords
    |> Enum.map_join(" ", fn row ->
      "#{row.x + area_padding},#{row.y_max + area_padding}"
    end)
    |> Draw.polygon(
      stroke: ribbon.color,
      stroke_width: ribbon.size,
      fill: ribbon.fill,
      fill_opacity: ribbon.alpha
    )
  end

  defp format_coordinates(y_aesthetic, geom, data, plot) do
    data
    |> Enum.map(fn row ->
      %{
        x: plot.scales.x.transform.(row[geom.mapping[:x]]),
        y_max: transform_and_pad_y(row[geom.mapping[y_aesthetic]], plot)
      }
    end)
    |> Enum.sort_by(fn row -> row.x end)
  end

  defp transform_and_pad_y(y_value, plot) do
    (plot.width - plot.scales.y.transform.(y_value)) / plot.aspect_ratio
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
    Enum.zip_with(first_list, second_list, fn first_row, second_row ->
      %{x: first_row.x, y_max: first_row.y_max + second_row.y_max - plot_height}
    end)
  end
end
