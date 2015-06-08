puts "LOADING \"#{__FILE__}\"..."
class Point 
	attr_accessor :x
	attr_accessor :y

	def initialize (x,y)
		@x = x.to_f
		@y = y.to_f
	end

	def isEqual (pt)
		if (pt.x==@x and pt.y==@y)
			return true
		end
	end

	def getCoordinates
		return [x,y]
	end

	def getPoints
		return [self]
	end
end

class IndexPoint < Point
	attr_accessor :index
	
	def initialize(x,y,i)
		@index = i
		super(x,y)
	end
end

class CrossSearchPiont < IndexPoint

	attr_accessor :segmentIndex
	attr_accessor :isSegmentPoint
	def initialize(x,y,i, si, isSegP)
		@isSegmentPoint = isSegP
		@segmentIndex = si
		super(x,y,i)
	end
end

class PointOfSegmentZ < Point
	attr_accessor :zLevel
	attr_accessor :oneway
	attr_accessor :isFirst
	attr_accessor :segmentIndex

	def initialize(x,y,z,ow,first,segindex)
		@zLevel = z
		@oneway = ow
		@isFirst = first
		@segmentIndex = []
		@segmentIndex << segindex
		super(x,y)
	end
end