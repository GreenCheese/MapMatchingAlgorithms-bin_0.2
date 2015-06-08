
#Реализация геометрических преобразований и вычислений

puts "LOADING \"#{__FILE__}\"..."
$:.unshift(File.dirname(__FILE__))

require 'point'
require 'segment'

class Geometry
	def initialize
		@ConstXFactorMoscowRegion = 63.85
		@ConstyFactorMoscowRegion = 111.1329
	end

private

	def getLengthFormula (point1, point2)
		return lambda{Math.sqrt((((point1.x - point2.x)**2)*(@xFactor**2)) + (((point1.y - point2.y)**2)*(@yFactor**2)))}
	end

public

	def getSequencePointsLen(pointsArray)
		len = 0
		p1 = pointsArray[0]
		
		for i in 1..pointsArray.size-1
			p2 = pointsArray[i]
			len = len + spatialLength2D(p1, p2)
			p2 = p1
		end
		return len
	end
	#Находит точку пересечения отрезка и перпендикуляра, опущенного из точки на этот отрезок
	#Если перпендикуляр опускается за пределы отрезка, возвращает nil
	def getNormalCrossForEdgeSpatial (point, pa, pb)
	#					P(xp,yp)
	#					  /|\
	#					 / | \
	#		pa(x1,y1)------O-----pb(x2,y2)
	
		xFactor = @ConstXFactorMoscowRegion
		yFactor = @ConstyFactorMoscowRegion
	
		xp = point.x*xFactor
		x1 = pa.x*xFactor
		x2 = pb.x*xFactor
	
		yp = point.y*yFactor
		y1 = pa.y*yFactor
		y2 = pb.y*yFactor
	
		xPer = 0.0
		yPer = 0.0
	
		xMin = 0.0
		yMin = 0.0
		xMax = 0.0
		yMax = 0.0
	
	
		if (x1<x2)
			xMin =  x1
			xMax =  x2
		else
			xMin = x2
			xMax = x1
		end
	
		if (y1<y2)
			yMin =  y1
			yMax =  y2
		else
			yMin = y2
			yMax = y1
		end
	
		if (x1==x2)
			xPer = x1
			yPer = yp
		elsif (y1==y2)
			xPer = xp
			yPer = y1
		else
			xPer = (((x1*(y2-y1)**2+xp*(x2-x1)**2+(x2-x1)*(y2-y1)*(yp-y1))).to_f/((y2-y1)**2+(x2-x1)**2)).to_f
			yPer = (((((x2-x1)*(xp-xPer))).to_f/(y2-y1))+yp).to_f
		end
	
		if (xMin<=xPer and xMax>=xPer and yMin<=yPer and yMax>=yPer)
			return Point.new((xPer/xFactor).round(8), (yPer/yFactor).round(8))
		end
	
		return nil
		#pPer = Point.new(xPer/xFactor, yPer/yFactor)
	end

	#врозвращает расстояние между двумя точками в пространстве (на вход - долгота и широта)
	def spatialLength2D(p1, p2)
		@xFactor = @ConstXFactorMoscowRegion
		@yFactor = @ConstyFactorMoscowRegion
		t = getLengthFormula(p1,p2)
		return t.call
	end

	#врозвращает расстояние между двумя точками в пространстве (на вход - координаты точки на плоскости)
	def planarLength2D(p1, p2)
		@xFactor = 1
		@yFactor = 1
		t = getLengthFormula(p1,p2)
		return t.call
	end

	#Алгоритм получает на вход массив сегментов, каждый их которых состоит из массива точек и точку p
	#Каждая последовательная пара точек представляет собой отрезок.
	#Алгоритм смотрит расстояние от точки p до границ отрезка, а так же строит перпендикуляр к нему.
	#Возвращает:
	# 	точку, расстояние от которой до точек сегмента или перпендикуляру к отрезу минимально.
	# 	индекс сегмента в начальном массиве, для которой нашли эту точку
	# 	индекс точки n в сегменте, на участке которого [n-1, n] есть искомая точка.

	def getNearestPointSpatial(segArr, p)
		minLen = 10000
		minPt = nil
		isSegmentPt = false
		
		#segIndex = 0
		minSegIndex = - 1
		minPtIndex = - 1
		resIsSegmentPt = false

		segArr.each{|segment|
			ptIndex = 0 
			pts = segment.pointsArr
			size = pts.size
			
			p1 = pts[0]
	
			len = spatialLength2D(p1, p)
			if len<minLen
				minLen = len
				isSegmentPt = true
				minPt = p1
				minSegIndex = segment.index
				minPtIndex = ptIndex
				resIsSegmentPt = isSegmentPt
			end
	
			for i in 1..size-1
				ptIndex = ptIndex + 1
				p2 = pts[i]
	
				len = spatialLength2D(p2, p)
				if len<minLen
					minLen = len
					isSegmentPt = true
					minPt = p2
					minSegIndex = segment.index
					minPtIndex = ptIndex
					resIsSegmentPt = isSegmentPt
				end
	
				crossP = getNormalCrossForEdgeSpatial(p, p1, p2)
	
				#crossP = nil #!!!!!!!!!!!! TODO заглушка

				if (crossP!=nil)
					crossLen = spatialLength2D(crossP, p)
					if crossLen<minLen
						minLen = crossLen
						isSegmentPt = false
						minPt = crossP
						minSegIndex = segment.index
						minPtIndex = ptIndex
						resIsSegmentPt = isSegmentPt
					end
				end
				p1=p2
			end
		}
	
		#puts "\tDEBUG minLen = #{minLen}\nminPt = #{minPt}\nisSegmPt = #{isSegmentPt}"

		return CrossSearchPiont.new(minPt.x, minPt.y, minPtIndex, minSegIndex, resIsSegmentPt)
		#return [minPt, minSegIndex, minPtIndex]
	end



private 
	:ConstXFactorMoscowRegion
	:ConstyFactorMoscowRegion
	:xFactor
	:yFactor
end