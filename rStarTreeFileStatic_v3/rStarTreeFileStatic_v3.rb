#encoding: utf-8
#encode: utf-8
puts "LOADING \"#{__FILE__}\"..."
require 'thread'

$:.unshift(File.dirname(__FILE__))
require 'fTeeSL_v3.rb'

$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'point.rb'

@@DEBUG = false
@@SHOWCALLSTACK = false
FileStruct = "1structTree"
FileData = "1data1"
FileCode = "1code"
NIL_INT = -999999999
Latitude_factor = 111.1329
Longitude_factor = 63.85

# axis 
# 0 = x
# 1 = y
# 
# bounds
# 0 = left
# 1 = right

def Math.min(x1, x2)
	if(x1<x2)
		return x1
	else
		return x2
	end
end

def Math.max(x1, x2)
	if(x1>x2)
		return x1
	else
		return x2
	end
end


class MBR 
	attr_accessor :left
	attr_accessor :right

	def initialize
		@left = Point.new(0,0)
		@right = Point.new(0,0)
	end

	def isPointInside(point, radiusKm)
		isInsideFlag = false
		nlx = @left.x - radiusKm/Longitude_factor
 		nly = @left.y - radiusKm/Latitude_factor
 		nrx = @right.x + radiusKm/Longitude_factor
 		nry = @right.y + radiusKm/Latitude_factor

 		if(point.x>=nlx and point.x<=nrx and point.y>=nly and point.y<=nry)
 			isInsideFlag = true
 		end

 		return isInsideFlag
	end

	def SetFromData(data)
		pts = data.getPoints
		minx = pts[0].x
		miny = pts[0].y
		maxx = pts[0].x
		maxy = pts[0].y
		
		for i in 1..pts.size - 1
			minx = Math.min(pts[i].x, minx)
			miny = Math.min(pts[i].y, miny)
			maxx = Math.max(pts[i].x, maxx)
			maxy = Math.max(pts[i].y, maxy)
		end

		@left = Point.new(minx,miny)
		@right = Point.new(maxx,maxy)
		
	end

	def cDistance(item_mbr)
		ncX = (self.left.x+self.right.x).to_f/2
		ncY = (self.left.y+self.right.y).to_f/2

		icX = (item_mbr.left.x+item_mbr.right.x).to_f/2
		icY = (item_mbr.left.y+item_mbr.right.y).to_f/2

		return Math.sqrt((icX-ncX)*(icX-ncX)+(icY-ncY)*(icY-ncY))
	end

	def overlap(mbr)
		x = Math.min(self.right.x, mbr.right.x) - Math.max(self.left.x, mbr.left.x)
		if (x<=0)
			return 0
		end
		
		y = Math.min(self.right.y, mbr.right.y) - Math.max(self.left.y, mbr.left.y)
		if (y<=0)
			return 0
		end
		return x*y
	end

	def area
		return (right.x-left.x)*(right.y-left.y)
	end
end


class Segment
#			s,i s,f 		s,f 		v,i 	v,i 	s,b 	s,b			s,b 		s,f
#wkt_geom	ID	F_SPEEDLIM	T_SPEEDLIM	F_ZLEV	T_ZLEV	ONEWAY	F_BUSLANES	T_BUSLANES	FEATLEN

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
	:parentIndex

	def initialize (ptArr, extID, ind, fspdlim, tspdlim, onew, fbslan, tbslan, len, fzlev, tzlev)
		@pointsArr = Array.new

		ptArr.each{|pt|
			@pointsArr << pt
		}

		@externalID = extID
		@index 		= ind
		@f_speedLim	= fspdlim
		@t_speedlim	= tspdlim
		@oneway		= onew
		@f_buslanes	= fbslan
		@t_buslanes	= tbslan
		@featlen	= len
		@fzlev 		= fzlev
		@tzlev 		= tzlev

	end

	def marshal_dump
		[@pointsArr, @externalID, @index, @f_speedLim, @t_speedlim, @oneway, @f_buslanes, @t_buslanes, @featlen, @fzlev, @tzlev]
	end

	def self.loadNode(str)
		return Marshal.load(str)
	end

	def marshal_load array
		@pointsArr, @externalID, @index, @f_speedLim, @t_speedlim, @oneway, @f_buslanes, @t_buslanes, @featlen, @fzlev, @tzlev = array
	end

	def setParentIndex(pIndex)
		@parentIndex = pIndex
	end

	def getParentIndex
		return @parentIndex
	end

	def getPoints
		return @pointsArr
	end
end


