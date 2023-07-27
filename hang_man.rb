#In the future, allow user to guess the word by typing in full words instead of letters one by one
#can check word to see if it matches the guessed word, if it does , user wins.
#saved game is deleted right after loading it , might want to change in the future
require 'yaml'
module Database

  #serialization 
  def save_game
    name = save_name
    Dir.mkdir('output') unless Dir.exist?('output')
    @filename = "output/#{name}_game.yaml"
    File.open(@filename, 'w') do |file|
      file.write to_yaml
    end
    puts "Saving game to #{@filename}"
  end

  def to_yaml
    YAML.dump(
      :word => @word,
      :unsolved_letters => @unsolved_letters,
      :turn => @turn,
      :solved_letters => @solved_letters,
    )
  end

  def save_name
    puts "Enter a name for you to save your game"
    name = gets.chomp
    return name
  end

  def show_file_list
    file_list.each_with_index do |file, index|
      puts "#{index + 1}) #{file}"
    end
  end

  def file_list
    files = []
    Dir.entries('output').each do |file|
      files << file if file.include?('game')
    end
    files
  end
  def load_selected_file(file_number)
    file = YAML.load(File.read("output/#{(file_list[file_number - 1])}"))
    @word = file[:word]
    @unsolved_letters = file[:unsolved_letters]
    @turn = file[:turn]
    @solved_letters = file[:solved_letters]
  end

  def load_saved_game
    if file_list.empty?
      puts "You have no saved games yet"
      exit
    end
    show_file_list
    puts "Please select which game you want to load"
    begin 
      selected_file = Integer(gets.chomp)
    rescue
      puts "Please enter a number"
      retry
    end
    if selected_file.between?(1, file_list.length)
      load_selected_file(selected_file)
    else
      puts "That file does not exist"
      exit
    end
    File.delete("output/#{(file_list[selected_file - 1])}") if File.exist?("output/#{(file_list[selected_file - 1])}")
    game_loop
    
  end
end


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

      It is currently Turn #{@turn}, Try to guess the letters in the secret word.
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

  def display_invalid_guess
    "Please input a valid letter"
  end

  def display_wrong_guess
    <<~HEREDOC

    This letter is not in the secret word
    #{@unsolved_letters.join(' , ')}
    HEREDOC
  end

  def display_correct_guess
    <<~HEREDOC
    #{@unsolved_letters.join(' , ')}
    You have guessed correctly!
    #{@solved_letters.join(' ')}
    HEREDOC
  end

  def display_letters_remaining
    "#{@solved_letters.join(' ')}"
  end

  def display_one_turn_left
    "Think hard! You have one try left\n"
  end

  def display_exit_msg
    "Exiting game ..."
  end

  def display_play_again_msg
    "Do you want to play again? Enter Y/N"
  end

  def display_thank_you
    "Thank you for playing!"
  end

  def display_winner_msg
    "You have guessed the secret word, you win!!"
  end
  def display_loser_msg
    <<~HEREDOC

    "You Lose! The word was #{@word}"

    Sorry you did not guess the word! 

    HEREDOC
  end
  def display_already_guessed_letter
    "Please input another letter, you have already guessed this"
  end
end

class Game
  include Database
  include Display
  attr_accessor :word, :turn, :all_letters, :unsolved_letters, :solved_letters
  def initialize
    @turn = 1
    @all_letters = ("a".."z").to_a
    @unsolved_letters = []
    @solved_letters = []
    game_start
  end

  def create_blank_letters
    @word.each_char { @solved_letters << '_'}
    puts display_word_length
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
  
  #Heart of the game
  # loops until turn 11 or until player has won
  # if user_letter_guess is in the hidden word, udpate solved_letters array with the letter filled in 
  # if it is not in the hidden word, go next turn 
  def new_game
    @word = random_word
    create_blank_letters
    game_loop 
  end

  def game_loop
    puts display_letters_remaining
    until game_over? || game_solved?
      puts display_turn_prompt
      @user_letter_guess = gets.chomp.downcase
      guess_again_if_bad_input
      if @user_letter_guess == 'exit'
        puts display_exit_msg
        exit
      end
      if @user_letter_guess == 'save'
        save_game
        play_again_option
      end
      incorrect_guess unless @word.include?(@user_letter_guess)
      update_solved_letters if @word.include?(@user_letter_guess)
      puts display_one_turn_left if @turn == 12
    end
    if game_solved?
      puts display_winner_msg
    else
      puts display_loser_msg
    end
    play_again_option
  end

  def guess_again_if_bad_input
    while @solved_letters.include?(@user_letter_guess) || @unsolved_letters.include?(@user_letter_guess)
      puts display_already_guessed_letter
      @user_letter_guess = gets.chomp.downcase
      until (@user_letter_guess.length == 1 && @all_letters.include?(@user_letter_guess)) || @user_letter_guess == 'save' || @user_letter_guess == 'exit'
        puts display_invalid_guess
        @user_letter_guess = gets.chomp.downcase
      end
    end
  end

  def random_word 
    word_list = File.readlines('available_words.txt')
    word_list.each do |word|
      word.strip!
    end
    word_list.select { |word| word.length.between?(5, 12) }.sample
  end

  def update_solved_letters
    @word.split('').each_with_index do |letter, index|
      if letter == @user_letter_guess
        @solved_letters[index] = letter
      end
    end
    puts display_correct_guess
    @turn += 1
  end

  def incorrect_guess 
    @turn += 1
    @unsolved_letters << @user_letter_guess
    puts display_wrong_guess
    puts display_letters_remaining
  end

  def game_solved?
    !@solved_letters.include?('_')
  end

  def game_over?
    @turn == 13
  end

  def play_again_option
    puts display_play_again_msg
    player_choice = gets.chomp.downcase
    until player_choice == 'y' || player_choice == 'n'
      puts display_play_again_msg
      player_choice = gets.chomp.downcase
    end
    if player_choice == 'y'
      Game.new()
    elsif player_choice == 'n'
      puts display_thank_you
      puts display_exit_msg
      exit
    end
  end


end


Game.new()