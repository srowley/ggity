defprotocol GGity.Legend do
  @moduledoc false

  @fallback_to_any true

  @spec draw_legend(GGity.Legend.t(), binary(), atom()) :: iolist()
  def draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: GGity.Scale.Alpha.Discrete do
  def draw_legend(scale, label, key_glyph),
    do: GGity.Scale.Alpha.Discrete.draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: GGity.Scale.Color.Viridis do
  def draw_legend(scale, label, key_glyph),
    do: GGity.Scale.Color.Viridis.draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: GGity.Scale.Fill.Viridis do
  def draw_legend(scale, label, key_glyph),
    do: GGity.Scale.Fill.Viridis.draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: GGity.Scale.Linetype.Discrete do
  def draw_legend(scale, label, key_glyph),
    do: GGity.Scale.Linetype.Discrete.draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: GGity.Scale.Shape do
  def draw_legend(scale, label, _key_glyph), do: GGity.Scale.Shape.draw_legend(scale, label)
end

defimpl GGity.Legend, for: GGity.Scale.Shape.Manual do
  def draw_legend(scale, label, _key_glyph),
    do: GGity.Scale.Shape.Manual.draw_legend(scale, label)
end

defimpl GGity.Legend, for: GGity.Scale.Size.Discrete do
  def draw_legend(scale, label, key_glyph),
    do: GGity.Scale.Size.Discrete.draw_legend(scale, label, key_glyph)
end

defimpl GGity.Legend, for: Any do
  def draw_legend(_scale, _label, _key_glyph), do: []
end
