

require "config"
require 'tpsloader'
require 'spriter'
require "rapanui-sdk.rapanui"
require "shaders"

function loadScene(playerCoords, playerScale)         
  backSprite, backSpriteDeck = RNFactory.createImage("beach.jpg", {top=0})  
  backSprite.prop:setPriority(0)
  
  local playerx = playerCoords[1]         
  local playery = playerCoords[2]
  
  playerScale[1] = playerScale[1] / config.unStretchRatio
  gfxQuads, names, sizes = tpsloader ( 'mainchar_pieces.lua', 'mainchar_pieces.png', 'mainchar_pieces_n.png' )
  playerSprite = spriter("main_char.lua", gfxQuads, names, nil, sizes)
  
  playerAnims = {}
  
  firstAnim = "stand"  
  playerAnims["stand"] = playerSprite:createAnim ( "Stand", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["stand"]:insertPropsRN()
  playerAnims["standUp"] = playerSprite:createAnim ( "Stand_away", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["standUp"]:insertPropsRN()
  playerAnims["standDown"] = playerSprite:createAnim ( "Stand_towards", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["standDown"]:insertPropsRN()
  playerAnims["walkSideways"] = playerSprite:createAnim ( "Walk", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["walkSideways"]:insertPropsRN()
  playerAnims["walkSidewaysUp"] = playerSprite:createAnim ( "Walk_away", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["walkSidewaysUp"]:insertPropsRN()
  playerAnims["walkSidewaysDown"] = playerSprite:createAnim ( "Walk_towards", playerx, playery, playerScale[1], playerScale[2] )
  playerAnims["walkSidewaysDown"]:insertPropsRN()
  
  lastAnim = "walkSidewaysDown"

  lighting= {light_x=1.0, light_y=1.0, light_z=0.3, intensity=1.2, range=2.5, color={0.77, 0.80, 1.0}, ambient_color={1.0, 1.0, 1.15}}
  shader = point_lighting_shader_desktop(lighting.light_x,lighting.light_y,lighting.light_z,lighting.intensity,lighting.range,lighting.color[1],lighting.color[2],lighting.color[3],lighting.ambient_color[1],lighting.ambient_color[2],lighting.ambient_color[3], lighting.move_with_player, false)
  
  gfxQuads:setShader(shader)
  
  player = playerAnims["stand"]
  player.name = "stand"

  player:start () 
  
  RNListeners:addEventListener("touch", screen_touch)
end

function setPlayerDirection()   
  local xs, ys = player.root:getScl()
  local currentX, currentY = player.root:getLoc()
  print("xs " .. xs .. ", ys " .. ys)
  if player.hastarget then                  
    if player.targetx > currentX then
      if xs < 0 then            
        player.root:setScl(-xs,ys)        
      end
    elseif player.targetx < currentX then
      if xs > 0 then
        player.root:setScl(-xs,ys)
      end
    end      
  end
end

function movePlayerToTarget(moveAnim) 
  if player ~= nil then
    local currentX, currentY = player.root:getLoc()   
    local xs, ys = player.root:getScl() 

    if player.targetx ~= nil and player.targety ~= nil and currentX ~= nil and currentY ~= nil then    
      while true do 
        currentX, currentY = player.root:getLoc()
        if player ~= nil and player.targetx ~= nil and player.targety ~= nil and currentX ~= nil and currentY ~= nil and (math.abs(currentX - player.targetx) <= 7 and math.abs(currentY - player.targety) <= 145*(-ys)) then
          break
        end
        coroutine:yield()
      end
      if player ~= nil then
        player.hastarget = false        
      end
    end
    setPlayerStandAnimation()
  end
end

function setPlayerStandAnimation()
  if player ~= nil then
    if player.moveDirection == "up" then   
      switchPlayerAnim("standUp")
    elseif player.moveDirection == "down" then
      switchPlayerAnim("standDown")
    else
      switchPlayerAnim("stand")
    end
    player.hastarget = false
  end
end

function doMove(x, y, speed, moveAnim, timeToDest) 
  setPlayerDirection()
  if(playerThread ~= nil) then
    playerThread:stop()
    playerThread = nil
  end
  playerThread = MOAICoroutine.new ()
  playerThread:run ( movePlayerToTarget , moveAnim )
end

function switchPlayerAnim(moveAnim)
  local currentX, currentY = player.root:getLoc() 
  local xs, ys = player.root:getScl() 
  player:stop()  
  for i=1, table.getn(player.rnprops) do
    player.rnprops[i]:setVisible(false)
  end  
  local moveDirection = player.moveDirection
  player = playerAnims[moveAnim]
  player.moveDirection = moveDirection
  player.root:seekLoc(currentX, currentY, 0, 0) 
  player.root:setScl(xs, ys) 
  for i=1, table.getn(player.rnprops) do
    player.rnprops[i]:setVisible(true)
  end
  player.name = moveAnim
  player:throttle(.8)
  player:start()
end

function movePlayerTo(x,y,speed,moveAnim)  
  if player ~= nil then
    local xs, ys = player.root:getScl()
    local currentX, currentY = player.root:getLoc()   
    local xDiff = math.abs(currentX - x)
    local yDiff = currentY + (140 * math.abs(ys))  - y
    local totalDist = math.sqrt((xDiff^2)+(yDiff^2))
    timeToDest = totalDist / (speed * 1.2)
    local moveAngleRad = math.atan2(yDiff, xDiff)
    player.moveDirection = "side"
    if moveAnim == "walkSideways" and moveAngleRad < -.3 then 
      moveAnim = "walkSidewaysDown"
      player.moveDirection = "down"
    elseif moveAnim == "walkSideways" and moveAngleRad > .3 then 
      moveAnim = "walkSidewaysUp"
      player.moveDirection = "up"
    end
    
    if player.name ~= moveAnim then
      switchPlayerAnim(moveAnim)
    end
    if moveAction ~= nil then
      moveAction:pause()
    end
    moveAction = player.root:seekLoc(x, y-(140 * math.abs(ys)), 0, timeToDest, MOAIEaseType.LINEAR) 
    
    if (x ~= currentX or y ~= currentY) then
      player.targetx = x
      player.targety = y
      player.hastarget = true
    end
    
    doMove(x, y, speed, moveAnim, timeToDest)
  end
end

function rnApplyShader(rnobj, shader)
  for i=1, table.getn(rnobj.rnprops) do
    rnobj.rnprops[i].prop:setShader(shader)
  end  
end

--handling touch
function screen_touch(event)
  mx = event.x
  my = event.y
  if event.phase == "ended" then
     movePlayerTo(mx,my+145,300,"walkSideways")
  end
end

loadScene({800,680}, {-1.0,-1.0})