defmodule Mix.Tasks.Smoke do
  use Mix.Task

  @shortdoc "Run smoke tests"
  def run(args) do
    :ok = Mix.Shell.IO.info("Running smoke tests")
    :ok = Mix.Tasks.Cmd.run(~w(MIX_ENV=dev mix test smoke_test --color --trace --seed 0 --max-failures 1) ++ args)
  end
end
