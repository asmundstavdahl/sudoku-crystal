require "termbuf"

# TODO: Write documentation for `sudoku`
module Sudoku
  VERSION = "0.1.0"

  save_file = ".sudoku-save"

  alias Command = Highlight | Fill | Save | Load | NoOp

  class Game
    @grid : Array(Cell)

    @highlight_digit = 0

    def initialize(board_data)
      @grid = board_data.chars.map { |char| Cell.new(char.to_i) }

      @disp = Termbuf::Display.new(13, 13)
      draw_board @disp
    end

    def process(c : Command)
      case c
      when Fill
        at(c.x, c.y).digit = c.digit
      when Highlight
        @highlight_digit = c.digit
      when Save
        File.open(c.name, "w") do |file|
          file.puts @grid.map(&.digit).join
        end
      when Load
        File.open(c.name, "r") do |file|
          (1...c.board_nr).each do
            file.gets
          end
          board_data = file.gets(true).not_nil!
          board_data.chars.each.with_index do |c, i|
            @grid[i] = Cell.new(c.to_i)
          end
        end
      else
        puts c
      end
    end

    def render
      @grid.each.with_index do |cell, i|
        cell_x = i % 9
        cell_y = (i - cell_x) // 9
        x = cell_x + cell_x // 3
        y = cell_y + cell_y // 3
        @disp.set_char!({x + 1, y + 1}, cell.render)
        style = case cell.digit
                when 0
                  "\e[2m"
                when @highlight_digit
                  "\e[7m"
                end
        @disp.set_style!({x + 1, y + 1}, style)
      end

      @disp.render
    end

    def at(x, y)
      @grid[(x - 1) + (y - 1) * 9]
    end

    def draw_board(disp)
      (1..9).each do |i|
        x = i + (i - 1) // 3
        y = 0
        disp.set_char!({x, y}, i.to_s)
        disp.set_style!({x, y}, "\e[2m")
      end
      (1..9).each do |i|
        x = 0
        y = i + (i - 1) // 3
        disp.set_char!({x, y}, i.to_s)
        disp.set_style!({x, y}, "\e[2m")
      end
    end
  end

  class Cell
    def initialize(@digit : Int32)
    end

    getter :digit
    setter :digit

    def render
      if @digit == 0
        "·"
      else
        @digit.to_s
      end
    end
  end

  struct Highlight
    def initialize(@digit : Int32)
    end

    getter :digit
  end

  struct Fill
    def initialize(@xy : {Int32, Int32}, @digit : Int32)
    end

    getter :digit

    def x
      @xy[0]
    end

    def y
      @xy[1]
    end
  end

  struct Save
    def initialize(@name : String)
    end

    getter :name
  end

  struct Load
    def initialize(@name : String, @board_nr : Int32)
    end

    getter :name
    getter :board_nr
  end

  struct NoOp
  end
end

# re_fill_digit = /^(?<digit>[\d])( ([\d],[\d]))+$/
# case input
# when .match re_fill_digit
#   parts = input.split " "
#   digit = parts.shift.to_i
#   xys = parts.map do |xy|
#     x, y = xy.split(",").map &.to_i
#     @queue.push Sudoku::Fill.new({x, y}, digit)
#   end
#   @queue.pop
# when .match /^[\d]$/
#   Sudoku::Highlight.new(input.to_i)
# when .match re_save
#   match = input.match(re_save)
#   case match
#   when nil
#     Sudoku::NoOp.new
#   else
#     case match["name"]
#     when String
#       Sudoku::Save.new(match["name"])
#     else
#       Sudoku::Save.new(SaveFile)
#     end
#   end
# when .match re_load
#   match = input.match re_load
#   case match
#   when nil
#     Sudoku::NoOp.new
#   else
#     name = match["name"]

#     board_nr = case match["board_nr"]
#                when nil
#                  1
#                else match["board_nr"].to_i
#                end
#     Sudoku::Load.new(name, board_nr)
#   end
# else
#   puts "Command not recognized: #{input}"
#   Sudoku::NoOp.new
# end