class RStarTreeNode

	def initialize(sizeMax)
		@loadedAtRAM = false
		@mbr = MBR.new()
		@pointer = Array.new(sizeMax)
		@pointer_offset = Array.new(sizeMax, NIL_INT)
		@pointer_size = Array.new(sizeMax, NIL_INT)
		@parent_offset = NIL_INT
		@parent_size = NIL_INT
		@offset = NIL_INT

		@data_offset = NIL_INT
		@data_size = NIL_INT

		@parent = nil
		@leaf = false
		@level = -1
		@n = 0
	end

	def del_child(child)
		for i in 0..@n-1
			if (@pointer[i] == child)
				#использовать delete_at плохо, т.к. уменьшается размер массива, что критично и неприемлимо.
				#del_item = @pointer.delete_at(i)
				del_item = @pointer[i]
				for j in i..@n-2
					@pointer[j]=@pointer[j+1]
				end
				@n = @n-1
				return del_item
			end
		end
	end

	def reset
		@mbr = MBR.new
		@n = 0
	end

	def add(item)
		if (@n>=@pointer.size)
			puts "ERROR"
			exit
		end

		@pointer[@n] = item
		@n = n+1
		item.parent = self
	end

	def copy(node)
		for i in 0..node.n-1
			self.pointer[i] = node.pointer[i]
			self.pointer[i].parent = self
		end
		self.n = node.n
		self.leaf = node.leaf 
		self.parent = node.parent 
		self.level = node.level 

		self.mbr.left.x = node.mbr.left.x
		self.mbr.left.y = node.mbr.left.y
		self.mbr.right.x = node.mbr.right.x
		self.mbr.right.y = node.mbr.right.y
	end

	def margin
		return ((@mbr.right.x-@mbr.left.x)+(@mbr.right.y-@mbr.left.y))*2
	end

	def updateMBR
		mbrChanged = false

		old_left_x = @mbr.left.x
		old_left_y = @mbr.left.y
		old_right_x = @mbr.right.x
		old_right_y = @mbr.right.y

		@mbr.left.x = @pointer[0].mbr.left.x
		@mbr.left.y = @pointer[0].mbr.left.y
		@mbr.right.x = @pointer[0].mbr.right.x
		@mbr.right.y = @pointer[0].mbr.right.y

		for i in 0..@n-1
			if (@pointer[i].mbr.left.x < @mbr.left.x)
				@mbr.left.x = @pointer[i].mbr.left.x
			end

			if (@pointer[i].mbr.left.y < @mbr.left.y)
				@mbr.left.y = @pointer[i].mbr.left.y
			end

			if (@pointer[i].mbr.right.x > @mbr.right.x)
				@mbr.right.x = @pointer[i].mbr.right.x
			end

			if (@pointer[i].mbr.right.y > @mbr.right.y)
				@mbr.right.y = @pointer[i].mbr.right.y
			end
		end

		if (old_left_x != @mbr.left.x or old_left_y != @mbr.left.y or old_right_x != @mbr.right.x or old_right_y != @mbr.right.y)
			mbrChanged = true
		end

		if (mbrChanged)
			if (@parent!=nil)
				@parent.updateMBR
			end
		end

		return
	end
	
	def store
		return Marshal.dump(self)
	end

	def self.loadNode(str)
		return Marshal.load(str)
	end

=begin
	def marshal_dump
		[@n, @mbr, @pointer, @parent, @leaf, @level]
	end

	def marshal_load array
		@n, @mbr, @pointer, @parent, @leaf, @level = array
	end
=end

	def marshal_dump
		[@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size]
	end

	def marshal_load array
		@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size = array
	end

	attr_accessor :n #количество записей, хранящиъся в узле
	attr_accessor :mbr # minimalBoundRectangle
	attr_accessor :pointer #Указатели на дочерние узлы, n+1 штука
	attr_accessor :parent
	#при этом,
	# c[1].k[i]<= k[1] <= c[2].k[i] <=
	# 
	attr_accessor :leaf # = TRUE - лист, FALSE - внутренний узел
	attr_accessor :level #уровень узла в дереве (0=лист)
	attr_accessor :loadedAtRAM
	attr_accessor :offset
	#attr_accessor :parent_offset 	#А НУЖНО ЛИ? TODO проверить!
	#attr_accessor :parent_size 	#А НУЖНО ЛИ? TODO проверить!
	#attr_accessor :pointer_offset
	attr_accessor :pointer_size
end

class RTreeObject < RStarTreeNode
	#:mbr
	attr_accessor :data
	attr_accessor :data_offset
	attr_accessor :data_size
	#:parent

	def setMBR
		#@mbr = MBR.new()
		@mbr.SetFromData(@data)
	end

	def initialize(data)
		super(0) #хз как себя поведет...
		@data = data
		@parent = nil
		#@n = 1
		@leaf = nil
		@data_offset = NIL_INT
		self.setMBR
	end

	def marshal_dump
		[@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size, @data, @data_size]
	end

	def marshal_load array
		@n, @mbr, @leaf, @level, @offset, @pointer, @pointer_size, @data, @data_size = array
	end

	def store
		#str1 = super
		str1 = Marshal.dump(self) #super
		str2 = Marshal.dump(@data)
		return [str1, str2]
	end

	def self.loadNode(res)

		s1 = res[0]
		#zz = super(s1)
		zz = Marshal.load(s1)

		s2 = res[1]
		segment = Segment.loadNode(s2)

		#zz.setasd(pt)
		@data = segment
		return zz
	end

	def print
		puts "VV"
		puts "mbr:\n"
		p @mbr
		puts "\ndata\n"
		p @data
		puts "^^"
	end
end

