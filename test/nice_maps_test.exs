defmodule NiceMapsTest do
  use ExUnit.Case
  doctest NiceMaps

  describe "edge cases" do
    test "bug with key :currency_reward_currency" do
      map = %{currency_reward_currency: "something"}

      assert %{currencyRewardCurrency: "something"} == NiceMaps.parse(map, keys: :camelcase)
    end
  end
end
