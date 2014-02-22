require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

# CONSTANTS

BLACKJACK = 21

# HELPERS

helpers do
  
  def calculate_total(cards) 
  array = cards.map {|card| card[1]} 
  total = 0
  array.each do |value|
    if value == "A" 
      total += 11 
    elsif value.to_i == 0 
      total += 10
    else
      total += value.to_i
    end
  end 

    array.select {|card| card.include?("A")}.count.times do
      total -= 10 if total > 21
    end
  total # don't forget to include total here before exiting. IMPORTANT!!
  end # ends the calculate_total helper method

  def card_images(card)
    suit = case card[0]
        when "Clubs" then 'clubs'
        when "Diamonds" then 'diamonds'
        when "Spades" then 'spades'
        when "Hearts" then 'hearts'
      end
    # Values
    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
    value = case card[1]
      when "J" then 'jack'
      when "Q" then 'queen'
      when "K" then 'king'
      when "A" then 'ace'
    end #ends if
    end #ends value
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_display'>"
  end # ends the card images helper method

  def current_total_amount
    if calculate_total(session[:player_cards]).to_i == 21
      @amount.to_i + session[:player_bet].to_i 
    elsif calculate_total(session[:player_cards]).to_i > BLACKJACK
      @amount.to_i - session[:player_bet].to_i
    elsif calculate_total(session[:dealer_cards]).to_i > BLACKJACK
      @amount.to_i + session[:player_bet].to_i 
    elsif calculate_total(session[:dealer_cards]).to_i == BLACKJACK
      @amount.to_i - session[:player_bet].to_i
    elsif calculate_total(session[:player_cards]).to_i > calculate_total(session[:dealer_cards]).to_i
      @amount.to_i + session[:player_bet].to_i 
    else @amount.to_i - session[:player_bet].to_i 
    end # ends if statement
  end # ends current_total_amount method

    def compare_winner
      if calculate_total(session[:player_cards]).to_i > calculate_total(session[:dealer_cards]).to_i
        @success = 'Congratulations, you have the higher score. You win! Your total is now #{current_total_amount}'
        current_total_amount = session[:current_total_amount]
      else
        @error = "Sorry, the Dealer's total is higher. Better luck next time #{session[:player_name]}."
      end
    end # ends compare winner method

    def winner!(message)
      @success = "<strong>Congratulations! #{session[:player_name]} won.</strong> #{message}" 
      @hit_or_stay = false 
      @play_again = true
    end

    def loser!(message)
      @error = "<strong>Sorry, #{session[:player_name]} lost.</strong> #{message}"
      @hit_or_stay = false
      @play_again = true
    end

    def tie!(message)
      @info = "<strong>That was a lucky break. Its a tie.</strong> #{message}"
      @hit_or_stay = false
      @play_again = true
    end

end # ends Helpers

#++++++++++++++++++++++++++++++++++++++++++++++++++

# BEFORE

before do
  @hit_or_stay = true
  @amount = 500
  # @updated_amount = 
end

#++++++++++++++++++++++++++++++++++++++++++++++++++

# MAIN PAGE

get '/' do
  if session[:player_name]
   redirect to '/bet'
  else
    redirect to '/new_form'
  end
end

get '/new_form' do
  @message = "Welcome to Blackjack, please enter your name before proceeding."
  #session[:player_name] = gets.chomp.capitalize
  erb :name
end

post '/new_form' do
  if params[:player_name].empty?
  @error = 'You are required to enter your name in order to play.'
   @message = "Welcome to Blackjack, please enter your name before proceeding."
  halt erb(:name)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

#++++++++++++++++++++++++++++++++++++++++++++++++++++

# GAMEPLAY

