defmodule ExOneSignal.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_one_signal,
      version: "0.1.0",
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
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"}
    ]
  end
end
