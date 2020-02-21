defmodule GGity.Scale.Alpha.Manual do
  @moduledoc false

  alias GGity.Scale.Alpha

  @default_alpha 1

  @type t() :: %__MODULE__{}

  defstruct transform: nil

  @doc false
  @spec new(any()) :: Alpha.Manual.t()
  def new(value \\ @default_alpha) when value >= 0 and value <= 1 do
    struct(Alpha.Manual, transform: fn _value -> value end)
  end
end
