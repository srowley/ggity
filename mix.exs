defmodule GGity.MixProject do
  use Mix.Project

  @source_url "https://github.com/srowley/ggity"
  @version "0.4.0"

  def project do
    [
      app: :ggity,
      version: @version,
      aliases: aliases(),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "GGity",
      description: """
        GGity brings the familiar interface of R's ggplot2 library to SVG
        charting in Elixir.
      """,
      homepage_url: "http://www.pocketbookvote.com",
      docs: docs()
    ]
  end

  def application, do: []

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:sweet_xml, "~> 0.7", only: :test},
      {:nimble_csv, "~> 1.2"},
      {:nimble_strftime, "~> 0.1"}
    ]
  end

  defp aliases do
    [
      checks: [
        "compile",
        "credo",
        "format",
        "ggity.visual"
      ],
      build_docs: [
        "ggity.docs",
        "docs"
      ]
    ]
  end

  defp package() do
    [
      maintainers: "Steve Rowley",
      name: "ggity",
      files: ~w(lib priv mix.exs README* LICENSE* ROADMAP* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "Website" => "http://www.pocketbookvote.com/",
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "Roadmap" => "#{@source_url}/blob/master/ROADMAP.md"
      }
    ]
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v#{@version}",
      main: "readme",
      extra_section: "CONCEPTS & EXAMPLES",
      assets: "guides/assets",
      formatters: ["html", "epub"],
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      api_reference: false
    ]
  end

  defp extras() do
    [
      "README.md",
      "guides/geom_point.md": [title: "Points"],
      "guides/geom_line.md": [title: "Lines"],
      "guides/geom_bar.md": [title: "Bars"],
      "guides/geom_boxplot.md": [title: "Boxplot"],
      "guides/geom_text.md": [title: "Text"],
      "guides/scale_color_viridis.md": [title: "Color/Fill Viridis"],
      "guides/theme.md": [title: "Theme"],
      "guides/annotate.md": [title: "Annotate"]
    ]
  end

  defp groups_for_extras do
    [
      Geoms: [
        "guides/geom_point.md",
        "guides/geom_line.md",
        "guides/geom_bar.md",
        "guides/geom_boxplot.md",
        "guides/geom_text.md"
      ],
      Scales: [
        "guides/scale_color_viridis.md"
      ],
      Themes: [
        "guides/theme.md"
      ],
      Annotations: [
        "guides/annotate.md"
      ]
    ]
  end

  defp groups_for_modules do
    [
      "Plot API": [GGity.Plot],
      Themes: [GGity.Theme, GGity.Element.Line, GGity.Element.Rect, GGity.Element.Text],
      Helpers: [GGity.Labels]
    ]
  end
end
