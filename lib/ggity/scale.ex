defprotocol GGity.Scale do
  @moduledoc false

  @type date() :: %Date{}
  @type datetime() :: %DateTime{} | %NaiveDateTime{}
  @type date_or_time() :: date() | datetime()
  @type continuous_value :: number() | date_or_time()

  @spec train(GGity.Scale.t(), {continuous_value(), continuous_value()} | list()) ::
          GGity.Scale.t()
  def train(scale, parameters)
end

defimpl GGity.Scale, for: GGity.Scale.Alpha.Continuous do
  def train(scale, {min, max}),
    do: GGity.Scale.Alpha.Continuous.train(scale, {min, max})
end

defimpl GGity.Scale, for: GGity.Scale.Alpha.Discrete do
  def train(scale, levels),
    do: GGity.Scale.Alpha.Discrete.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Color.Viridis do
  def train(scale, levels),
    do: GGity.Scale.Color.Viridis.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Fill.Viridis do
  def train(scale, levels),
    do: GGity.Scale.Fill.Viridis.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Linetype.Discrete do
  def train(scale, levels),
    do: GGity.Scale.Linetype.Discrete.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Shape do
  def train(scale, levels), do: GGity.Scale.Shape.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Shape.Manual do
  def train(scale, levels),
    do: GGity.Scale.Shape.Manual.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Size.Continuous do
  def train(scale, {min, max}),
    do: GGity.Scale.Size.Continuous.train(scale, {min, max})
end

defimpl GGity.Scale, for: GGity.Scale.Size.Discrete do
  def train(scale, levels),
    do: GGity.Scale.Size.Discrete.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.X.Continuous do
  def train(scale, {min, max}),
    do: GGity.Scale.X.Continuous.train(scale, {min, max})
end

defimpl GGity.Scale, for: GGity.Scale.X.Date do
  def train(scale, {min, max}),
    do: GGity.Scale.X.Date.train(scale, {min, max})
end

defimpl GGity.Scale, for: GGity.Scale.X.DateTime do
  def train(scale, {min, max}),
    do: GGity.Scale.X.DateTime.train(scale, {min, max})
end

defimpl GGity.Scale, for: GGity.Scale.X.Discrete do
  def train(scale, levels),
    do: GGity.Scale.X.Discrete.train(scale, levels)
end

defimpl GGity.Scale, for: GGity.Scale.Y.Continuous do
  def train(scale, {min, max}),
    do: GGity.Scale.Y.Continuous.train(scale, {min, max})
end
