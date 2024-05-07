love.graphics.setDefaultFilter( "nearest", "nearest",1 )


W, H = 100,75

timeStep = 0.001

windowW = 800  --real viewportSize
windowH = 600

wScale = 1 / ( W / windowW )
hScale = 1 / ( H / windowH )

lifeCanvas = love.graphics.newCanvas(W, H)

markupCanvas = love.graphics.newCanvas(W, H)

bufferCanvas = love.graphics.newCanvas(W, H)

pent = function(x,y)
    love.graphics.points(x,y,x,y+1,x,y+2, x+1,y+1, x-1,y+2)
end

glider = function(x,y)
    love.graphics.points(x-1, y+1, x, y+1, x+1, y + 1, x+1, y, x, y -1)
end

randomFill = function(pattern, num)
    for i = 1, num do 
        pattern(math.random( 1, W),math.random( 1, H) )
    end
end



inititialDraw = function()
    love.graphics.setColor(1,1,1,1)
    randomFill(glider, 10)
    randomFill(pent, 2)
end

   lifeCanvas:renderTo( inititialDraw )

editMarkup = love.graphics.newShader [[
    extern Image TEX;
    extern float cw;
    extern float ch;

    const vec4 DEAD_COLOR = vec4(1., 0., 0., 1.);
    const vec4 LIVE_COLOR = vec4(0., 1., 0., 1.);
    const vec4 EMPTY = vec4(0., 0., 0., 0.);
    const vec4 ALIVE = vec4(1., 1., 1., 1.);

    vec4 getColorOfNeighbour(Image texture,vec2 pixel_coords) {
        vec2 coords = pixel_coords;
        if ( coords.x <= 0) {
            coords.x = cw - coords.x;
        }
        if ( coords.x >= 1.) {
            coords.x = coords.x - 1.;
        }
        if ( coords.y <= 0) {
            coords.y = ch - coords.y;
        }
        if ( coords.y >= 1.) {
            coords.y = coords.y - 1.;
        }
        vec4 texturecolor = Texel(texture, coords);
        return texturecolor;
    }

    float countNeighbours(Image texture,vec2 pixel_coords) {
        float result = 0.;
        
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(-1. / cw,-1. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(0. / cw,-1. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(1. / cw ,-1. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(1. / cw , 0. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(1. / cw ,1. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(0. / cw ,1. / ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(-1. / cw,1. /ch)) == ALIVE  ) {
            result++ ;
        }
        if (getColorOfNeighbour(texture ,pixel_coords + vec2(-1./ cw ,0.  / ch)) == ALIVE  ) {
            result++ ;
        }
       

        return result;
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
            float count = countNeighbours( TEX, texture_coords);
            vec4 texturecolor = Texel(texture, texture_coords);
            if ( (count > 3. || count < 2.  ) && texturecolor != EMPTY) {
               return DEAD_COLOR;
            }
             if ( count == 3.  && texturecolor != ALIVE) {
               return LIVE_COLOR;
            }
            return texturecolor;
        }
]]

handleMarkup = love.graphics.newShader [[
    extern Image TEX;
    const vec4 DEAD_COLOR = vec4(1., 0., 0., 1.);
    const vec4 LIVE_COLOR = vec4(0., 1., 0., 1.);
    const vec4 EMPTY = vec4(0., 0., 0., 0.);
    const vec4 ALIVE = vec4(1., 1., 1., 1.);
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
            vec4 texturecolor = Texel(TEX, texture_coords);

            if(texturecolor ==  DEAD_COLOR) {
                texturecolor = EMPTY;
            } else if(texturecolor ==  LIVE_COLOR) {
                 texturecolor = ALIVE;
            }
            return texturecolor;
        }
    ]]
function love.load()

end

local function markupFrame()
    editMarkup:send( "TEX", lifeCanvas )
    love.graphics.setShader(editMarkup)
    love.graphics.draw(lifeCanvas);
    love.graphics.setShader()
end

local function fullRender()
    local current_canvas1 = love.graphics.getCanvas()
    love.graphics.setCanvas(bufferCanvas)
    ------------------------------------------------
    ------------------------------------------------
    local current_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(markupCanvas)
    --love.graphics.clear( 0,0,0,0 )
    
    ------------------------------------------------
    editMarkup:send( "TEX", lifeCanvas )
    editMarkup:send( "cw", W )
    editMarkup:send( "ch", H )
    love.graphics.setShader(editMarkup)
    love.graphics.draw(lifeCanvas);
    love.graphics.setShader()
    ------------------------------------------------
    love.graphics.setCanvas(current_canvas)
    handleMarkup:send( "TEX", markupCanvas )
    love.graphics.clear( 0,0,0,0 )
    love.graphics.setShader(handleMarkup)
    love.graphics.draw(markupCanvas);
    love.graphics.setShader()

    ------------------------------------------------
    ------------------------------------------------
    love.graphics.setCanvas(current_canvas1)


    love.graphics.print(love.timer.getFPS())
   
    love.graphics.scale(wScale,hScale)


    love.graphics.draw(bufferCanvas);

    lifeCanvas = bufferCanvas

    

end


function love.draw()
    fullRender()
end


function love.update(dt)

end


function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
	--	if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer and timeStep > 0 then love.timer.sleep(timeStep) end
	end
end