
puts "LOADING \"#{__FILE__}\"..."
#создает и пополняет структуру минисегментов скоростей.



#незабыть про
# разбиение времени
#
#
# 


#RoadPathData
# 	|
#   +--[header1] //times
# 	|	|
# 	|	+ [id1_from_roadTree] 
# 	|	|	|
# 	|	|	+ segment1
# 	|	|	|
# 	|	|	+ segment2
# 	| 	+ [id2_from_roadTree]
# 	|
#   + [header2]


class RoadPathData
	:data
	:periodicity
	:periodicity_offset
	def initialize(periodicity, periodicity_offset)
		@data = {}

		@periodicity = periodicity
		if (@periodicity == 1)
			@periodicity_offset = 0 
		else
			@periodicity_offset = periodicity_offset % @periodicity
		end
	end

	def add
		
	end

end

class Accumulator

	:rpd

	def initialize
		@rpd = RoadPathData.new
	end

	def method_name
		
	end

	def add (roadPath)

		#puts "\n*******************\n#{roadPath.inspect}\n*******************\n"
		#puts "#{roadPath.inspect}\n*******************\n\n"
		roadPath.getSegments.each{|seg|
			
			p seg.getParentIndex
		}

	end
end