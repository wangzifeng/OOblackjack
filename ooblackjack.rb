# blackjack, object oriented version
#
class Player
  attr_accessor :name, :wins, :losses, :stake, :hands, :dealer, :bet, :winnings
  def initialize(name, dealer = false)
    @name = name
    @dealer = dealer
    @hands = {}
    @wins = 0
    @losses = 0
    @stake = 0
    @stake = 50 unless dealer
    @bet = 0
    @winnings = 0
  end
  def hands
    @hands
  end
  def update_hand(key, hand)
    #insert a new Hand into the player's hash
    @hands[key]=hand
    @bet += hand.hand_bet
  end
end


class Deck
  attr_accessor :name, :hand_status, :hand_bet
  def initialize(packs = 1)
    @name = "Deck"
    @hand_status = "in progress"
    @hand_bet = 0
    @cards = []
    add_packs(packs)
  end
   def add_packs(packs = 1)
    suits = %w(S H C D)
    faces = %w(A 2 3 4 5 6 7 8 9 10 J Q K)
    packs.times do
      suits.each do |this_suit|
        faces.each do |this_face|
          @cards.push(Card.new(this_suit, this_face, true))
        end
      end
    end
    @cards.shuffle!
  end

  def card_count
    @cards.count
  end
  def deal(target, visible = "SHOW")
    # if this is a Deck (not a Hand) and less than 20 cards, add a fresh pack
    if self.class.to_s == "Deck" and @cards.count < 20
      puts "adding more cards to the deck..."
      add_packs
    end
    card = @cards.pop #get a card, then set visibility
    if visible.upcase == "SHOW"
      card.show
    elsif visible.upcase == "HIDE"
      card.hide
    end
    target.accept_card(card) #send the card to the destination deck/hand
  end

  def blackjack_or_bust(player)
    
    if score[0] > 21
      player.losses = player.losses + 1
      player.bet -= self.hand_bet
      player.stake -= self.hand_bet
      player.winnings -= self.hand_bet
      puts
      self.hand_status = "#{player.name}, you busted!  Sorry!"
    elsif score[0] == 21 && card_count == 2
      player.wins = player.wins + 1
      player.bet -= self.hand_bet
      player.stake += self.hand_bet
      player.winnings += self.hand_bet
      puts 
      self.hand_status = "#{player.name}, you got Blackjack! Congrats!" 
    else
      nil
    end
  end

  def beat(dealer_hand,player)
    my_score = self.score[0] 
    his_score = dealer_hand.score[0] 
    if my_score == his_score
      player.bet -= self.hand_bet
      self.hand_status = "Same score, hand is a tie!"
    elsif his_score > 21
      player.wins = player.wins + 1
      player.bet -= self.hand_bet
      player.stake += self.hand_bet
      player.winnings += self.hand_bet
      self.hand_status = "#{player.name}, dealer has busted!  You win! Congrats!"
      
    elsif his_score > my_score
      player.losses = player.losses + 1
      player.bet -= self.hand_bet
      player.stake -= self.hand_bet
      player.winnings -= self.hand_bet
      self.hand_status = "Sorry, dealer has a better hand!"
    else
      player.wins = player.wins + 1
      player.bet -= self.hand_bet
      player.stake += self.hand_bet
      player.winnings += self.hand_bet
      self.hand_status = "#{player.name}, you have the better hand! You win! Congrats!"
    end
  end
  def cards
    @cards
  end
  def show_hand
    hidden = false
    puts
    print "#{@name} has "
    @cards.each {|card| print "#{card}, "
        hidden = card.hidden? if hidden == false} #if at least 1 card hidden, no value pls!
    unless hidden   
      print "for a value of #{score[0]}"
      print " \(or #{score[1]}\)" if score[1] != 0
    end
    puts
  end
  def score()
    total_score = 0
    soft_score = 0
    aces = 0
    @cards.each do |card|
      total_score += card.value
      aces += 1 if card.value == 11
    end
    while total_score > 21 && aces > 0
      total_score -= 10
      aces -= 1   
    end
    soft_score = total_score - 10 if aces > 0 && total_score < 21
    return total_score, soft_score
  end  
  protected
  def accept_card(card)
    @cards << card
  end
  
  
end


class Hand < Deck
  attr_accessor :name, :hand_bet
  def initialize(name, bet)
    @name = name
    @hand_bet = bet
    @hand_status = "in progress"
    @cards = []
  end
end

