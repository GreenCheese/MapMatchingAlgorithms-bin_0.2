puts "LOADING \"#{__FILE__}\"..."
require 'drb/drb'

#SERVER_URI ="druby://192.168.79.95:8787"
#SERVER_URI ="druby://192.168.77.211:8787"
#SERVER_URI ="druby://10.68.41.55:8787"
SERVER_URI ="druby://10.0.0.20:8787"


$:.unshift((File.dirname(__FILE__)+"/graph/"))
require 'graph.rb'

$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'point.rb'

$:.unshift((File.dirname(__FILE__)+"/../commonStructs/"))
require 'geometry.rb'

$:.unshift((File.dirname(__FILE__)+"/rbTree/"))
require 'rbtree.rb'

#$:.unshift((File.dirname(__FILE__)+"/rStarTreeFileStatic_v3-treeManager/"))
#require 'treeManager.rb'



TREE_SEARCH_ITEM_RADIUS = 0.05

Geom = Geometry.new


#To Work with DRB
def getRoadTree
	DRb.start_service
	return DRbObject.new_with_uri(SERVER_URI)	
end

#def getRoadTree
#	return TreeManager.getTree
#end


def matchPointToGraph(point, t)
	res = t.findSegmentsNearPoint(point, TREE_SEARCH_ITEM_RADIUS)
	#должна выдавать несколько результатов, меньше некоторого минимума.
	finedNear = Geom.getNearestPointSpatial(res, point) #TODO
	return finedNear
end

def searchSegmentBuffer(p1, p2, t)
#t1 = Time.now
	segArr=[]
	rbtree = RBTree.new

	radius = Geom.spatialLength2D(p1, p2)
	searchRadius = 2*radius
	
#t2 = Time.now
#p "searchSegmentBuffer calcRadius time #{t2-t1}"	

	#Собираем все сегменты в радиусе удвоенного расстояния от начальной точки до конечной вокруг начальной точки
#t1 = Time.now
	res = t.findSegmentsNearPoint(p1, searchRadius)

#t2 = Time.now
#p "searchSegmentBuffer findSegmentsNearPoint time #{t2-t1}"	

#t1 = Time.now	

	


	res.each{|seg|
		node = rbtree.rbTreeSarch(rbtree.root, seg.index)
		if node.key == nil
			item = Node.new(seg.index)
			rbtree.Insert(item)

			segArr << seg
		end
	}
#t2 = Time.now
#p "searchSegmentBuffer storeArray1 time #{t2-t1}"	
	#Собираем все сегменты в радиусе удвоенного расстояния от начальной точки до конечной вокруг конечной точки
#t1 = Time.now
	res = t.findSegmentsNearPoint(p2, searchRadius)
#t2 = Time.now
#p "searchSegmentBuffer findSegmentsNearPoint time #{t2-t1}"	

#t1 = Time.now		
	res.each{|seg|
		node = rbtree.rbTreeSarch(rbtree.root, seg.index)
		if node.key == nil
			item = Node.new(seg.index)
			rbtree.Insert(item)

			segArr << seg
		end
	}
#t2 = Time.now
#p "searchSegmentBuffer storeArray2 time #{t2-t1}"	
	return segArr	
end

