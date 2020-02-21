defmodule GGity.Scale.Identity do
  @moduledoc false

  alias GGity.{Plot, Scale}

  @type t() :: %__MODULE__{}
  @type aesthetic() :: :x | :y | :color | :size | :alpha
  @valid_aesthetics [:x, :y, :color, :size, :alpha]

  defstruct transform: nil,
            levels: nil

  @spec new(Plot.t(), aesthetic()) :: Scale.Identity.t()
  def new(plot, aesthetic) when aesthetic in @valid_aesthetics do
    levels =
      Stream.map(plot.data, fn row -> Map.get(row, plot.mapping[aesthetic]) end)
      |> Enum.uniq()

    struct(Scale.Identity, levels: levels, transform: fn value -> value end)
  end
end
