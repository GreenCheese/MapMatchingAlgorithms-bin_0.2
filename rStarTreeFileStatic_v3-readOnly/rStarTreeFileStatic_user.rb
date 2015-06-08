#encoding: utf-8
puts "LOADING \"#{__FILE__}\"..."
require 'thread'

$:.unshift(File.dirname(__FILE__))
require 'fTeeSL_user.rb'

$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'point.rb'

Latitude_factor = 111.1329
Longitude_factor = 63.85

class MBR 
	attr_accessor :left
	attr_accessor :right

	def isPointInside(point, radiusKm)
		isInsideFlag = false
		nlx = @left.x - radiusKm/Longitude_factor
 		nly = @left.y - radiusKm/Latitude_factor
 		nrx = @right.x + radiusKm/Longitude_factor
 		nry = @right.y + radiusKm/Latitude_factor

 		if(point.x>=nlx and point.x<=nrx and point.y>nly and point.y<nry)
 			isInsideFlag = true
 		end
 		return isInsideFlag
	end
end

class Segment
	:pointsArr
	:externalID #External
	:index #internal
	:f_speedLim
	:t_speedlim
	:oneway
	:f_buslanes
	:t_buslanes
	:featlen
	:fzlev
	:tzlev
	
	def marshal_load array
		@pointsArr, @externalID, @index, @f_speedLim, @t_speedlim, @oneway, @f_buslanes, @t_buslanes, @featlen, @fzlev, @tzlev = array
	end
	
	def getPoints
		return @pointsArr
	end
end

class RStarTreeNode
	def marshal_load array
		@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size = array
	end

	attr_accessor :n
	attr_accessor :mbr
	attr_accessor :pointer
	attr_accessor :parent

	attr_accessor :leaf # = TRUE - лист, FALSE - внутренний узел
	attr_accessor :level #уровень узла в дереве (0=лист)
	attr_accessor :loadedAtRAM
	attr_accessor :pointer_size
end

class RTreeObject < RStarTreeNode
	attr_accessor :data
	attr_accessor :data_size

	def marshal_load array
		@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size, @data, @data_size = array
	end
end

class RStarTree
	attr_accessor :root
	attr_accessor :root_offset
	attr_accessor :root_size
	attr_accessor :m
	attr_accessor :M
	:treeLoader

	def setLoader(tl)
		@treeLoader = tl
	end

	def marshal_load array
		@nextFreeStructOffset, @nextFreeDataOffset, @m, @M, @root_offset, @root_size = array
	end

	def loadChildren(node) 
		if (node.loadedAtRAM)
			return
		end
		for i in 0..node.n-1
			@treeLoader.commonLoadChild(node.pointer[i], node.pointer_size[i], node, i)
			#TreeLoad.commonLoadChild(node.pointer[i], node.pointer_size[i], node, i)
		end
		node.loadedAtRAM = true
	end

	def findSegmentsNearPoint(pt, radiusKm)
		puts "SEARCHER SERVER: LAST REQUEST AT #{Time.now}"
		#f = File.new("log_srv", "a")
		bt = Time.now
		#str = "point = #{pt.x};#{pt.y}\tradius = #{radiusKm}\nBT = #{bt}"
		#f.write(str)
		
		finedSegments = []
 		q = Queue.new
		q.push(self.root)
		while (!q.empty?)
			node = q.pop
			if (node.level!=-1)
				if(node.mbr.isPointInside(pt,radiusKm))
					loadChildren(node)
					for i in 0..node.n-1
						q.push(node.pointer[i])
					end
				end
			else
				if (node.mbr.isPointInside(pt,radiusKm))
					finedSegments << node.data
				end
			end
		end
		et = Time.now
		#str = "\nDT = #{et-bt}\t cntRes = #{finedSegments.size}\n\n"
		puts "time = #{et-bt}"
		#f.write(str)
		#f.close
		#return Marshal.dump(finedSegments)
		puts "timeNow = #{Time.now}"
		#return DRbObject.new(finedSegments)
		return finedSegments

	end
end