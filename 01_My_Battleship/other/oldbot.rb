
class CPU_player
    
    def initialize
        @ocean = "~".colorize(:light_blue)
        @miss = "*".colorize(:light_green)
        @hit = "X".colorize(:red)
        @guess_history = []
        @hit_guesses = []
        @unsunk_hit_ship = false
        @strategy_new = false
    end

    # def hit?(hit)

    # end
    
    def destroyed_ship(enemy_sunk)
        if enemy_sunk
            @strategy_new = false
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
        # puts "CPU guess"
        # puts guess
        return guess
    end

    def find_guess(grid, enemy_sunk)
        if @guess_history.empty?
            return random_guess(grid)
            
        end
        # puts "guess history  "
        # puts @guess_history
        if grid[@guess_history[-1][0]][@guess_history[-1][1]] == @hit
            @hit_guesses << @guess_history[-1]
            if @hit_guesses.length == 1
                @unsunk_hit_ship = true
            end
        end
        # puts "hit history "
        # puts @hit_guesses

        destroyed_ship(enemy_sunk)

        if @unsunk_hit_ship
            if @hit_guesses.length == 1
                return rand_adjacent_guess(@hit_guesses[0],grid)
            elsif @hit_guesses.length >= 2 && !@strategy_new
                next_in_line = [2 * @hit_guesses[-1][0] - @hit_guesses[-2][0], 2 * @hit_guesses[-1][1] - @hit_guesses[-2][1] ]
                # puts "next in line"
                # puts next_in_line

                if grid[next_in_line[0]][next_in_line[1]] && grid[next_in_line[0]][next_in_line[1]] == @ocean
                    return next_in_line
                    
                else #next_in_line == @miss
                    next_in_line = [2 * @hit_guesses[0][0] - @hit_guesses[1][0], 2 * @hit_guesses[0][1] - @hit_guesses[1][1] ]
                    if grid[next_in_line[0]][next_in_line[1]] == @ocean
                        return next_in_line
                        
                    else
                        #@strategy_new = true
                        return rand_adjacent_guess(@hit_guesses[0], grid)
                          
                    end
                end
            elsif @strategy_new
                while true
                    chaos = rand_adjacent_guess(@hit_guesses.sample, grid)
                    if chaos
                        return  chaos
                         
                    end
                end
            end

        else
            return random_guess(grid)
        end

    end

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
                next
            else
                return [row,col]
            end
            i += 1
        end
        return false
    end



    def random_guess(grid)
        while true
            row = rand(10)
            col = rand(10)
            if ![@hit, @miss].include?(grid[row][col])
                return [row,col]
            end
        end
    end        
end

#takes in grid (of only ~, *, and X)
#outputs guess (coordinates)
#random guesses except when hits, kill ship