class RStarTree
	attr_accessor :root
	attr_accessor :root_offset
	attr_accessor :root_size
	attr_accessor :m
	attr_accessor :M

	def initialize (max)
		@M = max
		@m = (0.4*@M).to_i
		@root_offset = NIL_INT
		@root_size = NIL_INT
	end

	def rStarTreeCreate
		x = RStarTreeNode.new(@M)
		x.leaf = true
		x.n = 0
		x.level = 0
		self.root = x
	end

	def storeTreeHeader
		str = Marshal.dump(self)
		IO.binwrite(FileStruct, str, 0)
		return str.size
	end

	def marshal_dump
		[@nextFreeStructOffset, @nextFreeDataOffset, @m, @M, @root_offset, @root_size]
	end

	def marshal_load array
		@nextFreeStructOffset, @nextFreeDataOffset, @m, @M, @root_offset, @root_size = array
	end

	def Insert(item)
		n = self.root
		ChooseSubtree(item, n)
	end

	def QuickSort(array, iLo, iHi, axe, bound)
		lo = 0
		hi = 0
		t = nil
		mid = 0.0

		lo = iLo
		hi = iHi

		case bound 
		when 0 #left
			case axe 
			when 0 #X
				mid = array[((lo+hi)/2).to_i].mbr.left.x
			when 1 #Y 
				mid = array[((lo+hi)/2).to_i].mbr.left.y
			end
		when 1 #right
			case axe 
			when 0 #X
				mid = array[((lo+hi)/2).to_i].mbr.right.x
			when 1 #Y 
				mid = array[((lo+hi)/2).to_i].mbr.right.y
			end
		end
			
		#do
		begin
			case bound
			when 0 #Left
				case axe
				when 0 #X
					while array[lo].mbr.left.x < mid
						lo = lo + 1
					end
					while array[hi].mbr.left.x > mid
						hi = hi - 1
					end
				when 1 #Y
					while array[lo].mbr.left.y < mid
						lo = lo + 1
					end
					while array[hi].mbr.left.y > mid
						hi = hi - 1
					end
				end
			when 1 #Right
				case axe
				when 0 #X
					while array[lo].mbr.right.x < mid
						lo = lo + 1
					end
					while array[hi].mbr.right.x > mid
						hi = hi - 1
					end

				when 1 #Y
					while array[lo].mbr.right.y < mid
						lo = lo + 1
					end
					while array[hi].mbr.right.y > mid
						hi = hi - 1
					end
				end
			end

			if (lo<=hi)
				t = array[lo]
				array[lo] = array[hi]
				array[hi] = t
				lo = lo + 1
				hi = hi - 1
			end
		end until lo>hi

		if (hi>iLo)
			QuickSort(array, iLo, hi, axe, bound)
		end
		
		if (lo<iHi)
			QuickSort(array, lo, iHi, axe, bound)
		end
	end

	def QuickSortDependence(array_data, array_key, iLo, iHi)
		lo = 0
		hi = 0
		t = nil
		mid = 0.0

		lo = iLo
		hi = iHi
		
		mid = array_key[((lo+hi)/2).to_i]
			
		begin
			while array_key[lo] < mid
				lo = lo + 1
			end
		
			while array_key[hi] > mid
				hi = hi - 1
			end
		
			if (lo<=hi)
				t = array_key[lo]
				array_key[lo] = array_key[hi]
				array_key[hi] = t

				t = array_data[lo]
				array_data[lo] = array_data[hi]
				array_data[hi] = t				

				lo = lo + 1
				hi = hi - 1
			end
		end until lo>hi

		if (hi>iLo)
			QuickSortDependence(array_data, array_key, iLo, hi)
		end
		
		if (lo<iHi)
			QuickSortDependence(array_data, array_key, lo, iHi)
		end
	end

	def insertObject(item)
		overflowArray = Array.new(self.root.level, 0)

		insert(item, overflowArray)
		overflowArray.clear
		overflowArray = nil
	end


	def printInternalCondition
		puts "\n\n**************************************************"
		nnode = self.root
		puts "qweqwe 1 (level)"
		puts "node                #{nnode.level} <"
		puts "node->child         #{nnode.pointer[0].level}"
		puts "node->child->parent #{nnode.pointer[0].parent.level} <\n"
		p "node                   #{nnode}"
		p "node->child->parent    #{nnode.pointer[0].parent}"
		puts "\n"
		p "node->child    #{nnode.pointer[0]}"
		puts "--------"
	
		if (nnode.pointer[0].pointer[0]!=nil)
			puts "node->child                   #{nnode.pointer[0].level} <"
			puts "node->child->child->parent    #{nnode.pointer[0].pointer[0].parent.level} <\n"
			p "root->child[0]                   #{nnode.pointer[0]}"
			p "root->child[0]->child->parent    #{nnode.pointer[0].pointer[0].parent}"
			puts "\n"
			if (nnode.pointer[1]!=nil)
				p "root->child[1]                   #{nnode.pointer[1]}"
				p "root->child[1]->child->parent    #{nnode.pointer[1].pointer[0].parent}"
			end
			puts "\n"
			p "root                             #{nnode}"
			p "root->child[0]->parent           #{nnode.pointer[0].parent}"
		end
		puts "************************************************************\n\n"
	end

	def insert(item, overflowArray)
		if (@@SHOWCALLSTACK)
			puts "insert - \t\t\t\t#{item.class} item = #{item}"
		end

		node = self.root
		
		if(@@DEBUG)
			#printInternalCondition
			print_internal
		end

		#вызываем chooseSubtree для того, чтобы найти подходящий узел в который вставим запись item
		node = chooseSubtree(item, node) # - тут нужно учитывать level

		if(@@DEBUG)
			puts "found node = #{node}"
		end

		#если в найденном узле есть место
		if(node.n<@M)
			#размещаем item в найденный узел
			node.add(item)
			node.updateMBR
		else
			#иначе
			if (node.n==@M)
				OverflowTreatment(item, node, overflowArray)
			else
				#Быть такого не может, где-то ошибка
				puts "insert error: node has more than max item."
				exit
			end

		end
		
		#Если OverflowTreatment был вызван и в нем был вызван split
		#разпространить OverflowTreatment вверх, если необходимо... (видимо, если у родителя так же нет места)

		#Если OverflowTreatment привел к разделению корня, создать новый корень

		#поправить все mbr по пути вставки 
