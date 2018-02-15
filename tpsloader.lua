-- 
--  tpsloader.lua
--  moai-dev
--  
--  Created by Zipline Games.
--  Distributed under CPAL license (http://www.opensource.org/licenses/cpal_1.0).
-- 

function tpsloader(lua, png, normal_png)
    local frames = dofile ( lua ).frames
    -- workaround for weird bug with UVQuad that misses the first frame, so insert a dummy frame
    table.insert(frames, 1, frames[1]) 
    frames[1].name = "dummy.png"
    
        -- Construct the deck
    local deck = MOAISpriteDeck2D.new ()
    
    if normal_png then
      local diffuse = MOAITexture.new ()
      diffuse:load ( png )

      local normal = MOAITexture.new ()
      normal:load ( normal_png )
            
      deck:setTexture ( 1, 1, diffuse )
      deck:setTexture ( 1, 2, normal )
    else
      tex = MOAITexture.new ()
      tex:load ( png )
      
      deck:setTexture ( tex )
    end

    -- Annotate the frame array with uv quads and geometry rects
    for i, frame in ipairs ( frames ) do
        -- convert frame.uvRect to frame.uvQuad to handle rotation
        local uv = frame.uvRect
        local q = {}
        if not frame.textureRotated then
            -- From Moai docs: "Vertex order is clockwise from upper left (xMin, yMax)"
            q.x0, q.y0 = uv.u0, uv.v0
            q.x1, q.y1 = uv.u1, uv.v0
            q.x2, q.y2 = uv.u1, uv.v1
            q.x3, q.y3 = uv.u0, uv.v1
        else
            -- Sprite data is rotated 90 degrees CW on the texture
            -- u0v0 is still the upper-left
            q.x3, q.y3 = uv.u0, uv.v0
            q.x0, q.y0 = uv.u1, uv.v0
            q.x1, q.y1 = uv.u1, uv.v1
            q.x2, q.y2 = uv.u0, uv.v1
        end
        frame.uvQuad = q

        -- convert frame.spriteColorRect and frame.spriteSourceSize
        -- to frame.geomRect.  Origin is at x0,y0 of original sprite
        local cr = frame.spriteColorRect
        local r = {}
        r.x0 = cr.x
        r.y0 = cr.y
        r.x1 = cr.x + cr.width
        r.y1 = cr.y + cr.height
        frame.geomRect = r
    end

    deck:reserveQuads ( #frames )
    local names = {}
    local sizes = {}
    for i, frame in ipairs ( frames ) do
        local q = frame.uvQuad
        local r = frame.geomRect
        names[frame.name] = i
        sizes[frame.name] = frame.spriteSourceSize
        deck:setUVQuad ( i, q.x0,q.y0, q.x1,q.y1, q.x2,q.y2, q.x3,q.y3 )
        deck:setRect ( i, r.x0,r.y0, r.x1,r.y1 )
        deck:setUVRect ( 1, 1, 1, 1, 1)
    end

    return deck, names, sizes
end