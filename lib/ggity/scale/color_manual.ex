defmodule GGity.Scale.Color.Manual do
  @moduledoc false

  alias GGity.Scale.Color

  @default_color "black"

  @type t() :: %__MODULE__{}

  defstruct transform: nil,
            levels: nil

  @spec new(any()) :: Color.Manual.t()
  def new(value \\ @default_color) when is_binary(value) do
    struct(Color.Manual, levels: [value], transform: fn _value -> value end)
  end
end