#		if(@@DEBUG)
#			printInternalCondition
#		end

	end


	def OverflowTreatment(item, node, overflowArray)
		#Если node - не корень и мы ранее не вызывали этот метод на данном уровне в процессе вставки элемента, то 
		if (@@SHOWCALLSTACK)
			puts "OverflowTreatment - \t#{item.class}"
		end

		if (node!=self.root and overflowArray[node.level]==0)
			overflowArray[node.level] = 1
			reinsert(item, node, overflowArray)
		else
			splitNodeRStar(item, node, overflowArray)
		end
		#вызвать reinsert
		#иначе - вызвать splitNodeRStar(item, node)
	end

	def reinsert(item, node, overflowArray)
		if (@@SHOWCALLSTACK)
			puts "reinsert - \t\t\t\t#{item.class} item = #{item} node = #{node}"
			puts "node.mbr = #{node.mbr.inspect}"
		end

		if(@@DEBUG)
			#printInternalCondition
			print_internal
		end

		objArray = Array.new(@M+1)
		distanceArray = Array.new(@M+1)

		for i in 0..node.n-1
			objArray[i] = node.pointer[i]
		end

		objArray[node.n] = item

		for i in 0..@M
			#тут во вопрос - mbr node учитывает mbr item, или нет? TODO разобраться...
			distanceArray[i] = node.mbr.cDistance(objArray[i].mbr)
		end

		#сортируем массив objArray в порядке уменьшения дистанции:
		QuickSortDependence(objArray, distanceArray, 0, @M)
		objArrayReverced = objArray.reverse

		p = (@M*0.3).to_i
		if p == 0
			p = 1
		end
		reinsert_items = Array.new(p) 
		#Удаляем первые p записей из n
		#удаление реализуем так: первые p записей записываем в одну вершину (В1)
		#остальные - в другую (В2).
		#текущую вершину удаляем, заменяем на B2


		# тут несколько вариантов:
		# 1. среди удаляемых вершин есть та, которую хотим добавить, но ее нету в node (пока не добавили)
		# 2. среди удаляемых вершин нету той, которую хотим добавить
		# т.е. в итоге - ставим флаг, встречался ли нам удаемый item. если 1 - то добавляем ее в массив reinsert, 
		# если 2 - то добавляем ее в node, благо после цикла в ней теперь есть место )
		found_item = false
		for i in 0..p-1
			if (objArrayReverced[i]==item)
				found_item = true
				reinsert_items[i] = item
			else
				item_reins = node.del_child(objArrayReverced[i])
				reinsert_items[i] = item_reins
			end
			#node_1.add(objArrayReverced[i])
		end

		if(!found_item)
			node.add(item)
		end

		node.updateMBR

		#if (@@SHOWCALLSTACK)
			#puts "After delete node.mbr: #{node.mbr.inspect}"
		#end

		for i in 0..reinsert_items.size-1
			insert(reinsert_items[i], overflowArray)
		end

		if(@@DEBUG)
			print_internal
		end

		return
	end

	def splitNodeRStar(item, node, overflowArray)
		if (@@SHOWCALLSTACK)
			puts "splitNodeRStar - \t\t#{item.class} node.size = #{node.n} item = #{item} node = #{node}"
		end

		if(@@DEBUG)
			#printInternalCondition
			print_internal
		end

		parent = nil
		objectArray = Array.new(@M+1)
		
		if (node == self.root)
			parent = RStarTreeNode.new(@M)
			parent.add(node)
			parent.level = parent.pointer[0].level+1
			self.root = parent
		else
			parent = node.parent
		end
		
		for i in 0..objectArray.size - 2
			objectArray[i] = node.pointer[i]
		end

		objectArray[objectArray.size-1] = item
		
		node_1_min = RStarTreeNode.new(@M) 
		node_2_min = RStarTreeNode.new(@M) 
		
		areaOverlapMin = 9999999
		areaMin = 9999999

		axe = chooseSplitAxis(item,node)
		#ChooseSplitIndex begin
		for i_bound in 0..1
			QuickSort(objectArray, 0, objectArray.size-1, axe, i_bound)

			for k in @m-1..@M-@m

				group1 = RStarTreeNode.new(@M) #CbIP TODO создание объекта в цикле заменить на создание вне цикла и очистку в цикле
				group2 = RStarTreeNode.new(@M) #CbIP TODO создание объекта в цикле заменить на создание вне цикла и очистку в цикле

				j = 0
				while j<=k
					group1.add(objectArray[j])
					j = j + 1
				end

				for j in k+1..objectArray.size-1
					group2.add(objectArray[j])
				end

				group1.updateMBR
				group2.updateMBR

				areaOverlap = group1.mbr.overlap(group2.mbr)
				
				if (areaOverlap>9999999)
					puts "areaOverlap: #{areaOverlap} - maxed item reached, magic number error 1"
					exit
				end
				
				if(areaOverlap<areaOverlapMin)

					node_1_min.copy(group1)
					node_2_min.copy(group2)

					areaOverlapMin = areaOverlap
				elsif (areaOverlap==areaOverlapMin)
					area = group1.mbr.area+group2.mbr.area
					
					if (area>9999999)
						puts "area: #{area} - превышение верхней границы, magic number error 2"
						exit
					end

					if (area<areaMin)

						node_1_min.copy(group1)
						node_2_min.copy(group2)
						areaMin = area
					end
				end
			end
		end

		node_1_min.level = node.level
		node_2_min.level = node.level

		node_1_min.leaf = node.leaf
		node_2_min.leaf = node.leaf

		node.copy(node_1_min)
		node.parent = parent
		node.updateMBR
		
		newChild = RStarTreeNode.new(@M)
		
		newChild.copy(node_2_min)
		newChild.parent = parent
		newChild.updateMBR

		if(@@DEBUG)
			puts "wwwwwwwwwwwwwwwwwwwwwwwwwwww"

			puts "item = #{item}"
			puts "node 1 childrens: (#{node.n})"
			for i in 0..node.n-1
				puts "node 1 childrens #{node.pointer[i]}"
			end

			puts "newChild childrens: (#{newChild.n})"
			for i in 0..newChild.n-1
				puts "newChild childrens #{newChild.pointer[i]}"
			end

			puts "vvvvvvvvvvvvvvvvvvvvvvvvvvvv"
		end

		if(parent.n<self.M)
			parent.add(newChild)
			parent.updateMBR
		else
			#TODO убедиться в правильности каммента
			#splitNodeRStar(newChild, parent, overflowArray)
			OverflowTreatment(newChild, parent, overflowArray)
		end

		if(@@DEBUG)
			print_internal
		end

	end

	def chooseSplitAxis(item, node)
		if (@@SHOWCALLSTACK)
			puts "chooseSplitAxis - \t\t#{item.class}"
		end
		#для каждой оси: 
		# сортируем записи по нижней границе mbr, затем по верхней.
		# определяем параметры каждого распределения
		# вычисляем S - сумму периметров каждого распредеения
		# выбираем ось, для которой S минимальна

		#p node

		if (not node.leaf)
			#это тот случай, когда при разделении листьев, нужно разделить родителя/лей, т.к. там перебор.
			#сделать что то ... 
		end

		objectArray = Array.new(@M+1)

		for i in 0 .. node.n-1
			objectArray[i] = node.pointer[i]
		end

		objectArray[node.n] = item
		perimetr_min = 999999
		result = nil

		for i_axis in 0..1 #оси
			perimetr = 0
			for j_bound in 0..1 #левые или правые границы

				group1 = RStarTreeNode.new(@M) #CbIP TODO создание объекта в цикле заменить на создание вне цикла и очистку в цикле
				group2 = RStarTreeNode.new(@M) #CbIP TODO создание объекта в цикле заменить на создание вне цикла и очистку в цикле

				QuickSort(objectArray, 0, objectArray.size-1, i_axis, j_bound)

				for k in 1 .. @M-@m*2+2 #комбинации

					idx = 0
					
					group1.reset
					while idx <((@m-1)+k)
						group1.add(objectArray[idx])
						idx = idx + 1
					end
					
					group2.reset
					for idx in idx..objectArray.size-1
 						#node_2.Objects[idx - ((MIN_M - 1) + k)] := arr_obj[idx];
						group2.add(objectArray[idx])
					end

					group1.updateMBR
					group2.updateMBR

					perimetr = perimetr + (group1.margin+group2.margin)
				end

			end

			if (perimetr_min>perimetr)
				perimetr_min = perimetr
				result = i_axis
			end

		end
		return result
	end


	def print_internal
		puts "vvvvvvvvvvvvvvvvvvvvINTERNAL CONDOTION OF TREEvvvvvvvvvvvvvvvvvvvv"
		q = Queue.new
		q.push(self.root)


		while (!q.empty?)
			node = q.pop
			rStarPrintInternal(node)

			if (node.level!=0)
				for i in 0..node.n-1
					q.push(node.pointer[i])
				end
			end
		end
		puts "^^^^^^^^^^^^^^^^^^END INTERNAL CONDOTION OF TREE^^^^^^^^^^^^^^^^^^"
	end

	def rStarPrintInternal(item)
		strret = ""
		cnt = self.root.level - item.level
		for i in 0..cnt-1
			strret = strret+"\t"
		end

		puts "#{strret}rStarPrintInternal\t==========item: #{item} ==========="
		if (item!=self.root)
			puts "#{strret}rStarPrintInternal\titem.parent: #{item.parent}"
		else
			puts "#{strret}rStarPrintInternal\tTHIS IS ROOT"
		end

		for i in 0..item.n-1
			puts "#{strret}rStarPrintInternal\titem.children: #{item.pointer[i]}"
		end
		puts "#{strret}rStarPrintInternal\t==========EOF item: #{item} ==========="

	end

	def loadChildren(node) #TODO исправить колхоз!
		if (node.loadedAtRAM)
			return
		end

		for i in 0..node.n-1
			TreeLoad.commonLoadChild(node.pointer[i], node.pointer_size[i], node, i)
			#loadChild(node.pointer[i], node.pointer_size[i], node, i)
		end
		node.loadedAtRAM = true
	end

	#метод используется для деревьев, у которых ноды - точки
	def isExist(pt)
 		q = Queue.new
		q.push(self.root)

		while (!q.empty?)
			node = q.pop

			#если нода - внутренний узел
			if (node.level!=-1)
				#проверяем, находится ли точка внутри MBR узла
				if(node.mbr.isPointInside(pt,0))
					#если точка внутри MBR узла кидаем в очередь детей узла (т.е. смотрим "внутрь"" узла).
					#loadChildren(node)
					for i in 0..node.n-1
						#дает небольшое ускорение
						if(node.pointer[i].mbr.isPointInside(pt,0))
							q.push(node.pointer[i])
						end
					end
				end
				#остальные вершины не рассматриваем (которые взяты из очереди, но чей MBR не содержит точку)
			else
			# нет! нода - лист (у него несколько детей- данных)
			# да! нода - данные

			#поскольку нода - данные (точка), то ее mbr - точка. Метод isPointInside вернет true в том случае, когда в дереве есть точка с координатами pt.x и pt.y
				if (node.mbr.isPointInside(pt,0))
					#finedSegments << node.data
					return node.data
				end
			end
		end
		return  nil #finedSegments		
	end

	#метод используется для деревьев, у которых ноды - точки
	def isExistZ(pt)
		#p "isExist(pt)"
 		q = Queue.new
		q.push(self.root)

		while (!q.empty?)
			node = q.pop

			#если нода - внутренний узел
			if (node.level!=-1)
				#проверяем, находится ли точка внутри MBR узла
				#но! внутри узла может быть точка с теми же координатами, но разными z
				if(node.mbr.isPointInside(pt,0))
					#если точка внутри MBR узла кидаем в очередь детей узла (т.е. смотрим "внутрь"" узла).
					#loadChildren(node)
					for i in 0..node.n-1
						#дает небольшое ускорение
						if(node.pointer[i].mbr.isPointInside(pt,0))
							q.push(node.pointer[i])
						end
					end
				end
				#остальные вершины не рассматриваем (которые взяты из очереди, но чей MBR не содержит точку)
			else
			# нет! нода - лист (у него несколько детей- данных)
			# да! нода - данные

			#поскольку нода - данные (точка), то ее mbr - точка. Метод isPointInside вернет true в том случае, когда в дереве есть точка с координатами pt.x и pt.y
			#Данный вызов (.getKey.zLevel) работает для класса PointOfSegmentZ
				if (node.mbr.isPointInside(pt,0))
					if (pt.zLevel==node.data.getKey.zLevel)
						#finedSegments << node.data
						return node.data
					end
				end
			end
		end
		return  nil #finedSegments		
	end

	def findSegmentsNearPoint(pt, radiusKm)
		#mbr:
		# 	  _________________________	 ____					
		#  	 | \					 / |	  ^ radiusKm
		#  	 |	*********************  |***** v
		# 	 |	*		right(x,y)_/*  |
		# 	 |	*					*  |
		# 	 |	* left(x,y)			*  |
		# 	 |	*/ 					*  |
		# 	 |	*********************  |
		# 	 |_/_ _ _ _ _ _ _ _ _ _ *\_|	
		# 		 					  
		#  							*  |
 		# 							*  | 
 		# 							< > radiusKm

		finedSegments = []

 		q = Queue.new
		q.push(self.root)

		while (!q.empty?)
			node = q.pop

			#если нода - внутренний узел
			if (node.level!=-1)
				#проверяем, находится ли точка внутри MBR узла
				if(node.mbr.isPointInside(pt,radiusKm))
					#если точка внутри MBR узла кидаем в очередь детей узла (т.е. смотрим "внутрь"" узла).
					loadChildren(node)
					for i in 0..node.n-1
						q.push(node.pointer[i])
					end
				end
				#остальные вершины не рассматриваем (которые взяты из очереди, но чей MBR не содержит точку)
			else
			# нет! нода - лист (у него несколько детей- данных)
			# да! нода - данные

			#проверяем, находится ли точка внутри mbr. Если да, то добавляем data листа в массив найденных сегментов.
				if (node.mbr.isPointInside(pt,radiusKm))
					finedSegments << node.data
				end
			end
		end

		return finedSegments
	end

	def print(fname)
		q = Queue.new
		q.push(self.root)

		while (!q.empty?)
			node = q.pop

			loadChildren(node)

			rStarPrint(node, fname)
			if (node.level!=0)
				for i in 0..node.n-1
					q.push(node.pointer[i])
				end
			end
		end
	end

	def rStarPrint(item, fname)
		clr = ""
		if (item.level==1)
			clr = "red"
		elsif
			item.level==0
			clr = "green"
		elsif
			item.level==2
			clr = "blue"
		else
			clr = "pink"
		end

		f = File.new("D://1//#{fname}", "a")
		@@printObjId = @@printObjId + 1

		str = "set object #{@@printObjId} rect from #{item.mbr.left.x}, #{item.mbr.left.y}, 0 to #{item.mbr.right.x}, #{item.mbr.right.y}, 0\n"
		f.write(str)
		#str = "set object #{@@printObjId} back lw #{(item.level+1)*2.0} fillstyle transparent solid 0.05 border rgb \"#{clr}\"\n"
		str = "set object #{@@printObjId} back lw 1 fillstyle transparent solid 0.05 border rgb \"#{clr}\"\n"
		f.write(str)

		if(item.level == 0)
			for i in 0..item.n-1
				@@printObjId = @@printObjId + 1
				str = "set object #{@@printObjId} rect from #{item.pointer[i].mbr.left.x}, #{item.pointer[i].mbr.left.y}, 0 to #{item.pointer[i].mbr.right.x}, #{item.pointer[i].mbr.right.y}, 0\n"
				f.write(str)
				
				#str = "set object #{@@printObjId} back lw #{(item.level+1)} fillstyle transparent solid 0.05\n"
				str = "set object #{@@printObjId} back lw 1 fillstyle transparent solid 0.05\n"
				f.write(str)

				@@printObjId = @@printObjId + 1
				#str = "set object #{@@printObjId} polygon from #{item.pointer[i].mbr.left.x}, #{item.pointer[i].mbr.left.y}, 0 to #{item.pointer[i].mbr.right.x}, #{item.pointer[i].mbr.right.y}, 0 to #{item.pointer[i].mbr.left.x}, #{item.pointer[i].mbr.left.y}, 0\n"
				
				#puts "\nlevel = #{item.pointer[i].level}"
				#puts "size = #{item.pointer[i].n}\n"
				#puts "class = #{item.pointer[i].class}\n"
				#puts "item adress = #{item.pointer[i]}\n"
				#puts "data = #{item.pointer[i].data}\n"

				x1 = item.pointer[i].data.getPoints[0].x
				y1 = item.pointer[i].data.getPoints[0].y
				x2 = item.pointer[i].data.getPoints[1].x
				y2 = item.pointer[i].data.getPoints[1].y
				str = "set object #{@@printObjId} polygon from #{x1}, #{y1}, 0 to #{x2}, #{y2}, 0 to #{x1}, #{y1}, 0\n"

				#str = "set object circle at first #{x1}, #{y1} radius char 0.5 fillstyle empty border lc rgb '#aa1100' lw 2\n"
				f.write(str)
			end
		end
		f.close
	end	

	def insertFromFile_v2(tree)
	#Polyline Id;Part Id;Point Id;X;Y
		#f = IO.read("road_data_v2.data")
		f = IO.read("WholeMoscowRoadData.data")
		
		i = 1

		f.split("\n").each{|row|
			#			s,i s,f 		s,f 		v,i 	v,i 	s,b 	s,b			s,b 		s,f
			#wkt_geom	ID	F_SPEEDLIM	T_SPEEDLIM	F_ZLEV	T_ZLEV	ONEWAY	F_BUSLANES	T_BUSLANES	FEATLEN
			pointsArr = Array.new

			splitted_row = row.split("\t")

			s_wkt 		= splitted_row[0]
			s_wkt = s_wkt[s_wkt.index("(")+1..s_wkt.rindex(")")-1]
			s_wkt.split(", ").each{|pare|
				x = pare.split(" ")[0]
				y = pare.split(" ")[1]
				#puts "x = #{x}; y = #{y}\n"
				pointsArr << Point.new(x,y)
			}

			#p pointsArr
			id = i
			idext		= splitted_row[1].to_i
			fspeedLim 	= splitted_row[2].to_f
			tspeedLim 	= splitted_row[3].to_f
			fzlev 		= splitted_row[4].to_i
			tzlev 		= splitted_row[5].to_i
			oneway 		= splitted_row[6]=="B" ? false : true
			fbuslanes 	= splitted_row[7]=="N" ? false : true
			tbuslanes 	= splitted_row[8]=="N" ? false : true
			featlen 	= splitted_row[9].to_f.round(3)

			#puts "ID\t\t\t=\t#{idext}\nidInt\t\t=\t#{id}\nF_SPEEDLIM\t=\t#{fspeedLim}\nT_SPEEDLIM\t=\t#{tspeedLim}\nF_ZLEV\t\t=\t#{fzlev}\nT_ZLEV\t\t=\t#{tzlev}\nONEWAY\t\t=\t#{oneway}\nF_BUSLANEW\t=\t#{fbuslanes}\nT_BUSLANES\t=\t#{tbuslanes}\nFRATLEN\t\t=\t#{featlen}\n"
			
			#line_id = row.split(";")[0]
			#part_id = row.split(";")[1]
			#point_id = row.split(";")[2]
			#x = row.split(";")[3].to_f
			#y = row.split(";")[4].to_f

			s = Segment.new(pointsArr, idext, id, fspeedLim, tspeedLim, oneway, fbuslanes, tbuslanes, featlen, fzlev, tzlev)
			obj = RTreeObject.new(s) #++
			#p obj
			tree.insertObject(obj)
=begin
			s = Segment.new(Point.new(prev_x, prev_y), Point.new(x,y))
			obj = RTreeObject.new(s)
			tree.insertObject(obj)
=end
		
		
			i = i + 1
			if (i%100==0)
				p i
			end
		}
	end
	
	def insertFromFile(tree)
	#Polyline Id;Part Id;Point Id;X;Y
		f = IO.read("Data//road.csv")

		prevline_id = 0
		i = 0	
		prev_x = 0.0
		prev_y = 0.0

		f.split("\n").each{|row|
			if (i == 14)
				#print_internal
				#@@DEBUG=true
				#@@SHOWCALLSTACK=true
			end

			#if (i>100001)
			if (i>500)
			#425-426
			#if (i>10000)
				#print_internal
				return
			end

			line_id = row.split(";")[0]
			#part_id = row.split(";")[1]
			#point_id = row.split(";")[2]
			x = row.split(";")[3].to_f
			y = row.split(";")[4].to_f

			if (line_id==prevline_id)
				s = Segment.new(Point.new(prev_x, prev_y), Point.new(x,y))
				obj = RTreeObject.new(s)
				#puts "#{prev_x}, #{prev_y}; #{x},#{y}\t\t\t [#{s.getPoints[0].x}, #{s.getPoints[0].y}] [#{s.getPoints[1].x}, #{s.getPoints[1].y}]"
				tree.insertObject(obj)
			else
				prevline_id = line_id
			end
		
			prev_x = x
			prev_y = y

			i = i + 1
			if (i%5000==0)
				p i
			end
		}
	end

	def chooseSubtree(item, node)
	
		if (node.level == item.level+1)
			return node
		end
		minOverlapEnlargementArray = Array.new
		#если у вершины дети - листья

		if (node.pointer[0].leaf)

			min_overlap_enlargement = item.mbr.area - node.pointer[0].mbr.overlap(item.mbr)
			minOverlapEnlargementArray.push(node.pointer[0])

			#идем по всем детям
			for i in 1..node.n-1
				overlap_enlargement = item.mbr.area - node.pointer[i].mbr.overlap(item.mbr)
				if (overlap_enlargement<=min_overlap_enlargement)
					#Если увеличение перекрытий совпадают, то добавляем к списку текущий элемент
					if (overlap_enlargement==min_overlap_enlargement)
						minOverlapEnlargementArray.push(node.pointer[i])
					else
					#Если же строго меньше, то очищаем массив, вставляем новый элемент
						min_overlap_enlargement = overlap_enlargement
						minOverlapEnlargementArray.clear
						minOverlapEnlargementArray.push(node.pointer[i])
					end
				end
			end

			#нашли один-единственный элемент (тут хотя бы 1 элемент должен быть, иначе был бы return при проверке детей)
			if (minOverlapEnlargementArray.size==1)
				return chooseSubtree(item, minOverlapEnlargementArray.pop)
			end
			#иначе, проверяем наименьшее увеличение площади.
			#но на самом деле, оптимизируем с целью уменишения дублирования кода (и проверка выполняется после if)
		else
			for i in 0..node.n-1
				minOverlapEnlargementArray.push(node.pointer[i])
			end
		end

		#проверяем наименьшее увеличение площади
		minAreaEnlargementArray = Array.new
		nodeMbr = node.pointer[0].mbr
		enlargement_mbr = MBR.new()

		enlargement_mbr.left.x = Math.min(item.mbr.left.x, nodeMbr.left.x)
		enlargement_mbr.left.y = Math.min(item.mbr.left.y, nodeMbr.left.y)
		enlargement_mbr.right.x = Math.max(item.mbr.right.x, nodeMbr.right.x)
		enlargement_mbr.right.y = Math.max(item.mbr.right.y, nodeMbr.right.y)

		min_area_enlargement = enlargement_mbr.area - nodeMbr.area
		minAreaEnlargementArray.push(node.pointer[0])
		
		for i in 1..minOverlapEnlargementArray.size-1
			nodeMbr = node.pointer[i].mbr
			enlargement_mbr = MBR.new()

			enlargement_mbr.left.x = Math.min(item.mbr.left.x, nodeMbr.left.x)
			enlargement_mbr.left.y = Math.min(item.mbr.left.y, nodeMbr.left.y)
			enlargement_mbr.right.x = Math.max(item.mbr.right.x, nodeMbr.right.x)
			enlargement_mbr.right.y = Math.max(item.mbr.right.y, nodeMbr.right.y)
			
			area_enlargement = enlargement_mbr.area - nodeMbr.area
			if (area_enlargement<=min_area_enlargement)
				if (area_enlargement==min_area_enlargement)
					minAreaEnlargementArray.push(node.pointer[i])
				else
					minAreaEnlargementArray.clear
					min_area_enlargement = area_enlargement
					minAreaEnlargementArray.push(node.pointer[i])
				end
			end
		end

		if (minAreaEnlargementArray.size == 1)
			return chooseSubtree(item, minAreaEnlargementArray.pop)
		else
			
			minarea = minAreaEnlargementArray[0].mbr.area
			minAreaItem = minAreaEnlargementArray[0]

			for i in 1..minAreaEnlargementArray.size-1
				if (minAreaEnlargementArray[i].mbr.area<minarea)
					minarea = minAreaEnlargementArray[i].mbr.area
					minAreaItem = minAreaEnlargementArray[i]
				end
			end

			return chooseSubtree(item, minAreaItem)
		end
	end
