# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule GGity.Examples do
  @moduledoc false

  def diamonds do
    file_name = Path.join([:code.priv_dir(:ggity), "diamonds.csv"])

    headers =
      File.stream!(file_name)
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.take(1)
      |> hd()
      |> Enum.drop(1)

    File.stream!(file_name)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn line -> Enum.drop(line, 1) end)
    |> Stream.map(fn [carat, clarity, color, cut, depth, price, table, x, y, z] ->
      [
        elem(Float.parse(carat), 0),
        clarity,
        color,
        cut,
        elem(Float.parse(depth), 0),
        elem(Float.parse(price), 0),
        elem(Float.parse(table), 0),
        elem(Float.parse(x), 0),
        elem(Float.parse(y), 0),
        elem(Float.parse(z), 0)
      ]
    end)
    |> Stream.map(fn line -> Enum.zip(headers, line) end)
    |> Enum.map(fn list -> Enum.into(list, %{}) end)
  end

  def economics do
    file_name = Path.join([:code.priv_dir(:ggity), "economics.csv"])

    headers =
      File.stream!(file_name)
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.take(1)
      |> hd()

    File.stream!(file_name)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn [date, pce, pop, psavert, unempmed, unemploy] ->
      [
        Date.from_iso8601!(date),
        elem(Float.parse(pce), 0),
        elem(Integer.parse(pop), 0),
        elem(Float.parse(psavert), 0),
        elem(Float.parse(unempmed), 0),
        elem(Integer.parse(unemploy), 0)
      ]
    end)
    |> Stream.map(fn line -> Enum.zip(headers, line) end)
    |> Enum.map(fn list -> Enum.into(list, %{}) end)
  end

  def economics_long do
    file_name = Path.join([:code.priv_dir(:ggity), "economics_long.csv"])

    ["" | headers] =
      File.stream!(file_name)
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.take(1)
      |> hd()

    File.stream!(file_name)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn [_row_num, date, variable, value, value01] ->
      [
        Date.from_iso8601!(date),
        variable,
        elem(Float.parse(value), 0),
        elem(Float.parse(value01), 0)
      ]
    end)
    |> Stream.map(fn line -> Enum.zip(headers, line) end)
    |> Enum.map(fn list -> Enum.into(list, %{}) end)
  end

  def mtcars do
    headers = [:model, :mpg, :cyl, :disp, :hp, :drat, :wt, :qsec, :vs, :am, :gear, :carb]

    data = [
      ["Mazda RX4", 21, 6, 160, 110, 3.9, 2.62, 16.46, 0, 1, 4, 4],
      ["Mazda RX4 Wag", 21, 6, 160, 110, 3.9, 2.875, 17.02, 0, 1, 4, 4],
      ["Datsun 710", 22.8, 4, 108, 93, 3.85, 2.32, 18.61, 1, 1, 4, 1],
      ["Hornet 4 Drive", 21.4, 6, 258, 110, 3.08, 3.215, 19.44, 1, 0, 3, 1],
      ["Hornet Sportabout", 18.7, 8, 360, 175, 3.15, 3.44, 17.02, 0, 0, 3, 2],
      ["Valiant", 18.1, 6, 225, 105, 2.76, 3.46, 20.22, 1, 0, 3, 1],
      ["Duster 360", 14.3, 8, 360, 245, 3.21, 3.57, 15.84, 0, 0, 3, 4],
      ["Merc 240D", 24.4, 4, 146.7, 62, 3.69, 3.19, 20, 1, 0, 4, 2],
      ["Merc 230", 22.8, 4, 140.8, 95, 3.92, 3.15, 22.9, 1, 0, 4, 2],
      ["Merc 280", 19.2, 6, 167.6, 123, 3.92, 3.44, 18.3, 1, 0, 4, 4],
      ["Merc 280C", 17.8, 6, 167.6, 123, 3.92, 3.44, 18.9, 1, 0, 4, 4],
      ["Merc 450SE", 16.4, 8, 275.8, 180, 3.07, 4.07, 17.4, 0, 0, 3, 3],
      ["Merc 450SL", 17.3, 8, 275.8, 180, 3.07, 3.73, 17.6, 0, 0, 3, 3],
      ["Merc 450SLC", 15.2, 8, 275.8, 180, 3.07, 3.78, 18, 0, 0, 3, 3],
      ["Cadillac Fleetwood", 10.4, 8, 472, 205, 2.93, 5.25, 17.98, 0, 0, 3, 4],
      ["Lincoln Continental", 10.4, 8, 460, 215, 3, 5.424, 17.82, 0, 0, 3, 4],
      ["Chrysler Imperial", 14.7, 8, 440, 230, 3.23, 5.345, 17.42, 0, 0, 3, 4],
      ["Fiat 128", 32.4, 4, 78.7, 66, 4.08, 2.2, 19.47, 1, 1, 4, 1],
      ["Honda Civic", 30.4, 4, 75.7, 52, 4.93, 1.615, 18.52, 1, 1, 4, 2],
      ["Toyota Corolla", 33.9, 4, 71.1, 65, 4.22, 1.835, 19.9, 1, 1, 4, 1],
      ["Toyota Corona", 21.5, 4, 120.1, 97, 3.7, 2.465, 20.01, 1, 0, 3, 1],
      ["Dodge Challenger", 15.5, 8, 318, 150, 2.76, 3.52, 16.87, 0, 0, 3, 2],
      ["AMC Javelin", 15.2, 8, 304, 150, 3.15, 3.435, 17.3, 0, 0, 3, 2],
      ["Camaro Z28", 13.3, 8, 350, 245, 3.73, 3.84, 15.41, 0, 0, 3, 4],
      ["Pontiac Firebird", 19.2, 8, 400, 175, 3.08, 3.845, 17.05, 0, 0, 3, 2],
      ["Fiat X1-9", 27.3, 4, 79, 66, 4.08, 1.935, 18.9, 1, 1, 4, 1],
      ["Porsche 914-2", 26, 4, 120.3, 91, 4.43, 2.14, 16.7, 0, 1, 5, 2],
      ["Lotus Europa", 30.4, 4, 95.1, 113, 3.77, 1.513, 16.9, 1, 1, 5, 2],
      ["Ford Pantera L", 15.8, 8, 351, 264, 4.22, 3.17, 14.5, 0, 1, 5, 4],
      ["Ferrari Dino", 19.7, 6, 145, 175, 3.62, 2.77, 15.5, 0, 1, 5, 6],
      ["Maserati Bora", 15, 8, 301, 335, 3.54, 3.57, 14.6, 0, 1, 5, 8],
      ["Volvo 142E", 21.4, 4, 121, 109, 4.11, 2.78, 18.6, 1, 1, 4, 2]
    ]

    Enum.map(data, fn row ->
      [headers, row]
      |> Enum.zip()
      |> Enum.into(%{})
    end)
  end

  def mpg do
    file_name = Path.join([:code.priv_dir(:ggity), "mpg.csv"])

    headers =
      file_name
      |> File.stream!()
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.take(1)
      |> hd()

    File.stream!(file_name)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn [manufacturer, model, displ, year, cyl, trans, drv, cty, hwy, fl, class] ->
      [
        manufacturer,
        model,
        elem(Float.parse(displ), 0),
        elem(Integer.parse(year), 0),
        elem(Integer.parse(cyl), 0),
        trans,
        drv,
        elem(Integer.parse(cty), 0),
        elem(Integer.parse(hwy), 0),
        fl,
        class
      ]
    end)
    |> Stream.map(fn line -> Enum.zip(headers, line) end)
    |> Enum.map(fn list -> Enum.into(list, %{}) end)
  end

  def tx_housing do
    file_name = Path.join([:code.priv_dir(:ggity), "tx_housing.csv"])

    headers =
      File.stream!(file_name)
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.take(1)
      |> hd()

    get_maybe_integer = fn value ->
      if Integer.parse(value) == :error do
        value
      else
        elem(Integer.parse(value), 0)
      end
    end

    get_maybe_float = fn value ->
      if Float.parse(value) == :error do
        value
      else
        elem(Float.parse(value), 0)
      end
    end

    File.stream!(file_name)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn [city, year, month, sales, volume, median, listings, inventory, date] ->
      [
        city,
        elem(Integer.parse(year), 0),
        elem(Integer.parse(month), 0),
        get_maybe_integer.(sales),
        get_maybe_integer.(volume),
        get_maybe_integer.(median),
        get_maybe_integer.(listings),
        get_maybe_float.(inventory),
        get_maybe_float.(date)
      ]
    end)
    |> Stream.map(fn line -> Enum.zip(headers, line) end)
    |> Enum.map(fn list -> Enum.into(list, %{}) end)
  end
end
