c = document.getElementById('draw')
ctx = c.getContext('2d')

delta = 0
now = 0
before = Date.now()


c.width = window.innerWidth
c.height = window.innerHeight

keysDown = {}

window.addEventListener("keydown", (e) ->
    keysDown[e.keyCode] = true
, false)

window.addEventListener("keyup", (e) ->
    delete keysDown[e.keyCode]
, false)

setDelta = ->
    now = Date.now()
    delta = (now - before) / 1000
    before = now

player =
    x: c.width / 2
    y: c.height / 2
    dx: 0
    dy: 0
    angle: 0
    size: 10
    mass: 11
    speed: 100
    angularSpeed: 150
    minX: 0
    maxX: 385
    minY: 0
    maxY: 285
    color: '#222222'
    tail: []

random = (min, max) ->
    Math.random() * (max - min) + min

makeEnemy = (x, y, dir, size) ->
    x: x
    y: y
    dx: dir.x
    dy: dir.y
    speed: random(10, 60) + player.size
    size: size

moves = []

spawnEnemy = [
    (minSize, maxSize) ->
        x = Math.floor(Math.random() * c.width)
        angle = Math.random() * 90 - 45
        dir = rotate(0, 1, angle)
        size = random(minSize, maxSize)

        makeEnemy(x, -30, dir, size)

    (minSize, maxSize) ->
        x = Math.floor(Math.random() * c.width)
        angle = Math.random() * 90 - 45
        dir = rotate(0, -1, angle)
        size = random(minSize, maxSize)

        makeEnemy(x, c.height + 30, dir, size)

    (minSize, maxSize) ->
        y = Math.floor(Math.random() * c.height)
        angle = Math.random() * 90 - 45
        dir = rotate(1, 0, angle)
        size = random(minSize, maxSize)

        makeEnemy(-30, y, dir, size)

    (minSize, maxSize) ->
        y = Math.floor(Math.random() * c.height)
        angle = Math.random() * 90 - 45
        dir = rotate(-1, 0, angle)
        size = random(minSize, maxSize)

        makeEnemy(c.width + 30, y, dir, size)
]

enemies = []

toEnemy = 2
toToEnemy = 2
toToToEnemy = 10

ogre = false

clamp = (v, min, max) ->
    if v < min then min else if v > max then max else v

distance = (a, b) ->
    dx = b.x - a.x
    dy = b.y - a.y

    Math.sqrt(dx * dx + dy * dy)

collides = (a, b) ->
    distance(a, b) < (a.size + b.size)

enemyInside = (e, i) ->
    e.x >= players[i].minX and e.x <= players[i].maxX and e.y >= players[i].minY and e.y <= players[i].maxY

rotate = (x, y, angle) ->
    angle = angle * (Math.PI / 180)
    ds = Math.sin(angle)
    dc = Math.cos(angle)

    dx = x * dc - y * ds
    dy = x * ds + y * dc

    return { x: dx, y: dy }


speedMod = 60
elapsed = 0

update = ->
    setDelta()

    elapsed += delta

    angleDiff = 0

    if keysDown[65]
        angleDiff = -player.angularSpeed * delta
    if keysDown[68]
        angleDiff = player.angularSpeed * delta

    player.angle += angleDiff

    rotated = rotate(1, 0, player.angle)
    player.dx = rotated.x
    player.dy = rotated.y

    player.tail.push
        x: player.x
        y: player.y
        size: player.size
        ttl: 2

    player.x += player.dx * player.speed * delta
    player.y += player.dy * player.speed * delta

    i = 0
    while i < moves.length
        if moves[i].applied.length == player.tail.length
            moves.splice(i, 1)
        else
            i += 1

    for item in player.tail
        item.ttl -= delta

    toEnemy -= delta
    toToToEnemy -= delta

    if toEnemy <= 0
        enemy = spawnEnemy[Math.floor(random(0, 4))](player.size - 5, player.size + 5)
        enemies.push(enemy)

        toEnemy = toToEnemy

    if toToToEnemy <= 0
        toToEnemy = Math.max(toToEnemy - 0.1, 0.1)
        toToToEnemy = 4

    i = 0
    while i < enemies.length

        enemy = enemies[i]

        if collides(player, enemy)
            if enemy.size > player.size
                ogre = true
                break
            else

                enemies.splice(i, 1)
                player.size += 0.5

                enemy = spawnEnemy[Math.floor(random(0, 4))](player.size - 5, player.size + 5)
                enemies.push(enemy)
        else
            enemy.x += enemy.dx * enemy.speed * delta
            enemy.y += enemy.dy * enemy.speed * delta
            i += 1


    if player.x < player.size / 2 or
       player.y < player.size / 2 or
       player.x + player.size / 2 > c.width or
       player.y + player.size / 2 > c.height

        ogre = true

    draw(delta)

    if not ogre

        window.requestAnimationFrame(update)


draw = (delta) ->
    ctx.clearRect(0, 0, c.width, c.height)

    ctx.fillStyle = if ogre then 'rgba(100, 100, 100, 1.0)' else player.color
    ctx.beginPath()
    ctx.arc(player.x, player.y, player.size, 0, 2 * Math.PI)
    ctx.fill()

    for item in player.tail
        alpha = item.ttl / 2
        ctx.beginPath()
        ctx.arc(item.x, item.y, Math.max(alpha * item.size, 0), 0, 2 * Math.PI)
        ctx.fill()

    for enemy in enemies
        if enemy.size > player.size
            ctx.fillStyle = if ogre then 'rgba(0, 0, 0, 0.5)' else 'rgba(160, 0, 0, 0.5)'
        else
            ctx.fillStyle = if ogre then 'rgba(0, 0, 0, 0.5)' else 'rgba(0, 160, 0, 0.5)'
        ctx.beginPath()
        ctx.arc(enemy.x, enemy.y, enemy.size, 0, 2 * Math.PI)
        ctx.fill()

    ctx.font = '24px Visitor'
    ctx.fillStyle = '#000000'
    ctx.fillText('score: ' + Math.round(2 * (player.size - 10)), 20, 20)

    if ogre
        ctx.font = '140px Visitor'
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.fillStyle = '#000000'
        ctx.fillText('game over', c.width / 2, c.height / 2)


do ->
    w = window
    for vendor in ['ms', 'moz', 'webkit', 'o']
        break if w.requestAnimationFrame
        w.requestAnimationFrame = w["#{vendor}RequestAnimationFrame"]

    if not w.requestAnimationFrame
        targetTime = 0
        w.requestAnimationFrame = (callback) ->
            targetTime = Math.max targetTime + 16, currentTime = +new Date
            w.setTimeout (-> callback +new Date), targetTime - currentTime


update()
