defmodule NMEA do
  @moduledoc """
  Parser for NMEA 0183 Version 2.3.
  NMEA 0183 is a combined electrical and data specification for communication between marine electronics such as echo sounder, sonars, anemometer, gyrocompass, autopilot, GPS receivers and many other types of instruments
  More information on [Wikipedia](https://en.wikipedia.org/wiki/NMEA_0183)
  """

  import Bitwise, only: [bxor: 2]

  @doc """
  Parse a datagram.

  ## Examples

      iex> NMEA.parse("$GPRMC,092751.000,A,5321.6802,N,00630.3371,W,0.06,31.66,280511,,,A*45")
      {:ok, %NMEA.Sentence.RMC{
        talker: "GP",
        valid?: true,
        date_time: ~U[2011-05-28T09:27:51.000Z],
        latitude: 53.36133667,
        longitude: -6.50561833,
        speed_knots: 0.06,
        course: 31.66,
        mode: :autonomous}}
  """
  def parse(<<"$P", vendor::binary-size(3), type::binary-size(1), rest::binary>>) do
    [data, checksum] = String.split(rest, "*")

    if valid?("P" <> vendor <> type <> data, checksum) do
      [_ | values] = String.split(data, ",")

      {:ok,
       %NMEA.Sentence.Proprietary{
         vendor: vendor,
         type: type,
         records: values
       }}
    else
      {:error, :checksum}
    end
  end

  def parse("$" <> <<talker::binary-size(2)>> <> <<type::binary-size(3)>> <> rest) do
    [data, checksum] = String.split(rest, "*")
    [_ | values] = String.split(data, ",")
    module = Module.concat(NMEA.Sentence, type)
    _ = Code.ensure_loaded(module)

    cond do
      not valid?(talker <> type <> data, checksum) ->
        {:error, :checksum}

      not function_exported?(module, :parse, 2) ->
        {:ok,
         %NMEA.Sentence.Unknown{
           talker: talker,
           type: type,
           records: values
         }}

      true ->
        {:ok, module.parse(talker, values)}
    end
  end

  def parse(_), do: {:error, :invalid}

  defp valid?(text, checksum) do
    expected =
      text
      |> String.to_charlist()
      |> Enum.reduce(0, &bxor/2)

    expected == String.to_integer(checksum, 16)
  end
end
