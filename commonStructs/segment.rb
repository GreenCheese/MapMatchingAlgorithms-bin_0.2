

#иерархия классов и подклассов сегментов

puts "LOADING \"#{__FILE__}\"..."
#интерфейс
class Segment
	attr_accessor :pointsArr
	attr_accessor :externalID 	#External
	attr_accessor :index 		#internal
	attr_accessor :f_speedLim
	attr_accessor :t_speedlim
	attr_accessor :oneway
	attr_accessor :f_buslanes
	attr_accessor :t_buslanes
	attr_accessor :featlen
	attr_accessor :fzlev
	attr_accessor :tzlev
end