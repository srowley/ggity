defmodule GGity.Geom.Blank do
  @moduledoc false

  defstruct area_padding: 20,
            labels: %{}

  @spec draw() :: iolist()
  def draw, do: []
end
