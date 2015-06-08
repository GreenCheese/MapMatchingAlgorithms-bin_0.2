puts "LOADING \"#{__FILE__}\"..."
#FileStruct = "structTree"
#FileData = "data"
#HEADER_SIZE = 38
#NODE_SIZE = 218
#DATA_SIZE = 91
#NIL_INT = -999999999
require 'win32ole'

class TreeStore
	attr_accessor :nextFreeStructOffset
	attr_accessor :nextFreeDataOffset
	attr_accessor :tree

	def initialize (tree)
		@tree = tree
		@nextFreeStructOffset = 0
		@nextFreeDataOffset = 0
	end


	def storeTreeHeader
		str = Marshal.dump(@tree)
		hs = IO.binwrite(FileStruct, str, 0)
		return str.size
	end

	def store
		hSize = storeTreeHeader()

		@nextFreeStructOffset = @nextFreeStructOffset + hSize

		node = @tree.root
		#p node
		size = store_item(node)
		#p size
		
		tree.root_offset = node.offset
		tree.root_size = size
		hSize = storeTreeHeader()

		storeCode(hSize)
	end

	def storeCode(code)
		f = File.new(FileCode, "wb+")
		f.write(code)
		f.close
	end

	#вообще, все сохранение происходит в 2 этапа:
	#от листьев к корню. 
	#1. Сначала сохраняются все дети узла
	#2. в узле прописываются все смещения
	#3. затем сохраняется родитель
	#4. у детей прописываются смещения родителя
	#5. Дети повторно сохраняются уже финально...
	#!!! Проблема в том, чтобы обеспечить одинаровый размер структуры детей на этапе 1 и на этапе 5...
	#хотя, при правильной инициализации, он может стать только меньше, а binread корректно обрабатывает в случае чтения данных объекта, меньшего, чем заданной строки..
	def store_item(node)
		

		if node.level!=0
			for i in 0..node.n-1
				pointerSize = store_item(node.pointer[i])
				node.pointer_size[i] = pointerSize
				node.pointer[i] = node.pointer[i].offset

			end
		else
			#когда node.level == 0, то node.pointer[i].class == OBJECT, т.е. есть доступ к data..
			for i in 0..node.n-1
				leafSize = storeLeaf(node.pointer[i])
				node.pointer_size[i] = leafSize
				node.pointer[i] = node.pointer[i].offset
			end
		end

		return storeNode(node)
		#сохраняем ноду, но при этом у детей нужно поправить ссылку на родителя...
		# а нужно ли?????....
	end


	def storeLeaf(item)
		
		#debugStrstruct = @nextFreeStructOffset.to_s
		#debugFlag = false
		#if (@nextFreeStructOffset == 701)
		#	debugFlag = true
		#	puts "\t\t!!!!!!!!!!!!!!"
		#end


		#if (@tree.root == item)
		#	puts "store leaf"
		#end

		item_size = 0
		
=begin
		if (item.offset > 0)
			#[0] - node
			#[1] - data
			res = ""

			#if (@item.n>0)
			puts "store Leaf"
			if (item.data_offset<0)
				puts "store Leaf < 0"
				item.data_offset = @nextFreeDataOffset

				data_size = Marshal.dump(item.data).size

				item.data_size = data_size
				#res = item.store	#пересобираем с учетом присваивания выше #хзхз
				res2 = Marshal.dump(item)
				res1 = Marshal.dump(item.data)


				#IO.binwrite(FileData, res[1], item.data_offset)
				IO.binwrite(FileData, res1, item.data_offset)
				#@nextFreeDataOffset = @nextFreeDataOffset + res[1].size
				@nextFreeDataOffset = @nextFreeDataOffset + res1.size

				#IO.binwrite(FileStruct, res[0], item.offset)
				IO.binwrite(FileStruct, res2, item.offset)
				#item_size = res[0].size
				item_size = res2.size
			else
				puts puts "store Leaf else"
			end

			if (res == "")
				str = Marshal.dump(item)
				IO.binwrite(FileStruct, str, item.offset)
				item_size = str.size
			end
		else
