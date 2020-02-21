defmodule GGity.Scale.Shape.Manual do
  @moduledoc false

  alias GGity.Scale.Shape

  @default_shape :circle
  @valid_shapes [:circle, :square, :diamond, :triangle]

  @type t() :: %__MODULE__{}

  defstruct transform: nil

  @spec new(atom()) :: Shape.Manual.t()
  def new(shape \\ @default_shape) when shape in @valid_shapes do
    struct(Shape.Manual, transform: fn _shape -> shape end)
  end
end
