defmodule GGity.Scale.Size.Manual do
  @moduledoc false

  alias GGity.Scale.Size

  @default_size 4

  @type t() :: %__MODULE__{}

  defstruct transform: nil

  @spec new(number()) :: Size.Manual.t()
  def new(size \\ @default_size) when is_number(size) do
    struct(Size.Manual, transform: fn _size -> size end)
  end
end
