puts "LOADING \"#{__FILE__}\"..."
$:.unshift((File.dirname(__FILE__)+"/../heap"))
require 'heap.rb'
$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'point.rb'
$:.unshift((File.dirname(__FILE__)+"/../rStarTreeFileStatic_v3"))
require 'rStarTreeFileStatic_v3.rb'

NIL_FLOAT_MAX = 999999999.0

COMMON = 0
DIJKSTRA = 1 #Создает граф, где в каждой вершине дополнительно вводятся параметры d и p

class Vertex
	def initialize(u)
		@key = u
		@index = 0
	end

	def isEqual(p)
		res = false
	
		if(@key.x == p.getKey.x and @key.y==p.getKey.y)
			res = true
		end
		return res
	end

	def getKey
		return @key
	end

	def getData
		return [@key.x, @key.y]
	end

	def getPoints
		return [@key]
	end
		
	def setIndex(i)
		@index = i
	end

	def getIndex
		return @index
	end
	:key
	:index
end

class VertexDijkstra < Vertex
	attr_accessor :d #оценка кротчайшего пути
	attr_accessor :p #предшественник
end

class GraphEdge

	def initialize(initialVertex)
		@vertexList = []
		@weight = []
		@initialVertex = initialVertex
	end

	def addAnotherIndex(segIndex)
		@initialVertex.getKey.segmentIndex << segIndex
	end

	def insert(vu, w)
		f = false
		for i in 0..@vertexList.size-1
			#такое ребро уже есть?
			if (@vertexList[i].isEqual(vu))
				f = true
			end
		end

		if (f==false)
			@vertexList<<vu
			@weight << w
		end
	end

	def getVertex
		return @initialVertex
	end

	def printEdges
		for i in 0..@vertexList.size-1
			puts "\t#{@initialVertex} ---> #{@weight[i]} ---> #{@vertexList[i]} (#{@initialVertex.getData} ---> #{@vertexList[i].getData})\n"
		end
	end

	def getVertexList
		return @vertexList		
	end

	def getWeightList
		return @weight
	end
	:vertexList
	:weight
	:initialVertex
end

#вообще говоря, в графе, вместо данных, можно использовать id точек...
class Graph
	:rtree
	def initialize(graphType)
		@vertexList = []
		@type = graphType
		@rtree = RStarTree.new(8)
		@rtree.rStarTreeCreate
	end

	def getAdj(u)
		p = u.getKey
		#resP = @rtree.isExist(p)
		resP = @rtree.isExistZ(p)
		return @vertexList[resP.getIndex]
	end

	def insert(p1, p2, w)
		#mAGIC_NUMBER = rand(10000)

		case @type

		when COMMON
			vu = Vertex.new(p1)
			vv = Vertex.new(p2)
		when DIJKSTRA
			vu = VertexDijkstra.new(p1)
			vv = VertexDijkstra.new(p2)
		end

		fu = false
		fv = false
		iu = 0
		iv = 0
		#при таком способе вставки происходит дублирование вершин (разные адреса у вершины u, являющейся начальной и ею же, являющейся элементов списка для другой начальной)
		#№поэтому и первая и вторая вершина должны вставляться одновременно..
		#исправлено

		#resP1 = @rtree.isExist(p1) #TODO! Должен быть учет вершины z!
		resP1 = @rtree.isExistZ(p1)	#готово

		if (resP1!=nil)
			#Вершина u есть в графе
			fu = true
			iu = resP1.getIndex
		end

		#resP2 = @rtree.isExist(p2)
		resP2 = @rtree.isExistZ(p2)
		

		if (resP2!=nil)
			fv = true
			iv=resP2.getIndex
		end

		#вершина отсутсвует в графе
		if (fv == false)
			edge = GraphEdge.new(vv)
			@vertexList << edge

			vv.setIndex(@vertexList.size-1)
			obj = RTreeObject.new(vv)
			@rtree.insertObject(obj)
		else
			
			p2segInd = p2.segmentIndex[0]
			@vertexList[iv].addAnotherIndex(p2segInd)
			vv = @vertexList[iv].getVertex
		end

		if (fu == false)
			edge = GraphEdge.new(vu)
			edge.insert(vv, w)
			@vertexList << edge 

			vu.setIndex(@vertexList.size-1)
			obj = RTreeObject.new(vu)
			@rtree.insertObject(obj)
		else
			#Необходимо добавить в точку vu индекс сегмента точки p2.
			p2segInd = p2.segmentIndex[0]
			@vertexList[iu].addAnotherIndex(p2segInd)
			@vertexList[iu].insert(vv,w)
		end
	end

	def printGraph
		puts "count vertex = #{@vertexList.size}"
		for i in 0..@vertexList.size-1
			puts "vertex[#{i+1}]: #{@vertexList[i].getVertex} (#{@vertexList[i].getVertex.getData})\t #{@vertexList[i].getVertex.getKey.segmentIndex}\n"
			@vertexList[i].printEdges			
		end
	end

	def getVertexList
		return @vertexList
	end

	def getVertexIndex(p)
		v = Vertex.new(p)
		for i in 0..@vertexList.size-1
			#p @vertexList[i].getVertex
			if(@vertexList[i].getVertex.isEqual(v))
				return i 
			end
		end
		return nil
	end

	:vertexList
	:type
end

class DijkstraAlgorithm
	:sarr
	:q
	def initialize
		@sarr = []	
		@q = NDCPriorityQueue.new
	end

	def initializeSingleSource(g, s)
		vertexList = g.getVertexList
		for i in 0..vertexList.size-1
			vertexList[i].getVertex.d = NIL_FLOAT_MAX
			vertexList[i].getVertex.p = nil
		end
		s.d = 0
	end

	def relax(u,v,w)

		if (v.d>(u.d+w))
#			puts "Relaxing: #{v.d} -> #{u.d+w}"
			#p v.getKey.class
			#p v.class
			i = @q.getIndex(v)
#			puts i
			@q.heapDecreaseKey(i, u.d+w)
			v.d = u.d+w
			v.p = u
		end
	end

	def fillQuerry(g)
		vlist = g.getVertexList
		for i in 0..vlist.size-1
	#												"data" 				"weight"
			@q.minHeapInsert(QueueElement.new(vlist[i].getVertex,vlist[i].getVertex.d)) #по сути, тут vlist[i] есть edge, т.е. массив с ребрами из вершины getVertex
		end
	end

	def run(g, s) # тут s - элемент графа
		initializeSingleSource(g,s)
		fillQuerry(g)

		while true
			# u - это edge с весом
			#puts "beforeRelax: "
			#@q.printW

			u = @q.heapExtractMin
	
			if (u==nil)
				break
			end
			#puts "vertex = #{u.getData}: #{u.d}"

			@sarr << u

			adjArrList = g.getAdj(u)

			uAdjVertexArr = adjArrList.getVertexList
			uAdjWeightArr = adjArrList.getWeightList

			for i in 0..uAdjVertexArr.size-1
				v = uAdjVertexArr[i]
				w = uAdjWeightArr[i]
				relax(u,v,w)
			end
		end
	end

	def getVertex(p)
		v = Vertex.new(p)
		for i in 0..@sarr.size-1
			if (@sarr[i].isEqual(v))
				return @sarr[i]
			end
		end
	end

	def print 
		for i in 0..@sarr.size-1
			puts "to #{@sarr[i].getData} len == #{@sarr[i].d} "
			v = @sarr[i]
			while true
				parent = v.p
				if (parent == nil)
					break
				end					
				puts "\t ---> #{parent.getData};"
				v = parent
			end
		end
	end
end