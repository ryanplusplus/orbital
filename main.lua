GravitationConstant = 2
VelocityFactor = 2.0
RadiusFactor = 0.33
DtLimit = 0.02

CreationMass = 10
Press = {}
Bodies = {}

function love.load()
  love.graphics.setColor(0, 0, 0)
  love.graphics.setBackgroundColor(255, 255, 255)
  love.graphics.setLineStyle("smooth")

  love.window.setTitle("Orbital")
  love.window.setFullscreen(true, "desktop")

  math.randomseed(os.time())
end

function generateBodies()
  local width, height = love.window.getDimensions()

  for _ = 1, 250 do
    local x = math.random(-width / 2, 1.5 * width)
    local y = math.random(-height / 2, 1.5 * width)
    local xvel = 0
    local yvel = 0
    local radius = 1
    local mass = radiusToMass(radius)

    Bodies[#Bodies + 1] = {
      position = {x = x, y = y},
      velocity = {x = xvel, y = yvel},
      acceleration = {x = 0, y = 0},
      mass = mass,
      radius = radius}
  end
end

function radiusToMass(radius)
  return radius^3 * 4/3 * 3.14
end

function massToRadius(mass)
  return (mass * 3/4 / 3.14)^(1/3)
end

function dist(x1, y1, x2, y2)
  return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function bodyDist(body1, body2)
  return dist(body1.position.x, body1.position.y, body2.position.x, body2.position.y)
end

function colliding(body1, body2)
  return bodyDist(body1, body2) < math.max (body1.radius, body2.radius)
end

function tooFarAway(body)
  local width, height = love.window.getDimensions()

  return body.position.x > 3 * width
      or body.position.x < -2 * width
      or body.position.y > 3 * height
      or body.position.y < -2 * height
end

function merge(body1, body2)
  local newMass = body1.mass + body2.mass

  body1.velocity.x = (body1.mass * body1.velocity.x + body2.mass * body2.velocity.x) / newMass
  body1.velocity.y = (body1.mass * body1.velocity.y + body2.mass * body2.velocity.y) / newMass

  if body2.mass > body1.mass then
    body1.position = body2.position
  end

  body1.mass = newMass
  body1.radius = massToRadius(newMass)
end

function updateAcceleration(body, other)
  local r = dist(
    other.position.x, other.position.y,
    body.position.x, body.position.y)

  local a = other.mass * GravitationConstant / (r^2)

  local x = (other.position.x - body.position.x)
  local y = (other.position.y - body.position.y)

  local hypotenuse = math.sqrt(x^2 + y^2)

  body.acceleration.x = body.acceleration.x + a * x / hypotenuse
  body.acceleration.y = body.acceleration.y + a * y / hypotenuse
end

function updateVelocity(dt, body)
  body.velocity.x = body.velocity.x + dt * body.acceleration.x
  body.velocity.y = body.velocity.y + dt * body.acceleration.y
end

function updatePosition(dt, body)
  body.position.x = body.position.x + dt * body.velocity.x
  body.position.y = body.position.y + dt * body.velocity.y
end

function resetAcceleration(body)
  body.acceleration.x = 0
  body.acceleration.y = 0
end

function love.update(dt)
  dt = math.min(dt, DtLimit)

  for i, body in pairs(Bodies) do
    resetAcceleration(body)

    for j, other in pairs(Bodies) do
      if i ~= j then
        updateAcceleration(body, other)
      end
    end

    updateVelocity(dt, body)
    updatePosition(dt, body)
  end

  local deadBodies = {}

  for i, body in pairs(Bodies) do
    for j, other in pairs(Bodies) do
      if j > i then
        if colliding(body, other) then
          deadBodies[#deadBodies + 1] = j
          merge(body, other)
        end
      end
    end
  end

  for i, body in pairs(Bodies) do
    if tooFarAway(body) then
      deadBodies[#deadBodies + 1] = i
    end
  end

  for _, i in pairs(deadBodies) do
    Bodies[i] = nil
  end
end

function drawBody(body)
  love.graphics.circle("fill", body.position.x, body.position.y, body.radius, 50)
end

function love.draw()
  if love.mouse.isDown("l") then
    local x, y = love.mouse.getPosition()
    love.graphics.line(Press.x, Press.y, x, y)
  end

  if love.mouse.isDown("r") then
    local x, y = love.mouse.getPosition()
    local radius = dist(Press.x, Press.y, x, y)
    love.graphics.circle("fill", Press.x, Press.y, radius * RadiusFactor, 50)
  end

  for _, body in pairs(Bodies) do
    drawBody(body)
  end
end

function love.mousepressed(x, y, button)
  Press = {x = x, y = y}
end

function love.mousereleased(x, y, button)
  if button == "r" then
    local x, y = love.mouse.getPosition()
    local radius = dist(Press.x, Press.y, x, y) * RadiusFactor

    if radius > 0 then
      CreationMass = radiusToMass(radius)
    end
  end

  if button == "l" then
    local xvel, yvel = (x - Press.x) * VelocityFactor, (y - Press.y) * VelocityFactor

    Bodies[#Bodies + 1] = {
      position = {x = Press.x, y = Press.y},
      velocity = {x = xvel, y = yvel},
      acceleration = {x = 0, y = 0},
      mass = CreationMass,
      radius = massToRadius(CreationMass)}
  end
end

function love.keypressed(key, isrepeat)
  if key == "g" and not isrepeat then
    generateBodies()
  end

  if key == "r" and not isrepeat then
    Bodies = {}
  end
end
