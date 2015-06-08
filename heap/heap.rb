puts "LOADING \"#{__FILE__}\"..."
#nonincreasing heap
NIL_INT_MIN = -999999999
NIL_INT_MAX = 999999999

class Heap
	:heapSize
	def initialize
		@heapSize = 0
	end

	def parent(i)
		return i/2
	end

	def left(i)
		return 2*i
	end

	def right(i)
		return 2*i+1
	end
end

#nonincreasing heap
class NICHeap < Heap
	def initialize
		super
	end

	def maxHeapfy(arr, i)
		l = left(i)
		r = right(i)
		largest = 0

		if(l<=@heapSize and arr[l-1]>arr[i-1])
			largest = l
		else
			largest = i
		end

		if (r<=@heapSize and arr[r-1]>arr[largest-1])
			largest = r
		end

		if(largest!=i)
			t = arr[i-1]
			arr[i-1] = arr[largest-1]
			arr[largest-1] = t
			maxHeapfy(arr, largest)
		end
	end

	def buildMaxHeap(arr)
		@heapSize = arr.size
		st = ((arr.size)/2)
		st.downto(1){|i|
			maxHeapfy(arr,i)
		}
	end
end

#nondecreasing heap
class NDCHeap <Heap
	def minHeapfy(arr, i)
		l = left(i)
		r = right(i)
		smallest = 0

		if(l<=@heapSize and arr[l-1].key<arr[i-1].key)
			smallest = l
		else
			smallest = i
		end

		if (r<=@heapSize and arr[r-1].key<arr[smallest-1].key)
			smallest = r
		end

		if(smallest!=i)
			t = arr[i-1]
			arr[i-1] = arr[smallest-1]
			arr[smallest-1] = t
			minHeapfy(arr, smallest)
		end
	end

	def buildMinHeap(arr)
		@heapSize = arr.size
		st = ((arr.size)/2)
		st.downto(1){|i|
			minHeapfy(arr,i)
		}
	end
end

#nondecreasing priority queue
class NDCPriorityQueue < NDCHeap
	:a
	def initialize
		@a = Array.new
		super()
	end

	def minHeapInsert(element)
		@heapSize = @heapSize + 1
		#@a[@heapSize-1]=QueueElement.new(element.data,NIL_INT_MAX)
		@a << QueueElement.new(element.data,NIL_INT_MAX)
		heapDecreaseKey(@heapSize, element.key)
	end

	def heapExtractMin
		if (@heapSize < 1)
#			puts "Queue is empty"
			return nil
		end
		min = @a[0]
		@a[0] = @a[@heapSize-1]
		@a[@heapSize-1] = nil
		@heapSize = @heapSize - 1

		minHeapfy(@a, 1)
		return min.data
	end

	def getIndex(k)
		for i in 1..@heapSize
			if (@a[i-1].data==k)
				#puts @a[0].data.class
				return i
			end
		end
		return nil
	end

	def heapDecreaseKey(i, key)
		#p i 
		if (@a[i-1].key<key)
			puts "New key is bigger than current"
			return 
		end

		@a[i-1].key = key

		#p @a
		while (i>1 and @a[parent(i)-1].key>@a[i-1].key)
			tmp = @a[i-1]
			@a[i-1] = @a[parent(i)-1]
			@a[parent(i)-1] = tmp
			i = parent(i)
		end
	end

	def printW
		tmp = ""
		for i in 0..@heapSize-1
			tmp = tmp + "#{@a[i].key}, "
		end
		puts tmp
	end

	def print
		p @a
	end

	def heapMinimum
		if (@heapSize != 0)
			return a[0]
		end
	end
end

#nonIncreasing priority queue
class NICPriorityQueue < NICHeap
	:a
	def initialize
		@a = Array.new
		super()
	end

	def maxHeapInsert(key)
		@heapSize = @heapSize + 1
		@a[@heapSize-1]=NIL_INT_MIN
		heapIncreaseKey(@heapSize, key)
	end

	def heapExtractMax
		if (@heapSize < 1)
			#puts "Queue is empty"
			return nil
		end
		max = @a[0]
		@a[0] = @a[@heapSize-1]
		@a[@heapSize-1] = nil
		@heapSize = @heapSize - 1
		maxHeapfy(@a, 1)
		return max
	end

	def heapIncreaseKey(i, key)
		if (@a[i-1]>key)
			puts "New key is smaller than current"
			return 
		end
		@a[i-1] = key

		while (i>1 and @a[parent(i)-1]<@a[i-1])
			tmp = @a[i-1]
			@a[i-1] = @a[parent(i)-1]
			@a[parent(i)-1] = tmp
			i = parent(i)
		end
	end

	def print
		p @a
	end

	def heapMaximum
		if (@heapSize != 0)
			return a[0]
		end
	end
end

class QueueElement
	:data
	
	def initialize(data, key)
		@data = data
		@key = key
	end

	attr_accessor :key
	attr_accessor :data
end


#ndcpq = NDCPriorityQueue.new(10)
#ndcpq.minHeapInsert(QueueElement.new("q",4))
#ndcpq.minHeapInsert(QueueElement.new("w",2))
#ndcpq.print
#ndcpq.heapDecreaseKey(2, 1)
#ndcpq.print


#ndcpq = NDCPriorityQueue.new
#ndcpq.minHeapInsert(QueueElement.new("q",1))
#ndcpq.minHeapInsert(QueueElement.new("w",3))
#ndcpq.minHeapInsert(QueueElement.new("e",2))
#ndcpq.minHeapInsert(QueueElement.new("r",16))
#ndcpq.minHeapInsert(QueueElement.new("t",9))
#ndcpq.minHeapInsert(QueueElement.new("y",10))
#ndcpq.minHeapInsert(QueueElement.new("u",14))
#ndcpq.minHeapInsert(QueueElement.new("i",8))
#ndcpq.minHeapInsert(QueueElement.new("o",7))
#
#
#
#ndcpq.print
#ndcpq.heapDecreaseKey(7, 2)
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print
#ndcpq.heapExtractMin
#ndcpq.print