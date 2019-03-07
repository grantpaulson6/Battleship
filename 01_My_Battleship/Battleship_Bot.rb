require "colorize"

class Battleship_Bot
    
    def initialize
        @ocean = "~".colorize(:light_blue)
        @miss = "*".colorize(:light_green)
        @hit = "X".colorize(:red)
        @guess_history = []
        @hit_guesses = []
        @unsunk_hit_ship = false
        @neighbor_strategy = false
        @neighbor_guesses = []
        @neighbor_seed_guesses = []
    end
    
    #need to edit this to keep capping lines with neighbor strategy
    def destroyed_ship(enemy_sunk)
        if enemy_sunk
            @neighbor_strategy = false
            @unsunk_hit_ship = false
            @hit_guesses = []
            return true
        else
            return false
        end
    end

    def play(grid, enemy_sunk)
        guess = find_guess(grid, enemy_sunk)
        @guess_history << guess
        return guess
    end

    def target_potential(grid)
        potential_grid = Array.new(10) { Array.new(10, 0) }
        (0...10).each do |row|
            (0...10).each do |col|
                prox_pot = proximity_potential(row,col,grid)
                potential_grid[row][col] = prox_pot
            end
        end
        potential_grid
    end

    def proximity_potential(row,col,grid)
        count = 0
        if grid[row][col] == @ocean
            [-1,1].each do |i|
                if (row + i) >= 0 && (row + i) <= 9 && grid[row + i][col] == @ocean
                    count += 1
                    if (row + 2*i) >= 0 && (row + 2*i) <= 9 && grid[row + 2*i][col] == @ocean
                        count += 1 
                    end
                end
                if (col + i) >= 0 && (col + i) <= 9 && grid[row][col + i] == @ocean
                    count += 1
                    if (col + 2*i) >= 0 && (col + 2*i) <= 9 && grid[row][col + 2*i] == @ocean
                        count += 1
                    end
                end
            end
        end
        count
    end


#=====================================================================================================================================