=end




				#res = item.store
				#res[0] - структура
				#res[1] - данные

				#p item.data

		item.data_size = Marshal.dump(item.data).size

		res1 = Marshal.dump(item.data)

		item.data = @nextFreeDataOffset
		item.offset = @nextFreeStructOffset

		item_size = Marshal.dump(item).size

				

				
				#res = item.store #хзхз
		res2 = Marshal.dump(item)
		
				#p res[1]

				#IO.binwrite(FileStruct, res[0], item.offset)
		IO.binwrite(FileStruct, res2, item.offset)

				#puts "res[1] = #{res[1]}"
				#puts "FileData = #{FileData}"
				#puts "item.data_offset = #{item.data_offset}\n\n"

				#IO.binwrite(FileData, res[1], item.data_offset)
				#puts "store item.data: #{item.data}"
				#p  res1
		IO.binwrite(FileData, res1, item.data)
				
				#puts "STORE LEAF: offset = #{item.offset}, size = #{item_size}"
				
				
				
		@nextFreeStructOffset = @nextFreeStructOffset + item_size
		@nextFreeDataOffset = @nextFreeDataOffset + item.data_size


		#if (debugFlag)
		#	puts "@nextFreeStructOffset = #{@nextFreeStructOffset}"
		#end

		#debugStrstruct = debugStrstruct + "\t" + item_size.to_s
		#puts debugStrstruct
		return item_size

	end

	def storeNode(item)
		#debugStrstruct = @nextFreeStructOffset.to_s
		#checkItem(item)
		#узел - либо лист, либо внутренний
		#offset=0
		size = 0
		
		#внутренний узел - сохраняем в структуру
			
		#2 случая - обновляем старый или записываем новый
			

		if (item.offset > 0)
			#обновляем старый, по адресу offset
			str = Marshal.dump(item)

			IO.binwrite(FileStruct, str, item.offset)
			#offset = item.offset
			size = str.size
		else
			#записываем новый, в конец
			item.offset = @nextFreeStructOffset

			str = Marshal.dump(item)
			IO.binwrite(FileStruct, str, item.offset)
			#offset = @offset

			size = str.size
			@nextFreeStructOffset = @nextFreeStructOffset + size
		end
		#debugStrstruct = debugStrstruct + "\t" + size.to_s
		#puts debugStrstruct
		return size
		
	end




end

#@@cnt = 0

class TreeLoad
	:tree
	def initialize
		@tree = nil
	end

	def loadHeader(hSize)
		headerStr = IO.binread(FileStruct, hSize, 0)
		return Marshal.load(headerStr)
	end

	def self.commonLoadChild(offset, size, parentnode, index)
		nodeStr = IO.binread(FileStruct, size, offset)
		node = Marshal.load(nodeStr)
		if (parentnode.leaf)
			#for i in 0..node.n-1
				#dataNode = loadLeaf(node.pointer[i], node.pointer_size[i])
				#dataNode.parent = node
				#node.pointer[i] = dataNode

				dataStr = IO.binread(FileData, node.data_size, node.data)
				data = Marshal.load(dataStr)
				#p data
				node.data = data
			#end
		end
		node.parent = parentnode
		parentnode.pointer[index] = node
	end

	def loadLeaf(offset, size)
#		@@cnt = @@cnt + 1
#		if (@@cnt%5000==0)
#			p @@cnt
#		end

		#puts "Load LEAF: offset = #{offset}, size = #{size}"
		#@@cnt = @@cnt + 1
		#puts "@@cnt = #{@@cnt}"

#		if (@@cnt == 392)
#			puts "node: offset = #{offset}, size = #{size}"
#		end

		#puts "Leaf -> #{offset}\t#{size}"
		nodeStr = IO.binread(FileStruct, size, offset)
		node = Marshal.load(nodeStr)

		#puts "data: node.data_offset = #{node.data_offset}, node.data_size = #{node.data_size}"
		#p node.data
		dataStr = IO.binread(FileData, node.data_size, node.data)
		data = Marshal.load(dataStr)

		#p data
		node.data = data
		return node
	end


	def loadNode(offset, size)
		#puts "loadNode: #{offset}\t#{size}"
		nodeStr = IO.binread(FileStruct, size, offset)
		node = Marshal.load(nodeStr)
		if (node.pointer == nil)
			node.pointer = Array.new(@tree.M)
		end
		
		if (node.leaf)
			#подгружаем object

		
			for i in 0..node.n-1
				#puts "node.pointer_offset[i] = #{node.pointer_offset[i]}"
				#puts "node.pointer_size[i] = #{node.pointer_size[i]}"
				dataNode = loadLeaf(node.pointer[i], node.pointer_size[i])
				dataNode.parent = node
				node.pointer[i] = dataNode
			end
		end

		#p node
		return node
	end

	def getCode
		f = IO.read(File.dirname(__FILE__)+"/#{FileCode}")
		code = f.split("\n")[0].to_i
		#puts "code = #{code}"
		return code
	end

	def loadTreeUpsizeDown
		root = nil
		q = Queue.new
		q.push([@tree.root_offset, @tree.root_size, nil, 0])
		rootFlag = true

		while (!q.empty?)

			qi = q.pop	
			offset 	= qi[0]
			size 	= qi[1]
			parent 	= qi[2]
			index  	= qi[3]



			node = loadNode(offset, size)

			if (rootFlag)
				root = node
				rootFlag = false
			end
		
			if (parent != nil)
				parent.pointer[index] = node
			end
			node.parent = parent

			if (node.level!=0)
				for i in 0..node.n-1
					q.push([node.pointer[i], node.pointer_size[i], node, i])
				end
			end
		end
		return root

	end


	def load
		hSize = getCode

		@tree = loadHeader(hSize)

		#puts @tree.root_offset
		#puts @tree.root_size
		 
		@tree.root = loadNode(@tree.root_offset, @tree.root_size)
		#@tree.root = loadTreeUpsizeDown
		
		return @tree
	end

end