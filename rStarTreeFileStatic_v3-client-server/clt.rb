require 'drb/drb'

SERVER_URI ="druby://192.168.79.95:8787"


class Point 
	attr_accessor :x
	attr_accessor :y

	def initialize (x,y)
		@x = x.to_f
		@y = y.to_f
	end
end

class Segment
	attr_accessor :p1
	attr_accessor :p2
end

DRb.start_service

t = DRbObject.new_with_uri(SERVER_URI)
p = Point.new(37.641826, 55.758856)


res = t.findSegmentsNearPoint(p, 0.05)
res.each{|seg|
	puts "\t#{seg.p1.x};#{seg.p1.y};#{seg.p2.x};#{seg.p2.y}\n"
}