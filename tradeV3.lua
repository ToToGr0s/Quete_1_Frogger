    -- TIC-80 : Aller au boulot (Frogger-like)
    -- Objectifs : speedrun ou retard legit

    mode = "menu"
    level = 1
    gameTime = 0 -- Changé de 'time' à 'gameTime' pour éviter conflit
    limit = 1000
    player = {x = 112, y = 120, loot = 0, failed = false}
    player2 = nil -- Pour le mode 2 joueurs
    multi = false -- Flag pour mode multi
    boss = {x = 112, y = 8}
    lanespace = 16
    bestFast = nil
    menuOption = 1
    maxlane = 6 -- Limite à 6 lignes de camions

    -- Sprites pour les voitures selon la direction
    CAR_SPRITE_RIGHT = 261  -- Sprite voiture allant à droite
    CAR_SPRITE_LEFT = 293   -- Sprite voiture allant à gauche

    loots = {}
    lanes = {}

    -- Création des lanes 
    function genLevel()
        player.x = math.random( 40,200 )
        player.y = 120
        player.loot = 0
        player.failed = false
        boss.x = math.random(60, 200)
        boss.y = 8
        gameTime = 0 -- Changé de 'time' à 'gameTime'
        limit = 600 - (level - 1) * 30
        if limit < 300 then limit = 300 end

        loots = {}
        lanes = {}

        local nLanes = math.min(2 + level, maxlane) -- Limite à maxlane (6)
        for i = 1, nLanes do
            local dir = (i % 2 == 0) and 1 or -1
            local speed = 1 + 0.2 * level
            local obs = {}
            local laneY = 120 - (i * lanespace)
            for j = 0, 4 do
                local sprite_id = dir == 1 and CAR_SPRITE_RIGHT or CAR_SPRITE_LEFT
                table.insert(obs, {
                    x = j * 60,
                    y = laneY,
                    dir = dir,
                    speed = speed ,
                    sprite = sprite_id,  -- Ajout de l'ID du sprite
                })
            end
            table.insert(lanes, {y = laneY, obs = obs})
            if math.random(2, 4) == 3 then
                table.insert(loots, {
                    x = math.random(10, 220),
                    y = laneY,
                    caught = false
                })

            end
        end

        if multi then
            player2 = {x = 128, y = 120, failed = false, loot = 0}
        else
            player2 = nil
        end
    end

    function TIC()
        cls(7)
        if mode == "menu" then
            menuLoop()
        elseif mode == "game" then
            gameLoop()
        elseif mode == "scores" then
            scoresScreen()
        elseif mode == "Keys" then
            optionsScreen()
        else
            endScreen()
        end
    end

    function menuLoop()
        map(1)
        print("1 Player ", 10, 62, menuOption == 1 and 5 or 15)
        print("2 Players ", 67, 62, menuOption == 2 and 5 or 15)
        print("Keys", 140, 62, menuOption == 3 and 5 or 15)
        print("Quit", 195, 62, menuOption == 4 and 5 or 15)
        print("Left / Right: Navigate ", 35, 75, 7)
        print("SPACE : Select ", 160, 75, 7)

        if btnp(2) then -- Gauche
            menuOption = menuOption - 1
            if menuOption < 1 then menuOption = 3 end
        end
        if btnp(3) then -- Droite
            menuOption = menuOption + 1
            if menuOption > 4 then menuOption = 1 end
        end
        if keyp(48) then -- espace pour Select
            if menuOption == 1 then
                multi = false
                level = 1
                genLevel()
                mode = "game"
            elseif menuOption == 2 then
                multi = true
                level = 1
                genLevel()
                mode = "game"
            elseif menuOption == 3 then
                mode = "Keys"

            elseif menuOption == 4 then
                exit()

            end
        end
    end

    function gameLoop()
        gameTime = gameTime + 1 -- Changé de 'time' à 'gameTime'

        -- Dessiner la map 4 à la position (60, 0)
        map(60, 0)

        -- HUD
            print("Level:" .. level, 2, 2, 15)
        
        local frames_left = math.max(0, limit - gameTime)
        local seconds = math.floor(frames_left / 60)
        local milliseconds = math.floor((frames_left % 60) * 100 / 60) -- 0-99 ms
            print("Time left: " .. seconds .. "." .. string.format("%02d", milliseconds) .. "s", 50, 2, 15)
        
            print("Loot:" .. player.loot, 160, 2, 5)

        -- Contrôles Joueur 1 (flèches directionnelles)
        if btnp(0) then player.y = player.y - 8 end -- Haut
        if btnp(1) then player.y = player.y + 8 end -- Bas
        if btnp(2) then player.x = player.x - 8 end -- Gauche
        if btnp(3) then player.x = player.x + 8 end -- Droite

        -- Contrôles Joueur 2 (ZQSD, si multi)
        if multi then
            if keyp(26) then player2.y = player2.y - 8 end -- Z (haut)
            if keyp(19) then player2.y = player2.y + 8 end -- S (bas)
            if keyp(17) then player2.x = player2.x - 8 end -- Q (gauche)
            if keyp(4) then player2.x = player2.x + 8 end -- D (droite)
        end

        -- Clamp écran pour Joueur 1
        if player.x < 0 then player.x = 0 end
        if player.x > 232 then player.x = 232 end
        if player.y < 0 then player.y = 0 end
        if player.y > 120 then player.y = 120 end

        -- Clamp écran pour Joueur 2 (si multi)
        if multi then
            if player2.x < 0 then player2.x = 0 end
            if player2.x > 232 then player2.x = 232 end
            if player2.y < 0 then player2.y = 0 end
            if player2.y > 120 then player2.y = 120 end
        end

        -- boss
        spr(257, boss.x, boss.y, 0, 1.5, 0, 0, 2, 2)

        -- Joueur 1
        spr(259, player.x, player.y, 0, 1, 0, 0, 2, 2)

        -- Joueur 2 (si multi)
        if multi then
            spr(291, player2.x, player2.y, 0, 1, 0, 0, 2, 2)
        end

        -- Loots
        for i, l in ipairs(loots) do
            if not l.caught then
                spr(263, l.x, l.y, 0, 1, 0, 0, 2, 2)
                if math.abs(player.x - l.x) < 16 and math.abs(player.y - l.y) < 16 then
                    l.caught = true
                    player.loot = player.loot + 1
                    limit = limit + 120
                elseif multi and math.abs(player2.x - l.x) < 16 and math.abs(player2.y - l.y) < 16 then
                    l.caught = true
                    player2.loot = player2.loot + 1
                    limit = limit + 120
                end
            end
        end

        -- Obstacles
        for _, lane in ipairs(lanes) do
            for _, o in ipairs(lane.obs) do
                -- Utilise le sprite approprié selon la direction
                spr(o.sprite, o.x, o.y, 0, 1, 0, 0, 2, 2)
                
                o.x = o.x + o.dir * o.speed
                if o.dir == 1 and o.x > 240 then o.x = -16 end
                if o.dir == -1 and o.x < -16 then o.x = 240 end
                
                -- Collision detection (inchangée)
                if math.abs(player.x - o.x) < 8 and math.abs(player.y - o.y) < 8 then
                    player.failed = true
                end
                if multi and math.abs(player2.x - o.x) < 8 and math.abs(player2.y - o.y) < 8 then
                    player2.failed = true
                end
            end
        end

        if player.failed or (multi and player2.failed) then
            mode = "end"
            return
        end

        -- Arrivée
        local arrived1 = math.abs(player.x - boss.x) < 8 and math.abs(player.y - boss.y) < 8
        local arrived2 = multi and (math.abs(player2.x - boss.x) < 16 and math.abs(player2.y - boss.y) < 16) or not multi
        if arrived1 and arrived2 then
            mode = "end"
            return
        end

        -- Retard trop long
        if gameTime > limit then -- Changé pour utiliser gameTime (en frames)
            player.failed = true
            mode = "end"
            return
        end
    end

    function scoresScreen()
        cls(0)
        print("=== Scores ===", 60, 20, 7)
        if bestFast then
            print("Time: " .. math.floor(bestFast / 60) .. "s", 60, 60, 11)
        else
            print("Time: null", 60, 60, 11)
        end

        
        print("A = Return", 60, 90, 7)

        if keyp(2) then -- B for Return
            mode = "menu"
        end
    end

    function optionsScreen()
        cls(7)
        map(90,0)
        print ("Keys", 70 , 10 , 7)

        print("Player 1  : ", 30 ,30 ,15)

        print("Player 2  : ", 30 ,62 ,15)


        print("Menu : ", 30, 88, 15)

        if keyp(2) then -- B for return
            mode = "menu"
        end
    end

    function endScreen()
        cls()
        map(30, 0)
        print("=== End level" .. level .. "===", 25, 5, 0)

        if player.failed then
            print("Too late!", 180, 70, 5)
        else
            print("Arrive at work!", 25, 20, 11)
            print("Time:" .. math.floor(gameTime / 60) .. "s", 25, 30, 14) -- Changé 'time' à 'gameTime'
            print("Player 1 Loot:" .. player.loot, 25, 40, 14)

            if gameTime <= limit then -- Changé 'time' à 'gameTime'
                print("On time !", 180, 70, 0)
            end
            if bestFast == nil or gameTime < bestFast then bestFast = gameTime end -- Changé 'time' à 'gameTime'

        end

        print("R to retry", 25, 50, 15)
        print("Records:", 25, 60, 15)
        if bestFast then print("Time:" .. math.floor(bestFast / 60) .. "s", 25, 70, 14) end
            print("R = Restart", 40, 140, 12)
        if not player.failed then print("N = Next level !", 25, 90, 6) end

        if keyp(18) then -- R pour Restart
            genLevel()
            mode = "game"
        end
        if keyp(14) and not player.failed then -- N pour Next level
            level = level + 1
            genLevel()
            mode = "game"
        end
    end