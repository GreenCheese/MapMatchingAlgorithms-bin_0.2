puts "LOADING \"#{__FILE__}\"..."

#$:.unshift((File.dirname(__FILE__)+"/../bin/graph"))
#require 'graph.rb'
$:.unshift((File.dirname(__FILE__)+"/graph/"))
require 'graph.rb'

$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'point.rb'



#p1 = Point.new(1,1)
#p2 = Point.new(1,2)
#p3 = Point.new(2,2)
#p4 = Point.new(2,1)
#p5 = Point.new(3,1.5)

p1 = Point.new(1,1)
p2 = Point.new(2,2)
p3 = Point.new(3,1) #1

p4 = Point.new(3,1)
p5 = Point.new(4,3)
p6 = Point.new(5,1) #2

p7 = Point.new(5,1)
p8 = Point.new(6,4)
p9 = Point.new(7,1) #3


puz1 = PointOfSegmentZ.new(p1.x, p1.y, 0, true, false, 1)
pvz1 = PointOfSegmentZ.new(p2.x, p2.y, 0, true, true, 1)

#def initialize(x,y,z,ow,first,segindex)
puz2 = PointOfSegmentZ.new(p3.x, p3.y, 0, true, false, 2)
pvz2 = PointOfSegmentZ.new(p5.x, p5.y, 0, true, true, 2)

puz3 = PointOfSegmentZ.new(p3.x, p3.y, 0, true, false, 3)
pvz3 = PointOfSegmentZ.new(p2.x, p2.y, 0, true, false, 3)



gr = Graph.new(DIJKSTRA)

gr.insert(puz1,pvz1,2)
gr.printGraph
gr.insert(pvz1,puz1,2)
#gr.printGraph
puts "\n****\n"
#gr.insert(puz2,pvz2,3)
#gr.insert(puz3,pvz3,4)

gr.printGraph
puts "\n"


#gr.insert(puz3,pvz3,2)
#gr.printGraph
#puts "\n"

exit



gr = Graph.new(DIJKSTRA)
gr.insert(p1, p2, 5)
gr.insert(p1, p5, 91)
gr.insert(p2, p3, 3)
gr.insert(p3, p4, 4)
gr.insert(p4, p5, 5)
gr.insert(p3, p5, 5)


#gr.printGraph


index = gr.getVertexIndex(p1)
v = gr.getVertexList[index].getVertex


#puts "start vertex:"

#puts "\n\n"

#p v

dA = DijkstraAlgorithm.new
dA.run(gr,v)
#dA.print


dv = dA.getVertex(p5)

v = dv
p1 = v.getKey

while true
	if(v.p==nil)
		break
	end

	v = v.p
	p2 = v.getKey
	puts "#{p1.x};#{p1.y};#{p2.x};#{p2.y}"
	p1=p2
end