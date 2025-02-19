defmodule NMEATest do
  use ExUnit.Case
  doctest NMEA

  alias NMEA.Sentence

  test "parse empty text fails" do
    assert NMEA.parse(nil) == {:error, :invalid}
    assert NMEA.parse("") == {:error, :invalid}
  end

  test "parse invalid checksum fails" do
    assert NMEA.parse("$GPRMC,,V,,,,,,,,,,N*52") == {:error, :checksum}
  end

  test "parse succeeds when checksum is valid" do
    assert NMEA.parse("$GPGSV,3,1,12,01,,,23,02,,,23,03,,,22,05,,,23*7C") ==
             {:ok,
              %Sentence.Unknown{
                talker: "GP",
                type: "GSV",
                records: [
                  "3",
                  "1",
                  "12",
                  "01",
                  "",
                  "",
                  "23",
                  "02",
                  "",
                  "",
                  "23",
                  "03",
                  "",
                  "",
                  "22",
                  "05",
                  "",
                  "",
                  "23"
                ]
              }}
  end

  test "with zero padded checksum" do
    assert NMEA.parse("$IIMWV,332.8,R,15.5,M,A*05") ==
             {:ok,
              %Sentence.Unknown{
                talker: "II",
                type: "MWV",
                records: ["332.8", "R", "15.5", "M", "A"]
              }}
  end

  test "with RMC" do
    assert NMEA.parse("$GPRMC,192520.000,A,4221.11453,N,07103.94548,W,0.9,338.2,140225,,,A*74") ==
             {:ok,
              %Sentence.RMC{
                talker: "GP",
                date_time: ~U[2025-02-14T19:25:20.000Z],
                valid?: true,
                latitude: 42.35190883,
                longitude: -71.065758,
                speed_knots: 0.9,
                course: 338.2,
                variation: nil,
                mode: :autonomous
              }}
  end

  test "with GGA" do
    assert NMEA.parse(
             "$GPGGA,192520.000,4221.11453,N,07103.94548,W,1,07,2.9,033.65,M,-33.7,M,,*50"
           ) ==
             {:ok,
              %Sentence.GGA{
                talker: "GP",
                utc_time: ~T[19:25:20.000],
                latitude: 42.35190883,
                longitude: -71.065758,
                gps_quality: :autonomous,
                satellite_count: 7,
                horizontal_dilution_of_precision: 2.9,
                altitude: {33.65, :meter},
                geoidal_separation: {-33.7, :meter}
              }}
  end

  test "with GNS" do
    assert NMEA.parse(
             "$GNGNS,192520.000,4221.11453,N,07103.94548,W,AANNN,07,2.9,0033.7,-33.7,,*2E"
           ) ==
             {:ok,
              %Sentence.GNS{
                talker: "GN",
                utc_time: ~T[19:25:20.000],
                latitude: 42.35190883,
                longitude: -71.065758,
                modes: [
                  gps: :autonomous,
                  glonass: :autonomous,
                  galileo: :no_fix,
                  beidou: :no_fix,
                  qzss: :no_fix
                ],
                satellite_count: 7,
                horizontal_dilution_of_precision: 2.9,
                altitude: {33.7, :meter},
                geoidal_separation: {-33.7, :meter}
              }}
  end

  test "with VTG" do
    assert NMEA.parse("$GPVTG,338.2,T,,M,0.9,N,1.6,K,A*09") ==
             {:ok,
              %Sentence.VTG{
                talker: "GP",
                course_true: 338.2,
                speed_knots: 0.9,
                speed_kph: 1.6,
                mode: :autonomous
              }}
  end

  test "with proprietary message" do
    assert NMEA.parse("$PCPTI,vehicle_id,192520,192520*58") ==
             {:ok,
              %Sentence.Proprietary{
                vendor: "CPT",
                type: "I",
                records: ["vehicle_id", "192520", "192520"]
              }}
  end
end