def find_guess(grid, enemy_sunk)
        if @guess_history.empty?
            return random_guess(grid)
            
        end



        # if the last guess was a hit, add to the hit guesses.
        if !@neighbor_strategy
            if grid[@guess_history[-1][0]][@guess_history[-1][1]] == @hit
                @hit_guesses << @guess_history[-1]
                #If that was the first hit on a ship, initialize unsunk hit ship
                if @hit_guesses.length == 1
                    @unsunk_hit_ship = true
                end
            end
        end

        destroyed_ship(enemy_sunk) if !@neighbor_strategy

        if @unsunk_hit_ship && !@neighbor_strategy
            if @hit_guesses.length == 1
                return rand_adjacent_guess(@hit_guesses[0],grid)
            elsif @hit_guesses.length >= 2 #&& !@neighbor_strategy
                next_in_line = [2 * @hit_guesses[-1][0] - @hit_guesses[-2][0], 2 * @hit_guesses[-1][1] - @hit_guesses[-2][1] ]

                #if this next_in_line guess is in bounds and ocean, return it.
                if next_in_line[0] <= 9 && next_in_line[0] >= 0 && next_in_line[1] <= 9 && next_in_line[1] >=0 && grid[next_in_line[0]][next_in_line[1]] == @ocean
                    return next_in_line
                #else, start shooting on opposite side    
                else
                    next_in_line = [2 * @hit_guesses[0][0] - @hit_guesses[1][0], 2 * @hit_guesses[0][1] - @hit_guesses[1][1] ]
                    
                    #check if opposite side is in bounds and ocean
                    if next_in_line[0] <= 9 && next_in_line[0] >= 0 && next_in_line[1] <= 9 && next_in_line[1] >=0 && grid[next_in_line[0]][next_in_line[1]] == @ocean
                        #add first hit to end to allow guess in new direction properly
                        @hit_guesses << @hit_guesses[0]
                        return next_in_line
                        
                    else
                        @neighbor_strategy = true
                        #remove any duplicates from hit guesses
                        @neighbor_seed_guesses = @hit_guesses.uniq
                        @neighbor_guesses << @neighbor_seed_guesses[-1]
                        #cap every line in hit guesses
                        neighbor_attack(grid)
                    end
                end
            end

        elsif @neighbor_strategy
            self.neighbor_attack(grid)
        else
            return random_guess(grid)
        end

    end

    #cap all perpidincular lines to the hit guess lines
    def neighbor_attack(grid)
        if @neighbor_guesses.length == 1
            guess = rand_adjacent_guess(@neighbor_guesses[0],grid)
            @neighbor_guesses << guess
            return guess
        elsif @neighbor_guesses.length >= 2
            #check if last shot was miss or hit or what. if hit, do following, else, switch shooting
            #f grid[@neighbor_guesses[-1][0]][@neighbor_guesses[-1][1]] == @hit
            next_in_line = [2 * @neighbor_guesses[-1][0] - @neighbor_guesses[-2][0], 2 * @neighbor_guesses[-1][1] - @neighbor_guesses[-2][1] ]

            #if this next_in_line guess is in bounds and ocean, return it.
            if next_in_line[0] <= 9 && next_in_line[0] >= 0 && next_in_line[1] <= 9 && next_in_line[1] >=0 && grid[next_in_line[0]][next_in_line[1]] == @ocean
                
                @neighbor_guesses << next_in_line
                return next_in_line
            #else, start shooting on opposite side    
            else
                next_in_line = [2 * @neighbor_guesses[0][0] - @neighbor_guesses[1][0], 2 * @neighbor_guesses[0][1] - @neighbor_guesses[1][1] ]
                
                #check if opposite side is in bounds and ocean
                if next_in_line[0] <= 9 && next_in_line[0] >= 0 && next_in_line[1] <= 9 && next_in_line[1] >=0 && grid[next_in_line[0]][next_in_line[1]] == @ocean
                    #add first hit to end to allow guess in new direction properly
                    @neighbor_guesses << @neighbor_guesses[0]
                    @neighbor_guesses << next_in_line
                    return next_in_line
                else
                    if @neighbor_seed_guesses.length > 1
                        @neighbor_seed_guesses.pop
                        @neighbor_guesses = []
                        @neighbor_guesses << @neighbor_seed_guesses[-1]
                        return neighbor_attack(grid)
                    else
                        @neighbor_strategy = false
                        @neighbor_guesses = []
                        @neighbor_seed_guesses = []
                        destroyed_ship(true)
                        return random_guess(grid)
                    end
                end
            end
        end
    end

#=====================================================================================================================================

    def rand_adjacent_guess(guess, grid) # could optimize here
        compass = {up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}
        options = compass.keys
        i = 0
        while i < 4
            direction = options.sample
            options.delete(direction)
            row = guess[0]
            col = guess[1]
            row += compass[direction][0]
            col += compass[direction][1]
            if row < 0 || row > 9 || col < 0 || col > 9 || grid[row][col] != @ocean
                if i == 3
                    @neighbor_strategy = false
                    @neighbor_guesses = []
                    @neighbor_seed_guesses = []
                    destroyed_ship(true)
                    return random_guess(grid)
                else
                    next
                end
            else
                return [row,col]
            end
            i += 1
        end
    end



    def random_guess(grid)
        possible_guesses = []
        potential_grid = target_potential(grid)
        max_potential = potential_grid.flatten.max
        potential_grid.each_with_index do |row_array,row|
            row_array.each_with_index do |potential,col|
                if potential == max_potential
                    possible_guesses << [row,col] 
                end
            end
        end
        return possible_guesses.sample
    end

end

#takes in grid (of only ~, *, and X)
#outputs guess (coordinates)
#random guesses except when hits, kill ship