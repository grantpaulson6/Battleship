require_relative "Battleship_Bot"
require "colorize"

class BattleshipVS
    @@human_wins = 0
    @@battleship_bot_wins = 0

    def initialize
        @ocean = "~".colorize(:light_blue)
        @miss = "*".colorize(:light_green)
        @hit = "X".colorize(:red)
        @grid = Array.new(10) { Array.new(10, @ocean) }
        @enemy_grid = Array.new(10) { Array.new(10, @ocean) }
        @ships = { Destroyer: 2, Submarine: 3, Cruiser: 3, Battleship: 4, Aircraft_Carrier: 5 }
        @remaining_ships = @ships.keys
        @enemy_remaining_ships = @ships.keys
        @enemy_sunk = false
        @enemy = Battleship_Bot.new
        @turns = 0
    end

    def [](guess)
        @grid[guess[0]-1][guess[1]-1]
    end

    def []=(guess, value)       #guess is an array of length 2: (row, col)
        @grid[guess[0]-1][guess[1]-1] = value
    end

    def place_random_ship(map, str, length)
        compass = {up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}
        marker = str[0]

        while true
            row = rand(10)
            col = rand(10)
            direction = [:up, :down, :left, :right].sample
            clear_spaces = []

            while clear_spaces.length < length
                if  row < 0 || col < 0 || row > 9 || col > 9 || map[row][col] != @ocean
                    break 
                else
                    clear_spaces << [row,col] 
                end
                row += compass[direction][0]
                col += compass[direction][1]
            end

            if clear_spaces.length == length
                clear_spaces.each do |coordinate|
                    row = coordinate[0]
                    col = coordinate[1]
                    map[row][col] = marker
                end
                break
            end

        end
    end

    def place_ships(map)
        @ships.each { |ship, length| place_random_ship(map,ship,length) }
    end

    def play
        puts ""
        self.setup_enemy_grid
        puts ""
        puts "May the best Admiral win!"
        puts ""
        self.place_ships(@grid)
        #self.place_ships(@enemy_grid) #later, call setup_enemy_grid
        while !self.game_over?[0]
            self.each_turn(@enemy)
        end
        puts self.game_over?[1]
        self.game_print

    end

    def game_over?
        you_win = ["A","B","C","D","S"].none? do |ship|
            @grid.flatten.include?(ship)
        end
        bot_wins = ["A","B","C","D","S"].none? do |ship|
            @enemy_grid.flatten.include?(ship)
        end
        if you_win
            @@human_wins += 1
            return [true, "You've destroyed the enemy ship, " + "VICTORY!!!".colorize(:green)]
        elsif bot_wins
            @@battleship_bot_wins += 1
            return [true, "You're fleet has been destroyed, " + "THIS DEFEAT MUST NOT STAND!".colorize(:red)]
        else
            return [false, ""]
        end
    end

    def each_turn(enemy)
        self.game_print
        puts ""
        puts "Enter coordinates to attack, separted by a space,row first then col (ex: 3 9)"
        guess = gets.chomp.split.map(&:to_i)
        puts "------------------------------------------------------------"
        puts ""
        enemy_guess = enemy.play(hide_grid(@enemy_grid), @enemy_sunk)

        if legit(guess)
            user_output = self.check_guess1(guess)
        else
            user_output="not even on the map bro"
        end
        self.check_guess2(enemy_guess, user_output)
        self.check_sunk_ships1
        self.check_sunk_ships2
        puts ""

    end

    def legit(guess)
        return false unless guess.is_a? Array
        return false unless guess.length == 2
        row, col = guess
        if row < 1 || row > 10 || col < 1 || col > 10 || !(row.is_a? Integer) || !(col.is_a? Integer)
            return false
        else
            return true
        end
    end

    def check_guess1(guess)
        user = ""
        spot = @grid[guess[0]-1][guess[1]-1]
        if spot == @ocean
            user = "You missed        "
            @grid[guess[0]-1][guess[1]-1] = @miss
        elsif spot == @miss
            user = "Still a miss there"
        elsif spot == @hit
            user = "Already hit       "
        else
            user = "Disco! Thats a hit".colorize(:light_cyan)
            @grid[guess[0]-1][guess[1]-1] = @hit
        end
        return user
    end

    def check_guess2(enemy_guess, user)
        comp = ""
        #would need to udpate this if plugging in someone else's CPU
        if @enemy_grid[enemy_guess[0]][enemy_guess[1]] == @ocean
            @enemy_grid[enemy_guess[0]][enemy_guess[1]] = @miss
            comp = "Your enemy missed"
        else
            @enemy_grid[enemy_guess[0]][enemy_guess[1]] = @hit
            comp = "Your enemy hit your ship".colorize(:light_red)
        end
        puts user + " "*20 + comp
    end

    def check_sunk_ships1
        @remaining_ships.each do |ship|
            if !@grid.flatten.include?(ship[0])
                puts "You've sunk the #{ship}!".colorize(:cyan)
                @remaining_ships.delete(ship)
            end
        end
    end
    
    def check_sunk_ships2
        @enemy_sunk = false
        @enemy_remaining_ships.each do |ship|
            if !@enemy_grid.flatten.include?(ship[0])
                puts "Your #{ship} has been sunk!".colorize(:red)
                @enemy_sunk = true
                @enemy_remaining_ships.delete(ship)
            end
        end      
    end

    def hide_grid(grid)
        grid.map do |row|
            hidden_row = row.map do |ele|
                if [@ocean,@miss,@hit].include?(ele)
                    ele
                else
                    @ocean
                end
            end
        end
    end

    def game_print
        puts (1..10).to_a.unshift("  ").join(" ") + " "*14 + (1..10).to_a.unshift("  ").join(" ")
        hidden_grid = hide_grid(@grid)
        hidden_grid.each_with_index do |hidden_row, i|
            i += 1
            if i == 10
                j = i.to_s
            else
                j = " " + i.to_s 
            end
            puts hidden_row.unshift(j).join(" ") + " "*15 + j + " " + @enemy_grid[i-1].join(" ")
        end
    end

    def setup_enemy_grid
        puts "Would you like a random assignemt of your ships? (yes or no)"
        ans = gets.chomp
        if ans.downcase == "no"
            self.player_picked_grid
        else
            place_ships(@enemy_grid)
        end
    end

    def player_picked_grid
        @ships.each do |ship, length|
            ask_for_ship(ship, length)
        end

    end

    def ask_for_ship(ship, length)
        puts ""
        self.game_print
        puts ""
        puts "Place your #{ship} (length: #{length})"
        puts 'Enter the coordinate for the end of the ship separted by a space (ex: 3 9 for row 3 col 9):'
        tip = gets.chomp.split.map(&:to_i)
        puts 'Enter the direction for the rest of the ship (options: up, down, left, right):'
        direction = gets.chomp
        if self.legit(tip) && self.legit2(direction)
            place_specific_ship(ship, length, tip, direction)
        else
            puts ""
            puts "Please enter valid coordinate and direction"
            ask_for_ship(ship, length)
        end
    end

    def legit2(str)
        ["up","down","left","right"].include?(str)
    end

    def place_specific_ship(ship, length, tip, direction)
        compass = {"up"=>[-1, 0], "down"=>[1, 0], "left"=>[0, -1], "right" => [0, 1]} #is this right????
        marker = ship[0]
        dir = compass[direction]
        row = tip[0] - 1
        col = tip[1] -1 
        clear_spaces = []
        while clear_spaces.length < length
            
            if  row < 0 || col < 0 || row > 9 || col > 9 || @enemy_grid[row][col] != @ocean
                puts "incorrect entry, try again" 
                ask_for_ship(ship, length)
                break
                # need a break here??? get looped around in the call stack?
            else
                clear_spaces << [row,col] 
            end
            row += dir[0]
            col += dir[1]
        end

        if clear_spaces.length == length
            clear_spaces.each do |coordinate|
                row = coordinate[0]
                col = coordinate[1]
                @enemy_grid[row][col] = marker
            end
        end

    end

end



#Improvements:
#bug when Bot switches to shooting the opposite direction, gets stuck in rand adjacent guess
#CPU has smarter neighbor picks after hit
#CPU caps each line if the first hit line is capped with no sunk (side by side ships)