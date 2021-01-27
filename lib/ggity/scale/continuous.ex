defmodule GGity.Scale.Continuous do
  @moduledoc false

  @type extent() :: number() | %Date{} | %DateTime{} | %NaiveDateTime{}

  @doc false
  @spec transform({extent(), extent()}, {extent(), extent()}) :: (extent() -> number())
  def transform({domain_min, domain_max}, {range_min, range_max}) do
    fn value ->
      diff(value, domain_min) / diff(domain_max, domain_min) * diff(range_max, range_min)
    end
  end

  defp diff(first, second) when is_number(first) and is_number(second) do
    first - second
  end

  defp diff(%date_type{} = first, %date_type{} = second) when date_type == Date do
    Date.diff(first, second)
  end

  defp diff(%date_type{} = first, %date_type{} = second)
       when date_type in [DateTime, NaiveDateTime] do
    apply(date_type, :diff, [first, second, :millisecond])
  end
end
