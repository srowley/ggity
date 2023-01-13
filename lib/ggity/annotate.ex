defmodule GGity.Annotate do
  @moduledoc false

  alias GGity.{Geom, Layer}

  @type geom :: Geom.Rect.t() | Geom.Segment.t() | Geom.Text.t()

  @supported_geoms [:rect, :segment, :text]

  @required_parameters [
    rect: [:xmin, :xmax, :ymin, :ymax],
    segment: [:x, :xend, :y, :yend],
    text: [:x, :y, :label]
  ]

  @geom_structs [
    rect: %Geom.Rect{},
    segment: %Geom.Segment{},
    text: %Geom.Text{}
  ]

  @doc false
  @spec annotate(atom(), keyword()) :: geom()
  def annotate(geom_type, params) when geom_type in @supported_geoms do
    mapping = required_params_mapping(geom_type, params)
    options = construct_options(geom_type, params)
    Layer.new(@geom_structs[geom_type], mapping, options)
  end

  defp required_params_mapping(type, params) do
    for {key, _} <- params, key in required_parameters(type), do: {key, to_string(key)}, into: %{}
  end

  defp construct_options(type, params) do
    options = for {key, param} <- params, key not in required_parameters(type), do: {key, param}
    Keyword.put(options, :data, format_data(type, params))
  end

  defp format_data(type, params) do
    row =
      for {key, _} <- params,
          key in required_parameters(type),
          do: {to_string(key), params[key]},
          into: %{}

    Explorer.DataFrame.new([row])
  end

  defp required_parameters(type), do: @required_parameters[type]
end
