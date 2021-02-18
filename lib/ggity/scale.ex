defprotocol GGity.Scale do
  @moduledoc false

  @type date() :: %Date{}
  @type datetime() :: %DateTime{} | %NaiveDateTime{}
  @type date_or_time() :: date() | datetime()
  @type continuous_value :: number() | date_or_time()

  @spec train(GGity.Scale.t(), {continuous_value(), continuous_value()} | list(binary())) ::
          GGity.Scale.t()
  def train(scale, parameters)
end

defimpl GGity.Scale,
  for: [
    GGity.Scale.Alpha.Discrete,
    GGity.Scale.Color.Viridis,
    GGity.Scale.Fill.Viridis,
    GGity.Scale.Identity,
    GGity.Scale.Linetype.Discrete,
    GGity.Scale.Shape.Manual,
    GGity.Scale.Shape,
    GGity.Scale.X.Discrete
  ] do
  def train(%scale_type{} = scale, levels) do
    apply(scale_type, :train, [scale, levels])
  end
end

defimpl GGity.Scale,
  for: [
    GGity.Scale.Alpha.Continuous,
    GGity.Scale.Size,
    GGity.Scale.X.Continuous,
    GGity.Scale.X.Date,
    GGity.Scale.X.DateTime,
    GGity.Scale.Y.Continuous
  ] do
  def train(%scale_type{} = scale, {min, max}) do
    apply(scale_type, :train, [scale, {min, max}])
  end
end
