defmodule NiceMapsTest do
  use ExUnit.Case
  doctest NiceMaps

  describe "edge cases" do
    test "bug with key :currency_reward_currency" do
      map = %{currency_reward_currency: "something"}

      assert %{currencyRewardCurrency: "something"} == NiceMaps.parse(map, keys: :camelcase)
    end

    test "nested maps to camelcase" do
      map = %{
        order_line: %{
          fulfillment_status: "partial"
        }
      }

      assert %{orderLine: %{fulfillmentStatus: _}} = NiceMaps.parse(map, keys: :camelcase)
    end

    test "nested lists to camelcase" do
      map = %{
        order_lines: [
          %{
            fulfillment_status: "partial"
          }
        ]
      }

      assert %{orderLines: [%{fulfillmentStatus: _}]} = NiceMaps.parse(map, keys: :camelcase)
    end

    test "nested maps to snake_case" do
      map = %{
        orderLine: %{
          fulfillmentStatus: "partial"
        }
      }

      assert %{order_line: %{fulfillment_status: _}} = NiceMaps.parse(map, keys: :snake_case)
    end

    test "nested lists to snake_case" do
      map = %{
        orderLines: [
          %{
            fulfillmentStatus: "partial"
          }
        ]
      }

      assert %{order_lines: [%{fulfillment_status: _}]} = NiceMaps.parse(map, keys: :snake_case)
    end

    test "convert_structs: true" do
      map = %{
        list: [
          %MyStruct{id: 1, my_key: "foo"}
        ],
        struct: %MyStruct{id: 2, my_key: "bar"}
      }

      assert %{list: [map1], struct: map2} = NiceMaps.parse(map, convert_structs: true)

      refute Map.has_key?(map1, :__struct__)
      refute Map.has_key?(map2, :__struct__)
    end
  end
end
