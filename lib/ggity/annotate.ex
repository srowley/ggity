defmodule GGity.Annotate do
  @moduledoc false

  alias GGity.{Geom, Layer}

  @type geom :: Geom.Text.t()

  @supported_geoms [:text]

  @required_parameters [
    text: [:x, :y, :label]
  ]

  @geom_structs [
    text: %Geom.Text{}
  ]

  @doc false
  @spec annotate(atom(), keyword()) :: geom()
  def annotate(geom_type, values) when geom_type in @supported_geoms do
    mapping = required_params_mapping(geom_type, values)
    options = construct_options(geom_type, values)
    Layer.new(@geom_structs[geom_type], mapping, options)
  end

  defp required_params_mapping(type, values) do
    for {key, _} <- values, key in @required_parameters[type], do: {key, key}, into: %{}
  end

  defp construct_options(type, values) do
    options = for {key, value} <- values, key not in @required_parameters[type], do: {key, value}
    Keyword.put(options, :data, format_data(type, values))
  end

  defp format_data(type, values) do
    row =
      for {key, _} <- values, key in @required_parameters[type], do: {key, values[key]}, into: %{}

    [row]
  end
end
