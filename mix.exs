defmodule ExOneSignal.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_one_signal,
      version: "0.1.2",
      name: "ExOneSignal",
      description: "A simple interface to interact with OneSignal's push notification API.",
      package: package(),
      source_url: "https://github.com/logit-ai/ex_one_signal",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExOneSignal, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 0.8", only: :test},
      {:ex_doc, "~> 0.19", only: :dev},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"}
    ]
  end

  defp package do
    [
      name: "ex_one_signal",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Jamie Evans"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/logit-ai/ex_one_signal"
      }
    ]
  end
end
