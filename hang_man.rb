
#module for all text content
module Display
  def display_word_length 
    "The word for you to guess has been chosen and it has #{@solved_letters.length} letters\n"
  end

  def display_instructions 
    <<~HEREDOC
    This Hang Man game will be played on the command line and a random word with 5-12 characters from a txt file will be generated for you to guess

    You have 10 turns to guess the word and each turn, you will be guessing by typing in a letter. To win you must find all the letters in the word

    If the letter is in the word then it will let you know by filling in the letter to the blank.

    HEREDOC
  end

  def display_turn_prompt
    <<~HEREDOC
      It is currently Turn #{@turn}, Try to guess one letter in the secret word.
      You can also type 'save' or 'exit' to leave the game.
    HEREDOC
  end

  def display_user_choice
    <<~HEREDOC
    Time to play! Would you like to:

    1) Play a new game
    2) Load a saved game

    Enter 1 or 2
    HEREDOC
  end

  def display_reprompt_user_choice
    "Invalid input, Please enter 1 or 2"
  end 
end


class Game
  include Display
  def initialize
    @turn = 1
    @unsolved_letters = []
    @solved_letters = []
    game_start
  end

  def create_blank_letters
    @word.each_char { @solved_letters << '_'}
    puts display_word_length
    puts @solved_letters.join(' ')
  end
  #Method to start the game, if 1 is entered , new game, if 2 is entered, load a saved game
  def game_start
    puts display_instructions
    puts display_user_choice
    user_choice = gets.chomp
    until user_choice == '1' || user_choice == '2'
      puts display_reprompt_user_choice
      user_choice = gets.chomp
    end
    new_game if user_choice == '1'
    load_saved_game if user_choice == '2'
  end

  def new_game
    @word = random_word
    create_blank_letters
    puts display_turn_prompt
  end

  def load_saved_game
  end

  def random_word 
    word_list = File.readlines('available_words.txt')
    word_list.each do |word|
      word.strip!
    end
    word_list.select { |word| word.length.between?(5, 12) }.sample
  end
end


Game.new()