class Card 

  def initialize (suit, face, hidden)
    @suit = suit
    @face = face
    @hidden = hidden
  end

 
  def value
    card_value = @face.to_i
    if @face == "A"
      card_value = 11
    end
    if card_value == 0
      card_value = 10
    end
    card_value
  end
  def hidden?
    @hidden
  end
  def hide
    @hidden = true
  end
  def show
    @hidden = false
  end

  def to_s
    #build user friendly string of the Card instance
    suits = {"S" => "Spades", "H" => "Hearts", "D" => "Diamonds", "C" => "Clubs"}
    faces = {"A" => "Ace", "2" => "Two", "3" => "Three", "4"=> "Four",
             "5" => "Five", "6" => "Six", "7" => "Seven", "8" => "Eight",
             "9" => "Nine", "10" => "Ten", "J" => "Jack", "Q" => "Queen", "K" => "King"}
    unless @hidden
      return "#{faces[@face]} of #{suits[@suit]}"
    else
      return "hidden card"
    end
  end
end

class Blackjack
  attr_accessor :heroes, :dealer, :mydeck
  def initialize
    @heroes = []
    collect_players
    self.mydeck = Deck.new(4)
    self.dealer = Hand.new("Dealer",0)
    want_to_play = true
    while want_to_play
      introduce_table
      initial_deal
      players_turns
      dealers_turn
      final_results
      want_to_play = false if choose_option("End Game?",["Y","N"],"Y") == "Y"
    end
  end
  def choose_option(message, choices, default)
    # general method to prompt for input from user
    # choices is array of valid entries, default is used if user Enters
    option = nil
    until option
      puts
      print message + " " + choices.to_s
      print " (default is \"#{default}\")" unless default == nil
      puts
      option = gets.chomp.upcase[0]
      option = default if option == nil
      unless choices.include?(option)
        puts 
        puts "\"#{option}\" is not a valid choice, please try again"
        option = nil
      end
    end
    sleep(1)
    option
  end
  def collect_players
    #we get all the players names, create Player objexts
    puts
    puts 'Hi, welcome to Blackjack!'
    collecting_players = true
    while collecting_players
      puts

      puts "What's your name?"
      name = gets.chomp.downcase.capitalize
      puts 
      self.heroes << Player.new(name)
      puts "Nice to meet you, #{name}! You have #{self.heroes.last.stake} beans."
      
      puts ""
      collecting_players = false if choose_option("Enter another player?",["Y","N"],"Y") == "N"
    end
  end

  def introduce_table
    # puts all the player names out - plus we have a chance to throw away old hands
    # and we collect bets
    puts
    print "Ok, sitting around the table we have "
    prefix = ""
    self.heroes.each do |our_hero|
      print "#{prefix}#{our_hero.name} with #{our_hero.stake} beans"
      our_hero.hands = {}
      our_hero.bet = 0
      prefix = ", "
    end
    puts "."
    puts " "
    puts "Let's play some Blackjack!"
    puts
    sleep(3)
  end
  def get_bets(our_hero)
    if our_hero.stake == 0
      puts
      puts "Skipping #{our_hero.name}... no beans to bet with!"
      puts
      this_bet = 0
    else
      need_bet = true
      while need_bet
         puts "How much do you want to bet, #{our_hero.name}?"
        while ( this_bet = gets.chomp ) != this_bet.to_i.to_s
          puts "I just need a number, #{our_hero.name}... or enter '0' to pass."
          puts
          puts "How much do you want to bet, #{our_hero.name}?"
        end
        if this_bet.to_i > our_hero.stake
          puts "You can't bet that much!! You only have #{our_hero.stake} beans."
          puts
        else
          need_bet = false
        end
      end
    end
    this_bet.to_i
  end

  def initial_deal
    self.heroes.each do |our_hero|
      his_bet = get_bets(our_hero)
      our_hero.update_hand(0, Hand.new(our_hero.name,his_bet)) if his_bet != 0 #create one initial hand per player
    end

    self.heroes.each do |our_hero|
      our_hero.hands.each_pair do |pointer, hand|
        self.mydeck.deal(hand) # deal one card around table 
      end
    end

    self.mydeck.deal(self.dealer, "hide") #deal to dealer, face down

    self.heroes.each do |our_hero|
      our_hero.hands.each_pair do |pointer, hand|
        self.mydeck.deal(hand) # deal second card around table 
      end
    end
    self.mydeck.deal (self.dealer) # dealer's second card
  end
  def ok_to_split?(hand, player)
    if hand.cards[0].value == hand.cards[1].value
      if (player.stake - player.bet) < hand.hand_bet
        puts "#{player.name}, you have matching values BUT you only have #{player.stake - player.bet} beans left."
        puts "I can't offer you the option to split your hand. :("
        puts 
        false
      else
        true
      end 
    else
      false
    end
  end

  def players_turns
    # following Hand instance is local to the method, we use it to throw away cards
    discard = Hand.new("discarded",0) 
    self.heroes.each do |our_hero|
    # output who's turn
      puts "." * 80
      puts "#{our_hero.name}'s turn".center(80)
      puts "." * 80
      # the following is for cheating (!) a player called "Lucky" will always get split
      lucky_wink_wink = true
      handle_splits = true
      while handle_splits
        handle_splits = false
        temp_hand = {} # hash to temporarily store any new Hands because of splits
        # loop through all hands for this player, initially there will be only 1
        our_hero.hands.each_pair do |pointer, hand|
          # make sure hand has two cards (hand might only have 1 if create by split)
          self.mydeck.deal(hand) while hand.card_count < 2 
          # CHEAT CHEAT CHEAT ... player called "Lucky" will throw away cards and 
          # get new cards until he gets a split pair (used to test split function)
          while lucky_wink_wink && our_hero.name == "Lucky" && hand.cards[0].value != hand.cards[1].value 
            hand.deal(discard)
            self.mydeck.deal(hand)
          end  
          # check for split
          if ok_to_split?(hand,our_hero)
            lucky_wink_wink = false # this prevents us splitting "Lucky" indefinitely
            hand.show_hand
            if choose_option("Two cards are same value. Do you want to split?",["Y","N"],"Y") == "Y"
              new_number = our_hero.hands.count
              # change hand name from "John" to "John's hand # 1"
              our_hero.hands[0].name = our_hero.name + "'s hand # 1"
              # create a new hand
              temp_hand[new_number] = Hand.new(our_hero.name + "'s hand # #{new_number + 1}", hand.hand_bet)
              # increase player bet
              our_hero.bet += hand.hand_bet
              # deal a card from the old Hand ot the new Hand
              hand.deal(temp_hand[new_number])
              # flag that we'll need to loop again to add missing cards 
              # and to check for more splits
              handle_splits = true
            end  
          end
        end
        #now we move the newly created hands into the Player's Hand hash
        temp_hand.each_pair do |pointer,hand|
          our_hero.update_hand(pointer,hand) 
        end
      # at this point we jump up, add missing cards, check for splits
      end
      our_hero.hands.each_pair do |pointer, hand|
        player_turn = true
        while player_turn
          hand.show_hand
          self.dealer.show_hand 
          result = hand.blackjack_or_bust(our_hero) 
          if result
            puts result 
            break 
          end 
          if choose_option("#{our_hero.name}, would you like to HIT, or STAND?",["H","S"],"H") == "H"
            puts 
            puts "Player hits..."
            self.mydeck.deal(hand)
          else
            player_turn = false 
          end
        end
      end
    end
  end
  def dealers_turn
  puts "." * 80
  puts "dealer's turn".center(80)
  puts "." * 80
  puts "Dealer flips his card over..."
  self.dealer.cards[0].show
  self.dealer.show_hand
  # hit on under 17 or soft 17
  again = ""
  while self.dealer.score[0] < 17 || ( self.dealer.score[0] == 17 && self.dealer.score[1] != 0 ) 
    self.mydeck.deal(self.dealer)
    puts 
    puts "Dealer hits#{again}..."
    again = " again"
    sleep(1)
    self.dealer.show_hand
  end 
end
def final_results
  puts "." * 80
  puts "final results".center(80)
  puts "." * 80
  # check each player's hands against dealer
  self.heroes.each do |our_hero|
    our_hero.hands.each_pair do |pointer, hand|
      puts "#{hand.name}..."
      if hand.hand_status == "in progress" 
        # check to see if we won or lost
        puts "    " + hand.beat(self.dealer,our_hero)
      else
        # we won or lost during player's deal (blackjack or busted) just repeat the msg
        puts "    " + hand.hand_status
      end
    end
    puts "    So far, #{our_hero.name} has won #{our_hero.wins} games and lost #{our_hero.losses} games."
    puts "    Winnings are #{our_hero.winnings} beans, current assets are #{our_hero.stake} beans."
    puts
    sleep(5)
  end
end
end
game = Blackjack.new