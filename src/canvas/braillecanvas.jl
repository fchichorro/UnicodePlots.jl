# braille dots composing ⣿
const BRAILLE_SIGNS = UInt32.([
    '⠁' '⠈'
    '⠂' '⠐'
    '⠄' '⠠'
    '⡀' '⢀'
])

"""
The type of canvas with the highest resolution for Unicode-based plotting.
It uses the Unicode characters for the Braille symbols to represent individual pixel.
This effectively turns every character into 8 pixels that can individually be manipulated using binary operations.
"""
struct BrailleCanvas{YS<:Function,XS<:Function} <: Canvas
    grid::Transpose{UInt32,Matrix{UInt32}}
    colors::Transpose{ColorType,Matrix{ColorType}}
    blend::Bool
    visible::Bool
    pixel_height::Int
    pixel_width::Int
    origin_y::Float64
    origin_x::Float64
    height::Float64
    width::Float64
    yscale::YS
    xscale::XS
end

@inline blank(c::BrailleCanvas) = Char(BLANK_BRAILLE)

@inline y_pixel_per_char(::Type{<:BrailleCanvas}) = 4
@inline x_pixel_per_char(::Type{<:BrailleCanvas}) = 2

function BrailleCanvas(
    char_height::Int,
    char_width::Int;
    blend::Bool = true,
    visible::Bool = true,
    origin_y::Number = 0.0,
    origin_x::Number = 0.0,
    height::Number = 1.0,
    width::Number = 1.0,
    yscale::Function = identity,
    xscale::Function = identity,
)
    width > 0 || throw(ArgumentError("`width` has to be positive"))
    height > 0 || throw(ArgumentError("`height` has to be positive"))
    char_height  = max(char_height, 2)
    char_width   = max(char_width, 5)
    pixel_height = char_height * y_pixel_per_char(BrailleCanvas)
    pixel_width  = char_width * x_pixel_per_char(BrailleCanvas)
    grid         = transpose(fill(grid_type(BrailleCanvas)(BLANK_BRAILLE), char_width, char_height))
    colors       = transpose(fill(INVALID_COLOR, char_width, char_height))
    BrailleCanvas(
        grid,
        colors,
        blend,
        visible,
        pixel_height,
        pixel_width,
        float(origin_y),
        float(origin_x),
        float(height),
        float(width),
        yscale,
        xscale,
    )
end

function pixel!(c::BrailleCanvas, pixel_x::Int, pixel_y::Int, color::UserColorType)
    valid_x_pixel(c, pixel_x) || return c
    valid_y_pixel(c, pixel_y) || return c
    char_x, char_y, char_x_off, char_y_off = pixel_to_char_point_off(c, pixel_x, pixel_y)
    if checkbounds(Bool, c.grid, char_y, char_x)
        if BLANK_BRAILLE ≤ (val = c.grid[char_y, char_x]) ≤ FULL_BRAILLE
            c.grid[char_y, char_x] = val | BRAILLE_SIGNS[char_y_off, char_x_off]
        end
        set_color!(c.colors, char_x, char_y, ansi_color(color), c.blend)
    end
    c
end

function print_row(io::IO, _, print_color, c::BrailleCanvas, row::Int)
    0 < row ≤ nrows(c) || throw(ArgumentError("Argument row out of bounds: $row"))
    for col in 1:ncols(c)
        print_color(io, c.colors[row, col], Char(c.grid[row, col]))
    end
    nothing
end