def insertSFPointsIntoSegArrBothPt(segArr, insPoint1, insPoint2)
	
	#Если индексы разные - вставляем как обычно.
	if (insPoint1.segmentIndex!=insPoint2.segmentIndex)
		#p "***as usual p1:***"
		segArr = insertSFPointsIntoSegArr(segArr, insPoint1)
		#p "***as usual p2:***"
		segArr = insertSFPointsIntoSegArr(segArr, insPoint2)
		return segArr
	end


	checkPointRelativSeg = false
	
	insPointsegInd	= nil
	insPointInd1	= nil
	isSegPt1		= nil
	insPointInd2	= nil
	isSegPt2		= nil
	ptToSeg1		= nil
	ptToSeg2		= nil
	
	#ELSE:
	if (insPoint1.index<insPoint2.index)
		insPointsegInd = insPoint1.segmentIndex
		insPointInd1 = insPoint1.index
		isSegPt1 = insPoint1.isSegmentPoint

		insPointInd2 = insPoint2.index
		isSegPt2 = insPoint2.isSegmentPoint

		ptToSeg1 = Point.new(insPoint1.x, insPoint1.y)
		ptToSeg2 = Point.new(insPoint2.x, insPoint2.y)
	else
		#SWAP INDEXES 1 and 2
		#если индекс точек совпадает, то факт того, какая из них первая, зависит от того, к какой точке сегмента какая точка лежит ближе...
		
		# insPoint1.index строго больше insPoint2.index
		if(insPoint1.index!=insPoint2.index)
			insPointsegInd = insPoint2.segmentIndex
			insPointInd1 = insPoint2.index
			isSegPt1 = insPoint2.isSegmentPoint

			insPointInd2 = insPoint1.index
			isSegPt2 = insPoint1.isSegmentPoint

			ptToSeg1 = Point.new(insPoint2.x, insPoint2.y)
			ptToSeg2 = Point.new(insPoint1.x, insPoint1.y)
		else
			#insPoint1.index равен insPoint2.index
			insPointsegInd = insPoint1.segmentIndex
			checkPointRelativSeg = true
		end
	end
	
	res = []

	segArr.each{|seg|
		if (seg.index == insPointsegInd)
	

			#    	 segPT
			# 		  |
			# |-------|---------|------------|
			#  \______/\________/\___________/
			#  0   1       2           3
			
			if (checkPointRelativSeg)
				#ясно, что insPoint1.index == insPoint2.index
				segPT = seg.pointsArr[insPoint1.index]
				lenPT1 = Geom.spatialLength2D(segPT, insPoint1)
				lenPT2 = Geom.spatialLength2D(segPT, insPoint2)
				#Точка insPoint1 находится дальше от segPT, чем точка insPoint2
				#puts "lenPT1 = #{lenPT1}"
				#puts "lenPT2 = #{lenPT2}"

				if (lenPT1 > lenPT2)

					#insPointsegInd = insPoint1.segmentIndex
					insPointInd1 = insPoint1.index
					isSegPt1 = insPoint1.isSegmentPoint

					insPointInd2 = insPoint2.index
					isSegPt2 = insPoint2.isSegmentPoint

					ptToSeg1 = Point.new(insPoint1.x, insPoint1.y)
					ptToSeg2 = Point.new(insPoint2.x, insPoint2.y)
				
				elsif (lenPT1 < lenPT2)
					#insPointsegInd = insPoint2.segmentIndex
					insPointInd1 = insPoint2.index
					isSegPt1 = insPoint2.isSegmentPoint

					insPointInd2 = insPoint1.index
					isSegPt2 = insPoint1.isSegmentPoint

					ptToSeg1 = Point.new(insPoint2.x, insPoint2.y)
					ptToSeg2 = Point.new(insPoint1.x, insPoint1.y)
				else
					puts "\n\n***ERRR POINTS ARE THE SAME***\n\n"
					exit
				end
			end

			#тут надо запихнуть 2 точки, образовав 3 новых сегмента
			
			segA = nil #Segment.new
			segB = nil #Segment.new
			segC = nil #Segment.new
			
			tmpPointsArr = []
			
			if (insPointInd1 != 0 and !(insPointInd2==seg.pointsArr.size-1 and isSegPt2==true)) #Разобраться!TODO
				tmpLen = 0
				for i in 0..insPointInd1-1
					tmpPointsArr << seg.pointsArr[i]
				end
				tmpPointsArr << ptToSeg1
								

				tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
				parentIndex = getParentIndex(seg.getParentIndex, seg.index)
				segA = Segment.new(tmpPointsArr,seg.externalID, -seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.fzlev) #TODO - необходимо предусмотреть случай, когда начальная и конечная точка попадают на один сегмент. Тогда сегмент разделяется на 3 куска, и отрицательные id не должны совпадать.
				segA.setParentIndex(parentIndex)

				#segA = Segment.new(tmpPointsArr,seg.externalID,-seg.index,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,seg.featlen,seg.fzlev,seg.tzlev)

				tmpPointsArr = nil
				tmpPointsArr = []
				tmpPointsArr << ptToSeg1

				if (checkPointRelativSeg)
					tmpPointsArr << ptToSeg2
					tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
					parentIndex = getParentIndex(seg.getParentIndex, seg.index)
					segB = Segment.new(tmpPointsArr,seg.externalID, -seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.fzlev)
					segB.setParentIndex(parentIndex)
				else
					if (isSegPt1==false)
						for i in insPointInd1..insPointInd2-1
							tmpPointsArr << seg.pointsArr[i]
						end
					else
						for i in insPointInd1+1..insPointInd2-1
							tmpPointsArr << seg.pointsArr[i]
						end
					end
					tmpPointsArr << ptToSeg2
					#tmpPointsArr << seg.pointsArr[insPointInd2]
					tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
					parentIndex = getParentIndex(seg.getParentIndex, seg.index)
					segB = Segment.new(tmpPointsArr,seg.externalID, -seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.fzlev)
					segB.setParentIndex(parentIndex)
				end
				
				tmpPointsArr = nil
				tmpPointsArr = []
				tmpPointsArr << ptToSeg2


				if (isSegPt2==false)
					for i in insPointInd2..seg.pointsArr.size-1
						tmpPointsArr << seg.pointsArr[i]
					end
				else
					for i in insPointInd1+1..seg.pointsArr.size-1
						tmpPointsArr << seg.pointsArr[i]
					end
				end
				tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
				parentIndex = getParentIndex(seg.getParentIndex, seg.index)
				#segC = Segment.new(tmpPointsArr,seg.externalID,seg.index,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.tzlev)
				segC = Segment.new(tmpPointsArr,seg.externalID,-seg.index-rand(150000),seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.tzlev)
				segC.setParentIndex(parentIndex)
				#p "segB"
				#p segB
				res << segA
				res << segB
				res << segC
			else
				#puts "ELSE!"
				if (insPointInd1 == 0)
					res = insertSFPointsIntoSegArr(segArr, insPoint2)
				elsif (insPointInd2==seg.pointsArr.size-1 and isSegPt2==true)
					res = insertSFPointsIntoSegArr(segArr, insPoint1)
				else
					res << seg
				end
			end

		else
			res << seg
		end
	}
	return res

	
