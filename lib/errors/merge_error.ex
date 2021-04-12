defmodule NiceMaps.Errors.MergeError do
  defexception [:message]

  @impl true
  def exception(%{key: key, values: {value1, value2}}) do
    msg = """
    Can't merge given values for key `#{inspect(key)}`, values:
    #{inspect(value1)},
    #{inspect(value2)}
    """

    %__MODULE__{message: msg}
  end

  def exception(_) do
    %__MODULE__{message: "Can't merge given values because of incompatible types."}
  end
end
