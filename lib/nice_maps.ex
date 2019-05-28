defmodule NiceMaps do
  @moduledoc """
  Documentation for NiceMaps.
  """

  @doc """
  Hello world.

  ## Examples

    # Without Options:

    iex> NiceMaps.parse(%MyStruct{id: 1, my_key: "bar"})
    %{id: 1, my_key: "bar"}

    iex> NiceMaps.parse([%MyStruct{id: 1, my_key: "bar"}, %{value: "a"}])
    [%{id: 1, my_key: "bar"}, %{value: "a"}]

    iex> NiceMaps.parse([%MyStruct{id: 1, my_key: "bar"}, "String"])
    [%{id: 1, my_key: "bar"}, "String"]

    iex> NiceMaps.parse(%{0 => "0", 1 => "1"})
    %{0 => "0", 1 => "1"}

    # Keys to camelcase:

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
      :camelcase -> parse_camelcase_keys(map, opts)
      :snake_case -> parse_snake_case(map, opts)
      nil -> map
    end
  end

  defp parse_snake_case(map, opts) do
    Enum.map(map, fn
      {key, val} -> {convert_to_snake_case(key), parse(val, opts)}
    end)
    |> Enum.into(%{})
  end

  defp convert_to_snake_case(key) when is_bitstring(key), do: Macro.underscore(key)

  defp convert_to_snake_case(key) when is_atom(key),
    do: key |> to_string() |> Macro.underscore() |> String.to_atom()

  defp convert_to_snake_case(key), do: key

  defp parse_camelcase_keys(map, opts) do
    Enum.map(map, fn
      {key, val} -> {convert_to_camelcase(key), parse(val, opts)}
    end)
    |> Enum.into(%{})
  end

  defp convert_to_camelcase(key) when is_bitstring(key) do
    first_char = String.first(key)

    key
    |> Macro.camelize()
    |> String.replace_leading(String.upcase(first_char), first_char)
  end

  defp convert_to_camelcase(key) when is_atom(key),
    do: key |> to_string() |> convert_to_camelcase() |> String.to_atom()

  defp convert_to_camelcase(key), do: key
end