end

def getParentIndex(segParentIndex, segIndex)
	if (segParentIndex!=nil)
		return segParentIndex
	else
		return segIndex
	end
end

def insertSFPointsIntoSegArr(segArr, insPoint)

	insPointsegInd = insPoint.segmentIndex
	insPointInd = insPoint.index
	isSegPt = insPoint.isSegmentPoint

	ptToSeg = Point.new(insPoint.x, insPoint.y)
	res = []
	#i = 0
	segArr.each{|seg|
		#i=i+1
		#p "i: #{i} seg.index = #{seg.index}"
		if (seg.index == insPointsegInd)
			
						
			segA = nil #Segment.new
			segB = nil #Segment.new
			
			tmpPointsArr = []
			#
			#puts "insPointInd = #{insPointInd}"
			if (insPointInd != 0 and !(insPointInd==seg.pointsArr.size-1 and isSegPt==true)) #Разобраться!TODO
			#if (insPointInd != 0 or insPointInd!=seg.pointsArr.size-1)
				#puts "not Edge"
				for i in 0..insPointInd-1
					tmpPointsArr << seg.pointsArr[i]
				end
				tmpPointsArr << ptToSeg
				#p "insPoint: #{insPoint.inspect}"
				#p "srcSeg: #{seg.inspect}"

								
				#segA = Segment.new(tmpPointsArr,seg.externalID,-seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,seg.featlen,seg.fzlev,seg.tzlev) #TODO - необходимо предусмотреть случай, когда начальная и конечная точка попадают на один сегмент. Тогда сегмент разделяется на 3 куска, и отрицательные id не должны совпадать.
				tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
				


				parentIndex = getParentIndex(seg.getParentIndex, seg.index)

				segA = Segment.new(tmpPointsArr,seg.externalID,-seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.fzlev)
				segA.setParentIndex(parentIndex)
				#p "segA: #{segA.inspect}"
				
				#segA = Segment.new(tmpPointsArr,seg.externalID,-seg.index,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,seg.featlen,seg.fzlev,seg.tzlev)

				#puts "\n\n"
				#p "segA"
				#p segA
				tmpPointsArr = nil
				tmpPointsArr = []
				tmpPointsArr << ptToSeg
				if (isSegPt==false)
					for i in insPointInd..seg.pointsArr.size-1
						tmpPointsArr << seg.pointsArr[i]
					end
				else
					for i in insPointInd+1..seg.pointsArr.size-1
						tmpPointsArr << seg.pointsArr[i]
					end
				end
				tmpLen = Geom.getSequencePointsLen(tmpPointsArr)*1000
				parentIndex = getParentIndex(seg.getParentIndex, seg.index)

				#segB = Segment.new(tmpPointsArr,seg.externalID,seg.index,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.tzlev,parentIndex)
				segB = Segment.new(tmpPointsArr,seg.externalID,-seg.index-rand(150000).to_i,seg.f_speedLim,seg.t_speedlim,seg.oneway,seg.f_buslanes,seg.t_buslanes,tmpLen,seg.fzlev,seg.tzlev)
				segB.setParentIndex(parentIndex)
				#p "segB: #{segB.inspect}"
				res << segA
				res << segB
			else
				#puts "Edge"
				res << seg
			end
		else
			res << seg
		end
	}
	return res
