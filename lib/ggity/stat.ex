defmodule GGity.Stat do
  @moduledoc false

  @type dataset :: Explorer.DataFrame.t()

  @doc false
  @spec identity(dataset(), map()) :: {dataset(), map()}
  def identity(data, mapping), do: {data, mapping}

  @spec count(dataset(), map()) :: {dataset(), map()}
  def count(data, mapping) do
    discrete_variables = discrete_variables(data, mapping)

    stat =
      data
      |> Explorer.DataFrame.group_by(discrete_variables)
      |> Explorer.DataFrame.summarise_with(&[count: Explorer.Series.count(&1[mapping[:x]])])
      |> Explorer.DataFrame.arrange_with(& &1[mapping[:x]])

    mapping = Map.put(mapping, :y, "count")
    {stat, mapping}
  end

  @spec boxplot(dataset(), map()) :: {dataset(), map()}
  def boxplot(data, mapping) do
    discrete_aesthetics = discrete_aesthetics(data, mapping)
    permutations = permutations(discrete_aesthetics, data, mapping)
    data = Explorer.DataFrame.to_rows(data)

    stat =
      permutations
      |> Enum.reduce([], fn permutation, stat ->
        [
          discrete_aesthetics
          |> Map.new(fn aesthetic ->
            {mapping[aesthetic], permutation[aesthetic]}
          end)
          |> Map.merge(boxplot_stats_map(data, mapping, permutation))
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)
      |> Explorer.DataFrame.new(dtypes: [{"outliers", :binary}])

    {stat, mapping}
  end

  defp boxplot_stats_map(data, mapping, permutation) do
    permutation_data =
      data
      |> Enum.filter(fn row ->
        Enum.map(permutation, fn {k, _v} -> row[mapping[k]] end) ==
          Enum.map(permutation, fn {_k, v} -> v end)
      end)
      |> Enum.map(fn row -> row[mapping[:y]] end)

    permutation_series = Explorer.Series.from_list(permutation_data)

    quantiles =
      for quantile <- [0.25, 0.5, 0.75],
          do: {quantile, Explorer.Series.quantile(permutation_series, quantile)},
          into: %{}

    interquartile_range = quantiles[0.75] - quantiles[0.25]
    ymin_threshold = quantiles[0.25] - 1.5 * interquartile_range
    ymax_threshold = quantiles[0.75] + 1.5 * interquartile_range

    outliers =
      for record <- permutation_data,
          record > ymax_threshold or record < ymin_threshold,
          do: record

    %{
      "ymin" =>
        permutation_series
        |> Explorer.Series.mask(Explorer.Series.greater_equal(permutation_series, ymin_threshold))
        |> Explorer.Series.min(),
      "lower" => quantiles[0.25],
      "middle" => quantiles[0.5],
      "upper" => quantiles[0.75],
      "ymax" =>
        permutation_series
        |> Explorer.Series.mask(Explorer.Series.less_equal(permutation_series, ymax_threshold))
        |> Explorer.Series.max(),
      "outliers" => :erlang.term_to_binary(outliers)
    }
  end

  defp discrete_variables(data, mapping) do
    for {name, series} <- Explorer.DataFrame.to_series(data),
        Explorer.Series.dtype(series) == :string or name == mapping[:x],
        name in Map.values(mapping),
        do: name
  end

  defp discrete_aesthetics(data, mapping) do
    discrete_variables = discrete_variables(data, mapping)
    for {aesthetic, variable} <- mapping, variable in discrete_variables, do: aesthetic
  end

  defp permutations(discrete_aesthetics, data, mapping) do
    data = Explorer.DataFrame.to_rows(data)

    for row <- data,
        uniq: true,
        do:
          discrete_aesthetics
          |> Enum.map(fn aesthetic -> {aesthetic, row[mapping[aesthetic]]} end)
          |> Map.new()
  end
end
