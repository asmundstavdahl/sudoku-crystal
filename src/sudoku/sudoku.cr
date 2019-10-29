require "termbuf"

# TODO: Write documentation for `sudoku`
module Sudoku
  VERSION = "0.1.0"

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