#выбрать запись в N такую, чье увеличение перекрытия минимально при добавлении новых данных
			#спорные случаи: выбираем запись, у которой площадь требует меньшее увеличение
end

def preprintCreate (fname)
	@@printObjId = 0
	f = File.new("D://1//#{fname}", "wb+")
	str = "set encoding utf8\n"
	f.write(str)

	str = "set terminal jpeg size 1280,1024\n"
	#str = "set terminal jpeg size #{1280*10},#{1024*10}\n"
	f.write(str)
	f.close
end

def afterprintCreate(rtree, fname)
	f = File.new("D://1//#{fname}", "a")
	str =  "set output \"D://1//#{fname}.jpeg\"\n"
	f.write(str)

	str = "plot [#{rtree.root.mbr.left.x-0.01}:#{rtree.root.mbr.right.x+0.01}] [#{rtree.root.mbr.left.y-0.01}:#{rtree.root.mbr.right.y+0.01}] NaN notitle"
	f.write(str)
	
	f.close
end




=begin

rtree = RStarTree.new(15)
rtree.rStarTreeCreate

rtree.insertFromFile_v2(rtree)

ts = TreeStore.new(rtree)
ts.store

=end




=begin

file1 = "gnp1"

preprintCreate(file1)

#rtree = RStarTree.new(3)
rtree = RStarTree.new(15)
rtree.rStarTreeCreate

