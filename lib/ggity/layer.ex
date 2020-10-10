defprotocol GGity.Layer do
  @moduledoc false

  @spec new(GGity.Layer.t(), map(), keyword()) :: GGity.Layer.t()
  def new(geom, mapping, options)

  @spec draw(GGity.Layer.t(), list(map()), GGity.Plot.t()) :: iolist()
  def draw(geom, data, plot)
end

defimpl GGity.Layer, for: [GGity.Geom.Bar, GGity.Geom.Line, GGity.Geom.Point, GGity.Geom.Text] do
  def new(%geom_type{} = _geom, mapping, options) do
    apply(geom_type, :new, [mapping, options])
  end

  def draw(%geom_type{} = geom, data, plot) do
    apply(geom_type, :draw, [geom, data, plot])
  end
end

defimpl GGity.Layer, for: GGity.Geom.Blank do
  def new(_geom, _mapping, _options), do: struct(GGity.Geom.Blank)

  def draw(_geom, _data, _plot), do: GGity.Geom.Blank.draw()
end
