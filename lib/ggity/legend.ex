defprotocol GGity.Legend do
  @moduledoc false

  @fallback_to_any true

  @spec draw_legend(GGity.Legend.t(), binary()) :: iolist()
  def draw_legend(scale, label)

  @spec legend_height(GGity.Legend.t()) :: non_neg_integer()
  def legend_height(scale)
end

defimpl GGity.Legend, for: GGity.Scale.Alpha.Discrete do
  def draw_legend(scale, label), do: GGity.Scale.Alpha.Discrete.draw_legend(scale, label)
  def legend_height(scale), do: GGity.Scale.Alpha.Discrete.legend_height(scale)
end

defimpl GGity.Legend, for: GGity.Scale.Color.Viridis do
  def draw_legend(scale, label), do: GGity.Scale.Color.Viridis.draw_legend(scale, label)
  def legend_height(scale), do: GGity.Scale.Color.Viridis.legend_height(scale)
end

defimpl GGity.Legend, for: GGity.Scale.Shape do
  def draw_legend(scale, label), do: GGity.Scale.Shape.draw_legend(scale, label)
  def legend_height(scale), do: GGity.Scale.Shape.legend_height(scale)
end

defimpl GGity.Legend, for: GGity.Scale.Shape.Manual do
  def draw_legend(scale, label), do: GGity.Scale.Shape.Manual.draw_legend(scale, label)
  def legend_height(scale), do: GGity.Scale.Shape.Manual.legend_height(scale)
end

defimpl GGity.Legend, for: GGity.Scale.Size.Discrete do
  def draw_legend(scale, label), do: GGity.Scale.Size.Discrete.draw_legend(scale, label)
  def legend_height(scale), do: GGity.Scale.Size.Discrete.legend_height(scale)
end

defimpl GGity.Legend, for: Any do
  def draw_legend(_scale, _label), do: []
  def legend_height(_scale), do: 0
end
