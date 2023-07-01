defmodule MeriazardLocalTest do
  use ExUnit.Case
  doctest MeriazardLocal

  test "greets the world" do
    assert MeriazardLocal.hello() == :world
  end
end
