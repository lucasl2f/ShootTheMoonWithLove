
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
weaponsAmmo = {}

--Timers
canShoot = true
canShootTimerMax = 0.2
canShootTimer = canShootTimerMax
createEnemyTimerMax = 0.8
createEnemyTimer = createEnemyTimerMax
playerBlinkTimerMax = 0.1
playerBlinkTimer = playerBlinkTimerMax
playerBlinkQuantityMax = 20
playerBlinkQuantity = playerBlinkQuantityMax
playerTookDamage = false
playerHideGraphic = false

-- weapon cooldown
cooldownTimerThreshold = 3
cooldownTimer = 0

--Image Storage
bulletImg = nil
enemyImg = nil

-- Entity Storage
bullets = {}
enemies = {}

-- Background
bgSpeed = 100
bgMargin = 10

p1joystick = nil
joystickAxis = {x = 0, y = 0}

function love.load ()
	player = {x = 200, y = 710, speed = 200, img = nil}
	player.img = love.graphics.newImage('Assets/Aircrafts/Aircraft_03.png')
	weaponsAmmo = {w1 = nil, w2 = 30, w3 = 10}

	bulletImg = love.graphics.newImage('Assets/Bullets/bullet_2_blue.png')
	bullet1Img = love.graphics.newImage('Assets/Bullets/bullet_2_orange.png')

	enemyImg = love.graphics.newImage('Assets/Aircrafts/enemy.png')
	enemy = {x = 0, y = 0, img = enemyImg, randomFactor = 0}

	background1 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background1.png')}
	background2 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background2.png')}
	background3 = {x = 0, y = 0, img = love.graphics.newImage('Assets/Backgrounds/background3.png')}
	background1.y = love.graphics:getHeight() - background1.img:getHeight()
	background2.y = background1.y - background2.img:getHeight() + bgMargin
	background3.y = background2.y - background3.img:getHeight() + bgMargin * 2

	--animation rotor
	animation = newAnimation(love.graphics.newImage("Assets/Aircrafts/rotorSheet.png"), 48, 8, 0.2)
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
		if not playerHideGraphic then
			if playerTookDamage then
				love.graphics.setColor(230, 10, 10)
			else
				love.graphics.setColor(255, 255, 255)
			end
			love.graphics.draw(player.img, player.x, player.y)
			
			--animation rotor
			local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
			love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], player.x + player.img:getWidth() / 2 - 24, player.y, 0, 1)
		end

		love.graphics.setColor(255, 255, 255)
		if weaponIndex == 2 and weaponsAmmo.w2 == 0 then
			love.graphics.print("Weapon 2 is out of ammo!", love.graphics:getWidth()/2 - 50, love.graphics:getHeight()/2-10)
		elseif weaponIndex == 3 and weaponsAmmo.w3 == 0 then
			love.graphics.print("Weapon 3 is out of ammo!", love.graphics:getWidth()/2 - 50, love.graphics:getHeight()/2-10)
		end
	else
		love.graphics.print("Press 'R' of 'back' to play", love.graphics:getWidth()/2 - 50, love.graphics:getHeight()/2-10)
	end

	love.graphics.rectangle('line', 5, 5, 120, 80)

	-- left info
	love.graphics.print("Score: " .. tostring(score), 10, 10)
	love.graphics.print("Lives: " .. tostring(lives), 10, 30)
	love.graphics.print("Ammo: ~, " .. tostring(weaponsAmmo.w2) .. ", " .. tostring(weaponsAmmo.w3), 10, 50)

	if cooldownTimer > cooldownTimerThreshold then
		love.graphics.setColor(230, 10, 10)
	else
		love.graphics.setColor(255, 255, 255)
	end
	love.graphics.print("Cooldown: " .. string.format("%.1f", tostring(cooldownTimer)), 10, 70)

	-- right info
	love.graphics.setColor(255, 255, 10)
	love.graphics.printf("active bullets: " .. table.getn(bullets), love.graphics:getWidth() - 130, 10, 120, "right")
	love.graphics.printf("active enemies: " .. table.getn(enemies), love.graphics:getWidth() - 130, 30, 120, "right")
	love.graphics.printf("fps: " .. tostring(love.timer.getFPS()), love.graphics:getWidth() - 130, 50, 120, "right")
end

function love.joystickadded(joystick)
	p1joystick = joystick
end

