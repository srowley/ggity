defmodule GGity.Scale.Size.Continuous do
  @moduledoc false

  alias GGity.Scale.Size

  @default_size 4

  @type t() :: %__MODULE__{}

  defstruct size_min: 4,
            size_max: 14,
            transform: nil

  @spec new(list(), keyword()) :: Size.Continuous.t()
  def new(values, options \\ [])

  def new([nil | _tail], _options) do
    %{transform: fn _value -> @default_size end}
  end

  def new(values, options) do
    {value_min, value_max} = Enum.min_max(values)
    domain = value_max - value_min
    new(domain, value_min, options)
  end

  @spec new(number(), number(), keyword()) :: Size.Continuous.t()
  def new(0, _value_min, options) do
    scale = struct(Size.Continuous, options)
    struct(scale, transform: fn _value -> 1 end)
  end

  # TODO
  # Commented lines allow to set (circle at least) size based on area; revisit for all shapes
  def new(domain, value_min, options) do
    scale = struct(Size.Continuous, options)
    # area_min = :math.pow(scale.radius_min, 2) * :math.pi()
    # area_min = :math.pow(scale.radius_min, 2) * :math.pi()
    range = scale.size_max - scale.size_min

    struct(scale,
      transform: fn value -> scale.size_min + (value - value_min) / domain * range end
      # transform: fn value -> :math.sqrt((area_min + (value - value_min) * range / domain) / :math.pi()) end
    )
  end
end
