require "./sudoku"

SaveFile = ".sudoku-save"

in_file = case ARGV.size
          when 1, 2
            if ARGV[0] == "-"
              STDIN
            else
              ARGF
            end
          else
            File.open(SaveFile)
          end

board_nr = case ARGV.size
           when 2
             ARGV[1].to_i
           else
             1
           end

puts "Enter board data ((\d{9}){9})"
printf ">> "
(1...board_nr).each do
  in_file.gets
end
board_data = in_file.gets(true).not_nil! # "200040005506100000001002080000001200000000063304000050030007840002604000000090002"
puts "OK"

game = Sudoku::Game.new(board_data)

alias Command = String

class InputSource
  include Iterator(Sudoku::Command)

  @queue = [] of Sudoku::Command

  def initialize(@in_file : IO)
  end

  def next : Sudoku::Command | Iterator::Stop
    if @queue.size >= 1
      @queue.pop
    else
      input = @in_file.gets(true)

      case input
      when String
        parts = input.split " "
        if parts.first?
          first = parts.shift.not_nil!
          case
          when first == "save"
            case parts.size
            when 0 then @queue.push Sudoku::Save.new SaveFile
            else        @queue.push Sudoku::Save.new parts[0]
            end
          when first == "load"
            case parts.size
            when 0 then @queue.push Sudoku::Load.new SaveFile, 1
            when 1 then @queue.push Sudoku::Load.new parts[0], 1
            else        @queue.push Sudoku::Load.new parts[0], parts[1].to_i
            end
          when first =~ /^\d$/
            digit = first.to_i
            case parts.size
            when 0
              @queue.push Sudoku::Highlight.new(digit)
            else
              parts.each do |part|
                x, y = part.split(",").map &.to_i
                @queue.push Sudoku::Fill.new({x, y}, digit)
              end
            end
          else
            puts "Command not recognized: #{input}"
            @queue.push Sudoku::NoOp.new
          end
        end
        @queue.pop.not_nil!
      else stop
      end
    end
  end
end

prompt = "[0-9]( x,y)+? >> "

puts game.render
printf prompt

inputSource = InputSource.new STDIN
# inputSource = [
#  Sudoku::Fill.new({2, 1}, 2),
#  # Sudoku::Save.new(".sudoku-save"),
#  Sudoku::Load.new(".sudoku-save", 1),
# ]
inputSource.each do |command|
  game.process command
  puts game.render
  printf prompt
end
