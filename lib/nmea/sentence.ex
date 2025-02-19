defmodule NMEA.Sentence do
  @moduledoc """
  Parent module for individual NMEA sentence types.
  """
  alias NMEA.SentenceHelpers

  defmodule RMC do
    defstruct [
      :talker,
      :date_time,
      :valid?,
      :latitude,
      :longitude,
      :speed_knots,
      :course,
      :variation,
      :mode
    ]

    def parse(talker, [
          utc_time,
          status,
          latitude,
          north_south,
          longitude,
          east_west,
          speed_knots,
          course,
          date,
          variation,
          variation_east_west,
          mode
        ]) do
      %__MODULE__{
        talker: talker,
        date_time: SentenceHelpers.date_time(date, utc_time),
        valid?: status == "A",
        latitude: SentenceHelpers.latitude(latitude, north_south),
        longitude: SentenceHelpers.longitude(longitude, east_west),
        speed_knots: String.to_float(speed_knots),
        course: String.to_float(course),
        variation: SentenceHelpers.variation(variation, variation_east_west),
        mode: SentenceHelpers.mode(mode)
      }
    end
  end

  defmodule GGA do
    defstruct [
      :talker,
      :utc_time,
      :latitude,
      :longitude,
      :gps_quality,
      :satellite_count,
      :horizontal_dilution_of_precision,
      :altitude,
      :geoidal_separation,
      :dgps_age,
      :reference_station_id
    ]

    def parse(talker, [
          utc_time,
          latitude,
          north_south,
          longitude,
          east_west,
          gps_quality,
          satellite_count,
          horizontal_dilution_of_precision,
          altitude,
          altitude_unit,
          geoidal_separation,
          geoidal_unit,
          dgps_age,
          reference_station_id
        ]) do
      %__MODULE__{
        talker: talker,
        utc_time: SentenceHelpers.utc_time(utc_time),
        latitude: SentenceHelpers.latitude(latitude, north_south),
        longitude: SentenceHelpers.longitude(longitude, east_west),
        gps_quality:
          case gps_quality do
            "0" -> :no_fix
            "1" -> :autonomous
            "2" -> :differential
            "3" -> :not_applicable
            "4" -> :rtk_fixed
            "5" -> :rtk_float
            "6" -> :dead_reckoning
          end,
        satellite_count: String.to_integer(satellite_count),
        horizontal_dilution_of_precision: String.to_float(horizontal_dilution_of_precision),
        altitude: {String.to_float(altitude), SentenceHelpers.unit(altitude_unit)},
        geoidal_separation:
          {String.to_float(geoidal_separation), SentenceHelpers.unit(geoidal_unit)},
        dgps_age: SentenceHelpers.to_float(dgps_age),
        reference_station_id: SentenceHelpers.non_empty_string(reference_station_id)
      }
    end
  end

  defmodule GNS do
    defstruct [
      :talker,
      :utc_time,
      :latitude,
      :longitude,
      :modes,
      :satellite_count,
      :horizontal_dilution_of_precision,
      :altitude,
      :geoidal_separation,
      :dgps_age,
      :reference_station_id
    ]

    def parse(talker, [
          utc_time,
          latitude,
          north_south,
          longitude,
          east_west,
          modes,
          satellite_count,
          horizontal_dilution_of_precision,
          altitude,
          geoidal_separation,
          dgps_age,
          reference_station_id
        ]) do
      modes =
        ~w(gps glonass galileo beidou qzss)a
        |> Enum.zip(String.split(modes, "", trim: true))
        |> Enum.map(fn {constellation, mode} -> {constellation, SentenceHelpers.mode(mode)} end)

      %__MODULE__{
        talker: talker,
        utc_time: SentenceHelpers.utc_time(utc_time),
        latitude: SentenceHelpers.latitude(latitude, north_south),
        longitude: SentenceHelpers.longitude(longitude, east_west),
        modes: modes,
        satellite_count: String.to_integer(satellite_count),
        horizontal_dilution_of_precision: String.to_float(horizontal_dilution_of_precision),
        altitude: {String.to_float(altitude), :meter},
        geoidal_separation: {String.to_float(geoidal_separation), :meter},
        dgps_age: SentenceHelpers.to_float(dgps_age),
        reference_station_id: SentenceHelpers.non_empty_string(reference_station_id)
      }
    end
  end

  defmodule VTG do
    defstruct [:talker, :course_true, :course_magnetic, :speed_knots, :speed_kph, :mode]

    def parse(talker, [
          course_true,
          "T",
          course_magnetic,
          "M",
          speed_knots,
          "N",
          speed_kph,
          "K",
          mode
        ]) do
      %__MODULE__{
        talker: talker,
        course_true: String.to_float(course_true),
        course_magnetic: SentenceHelpers.to_float(course_magnetic),
        speed_knots: String.to_float(speed_knots),
        speed_kph: String.to_float(speed_kph),
        mode: SentenceHelpers.mode(mode)
      }
    end
  end

  defmodule Unknown do
    defstruct [:talker, :type, :records]
  end

  defmodule Proprietary do
    defstruct [:vendor, :type, :records]
  end
end
