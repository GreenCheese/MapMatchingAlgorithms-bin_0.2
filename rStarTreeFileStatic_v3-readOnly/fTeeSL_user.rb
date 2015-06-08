puts "LOADING \"#{__FILE__}\"..."
require 'win32ole'
FileStruct = "1structTree"
FileData = "1data1"
FileCode = "1code"

class TreeLoad
	:tree
	:dbPath
	def initialize
		@tree = nil
		@dbPath = ""
		loadPath
	end

	def loadPath
		f = IO.read("#{File.dirname(__FILE__)}\\db.ini")
		@dbPath = f.split("\n")[0]
		#puts "\n\n#{@dbPath};{FileStruct}\n\n"
	end

	def loadHeader(hSize)
		headerStr = IO.binread(@dbPath+FileStruct, hSize, 0)
		return Marshal.load(headerStr)
	end

	def commonLoadChild(offset, size, parentnode, index)
		nodeStr = IO.binread(@dbPath+FileStruct, size, offset)
		node = Marshal.load(nodeStr)
		if (parentnode.leaf)
			dataStr = IO.binread(@dbPath+FileData, node.data_size, node.data)
			data = Marshal.load(dataStr)
			node.data = data
		end
		node.parent = parentnode
		parentnode.pointer[index] = node
	end

	def loadLeaf(offset, size)
		nodeStr = IO.binread(@dbPath+FileStruct, size, offset)
		node = Marshal.load(nodeStr)
		dataStr = IO.binread(@dbPath+FileData, node.data_size, node.data)
		data = Marshal.load(dataStr)
		node.data = data
		return node
	end

	def loadNode(offset, size)
		nodeStr = IO.binread(@dbPath+FileStruct, size, offset)
		node = Marshal.load(nodeStr)
		if (node.pointer == nil)
			node.pointer = Array.new(@tree.M)
		end

		if (node.leaf)
			for i in 0..node.n-1
				dataNode = loadLeaf(node.pointer[i], node.pointer_size[i])
				dataNode.parent = node
				node.pointer[i] = dataNode
			end
		end
		return node
	end

	def getCode
		f = IO.read(@dbPath+FileCode)
		code = f.split("\n")[0].to_i
		return code
	end

	def load
		hSize = getCode
		@tree = loadHeader(hSize)
		@tree.root = loadNode(@tree.root_offset, @tree.root_size)
		return @tree
	end
end