require 'json'

class Game
  def initialize (secret_key = -1, all_guesses = [], incorrect_guesses = [], state_array = [])
    generate_secret_word(secret_key)
    @all_guesses = all_guesses
    @incorrect_guesses = incorrect_guesses
    if state_array.length == 0
      @state_array = Array.new(@secret_word.length, false)
    else
      @state_array = state_array
    end
  end

  def menu
    if File.exists?("save.json")
      puts "Saved game available, enter 1 to play saved game, enter 2 to play new game:"
      choice = gets
      loop do
        break if choice.match(/^[12]$/)
        puts "Saved game available, enter 1 to play saved game, enter 2 to play new game:"
        choice = gets
      end
      if choice.chomp.to_i == 1
        load
      else
        play
      end
    else
      play
    end
  end

  def play
    quit = false
    while @incorrect_guesses.length < 8 && !win && !quit
      print_incorrect_guesses
      print_result
      puts "Guess a letter or enter ! to save and quit:"
      guess_char = gets.chomp.downcase
      loop do
        break if guess_char.match(/^[a-z!]$/) && !@all_guesses.any?(guess_char)
        puts "Guess a letter or enter ! to save and quit:"
        guess_char = gets.chomp.downcase
      end
      if (guess_char == "!")
        quit = true
        save
      else
        guess(guess_char)
      end
    end
    if !quit
      if win
        puts "You win!"
      else
        puts "You lose!"
      end
      puts "Secret word: #{@secret_word}"
    end
  end

  private

  def to_json
    {
      'secret_key' => @secret_key, 
      'all_guesses' => @all_guesses, 
      'incorrect_guesses' => @incorrect_guesses,
      'state_array' => @state_array
    }.to_json
  end 

  def self.from_json string
    data = JSON.load string
    self.new data['secret_key'], data['all_guesses'], data['incorrect_guesses'], data['state_array']
  end

  def save
    File.open("save.json", 'w'){|f| f.write(self.to_json)}
  end

  def load
    game = Game.from_json File.read("save.json")
    File.delete("save.json")
    game.play
  end

  def generate_secret_word(key)
    fname = "google-10000-english-no-swears.txt"
    dictionary = File.open(fname, "r").readlines.select{|word| word.chomp.length>=5 && word.chomp.length<=12}
    if key == -1
      @secret_key = rand(0..dictionary.length)
    else
      @secret_key = key
    end
    @secret_word = dictionary[@secret_key].chomp
  end

  def guess(guess_char)
    prev_state = @state_array
    @state_array = @secret_word.chars.each_with_index.map {|char, index| char == guess_char || @state_array[index]}
    if prev_state == @state_array
      @incorrect_guesses << guess_char
    end
    @all_guesses << guess_char
  end

  def print_result
    result = @secret_word.chars.each_with_index.map {|char, index| @state_array[index]? char : "_"} 
    puts result.join(" ")
  end
  
  def print_incorrect_guesses
    if @incorrect_guesses.length > 0
      puts "Incorrect guesses: #{@incorrect_guesses.join(" ")}"
      puts "Incorrect guesses left: #{8-@incorrect_guesses.length}"
    end
  end

  def win
    @state_array.all?(true)
  end

end

Game.new.menu
