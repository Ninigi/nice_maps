defmodule NiceMaps.MixProject do
  use Mix.Project

  @github "https://github.com/Ninigi/nice_maps"

  def project do
    [
      app: :nice_maps,
      description: "A library to transform map keys / structs into maps.",
      version: "0.3.0",
      elixir: "~> 1.8",
      test_coverage: [tool: Coverex.Task],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENCE"
      ],
      links: %{"github" => @github},
      maintainers: ["Fabian Zitter <fabian.zitter@gmail.com>"],
      licenses: ["MIT"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0.1", only: :test},
      {:coverex, "~> 1.5", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