get '/game' do
  session[:turn] = session[:player_name]
  suits = ["Hearts", "Clubs", "Diamonds", "Spades"]
  cardnumbers = ["2", "3", "4", "5", "6", "7", "8", "9", "J", "Q", "K", "A"]
  session[:deck] = suits.product(cardnumbers).shuffle!
  #starting off with player and dealer cards
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards]).to_i
  if player_total == BLACKJACK
    winner!("Congratulations, you hit Blackjack! You now have $#{current_total_amount}")
    current_total_amount = session[:current_total_amount]
  end
  erb :game
end

post '/hit' do 

  session[:player_newcard] << session[:deck].pop
  session[:dealer_newcard] << session[:deck].pop

  redirect '/game'
end

post '/stay' do
  redirect '/game'
end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++

#BET PAGE

get '/bet' do # shows bet form  

  @amount # not working
  erb(:bet)
  
end

post '/player_bet' do # processes bet form. Bet amount cannot be empty
  if params[:player_bet].empty?
  @error = 'You are required to enter a bet amount.'
  halt erb(:bet)
  end

  if params[:player_bet].to_i > @amount.to_i
    @error = 'Please enter an amount below $' + @amount.to_s + '.'
    halt erb(:bet)
  end

  session[:player_bet] = params[:player_bet]
  redirect '/game'
end

#++++++++++++++++++++++++++++++++++++++++++++++++++

# PLAYER TURN

get '/player_play_again' do
  session[:current_total_amount]
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards]).to_i
  if player_total > BLACKJACK
    loser!("The total is more than 21. You are busted. You now have $#{current_total_amount} left in your balance.") #NOTE!
    current_total_amount = session[:current_total_amount]
  elsif player_total == BLACKJACK
    winner!("You hit Blackjack! You have a total of $#{current_total_amount}.")
    current_total_amount = session[:current_total_amount]
  end
  erb :game
end

post '/game/player/stay' do
  player_total = calculate_total(session[:player_cards]).to_i
  @info = "You have chosen to stay at #{player_total}. It is now the Dealer's turn." # there is an issue here with this display
  redirect '/game/dealer'
end

#++++++++++++++++++++++++++++++++++++++++++++++++++

# DEALER TURN

get '/game/dealer' do 
  session[:turn] = "dealer"
  @hit_or_stay = false
  dealer_total = calculate_total(session[:dealer_cards]).to_i
    if dealer_total == BLACKJACK
      loser!("Dealer got Blackjack. Better luck next time. Your total is now $#{current_total_amount}")
      current_total_amount = session[:current_total_amount]
    elsif dealer_total > BLACKJACK
      winner!("The Dealer's total is #{dealer_total}. The Dealer is busted. Your total is now $#{current_total_amount}.")
      current_total_amount = session[:current_total_amount]
    elsif dealer_total >= 17
      @info = "Dealer will stay at #{dealer_total}. We will now compare scores."
      redirect '/game/compare_winner'
    else
      @dealer_hit_button = true
    end # ends if statement
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

#++++++++++++++++++++++++++++++++++++++++++++++++++

# COMPARE WINNER

get '/game/compare_winner' do
  @hit_or_stay = false
  dealer_total = calculate_total(session[:dealer_cards]).to_i
  player_total = calculate_total(session[:player_cards]).to_i
  @info = "Dealer stays at #{dealer_total}." 
  if dealer_total > player_total
    loser!("Dealer has the higher score. Your total is now $#{current_total_amount}.")
    current_total_amount = session[:current_total_amount]
  elsif player_total > dealer_total
    winner! ("You have the higher score. Your total is now $#{current_total_amount}.")
    current_total_amount = session[:current_total_amount]
  else
    tie!("Both totals are #{dealer_total}. Your total is now $#{current_total_amount}.")
    current_total_amount = session[:current_total_amount]
  end
  erb :game
end # ends compare winner

#++++++++++++++++++++++++++++++++++++++++++++++++++

# END GAME - LOGOUT

get '/logout' do
  @info = 'You are now logged out. Thanks for playing.'
  session[:player_name] = false
  redirect '/'
end

#++++++++++++++++++++++++++++++++++++++++++++++++++

