function love.update (dt)
	--exit game
	if love.keyboard.isDown('escape') or (p1joystick ~= nil and p1joystick:isGamepadDown('start')) then
		love.event.push('quit')
	end

	--movement
	if p1joystick ~= nil then
		joystickAxis.x = p1joystick:getGamepadAxis("leftx")
		--joystickAxis.y = p1joystick:getGamepadAxis("lefty")
	end

	if isAlive then
		if love.keyboard.isDown('left', 'a') or joystickAxis.x < -0.2 then
			if (player.x > 0) then
				player.x = player.x - (player.speed * dt)
			end
		elseif love.keyboard.isDown('right', 'd') or joystickAxis.x > 0.2 then
			if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
				player.x = player.x + (player.speed * dt)
			end
		end
	end

	-- damage
	if playerTookDamage then
		playerBlinkTimer = playerBlinkTimer - (1* dt)
		if playerBlinkTimer < 0 then
			playerBlinkTimer = playerBlinkTimerMax
			playerBlinkQuantity = playerBlinkQuantity - 1
			playerHideGraphic = not playerHideGraphic
			
			if playerBlinkQuantity <= 0 then
				playerTookDamage = false
				playerHideGraphic = false
				playerBlinkQuantity = playerBlinkQuantityMax
			end
		end
	end

	-- shoot
	if isAlive then
		canShootTimer = canShootTimer - (1 * dt)
		if canShootTimer < 0 and cooldownTimer < cooldownTimerThreshold then
			canShoot = true
		end

		if cooldownTimer > 0 then
			cooldownTimer = cooldownTimer - (1*dt)
		else
			cooldownTimer = 0
		end

		if love.keyboard.isDown('space', 'rctrl', 'lctrl', 'ctrl') and canShoot then
			--newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
			--table.insert(bullets, newBullet)
			ShootWeapon[weaponIndex]()
		end

		if love.mouse.isDown (1) and canShoot then
			ShootWeapon[weaponIndex]()
		end

		if p1joystick ~= nil then
			if p1joystick:isGamepadDown('x') and canShoot then
				ShootWeapon[1]()
			end

			if p1joystick:isGamepadDown('y') and canShoot then
				ShootWeapon[2]()
			end

			if p1joystick:isGamepadDown('b') and canShoot then
				ShootWeapon[3]()
			end
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
			newEnemy = {x = randomNumber, y = -10, img = enemyImg, randomFactor = math.random(-100, 100)}
			table.insert(enemies, newEnemy)
		end
	end

	for i, enemy in ipairs(enemies) do
		enemy.y = enemy.y + (200 + enemy.randomFactor) * dt

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

		if not playerTookDamage then
			if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) then
				table.remove(enemies, i)
				lives = lives - 1
				playerTookDamage = true
				playerHideGraphic = true

				if lives == 0 then
					isAlive = false
				end
			end
		end
	end

	-- restart
	if not isAlive then
		if love.keyboard.isDown('r') or (p1joystick ~= nil and p1joystick:isGamepadDown('back')) then
			RestartGame()
		end
	end

	-- background
	if isAlive then
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

	-- animation
	animation.currentTime = animation.currentTime + dt
	if animation.currentTime >= animation.duration then
		animation.currentTime = animation.currentTime - animation.duration
	end
end

function RestartGame () 
	bullets = {}
	enemies = {}

	canShootTimer = canShootTimerMax
	createEnemyTimer = createEnemyTimerMax
	canShoot = true
	playerBlinkTimer = playerBlinkTimerMax
	playerBlinkQuantity = playerBlinkQuantityMax
	playerTookDamage = false
	playerHideGraphic = false

	player.x = 50
	player.y = 710

	score = 0
	isAlive = true
	lives = livesMax

	background1.y = love.graphics:getHeight() - background1.img:getHeight()
	background2.y = background1.y - background2.img:getHeight() + bgMargin
	background3.y = background2.y - background3.img:getHeight() + bgMargin * 2
end

-- animation
function newAnimation(image, width, height, duration)
	local animation = {}
	animation.spriteSheet = image
	animation.quads = {}

	for y = 0, image:getHeight() - height, height do
		for x = 0, image:getWidth() - width, width do
			table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
		end
	end

	animation.duration = duration or 1
	animation.currentTime = 0

	return animation
end

-- change weapon
ShootWeapon = {
	[1] = function ()
			canShoot = false
			canShootTimer = canShootTimerMax
			cooldownTimer = cooldownTimer + 0.7
			newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
			table.insert(bullets, newBullet)
		end,
	[2] = function ()
			if weaponsAmmo.w2 > 0 then
				canShoot = false
				canShootTimer = canShootTimerMax
				cooldownTimer = cooldownTimer + 1
				newBullet = {x = player.x + 10, y = player.y + 15, img = bullet1Img}
				table.insert(bullets, newBullet)
				newBullet1 = {x = player.x + (player.img:getWidth() - 10), y = player.y + 15, img = bullet1Img}
				table.insert(bullets, newBullet1)
				weaponsAmmo.w2 = weaponsAmmo.w2 - 1
			end
		end,
	[3] = function ()
			if weaponsAmmo.w3 > 0 then
				canShoot = false
				canShootTimer = canShootTimerMax
				cooldownTimer = cooldownTimer + 1.2
				newBullet = {x = player.x + (player.img:getWidth()/2 - bulletImg:getWidth()/2), y = player.y, img = bulletImg}
				table.insert(bullets, newBullet)
				newBullet1 = {x = player.x + 10, y = player.y + 15, img = bullet1Img}
				table.insert(bullets, newBullet1)
				newBullet2 = {x = player.x + (player.img:getWidth() - 20), y = player.y + 15, img = bullet1Img}
				table.insert(bullets, newBullet2)
				weaponsAmmo.w3 = weaponsAmmo.w3 - 1
			end
		end,
}