end

def printSeg(segArr, id)
	segArr.each{|seg|
		if (seg.index==id)
			p1 = seg.pointsArr[0]
			#p seg
			for i in 1..seg.pointsArr.size-1
				p2 = seg.pointsArr[i]
				p "#{p1.x};#{p1.y};#{p2.x};#{p2.y}"

				p1 = p2
			end
		end
	}
end

def generatePath(segArr, idArr)
	rp = RoadPath.new
	len = 0
				
	idArr.each{|arrayIndex|
		segArr.each{|seg|
			if(seg.index == arrayIndex)
				rp.addSegment(seg)
				len = len + seg.featlen/1000
				break
			end
		}
	}
	rp.setPathLen(len)
	return rp
end

def printSegExtend(segArr, id)
	segArr.each{|seg|
		if (seg.index==id)
			p1 = seg.pointsArr[0]
			#p seg
			for i in 1..seg.pointsArr.size-1
				p2 = seg.pointsArr[i]
				puts "#{p1.x};#{p1.y};#{p2.x};#{p2.y};#{id}"
				p seg
				p1 = p2
			end
		end
	}
end

def segArrDeponPointsFromTree(p1, p2)

############################## TREE WORK #############################
################## GET SEGMENT ARR DEPENDS ON POINT ##################
################## ARGS (T, POINT_S, POINT_F, SEGAR) #################
	#Получаем доступ к дереву.


	
	t = getRoadTree


	sp1 = nil
	sp2 = nil

	#Ищем все сегменты на расстоянии 50 метров от начальной точки
	#должна выдавать несколько результатов, меньше некоторого минимума.
	#finedNear = geom.getNearestPointSpatial(res, p1) #TODO

	
	startFindNear = matchPointToGraph(p1, t)
	sp1 = startFindNear
	
	#Ищем все сегменты на расстоянии 50 метров от конечной точки
	#Обязательно после insertSFPointsIntoSegArr(segArr, sp1), т.к. id сегментов могли поменяться после вставки первой точки
	#а вторая точка может попасть на тот же самый сегмент

	finishFindNear = matchPointToGraph(p2, t)
	sp2 = finishFindNear

 	segArr = []

	segArr = searchSegmentBuffer(p1, p2, t)


	#p "segArr.size = #{segArr.size}"
	#p "segArr.uniq.size = #{segArr.uniq.size}"
	#testArr = []
	#segArr.each{|seg|
	#	testArr << seg.index
	#}
	#puts "testArr.size = #{testArr.size}"
	#puts "testArr.uniq.size = #{testArr.uniq.size}"
	
	segArr = insertSFPointsIntoSegArrBothPt(segArr, sp1, sp2)

