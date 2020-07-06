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
    {value_min, value_max} = Enum.min_max(values)
    domain = value_max - value_min
    new(domain, value_min, options)
  end

  @spec new(number(), number(), keyword()) :: Alpha.Continuous.t()
  def new(0, _value_min, options) do
    scale = struct(Alpha.Continuous, options)
    struct(scale, transform: fn _value -> 1 end)
  end

  def new(domain, value_min, options) do
    scale = struct(Alpha.Continuous, options)
    range = scale.alpha_max - scale.alpha_min

    struct(scale,
      transform: fn value -> scale.alpha_min + (value - value_min) / domain * range end
    )
  end
end
