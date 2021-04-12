defmodule NiceMaps do
  @moduledoc """
  NiceMaps provides a single function `parse` to convert maps into the desired format.

  It can build camelcase/snake_case keys, convert string keys to atom keys and vice versa,
  or convert structs to maps
  """

  @doc """
  The main interface - this is where the magic happens.

  ## Options

  * `:keys` one of `:camelcase` or `:snake_case`
  * `:convert_structs` one of `true` or `false`, default: `false`
  * `:key_type`, one of `:string`, `:existing_atom`, or `:unsave_atom` (please use `:existing_atom` whenever possible)

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
  """
  def parse(map_or_struct, opts \\ [])

  def parse(map_or_struct, opts) when is_list(map_or_struct), do: parse_list(map_or_struct, opts)

  def parse(%{__struct__: _} = struct, opts),
    do: struct |> Map.from_struct() |> parse_keys(opts)

  def parse(map_or_struct, opts) when is_map(map_or_struct), do: parse_keys(map_or_struct, opts)

  def parse(obj, _opts), do: obj

  @doc false
  def parse_list(list, opts, result \\ [])
  def parse_list([], _opts, result), do: Enum.reverse(result)

  def parse_list([obj | rest], opts, result),
    do: parse_list(rest, opts, [parse(obj, opts) | result])

  @doc false
  def parse_keys(map, opts) do
    case Keyword.get(opts, :keys) do
      :camelcase ->
        parse_camelcase_keys(map, opts)

      :snake_case ->
        parse_snake_case(map, opts)

      nil ->
        key_type = Keyword.get(opts, :key_type)
        convert_structs = Keyword.get(opts, :convert_structs)

        if key_type || convert_structs do
          for {key, val} <- map, do: {parse_key_type(key, key_type), parse(val, opts)}, into: %{}
        else
          map
        end
    end
  end

  defp parse_key_type(key, :existing_atom) when is_atom(key), do: key

  defp parse_key_type(key, :existing_atom) when is_bitstring(key),
    do: String.to_existing_atom(key)

  defp parse_key_type(key, :unsave_atom) when is_atom(key), do: key

  defp parse_key_type(key, :unsave_atom) when is_bitstring(key),
    do: String.to_atom(key)

  defp parse_key_type(key, :string) when is_bitstring(key), do: key

  defp parse_key_type(key, :string), do: to_string(key)

  defp parse_key_type(key, _), do: key

  defp parse_snake_case(map, opts) do
    Enum.map(map, fn
      {key, val} -> {convert_to_snake_case(key, opts), parse(val, opts)}
    end)
    |> Enum.into(%{})
  end

  defp convert_to_snake_case(key, opts) when is_bitstring(key) do
    key_type = Keyword.get(opts, :key_type, :string)
    key |> Macro.underscore() |> parse_key_type(key_type)
  end

  defp convert_to_snake_case(key, opts) when is_atom(key) do
    key_type = Keyword.get(opts, :key_type)
    new_key = key |> to_string() |> Macro.underscore()

    if key_type do
      parse_key_type(new_key, key_type)
    else
      String.to_existing_atom(new_key)
    end
  end

  defp convert_to_snake_case(key, opts) do
    key_type = Keyword.get(opts, :key_type)
    key |> parse_key_type(key_type)
  end

  defp parse_camelcase_keys(map, opts) do
    Enum.map(map, fn
      {key, val} -> {convert_to_camelcase(key, opts), parse(val, opts)}
    end)
    |> Enum.into(%{})
  end

  defp convert_to_camelcase(key, opts) when is_bitstring(key) do
    first_char = String.first(key)
    key_type = Keyword.get(opts, :key_type, :string)

    key
    |> Macro.camelize()
    |> String.replace_prefix(String.upcase(first_char), first_char)
    |> parse_key_type(key_type)
  end

  defp convert_to_camelcase(key, opts) when is_atom(key) do
    key_type = Keyword.get(opts, :key_type)
    new_key = key |> to_string() |> convert_to_camelcase(opts)

    if key_type do
      parse_key_type(new_key, key_type)
    else
      String.to_existing_atom(new_key)
    end
  end

  defp convert_to_camelcase(key, opts) do
    key_type = Keyword.get(opts, :key_type)
    parse_key_type(key, key_type)
  end

  @doc """
  Merges the values of two given maps.

  ## Options

    - `:keys` (optional) only merge the given keys
    - `:fun`  (optional) merge handler annonymous function that accepts two arguments

  ## Examples

      iex> acc_requests = %{success: ["200", "200", "201"], failed: []}
      iex> new_requests = %{success: ["200", "200"], failed: ["404"]}
      iex> NiceMaps.merge_values(acc_requests, new_requests)
      %{success: ["200", "200", "201", "200", "200"], failed: ["404"]}

      iex> acc_requests = %{success: ["200", "200", "201"], failed: []}
      iex> new_requests = %{success: ["200", "200"], failed: ["404"]}
      iex> NiceMaps.merge_values(acc_requests, new_requests, keys: [:success])
      %{success: ["200", "200", "201", "200", "200"]}

      iex> joiner_fn = fn v1, v2 -> (v1 ++ v2) |> Enum.join(",") end
      iex> acc_requests = %{success: ["200", "200", "201"], failed: []}
      iex> new_requests = %{success: ["200", "200"], failed: ["404"]}
      iex> NiceMaps.merge_values(acc_requests, new_requests, fun: joiner_fn)
      %{success: "200,200,201,200,200", failed: "404"}

      iex> acc_requests = %{success: ["200", "200", "201"], failed: ["404"]}
      iex> new_requests = %{success: ["200", "200"], failed: ["404"]}
      iex> NiceMaps.merge_values(acc_requests, new_requests,
      ...>  keys: [
      ...>    :success,
      ...>    failed: fn v1, v2 -> (v1 ++ v2) |> Enum.join(",") end
      ...>  ]
      ...> )
      %{success: ["200", "200", "201", "200", "200"], failed: "404,404" }

  """
  @spec merge_values(map(), map(), keyword()) :: map()
  def merge_values(%{} = map1, %{} = map2, opts \\ []) do
    keys = Keyword.get(opts, :keys, Map.keys(map1))

    Enum.reduce(keys, %{}, fn
      {key, fun}, acc when is_function(fun) ->
        Map.put_new(acc, key, fun.(map1[key], map2[key]))

      key, acc when is_atom(key) ->
        try do
          Map.put_new(acc, key, apply_merge_fun(map1[key], map2[key], opts))
        rescue
          # we catch the base error to provide more information afterwards
          _ in NiceMaps.Errors.MergeError ->
            raise(NiceMaps.Errors.MergeError, %{key: key, values: {map1[key], map2[key]}})

          e ->
            e
        end
    end)
  end

  defp apply_merge_fun(val1, val2, opts) do
    if fun = Keyword.get(opts, :fun) do
      fun.(val1, val2)
    else
      apply_merge_fun(val1, val2)
    end
  end

  defp apply_merge_fun(val1, val2) when is_list(val1) and is_list(val2),
    do: val1 ++ val2

  defp apply_merge_fun(val1, val2) when is_list(val1) and is_nil(val2),
    do: val1

  defp apply_merge_fun(val1, val2) when is_nil(val1) and is_list(val2),
    do: val2

  defp apply_merge_fun(val1, val2) when is_map(val1) and is_map(val2),
    do: Map.merge(val1, val2)

  defp apply_merge_fun(val1, val2) when is_map(val1) and is_nil(val2),
    do: val1

  defp apply_merge_fun(val1, val2) when is_nil(val1) and is_map(val2),
    do: val2

  defp apply_merge_fun(val1, val2) when is_bitstring(val1) and is_bitstring(val2),
    do: val1 <> val2

  defp apply_merge_fun(val1, val2) when is_bitstring(val1) and is_nil(val2),
    do: val1

  defp apply_merge_fun(val1, val2) when is_nil(val1) and is_bitstring(val2),
    do: val2

  defp apply_merge_fun(_val1, _val2),
    do: raise(NiceMaps.Errors.MergeError)
end