#puts "\n**********\n"
#	segArr.each{|seg|
#		p seg
#	}

#t1 = Time.now
	#segArr = insertSFPointsIntoSegArr(segArr, sp1)
#t2 = Time.now
#p "insertSFPointsIntoSegArr sp1 time #{t2-t1}"







#t1 = Time.now
	#segArr = insertSFPointsIntoSegArr(segArr, sp2)
#t2 = Time.now
#p "insertSFPointsIntoSegArr sp2 time #{t2-t1}"		

	return [sp1,sp2,segArr]
############################## /TREE WORK #############################
################## /GET SEGMENT ARR DEPENDS ON POINT ##################

	
end

def fillGraph(gr, segArr)
	############################# CREATE GRAPH ############################
	######################### ARGS (GR, SEGMENTS) #########################

	iii = 0 
	segArr.each{|seg|
		iii = iii + 1
		pu = seg.pointsArr[0]
		zulevel = seg.fzlev
	
		segow = seg.oneway
		segInd = seg.index

		pv = seg.pointsArr[-1]
		
		zvlevel = seg.tzlev
	
		w = seg.featlen

		#if (segInd == 110862)
		#	puts "SEG INDEX (#{iii}) == 110862"
		#	puts "seg ow = #{segow}"
		#end

		puz = PointOfSegmentZ.new(pu.x, pu.y, zulevel, segow, true, segInd)
		pvz = PointOfSegmentZ.new(pv.x, pv.y, zvlevel, segow, false, segInd)
		

		#puts "segow = #{segow}"
		#puts "puz = #{puz.inspect}\n"
		#puts "pvz = #{pvz.inspect}\n\n"
		
		#t1 = Time.now
		gr.insert(puz,pvz,w)
		if (!segow)
			gr.insert(pvz,puz,w)
		end
		#t2 = Time.now
		#p "fillGraph gr.insert = #{t2-t1}"
	}
												   

	############################ /CREATE GRAPH ############################
end

def operateGraph(gr, sp1, sp2)
	#################### FIND START VERTEX GRAPH INDEX ####################

	index = gr.getVertexIndex(sp1)
	#gr.printGraph
	#exit

	######################## GET START VERTEX GRAPH #######################
	v = gr.getVertexList[index].getVertex

	
	dA = DijkstraAlgorithm.new
	dA.run(gr,v)

	##################### GET FINISH VERTEX AT DIJKSTRA ###################
	dv = dA.getVertex(sp2)
	return dv

end

def resultPath(v)
	######################### RESTORE RESULT PATH #########################
	#v = dv
	p1 = v.getKey

	reversed = []

	while true
		if(v.p==nil)
			break
		end

		v = v.p
		p2 = v.getKey

		if (p2.segmentIndex.uniq.size==1)
			si = p2.segmentIndex[0]
			reversed << si
		else
			si = p2.segmentIndex&p1.segmentIndex
		
			if si!=[] 
				reversed << si[0]
			end
		end
		p1=p2
	end
	reversed.reverse!
	return reversed
	######################### /RESTORE RESULT PATH #########################
end

def getPath(p1, p2)

#t1 = Time.now
	result = segArrDeponPointsFromTree(p1,p2)
	sp1 = result[0]
	sp2 = result[1]
	#if(@@DEBUG)
		puts "sp1 = #{sp1.inspect}"
		puts "sp2 = #{sp2.inspect}"
	#end

	# *******************************************************
	# * зона поиска: 										*
	# * включает сегмент, разбитый в соответствии с p1 и p2 *
	# *******************************************************
	segArr = result[2]
	#p segArr



#	segArr.each{|seg|
#	#puts "\n\n"
#	size = seg.pointsArr.size
#	
#	p0 = seg.pointsArr[0]
#	for i in 1..size-1
#		p1 = seg.pointsArr[i]
#		puts "#{p0.x};#{p0.y};#{p1.x};#{p1.y}\n"
#			
#		p0 = p1
#	end
#}
#t2 = Time.now
#p "DB Search Segment time #{t2-t1}"


#t1 = Time.now
	gr = Graph.new(DIJKSTRA)
	fillGraph(gr, segArr)