rtree.insertFromFile(rtree)

rtree.print(file1)
afterprintCreate(rtree, file1)


t1 = Time.now()
p "creating complete at #{t1}"
ts = TreeStore.new(rtree)
ts.store
			
t2 = Time.now()
p "store complete at #{t2}"
p "dt = #{t2-t1}"
=end


#file1 = "point"
#preprintCreate(file1)
=begin
rtree = RStarTree.new(3)
rtree.rStarTreeCreate

s1 = Point.new(25,61)

obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(38,72)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(46,81)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(57,93)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(46,77)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(57,69)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(74,13)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(85,101)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(42,59)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(78,42)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(114,86)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(105,40)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(96,57)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(108,75)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(18,4)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(3,23)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(24,3)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(68,36)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(120,46)
obj = RTreeObject.new(s1)
rtree.insertObject(obj) #*

s1 = Point.new(170,26)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(134,10)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(147,52)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)

s1 = Point.new(138,32)
obj = RTreeObject.new(s1)
rtree.insertObject(obj) 

s1 = Point.new(160,18)
obj = RTreeObject.new(s1)
rtree.insertObject(obj)
=end


#pt = Point.new(68,36)
#res = rtree.isExist(pt)
#p res
#rtree.print(file1)
#afterprintCreate(rtree, file1)

