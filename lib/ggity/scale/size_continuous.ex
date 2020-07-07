defmodule GGity.Scale.Size.Continuous do
  @moduledoc false

  alias GGity.Scale.Size

  @type t() :: %__MODULE__{}

  defstruct size_min: 4,
            size_max: 14,
            transform: nil

  @spec new(keyword()) :: Size.Continuous.t()
  def new(options \\ []), do: struct(Size.Continuous, options)

  # TODO: Commented lines allow to set (circle at least) size based on area; revisit for all shapes
  @spec train(Size.Continuous.t(), {number(), number()}) :: Size.Continuous.t()
  def train(scale, {value_min, value_max}) do
    # area_min = :math.pow(scale.radius_min, 2) * :math.pi()
    # area_min = :math.pow(scale.radius_min, 2) * :math.pi()
    domain = value_max - value_min
    range = scale.size_max - scale.size_min

    struct(scale,
      transform: fn value -> scale.size_min + (value - value_min) / domain * range end
      # transform: fn value -> :math.sqrt((area_min + (value - value_min) * range / domain) / :math.pi()) end
    )
  end
end
