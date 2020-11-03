defmodule GGity.Scale.Size.Continuous do
  @moduledoc false

  alias GGity.Scale.Size

  @type t() :: %__MODULE__{}

  defstruct range: {9, 100},
            transform: nil

  @spec new(keyword()) :: Size.Continuous.t()
  def new(options \\ []), do: struct(Size.Continuous, options)

  @spec train(Size.Continuous.t(), {number(), number()}) :: Size.Continuous.t()
  def train(scale, {value_min, value_max}) do
    domain = value_max - value_min
    {range_min, range_max} = scale.range
    range = range_max - range_min

    struct(scale,
      transform: fn value -> :math.sqrt(range_min + (value - value_min) / domain * range) end
    )
  end
end
