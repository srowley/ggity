defmodule GGity.Scale.Identity do
  @moduledoc false

  alias GGity.Scale

  @type t() :: %__MODULE__{}

  defstruct transform: nil,
            levels: nil,
            labels: :waivers,
            guide: :none,
            aesthetic: nil

  @spec new(atom()) :: Scale.Identity.t()
  def new(aesthetic) do
    struct(Scale.Identity, aesthetic: aesthetic)
  end

  @spec train(Scale.Identity.t(), list(binary())) :: Scale.Identity.t()
  def train(scale, [level | _other_levels] = levels) when is_list(levels) and is_binary(level) do
    transform = fn value -> value end
    struct(scale, levels: levels, transform: transform)
  end
end
