#класс реализует собой путь, которое ТС проехало в определенное время от одной точки до другой.


class RoadPath
	:point1
	:point2
	:point1Time
	:point2Time
	:segArray
	:velocity
	:pathLen

	def initialize
		@segArray = []
		@point1 = nil
		@point2 = nil
		@point1Time = nil
		@point2Time = nil
		@velocity = 0
		@pathLen = 0
	end

	def addSegment(seg)
		@segArray << seg
	end

	def getSegments
		return @segArray
	end

	def setVelocity(v)
		@velocity = v
	end

	def setPathLen(l)
		@pathLen = l
	end

	def getPathLen
		return @pathLen
	end

	def setPoints(p1, p2)
		@point1 = p1
		@point2 = p2
	end

	def setTimes(t1, t2)
		@point1Time = t1
		@point2Time = t2
	end
end