#t2 = Time.now
#p "total graph insert time = #{t2-t1}"


#t1 = Time.now
	# *******************************************************
	# * поиск пути от точки sp1 до sp2 в графе gr:			*
	# * возврашяет конечную точку в графе  					*
	# * (точку, которая соответствует sp2)					*
	# *******************************************************

	targetPoint = operateGraph(gr, sp1, sp2)
#t2 = Time.now
#p "Dijkstra time = #{t2-t1}"


	
	res = resultPath(targetPoint)
	#puts "tp res = #{res.inspect}\n targetPoint = #{targetPoint.inspect}"


	#
	#puts "targetPoint.key.x = #{targetPoint.getData[0]}"
	#puts "targetPoint.key.y = #{targetPoint.getData[1]}"
	#targetPoint.getKey.segmentIndex.each{|segInd|
	#	puts "segInd: #{segInd}"
	#	printSeg(segArr, segInd)
	#}

=begin
	res.each{|segInd|
		#printSeg(segArr, segInd)
		printSegExtend(segArr, segInd)
	}
=end
	return generatePath(segArr, res);

	
end


#участок с бабочкой - косяк
#p1 = Point.new(37.661219,55.616140)
#p2 = Point.new(37.660414,55.614171)

#участок с круговым движением  - косяк
#p1 = Point.new(37.659116,55.628178)
#p2 = Point.new(37.661712,55.630649)

#отрезок 2 км
#p1 = Point.new(37.752757,55.606451)
#p2 = Point.new(37.721643,55.612438)

#короткий отрезок
#p1 = Point.new(37.749603,55.604693)
#p2 = Point.new(37.744024,55.607396)
#radius = get_length(p1, p2)


#pcenter = Point.new((37.752757+37.721643)/2,(55.606451+55.612438)/2)

#getPath(p1,p2)




=begin

a = Point.new(10, 10)
b = Point.new(20, 10)
c = Point.new(30, 10)
d = Point.new(40, 10)
e = Point.new(50, 10)

ptArr = [a,b,c,d,e]

puts  "ptArr.size = #{ptArr.size}"

#testP = Point.new(31, 11)
#testP2 = Point.new(20, 11)

testP = Point.new(15, 11)
testP2 = Point.new(26, 11)



#pointsArr,externalID,index,f_speedLim,t_speedlim,oneway,f_buslanes,t_buslanes,featlen,fzlev,tzlev
seg = Segment.new(ptArr, 111, 2, 60, 60, true, true, true, 10, 1, 1)
testSegArr = [seg]

sPtestP = Geom.getNearestPointSpatial(testSegArr, testP)
sPtestP2 = Geom.getNearestPointSpatial(testSegArr, testP2)
puts "\nsPtestP = #{sPtestP.inspect}"


#insertSFPointsIntoSegArr

res = insertSFPointsIntoSegArrBothPt(testSegArr, sPtestP, sPtestP2)
#res = insertSFPointsIntoSegArrBothPt(testSegArr, sPtestP2, sPtestP)
#res = insertSFPointsIntoSegArr(testSegArr,sPtestP)

i = 0 
res.each{|element|
	i = i + 1
	puts "element #{i}:\n"
	element.pointsArr.each{|pt|
		puts "\t#{pt.inspect}\n"
	}
}
=end


=begin

p1 = Point.new(37.729632, 55.827098)
p2 = Point.new(37.609908, 55.806995)
t = getRoadTree

radius = Geom.spatialLength2D(p1, p2)
p radius

t1 = Time.now
res = t.findSegmentsNearPoint(p1, radius)
t2 = Time.now
p "findSegmentsNearPoint 1 #{t2-t1}"
p res.size
=end


=begin

res.each{|seg|
	puts "\n\n"
	


	size = seg.pointsArr.size
	
	p0 = seg.pointsArr[0]
	for i in 1..size-1
		p1 = seg.pointsArr[i]
		puts "#{p0.x};#{p0.y};#{p1.x};#{p1.y}\n"
			
		p0 = p1
	end
}
=end



#p res
#res = t.findSegmentsNearPoint(p1, 2*radius)
