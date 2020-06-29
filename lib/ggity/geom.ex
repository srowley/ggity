defprotocol GGity.Geom do
  @moduledoc false

  @spec new(GGity.Geom.t(), list(map()), map(), keyword()) :: GGity.Geom.t()
  def new(geom, data, mapping, options)

  @spec draw(GGity.Geom.t(), list(map())) :: iolist()
  def draw(geom, data)
end

defimpl GGity.Geom, for: GGity.Geom.Point do
  def new(_geom, data, mapping, options) do
    GGity.Geom.Point.new(data, mapping, options)
  end

  def draw(geom, data), do: GGity.Geom.Point.draw(geom, data)
end

defimpl GGity.Geom, for: GGity.Geom.Bar do
  def new(_geom, data, mapping, options) do
    GGity.Geom.Bar.new(data, mapping, options)
  end

  def draw(geom, data), do: GGity.Geom.Bar.draw(geom, data)
end

defimpl GGity.Geom, for: GGity.Geom.Line do
  def new(_geom, data, mapping, options) do
    GGity.Geom.Line.new(data, mapping, options)
  end

  def draw(geom, data), do: GGity.Geom.Line.draw(geom, data)
end

defimpl GGity.Geom, for: GGity.Geom.Blank do
  def new(_geom, _data, _mapping, _options), do: struct(GGity.Geom.Blank)

  def draw(_geom, _data), do: GGity.Geom.Blank.draw()
end