#rtree.print_internal




=begin
tl = TreeLoad.new
treeL = tl.load
puts treeL.root
p treeL.root.mbr
=end

=begin

	
	#file2 = "gnp2"
	#preprintCreate(file2)
	
	tl = TreeLoad.new
	
	t1 = Time.now()
	#p "start load at #{t1}"
	
	treeL = tl.load
	
	t2 = Time.now()
	#p "load complete at #{t2}"
	p "dt load = #{t2-t1}"
	
	#treeL.print(file2)
	#afterprintCreate(treeL, file2)
	
	
	#puts treeL.root
	#p treeL.root.mbr
	
	pt3 = Point.new(37.641826, 55.758856)
	
	#treeL.findSegmentsNearPoint(pt, 0.05)
	#treeL.findSegmentsNearPoint(pt2, 0.05)
	t1 = Time.now()
	res = treeL.findSegmentsNearPoint(pt3, 0.05)
	t2 = Time.now()
	
	puts "\n\nНашли: #{res.size} сегментов за #{t2-t1} секунд:\n"
	res.each{|seg|
		puts "\t#{seg.getPoints[0].x};#{seg.getPoints[0].y};#{seg.getPoints[1].x};#{seg.getPoints[1].y}\n"
	}
	
	
	
	pt4 = Point.new(37.641827, 55.758857)
	t1 = Time.now()
	res2 = treeL.findSegmentsNearPoint(pt4, 0.05)
	t2 = Time.now()
	puts "\n\nНашли: #{res2.size} сегментов за #{t2-t1} секунд\n"
	res2.each{|seg|
		puts "\t#{seg.getPoints[0].x};#{seg.getPoints[0].y};#{seg.getPoints[1].x};#{seg.getPoints[1].y}\n"
	}
	
	
	
	#treeL.print_internal
	

=end
