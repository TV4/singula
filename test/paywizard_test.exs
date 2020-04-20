defmodule PaywizardTest do
  use ExUnit.Case
  doctest Paywizard

  test "greets the world" do
    assert Paywizard.hello() == :world
  end
end
