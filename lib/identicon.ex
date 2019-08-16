defmodule Identicon do
  @moduledoc """
  Documentation for Identicon.
  """

  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  def pick_color(image) do
    # Pattern match, put hex list in image in hex_list
    %Identicon.Image{hex: hex_list} = image
    # Get the first 3 items from the list,
    # tell pattern match we acknowledge the tail exists but we don't care about it
    [r, g, b | _tail] = hex_list

    # Create a new struct using the data that was in the previous struct,
    # and then update the color field to a tuple (since order of the vars matter)
    %Identicon.Image{image | color: {r, g, b}}
  end

  def build_grid(image) do
    %Identicon.Image{hex: hex} = image

    grid =
        hex
          |> Enum.chunk(3)
          |> Enum.map(&mirror_row/1)
          |> List.flatten
          |> Enum.with_index
    #|> Enum.map(&mirror_row/1) -> & passes a reference to a function,
    # and /1 passes the arity to figure out which reference if there are several

    # Return a new struct with grid on it
    %Identicon.Image{image | grid: grid}
  end

  def mirror_row(row) do
    # Pattern match, take first 2, ignore rest
    [first, second | _tail] = row
    # Append a new list to row
    row ++ [ second, first]
  end

  def filter_odd_squares(image) do
    # Pattern match, assign the grid val of the image struct to a variable named grid
    %Identicon.Image{grid: grid} = image

    even_squares_only = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{ image | grid: even_squares_only}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do

    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = { horizontal + 50, vertical + 50 }

      { top_left, bottom_right }
    end

    %Identicon.Image{ image | pixel_map: pixel_map}
  end

  # Only use = image in the signature if you want to retain a reference to the passed in param
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def save_image(image, filename) do
    File.write("images/#{filename}.png", image)
  end
end
