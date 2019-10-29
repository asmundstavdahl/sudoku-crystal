require "./sudoku"

in_file = case ARGV.size
          when 1, 2
            ARGF
          else
            STDIN
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
  include Iterator(Command)

  @queue = [] of Sudoku::Command

  def next
    maybe_queued_command = @queue.pop?

    case maybe_queued_command
    when Command
      maybe_queued_command
    when nil
      input = gets(true)

      case input
      when nil then stop
      when String
        re_fill_digit = /^(?<digit>[\d])( ([\d],[\d]))+$/
        re_save = /^s(ave)?( (?<name>[\S]+))?$/
        re_load = /^l(oad)? (?<name>[\S]+)( (?<board_nr>\d+))?$/
        case input
        when .match re_fill_digit
          parts = input.split " "
          digit = parts.shift.to_i
          xys = parts.map do |xy|
            x, y = xy.split(",").map &.to_i
            @queue.push Sudoku::Fill.new({x, y}, digit)
          end
          @queue.pop
        when .match /^[\d]$/
          Sudoku::Highlight.new(input.to_i)
        when .match re_save
          match = input.match re_save
          name = match["name"]
          Sudoku::Save.new(name)
        when .match re_load
          match = input.match re_load
          name = match["name"]

          board_nr = case match["board_nr"]
                     when nil
                       1
                     else match["board_nr"]
                     end
          Sudoku::Load.new(name, board_nr)
        else
          puts "Command not recognized: #{input}"
          Sudoku::NoOp.new
        end
      end
    end
  end
end

prompt = "[0-9]( x,y)+? >> "

puts game.render
printf prompt

# inputSource = InputSource.new
inputSource = [
  Sudoku::Fill.new({2, 1}, 2),
  # Sudoku::Save.new(".sudoku-save"),
  Sudoku::Load.new(".sudoku-save", 1),
]
inputSource.each do |command|
  printf "[0-9]( x,y)+ >> "
  game.process command
  puts game.render
  printf prompt
end
