# NiceMaps

NiceMaps provides a single function `parse` to convert maps into the desired format.

It can build camelcase/snake_case keys, convert string keys to atom keys and vice versa,
convert structs to maps.

## `NiceMaps.parse`
The main interface - this is where the magic happens.

## Options

* `:keys` one of `:camelcase` or `:snake_case`
* `:convert_structs` one of `true` or `false`, default: `false`
* `:key_type`, one of `:string` or `:existing_atom`

## Examples

### Without Options:

    iex> NiceMaps.parse(%MyStruct{id: 1, my_key: "bar"})
    %{id: 1, my_key: "bar"}

    iex> NiceMaps.parse([%MyStruct{id: 1, my_key: "bar"}, %{value: "a"}])
    [%{id: 1, my_key: "bar"}, %{value: "a"}]

    iex> NiceMaps.parse([%MyStruct{id: 1, my_key: "bar"}, "String"])
    [%{id: 1, my_key: "bar"}, "String"]

    iex> NiceMaps.parse(%{0 => "0", 1 => "1"})
    %{0 => "0", 1 => "1"}

### Keys to camelcase:

    iex> NiceMaps.parse([%MyStruct{id: 1, my_key: "bar"}, %{value: "a"}], keys: :camelcase)
    [%{id: 1, myKey: "bar"}, %{value: "a"}]

    iex> NiceMaps.parse(%MyStruct{id: 1, my_key: "foo"}, keys: :camelcase)
    %{id: 1, myKey: "foo"}

    iex> NiceMaps.parse(%{"string" => "value", "another_string" => "value"}, keys: :camelcase)
    %{"string" => "value", "anotherString" => "value"}

    # Keys to snake case:

    iex> NiceMaps.parse(%MyCamelStruct{id: 1, myKey: "foo"}, keys: :snake_case)
    %{id: 1, my_key: "foo"}

    iex> NiceMaps.parse(%MyCamelStruct{id: 1, myKey: "foo"}, keys: :snake_case)
    %{id: 1, my_key: "foo"}

    iex> NiceMaps.parse(%{"string" => "value", "another_string" => "value"}, keys: :camelcase)
    %{"string" => "value", "anotherString" => "value"}

### Convert all structs into maps

    iex> map = %{
    ...>   list: [
    ...>     %MyStruct{id: 1, my_key: "foo"}
    ...>   ],
    ...>   struct: %MyStruct{id: 2, my_key: "bar"}
    ...> }
    ...> NiceMaps.parse(map, convert_structs: true)
    %{
      list: [
        %{id: 1, my_key: "foo"}
      ],
      struct: %{id: 2, my_key: "bar"}
    }

### Convert string keys to existing atom

    iex> map = %{
    ...>   "key1" => "value 1",
    ...>   "nested" => %{"key2" => "value 2"},
    ...>   "list" => [%{"key3" => "value 3", "key4" => "value 4"}]
    ...> }
    iex> NiceMaps.parse(map, key_type: :existing_atom)
    %{
      key1: "value 1",
      nested: %{key2: "value 2"},
      list: [%{key3: "value 3", key4: "value 4"}]
    }

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nice_maps` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nice_maps, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nice_maps](https://hexdocs.pm/nice_maps).
