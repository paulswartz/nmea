defmodule NMEA.SentenceHelpers do
  @moduledoc false

  @doc """
  iex> utc_time("192520.123")
  ~T[19:25:20.123]
  """
  def utc_time(<<hour::binary-2, minute::binary-2, second::binary-2, ".", microsecond::binary>>) do
    Time.new!(
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second),
      string_to_microsecond(microsecond)
    )
  end

  @doc """
  iex> date_time("140225", "192520.123")
  ~U[2025-02-14T19:25:20.123Z]

  """
  def date_time(
        <<day::binary-2, month::binary-2, year::binary-2>>,
        time
      ) do
    DateTime.new!(
      Date.new!(
        2000 + String.to_integer(year),
        String.to_integer(month),
        String.to_integer(day)
      ),
      utc_time(time),
      "Etc/UTC"
    )
  end

  def latitude(<<degrees::binary-2, minutes::binary>>, north_south) do
    decimal =
      Float.round(
        String.to_integer(degrees) + String.to_float(minutes) / 60,
        8
      )

    if north_south == "N" do
      decimal
    else
      -decimal
    end
  end

  def longitude(<<degrees::binary-3, minutes::binary>>, east_west) do
    decimal =
      Float.round(
        String.to_integer(degrees) + String.to_float(minutes) / 60,
        8
      )

    if east_west == "E" do
      decimal
    else
      -decimal
    end
  end

  def variation("", "") do
    nil
  end

  def mode(mode) do
    case mode do
      "A" -> :autonomous
      "D" -> :differential
      "E" -> :dead_reckoning
      "F" -> :rtk_float
      "M" -> :manual
      "N" -> :no_fix
      "P" -> :precise
      "R" -> :rtk_fixed
      "S" -> :simulator
      _ -> {:unknown, mode}
    end
  end

  def unit("M"), do: :meter

  def to_float(""), do: nil
  defdelegate to_float(string), to: String

  def non_empty_string(""), do: nil
  def non_empty_string(binary) when is_binary(binary), do: binary

  defp string_to_microsecond(binary) do
    number = String.to_integer(binary)
    size = byte_size(binary)
    scale = 10 ** (6 - size)
    {number * scale, size}
  end
end
