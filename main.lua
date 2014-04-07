function love.load()
  GravitationConstant = 1500
  VelocityFactor = 3.0

  Press = {}
  Bodies = {}

  local width, height = love.window.getDimensions()

  Sun = {
    position = {x = width / 2, y = height / 2},
    mass = 10000}

  love.graphics.setColor(0, 0, 0)
  love.graphics.setBackgroundColor(255, 255, 255)
  love.graphics.setLineStyle("smooth")

  love.window.setTitle("Orbital")
end

function dist(x1, y1, x2, y2)
  return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function updateAcceleration(body)
  local r = dist(
    Sun.position.x, Sun.position.y,
    body.position.x, body.position.y)

  local a = Sun.mass * GravitationConstant / (r^2)

  local x = (Sun.position.x - body.position.x)
  local y = (Sun.position.y - body.position.y)

  local hypotenuse = math.sqrt(x^2 + y^2)

  body.acceleration.x = a * x / hypotenuse
  body.acceleration.y = a * y / hypotenuse
end

function updateVelocity(dt, body)
  body.velocity.x = body.velocity.x + dt * body.acceleration.x
  body.velocity.y = body.velocity.y + dt * body.acceleration.y
end

function updatePosition(dt, body)
  body.position.x = body.position.x + dt * body.velocity.x
  body.position.y = body.position.y + dt * body.velocity.y
end

function love.update(dt)
  for _, body in ipairs(Bodies) do
    updateAcceleration(body)
    updateVelocity(dt, body)
    updatePosition(dt, body)
  end
end

function drawBody(body)
  love.graphics.circle("fill", body.position.x, body.position.y, body.mass^(1/3), 50)
end

function love.draw()
  if love.mouse.isDown("l") then
    local x, y = love.mouse.getPosition()
    love.graphics.line(Press.x, Press.y, x, y)
  end

  drawBody(Sun)

  for _, body in ipairs(Bodies) do
    drawBody(body)
  end
end

function love.mousepressed(x, y, button)
  Press = {x = x, y = y}
end

function love.mousereleased(x, y, button)
  local xvel, yvel = (x - Press.x) * VelocityFactor, (y - Press.y) * VelocityFactor

  Bodies[#Bodies + 1] = {
    position = {x = Press.x, y = Press.y},
    velocity = {x = xvel, y = yvel},
    acceleration = {x = 0, y = 0},
    mass = 25}
end
