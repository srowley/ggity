defmodule GGity.Geom.Blank do
  @moduledoc false

  defstruct data: nil,
            mapping: nil,
            position: :identity,
            stat: :identity,
            labels: %{}

  @spec draw() :: iolist()
  def draw, do: []
end
