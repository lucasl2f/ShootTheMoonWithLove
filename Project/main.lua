
-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

--player
isAlive = false
score = 0
livesMax = 3
lives = 0
weaponIndex = 1

--Timers
canShoot = true
canShootTimerMax = 0.2
canShootTimer = canShootTimerMax
createEnemyTimerMax = 0.4
createEnemyTimer = createEnemyTimerMax

--Image Storage
bulletImg = nil
enemyImg = nil

-- Entity Storage
bullets = {}
enemies = {}

-- Background
bgSpeed = 100
bgMargin = 10

function love.load ()
	player = {x = 200, y = 710, speed = 200, img = nil}
	player.img = love.graphics.newImage('Assets/Aircrafts/Aircraft_03.png')

	bulletImg = love.graphics.newImage('Assets/Bullets/bullet_2_blue.png')
	bullet1Img = love.graphics.newImage('Assets/Bullets/bullet_2_orange.png')
	enemyImg = love.graphics.newImage('Assets/Aircrafts/enemy.png')
	background1 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background1.png')}
	background2 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background2.png')}
	background3 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background3.png')}
	background1.y = love.graphics:getHeight() - background1.img:getHeight()
	background2.y = background1.y - background2.img:getHeight() + bgMargin
	background3.y = background2.y - background3.img:getHeight() + bgMargin * 2
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background1.img, 0, background1.y)
	love.graphics.draw(background2.img, 0, background2.y)
	love.graphics.draw(background3.img, 0, background3.y)

	for i, bullet in ipairs(bullets) do
		love.graphics.draw(bullet.img, bullet.x, bullet.y)
	end

	for i, enemy in ipairs(enemies)	do
		love.graphics.draw(enemy.img, enemy.x, enemy.y)--, math.rad(180))
	end

	if isAlive then
		love.graphics.draw(player.img, player.x, player.y)
	else
		love.graphics.print("Press 'R' to play", love.graphics:getWidth()/2 - 50, love.graphics:getHeight()/2-10)
	end

	-- left info
	love.graphics.print("Score: " .. tostring(score), 10, 10)
	love.graphics.print("Lives: " .. tostring(lives), 10, 30)

	-- right info
	love.graphics.setColor(255, 255, 10)
	love.graphics.printf("active bullets: " .. table.getn(bullets), love.graphics:getWidth() - 130, 10, 120, "right")
	love.graphics.printf("active enemies: " .. table.getn(enemies), love.graphics:getWidth() - 130, 30, 120, "right")
	love.graphics.printf("fps: " .. tostring(love.timer.getFPS()), love.graphics:getWidth() - 130, 50, 120, "right")
end

function love.update (dt)
	--exit game
	if love.keyboard.isDown('escape') then
		love.event.push('quit')
	end

	--movement
	if isAlive then
		if love.keyboard.isDown('left', 'a') then
			if (player.x > 0) then
				player.x = player.x - (player.speed * dt)
			end
		elseif love.keyboard.isDown('right', 'd') then
			if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
				player.x = player.x + (player.speed * dt)
			end
		end
	end

	--shoot
	if isAlive then
		canShootTimer = canShootTimer - (1 * dt)
		if canShootTimer < 0 then
			canShoot = true
		end

		if love.keyboard.isDown('space', 'rctrl', 'lctrl', 'ctrl') and canShoot then
			--newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
			--table.insert(bullets, newBullet)
			ShootWeapon[weaponIndex]()
			canShoot = false
			canShootTimer = canShootTimerMax
		end
	end

	for i, bullet in ipairs(bullets) do
		bullet.y = bullet.y - (250 * dt)

		if bullet.y < 0 then
			table.remove(bullets, i)
		end
	end

	-- change weapon
	if love.keyboard.isDown('1') then
		weaponIndex = 1
	end

	if love.keyboard.isDown('2') then
		weaponIndex = 2
	end

	if love.keyboard.isDown('3') then
		weaponIndex = 3
	end

	--enemies
	if isAlive then
		createEnemyTimer = createEnemyTimer - (1*dt)
		if createEnemyTimer < 0 then
			createEnemyTimer = createEnemyTimerMax

			--create
			randomNumber = math.random(10, love.graphics.getWidth() - 10)
			newEnemy = {x = randomNumber, y = -10, img = enemyImg}
			table.insert(enemies, newEnemy)
		end
	end

	for i, enemy in ipairs(enemies) do
		enemy.y = enemy.y + (200 * dt)

		if enemy.y > 850 then
			table.remove(enemies, i)
		end
	end

	
	for i, enemy in ipairs(enemies) do
		for j, bullet in ipairs(bullets) do
			if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
				table.remove(bullets, j)
				table.remove(enemies, i)
				if isAlive then
					score = score + 1
				end
			end
		end

		if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) then
			table.remove(enemies, i)
			lives = lives - 1

			if lives == 0 then
				isAlive = false
			end
		end
	end

	-- restart
	if not isAlive and love.keyboard.isDown('r') then
		bullets = {}
		enemies = {}

		canShootTimer = canShootTimerMax
		createEnemyTimer = createEnemyTimerMax

		player.x = 50
		player.y = 710

		score = 0
		isAlive = true
		lives = livesMax

		background1.y = love.graphics:getHeight() - background1.img:getHeight()
		background2.y = background1.y - background2.img:getHeight() + bgMargin
		background3.y = background2.y - background3.img:getHeight() + bgMargin * 2
	end

	-- background
	background1.y = background1.y + bgSpeed * dt
	background2.y = background2.y + bgSpeed * dt
	background3.y = background3.y + bgSpeed * dt

	if background1.y > love.graphics:getHeight() then
		background1.y = -background1.img:getHeight()
	end

	if background2.y > love.graphics:getHeight() then
		background2.y = -background2.img:getHeight()
	end

	if background3.y > love.graphics:getHeight() then
		background3.y = -background3.img:getHeight()
	end
end

-- change weapon
ShootWeapon = {
	[1] = function ()
			newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
			table.insert(bullets, newBullet)
		end,
	[2] = function ()
			newBullet = {x = player.x + 10, y = player.y + 15, img = bullet1Img}
			table.insert(bullets, newBullet)
			newBullet1 = {x = player.x + (player.img:getWidth() - 10), y = player.y + 15, img = bullet1Img}
			table.insert(bullets, newBullet1)
		end,
	[3] = function ()
			newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
			table.insert(bullets, newBullet)
			newBullet1 = {x = player.x + 10, y = player.y + 15, img = bullet1Img}
			table.insert(bullets, newBullet1)
			newBullet2 = {x = player.x + (player.img:getWidth() - 20), y = player.y + 15, img = bullet1Img}
			table.insert(bullets, newBullet2)
		end,
}
