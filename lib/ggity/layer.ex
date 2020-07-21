defprotocol GGity.Layer do
  @moduledoc false

  @spec new(GGity.Layer.t(), map(), keyword()) :: GGity.Layer.t()
  def new(geom, mapping, options)

  @spec draw(GGity.Layer.t(), list(map()), GGity.Plot.t()) :: iolist()
  def draw(geom, data, plot)
end

defimpl GGity.Layer, for: GGity.Geom.Point do
  def new(_geom, mapping, options) do
    GGity.Geom.Point.new(mapping, options)
  end

  def draw(geom, data, plot), do: GGity.Geom.Point.draw(geom, data, plot)
end

defimpl GGity.Layer, for: GGity.Geom.Bar do
  def new(_geom, mapping, options) do
    GGity.Geom.Bar.new(mapping, options)
  end

  def draw(geom, data, plot), do: GGity.Geom.Bar.draw(geom, data, plot)
end

defimpl GGity.Layer, for: GGity.Geom.Line do
  def new(_geom, mapping, options) do
    GGity.Geom.Line.new(mapping, options)
  end

  def draw(geom, data, plot), do: GGity.Geom.Line.draw(geom, data, plot)
end

defimpl GGity.Layer, for: GGity.Geom.Blank do
  def new(_geom, _mapping, _options), do: struct(GGity.Geom.Blank)

  def draw(_geom, _data, _plot), do: GGity.Geom.Blank.draw()
end

defimpl GGity.Layer, for: GGity.Geom.Text do
  def new(_geom, mapping, options) do
    GGity.Geom.Text.new(mapping, options)
  end

  def draw(geom, data, plot), do: GGity.Geom.Text.draw(geom, data, plot)
end
