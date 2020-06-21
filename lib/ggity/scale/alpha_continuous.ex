defmodule GGity.Scale.Alpha.Continuous do
  @moduledoc false

  alias GGity.Scale.Alpha

  @type t() :: %__MODULE__{}

  defstruct alpha_min: 0.1,
            alpha_max: 1,
            transform: nil

  @spec new(list(nil), keyword()) :: Alpha.Continuous.t()
  def new(values, options \\ [])

  def new([nil | _tail], _options) do
    struct(Alpha.Continuous, transform: fn _value -> 1 end)
  end

  def new(values, options) do
    scale = struct(Alpha.Continuous, options)
    domain = scale.alpha_max - scale.alpha_min
    {value_min, value_max} = Enum.min_max(values)
    range = value_max - value_min

    struct(scale,
      transform: fn value -> scale.alpha_min + (value - value_min) / range * domain end
    )
  end
end
