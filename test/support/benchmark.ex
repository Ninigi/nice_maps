defmodule Mix.Tasks.Benchmark do
  use Mix.Task

  defmodule MyStruct do
    defstruct [:id, :my_key, :myCamelKey]
  end

  def run(_) do
    Benchee.run(
      %{
        "NiceMaps" => fn input -> NiceMaps.parse(input) end,
        "NiceMaps to camelcase" => fn input -> NiceMaps.parse(input, keys: :camelcase) end,
        "NiceMaps to snake case" => fn input -> NiceMaps.parse(input, keys: :snake_case) end
      },
      time: 10,
      memory_time: 2,
      inputs: %{
        "Struct" => %MyStruct{id: 1, my_key: "bar", myCamelKey: "foo"},
        "List" => [%MyStruct{id: 1, my_key: "bar", myCamelKey: "foo"}, "String"],
        "Big map string keys" =>
          Enum.to_list(1..1_000_000) |> Enum.map(fn num -> "#{num}_key" end),
        "Big map atom keys" => Enum.to_list(1..1_000_000) |> Enum.map(fn num -> :"#{num}_key" end)
      }
    )
  end
end
