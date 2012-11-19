require 'rubygems'
require 'gosu'
include Gosu

module Tiles
	Grass = 0
	Earth = 1
end

class Object
	attr_reader :x, :y, :xoffset, :yoffset
end

class Enemy
	attr_reader :x, :y
	def iniitalize(image, x, y)
		@image = image
		@x, @y = x, y
	end
	def draw
		if @dir == 1 then
			offset_x = -@image.width/2
		end
		if @dir == 1 then
			offset_x = @image.width/2
		end
	end
end

class Player
	attr_reader :x, :y
	def initialize(window, x, y)
		@x, @y = x, y
		@gameWindow=window
		@map = @gameWindow.map
		@dir = 1 #1 = left
		@xvelocity = @yvelocity = @jump = @air = @up = 0
		@standing, @walk1, @walk2, @jumping =
			*Image.load_tiles(window, "media/CptnRuby.png", 50, 50, false)
		@cur_image = @standing
	end
	def draw
		if @dir == 1 then
			offs_x = -@cur_image.width/2 #(change to 1/2 width)
		else
			offs_x = @cur_image.width/2
		end
		@cur_image.draw(@x + offs_x, @y-49, 0, @dir, 1.0)
	end

	def right
		if (@dir == 1) 
			@dir = -1
		end
		if (@air > 0)
			@xvelocity += 0.75
		else
			@xvelocity += 1
		end
	end
	def left
		if (@dir == -1) 
			@dir = 1
		end
		if (@air > 0)
			@xvelocity -= 0.75
		else
			@xvelocity -= 1
		end
	end
	def jump
		if @map.solid?(@x+11, @y+1) or @map.solid?(@x-11, @y+1) then
			@cur_image = @jumping
			if @jump == 0
				@jump = 1
				@air = 1
				@up = 1
				@yvelocity = 10
			end
			
		end

		if @jump == 1 && @yvelocity > 0
			@yvelocity += 0.6
		end
	end
	def gravity
		if @map.solid?(@x+11, @y + 1) or @map.solid?(@x-11, @y+1) then
			@jump = 0	
			@air = 0
		else
			@air = 1
		end
		if @air == 1
			if (@yvelocity > -8)
				@yvelocity -= 1
			end
			if (@yvelocity < -8)
				@yvelocity = -8
			end
		end
	end
	def map_check(offs_x, offs_y)
		not @map.solid?(@x + offs_x+12, @y + offs_y) and
		not @map.solid?(@x + offs_x+12, @y + offs_y - 44) and
		not @map.solid?(@x + offs_x-12, @y + offs_y) and
		not @map.solid?(@x + offs_x+12, @y + offs_y - 25) and
		not @map.solid?(@x + offs_x-12, @y + offs_y - 25) and
		not @map.solid?(@x + offs_x-12, @y + offs_y - 44)
	
	end
		
	def update
		if @xvelocity > 0 then
			#@x += @xvelocity

			(@xvelocity.round).times { if map_check(1, 0) then @x += 1 end }
			if not map_check(0,0)
				@xvelocity *= 0.5
			end
			until map_check(0, 0)
				@x -=2
			end
		end
		if @xvelocity < 0 then			
			#@x += @xvelocity
			(-@xvelocity.round).times { if map_check(-1, 0) then @x -= 1 end }
			if not map_check(0,0)
				@xvelocity *= 0.5
			end
			until map_check(0, 0)
				@x +=2
			end
		end
		if @air == 0
			@xvelocity *= 0.85
			@yvelocity *= 0.7
		else
			@xvelocity *= 0.9
		end

		if (@air == 1)
			@y -= @yvelocity
			if not map_check(0, 0)
				@yvelocity *= 0.5
			end
			until map_check(0, 0)
				if @yvelocity > 0
					@y += 2
				else
					@y -= 2
				end
			end
		end
		if @xvelocity == 0
			@cur_image = @standing
		else
			@cur_image = (milliseconds / 175 % 2 == 0) ? @walk1 : @walk2
		end
	
		if @xvelocity.abs < 0.25
			@xvelocity = 0
		end
		if (@up == 10)
			@up = 0
		end
		if (@up > 0)
			@up += 1
		end
		gravity
	end
end

class Map
	attr_reader :width, :height, :hitbox_x, :hitbox_y
	def initialize(window, filename)
		#load tileset, run map
		loadMap(window, filename)
		

		#load monsters

		#load items

		#load npcs

	end
	def loadMap(window, filename)
		@tileset = Image.load_tiles(window, "media/CptnRuby Tileset.png", 25, 25, true)
		lines = File.readlines(filename).map { |line| line.chomp }
		@height = lines.size		
		@width = lines[0].size
		@tiles = Array.new(@width) do |x|
			Array.new(@height) do |y|
				case lines[y][x,1]
				when '"'
					Tiles::Grass
				when '#'
					Tiles::Earth
					
				when 'x'
					Tiles:: Grass #derp
					nil
				else
					nil
				end
			end
		end
		loadEnemies(window, filename)
	end
	def loadEnemies(window, filename)
		
	end
	def solid?(x, y)
		y < 0 || @tiles[x / 25][y / 25]
	end
	def draw
		@height.times do |y|
			@width.times do |x|
				tile = @tiles[x][y]
				if tile
						@tileset[tile].draw(x*25, y*25, 0)
				end
			end
		end
	end
end

class Game < Window
	attr_reader :map

	def initialize

		@gamestate = 1
		@windowx = 1080
		@windowy = 600

		super(@windowx, @windowy, false)
		#read setting file
		#parse height, weight
		@sky = Image.new(self, "media/Space.png", true)
		@map = Map.new(self, "media/CptnRuby Map.txt")
		@player = Player.new(self, 400, 100)
		@camera_x = @camera_y = 0
		#gamestate = 0 (menu)

	end
	def update
		#if gamestate == 0
			#menuscreen
		if @gamestate == 1
			gamescreen
			if button_down? Gosu::KbLeft then
				@player.left
			end
			if button_down? Gosu::KbRight then
				@player.right
			end
			if button_down? Gosu::KbUp then
				@player.jump
			end
			@player.update
		end
		#if gamestate == 2
			#pausescreen
		#if player hp <= 0 
			#dead screen
			#gamestate = 3
	end
	def loadmap
	end
	def menuscreen
	end
	def gamescreen
		@camera_x = [[@player.x - @windowx/2, 0].max, @map.width*25 - @windowx].min
		@camera_y = [[@player.y - @windowy/2, 0].max, @map.height*25 - @windowy].min
	end
	def pausescreen
	end
	def deadscreen
	end
	def draw
		@sky.draw 0, 0, 0
		translate(-@camera_x, -@camera_y) do
			@map.draw
			@player.draw
		end
	end
end

Game.new.show
