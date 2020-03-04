# NiceMaps

NiceMaps provides a single function `parse` to convert maps into the desired format.

It can build camelcase/snake_case keys, convert string keys to atom keys and vice versa,
or convert structs to maps.

## :fire: Danger Zone :fire:

`NiceMaps` uses [`String.to_existing_atom/1`](https://hexdocs.pm/elixir/String.html#to_existing_atom/1) for conversions from string keys and camelcase-snake_case, so please make sure your atoms exists before attempting something like

```elixir
%{this_does_not_exist_as_camelcase: "abc"} |> NiceMaps.parse(keys: :camelcase)
# ** (ArgumentError) argument error
#     :erlang.binary_to_existing_atom("thisDoesNotExistAsCamelcase", :utf8)
```

If you need to convert a map with unknown atoms, please use string keys instead:

```elixir
%{this_does_not_exist_as_camelcase: "abc"} |> NiceMaps.parse(keys: :camelcase, key_type: :string)
# %{"thisDoesNotExistAsCamelcase" => "abc"}
```

`NiceMaps` does not provide a `key_type: :atom` option for the same reason explained later, but you can convert keys to existing atoms using `key_type: :existing_atom`. If you absolutely insist on creating unknown atoms, there is a way to do it, but I will leave it to you to figure it out from the code (because I think it is a bad idea, and you should really know what you are doing before using it.)

## How to use it, and what for

Many people prefer working with atom keys over string keys, because you get some nice syntactic sugar like `map.key` and the JSON like notation `%{key: "value"}`, but because atoms are not garbage collected, web frameworks provide parameters as string key maps (otherwise an attacker could flood your memory with atoms until your server crashes.)

So, lets say you have parameters in a Phoenix controller and you want to convert the keys into atoms:

```elixir
# We only allow these keys, you could call it the "strong parameters approach"
@allowed_keys ["a", "b", "c"]

def my_controller(conn, params) do
  params
  |> Map.take(@allowed_keys)
  |> NiceMaps.parse(key_type: :existing_atom)
  |> MyContext.create_a_thing()
end
```

Another possible use case is JSON parsing. If you have a map that could or could not have struct values, libraries like [Jason](https://hex.pm/packages/jason) will explode on you, and you have to implement the `Jason.Encoder` protocol for your struct - which is not possible if you do not have control over the structs.
`NiceMaps` to the rescue:

```elixir
converted = %MyStruct{a: "a", b: "b", a_struct: %MyOtherStruct{c: "c"}} |> NiceMaps.parse(convert_structs: true)
# {a: "a", b: "b", a_struct: %{c: "c"}}

Jason.encode!(converted)
```

Last but not least, converting keys from snake case (`with_underscore`) to camelcase (`likeThis`) and vice versa. Different protocols/frameworks/programing languages use different conventions, snake case vs camelcase is one of those where there is no right or wrong, but you might want to convert - for example - a graphql response to a more "elixiry" map (using [Neuron](https://github.com/uesteibar/neuron) for this example):

```elixir
{:ok, %{body: response}} = Neuron.query("""
{
  aThing {
    aField
  }
}
""")
NiceMaps.parse(response, keys: :snake_case)
# %{a_thing: %{a_field: "whatever"}}
```

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
    ...>   struct: %MyStruct{id: 2, my_key: "bar"},
    ...>   other_struct: %MyStruct{id: 3, my_key: %MyStruct{id: 4, my_key: nil}}
    ...> }
    ...> NiceMaps.parse(map, convert_structs: true)
    %{
      list: [
        %{id: 1, my_key: "foo"}
      ],
      struct: %{id: 2, my_key: "bar"},
      other_struct: %{id: 3, my_key: %{id: 4, my_key: nil}}
    }

### Convert string keys to existing atom

    iex> map = %{
    ...>   "key1" => "value 1",
    ...>   "nested" => %{"key2" => "value 2"},
    ...>   "list" => [%{"key3" => "value 3", "key4" => "value 4"}],
    ...>    1 => "an integer key",
    ...>    %MyStruct{} => "a struct key"
    ...> }
    iex> [:key1, :key2, :key3, :key4, :nested, :list] # Make sure atoms exist
    iex> NiceMaps.parse(map, key_type: :existing_atom)
    %{
      :key1 => "value 1",
      :nested => %{key2: "value 2"},
      :list => [%{key3: "value 3", key4: "value 4"}],
      1 => "an integer key",
      %MyStruct{} => "a struct key"
    }

### Mix it all together

    iex> map = %{
    ...>   "hello_there" => [%{"aA" => "asdf"}, %{"a_a" => "bhjk"}, "a string", 1],
    ...>   thingA: "thing A",
    ...>   thing_b: "thing B"
    ...> }
    iex> NiceMaps.parse(map, keys: :camelcase, key_type: :string)
    %{"helloThere" => [%{"aA" => "asdf"}, %{"aA" => "bhjk"}, "a string", 1], "thingA" => "thing A", "thingB" => "thing B"}

    iex> map = %{
    ...>   "helloThere" => [%{"aA" => "asdf"}, %{"a_a" => "bhjk"}, "a string", 1],
    ...>   thingA: "thing A",
    ...>   thing_b: "thing B"
    ...> }
    iex> [:hello_there, :thing_a, :thing_b] # make sure atoms exist
    iex> NiceMaps.parse(map, keys: :snake_case, key_type: :existing_atom)
    %{:hello_there => [%{:a_a => "asdf"}, %{:a_a => "bhjk"}, "a string", 1], :thing_a => "thing A", :thing_b => "thing B"}

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
