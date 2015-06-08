puts "LOADING \"#{__FILE__}\"..."
#require 'thread'

##################################
# Реализация красно-черного дерева
##################################

RED = 0
BLACK = 1

class Node
	def initialize(key)
		@key = key
	end

	attr_accessor :color
	attr_accessor :key
	attr_accessor :left
	attr_accessor :right
	attr_accessor :p
end

class NilNode < Node
	def initialize
		@color = BLACK
		@key = nil
		@left = nil
		@right = nil
		@p = nil
	end


end




class RBTree

	attr_accessor :nn
	attr_accessor :root
	def initialize
		@nn = NilNode.new
		@root = @nn

		
	end

	def LeftRotate(x)
		y = x.right
		x.right = y.left

		if (y.left != self.nn)
			y.left.p = x
		end

		y.p  = x.p
		
		if (x.p == self.nn)
			self.root = y
		else
			if (x == x.p.left)
				x.p.left = y
			else
				x.p.right = y
			end
		end

		y.left = x
		x.p = y
	end	

	def RightRotate(x)
		y = x.left
		x.left = y.right

		if (y.right != self.nn)
			y.right.p = x
		end

		y.p  = x.p
		
		if (x.p == self.nn)
			self.root = y
		else
			if (x == x.p.right)
				x.p.right = y
			else
				x.p.left = y
			end
		end

		y.right = x
		x.p = y
	end	

	def rb_Insert_Fixup(z)

		while (z.p.color == RED)
			if(z.p ==z.p.p.left)
				y = z.p.p.right
				if(y.color == RED)
					z.p.color = BLACK
					y.color = BLACK
					z.p.p.color = RED
					z = z.p.p
				else
					if (z == z.p.right)
						z = z.p
						LeftRotate(z)
					end

					z.p.color = BLACK
					z.p.p.color = RED
					RightRotate(z.p.p)
				end
			else
				y = z.p.p.left
				if(y.color == RED)
					z.p.color = BLACK
					y.color = BLACK
					z.p.p.color = RED
					z = z.p.p
				else
					if (z == z.p.left)
						z = z.p
						RightRotate(z)
					end

					z.p.color = BLACK
					z.p.p.color = RED
					LeftRotate(z.p.p)
				end
			end
		end
		self.root.color = BLACK
		
	end

	def test
		puts self.root.key
		puts self.root.color
	end

	def Insert(z)
		y = self.nn
		x = self.root

		while (x!=self.nn)
			#puts "while"
			y=x
			#puts y.key
			if (z.key<x.key)
				x=x.left
			else
				x=x.right
			end
		end

		z.p = y
		if(y == self.nn)
			#puts "if"
			self.root = z
		else
			if(z.key<y.key)
				y.left = z
			else
				y.right = z
			end
		end

		z.left = self.nn
		z.right = self.nn
		z.color = RED

=begin
		if (self.root.left!=self.nn)
			puts "left ok"
		end

		if (self.root.right!=self.nn)
			puts "right ok"
		end
=end


		rb_Insert_Fixup(z)
	end

	def rb_Delete_Fixup(x)
		while (x!=self.root and x.color==BLACK)
			if (x == x.p.left)
				w = x.p.right
				if(w.color == RED)
					w.color = BLACK
					x.p.color = RED
					LeftRotate(x.p)
					w = x.p.right
				end

				if (w.left.color == BLACK and w.right.color == BLACK)
					w.color = RED
					x = x.p
				else
					if(w.right.color == BLACK)
						w.left.color = BLACK
						w.color = RED
						RightRotate(w)
						w = x.p.right
					end

					w.color = x.p.color
					x.p.color = BLACK
					w.right.color = BLACK
					LeftRotate(x.p)
					x = self.root
				end


			else
				w = x.p.left
				if(w.color == RED)
					w.color = BLACK
					x.p.color = RED
					RightRotate(x.p)
					w = x.p.left
				end

				if (w.right.color == BLACK and w.left.color == BLACK)
					w.color = RED
					x = x.p
				else
					if(w.left.color == BLACK)
						w.right.color = BLACK
						w.color = RED
						LeftRotate(w)
						w = x.p.left
					end

					w.color = x.p.color
					x.p.color = BLACK
					w.left.color = BLACK
					RightRotate(x.p)
					x = self.root
				end



			end
		end
	end

	def rbTreeSarch(x, k)
		if (x == self.nn or k == x.key)
			return x
		end

		if (k < x.key)
			return rbTreeSarch(x.left,k)
		else
			return rbTreeSarch(x.right,k)
		end

		
	end

	def printTree
		

		#p self.root.right.key

		q = Queue.new
		q.push(self.root)

		arr = []
		items_of_next_level = 0
		tmp_counter = 1
		str  = ""
		arrow = ""
		while (!q.empty?)
		



			x = q.pop
			#puts x.key
			#x = q.pop
			str = str + " #{x.key}"
			tmp_counter = tmp_counter - 1

			

			
			if (x.left!=self.nn)
				q.push (x.left)
				items_of_next_level = items_of_next_level + 1
				arrow = arrow + "/(#{x.key})"

			end

			if (x.right!=self.nn)
				q.push (x.right)
				items_of_next_level = items_of_next_level + 1
				arrow = arrow + "\\(#{x.key})"
			end


			if (tmp_counter == 0)
				puts "#{str}"
				#puts "\n"
				puts arrow
				#puts "\n"
				arrow = ""
				str = ""
				tmp_counter = items_of_next_level
				items_of_next_level = 0
			end
			
		end




	end

	def treeMinimum (x)

		while (x.left!=self.nn)
			x = x.left
		end

		return x
	end

	def treeSuccessor(x)

		if x.right!=self.nn
			#puts x.key
			#puts "****#{x.right.key}"

			return treeMinimum(x.right)
		end
		y = x.p

		while (y!=self.nn and x == y.right)
			x = y
			y = y.p
		end
		return y

	end

	def rb_Delete(z)
		if(z.left == self.nn or z.right == self.nn)
			y = z
		else
			y = treeSuccessor(z)
		end

		if (y.left!=self.nn)
			x = y.left
		else
			x = y.right
		end

		x.p = y.p

		if (y.p== self.nn)	
			self.root = x
		else
			if (y == y.p.left)
				y.p.left = x
			else
				y.p.right = x
			end
		end

		if (y!=z)
			z.key = y.key
		end

		if (y.color == BLACK)
			rb_Delete_Fixup(x)
		end
		return y
	end


end


#
#tree = RBTree.new
#
#item = Node.new(1)
#tree.Insert(item)
##tree.test
#
#item = Node.new(3)
#tree.Insert(item)
#
#item = Node.new(6)
#tree.Insert(item)
#
#item = Node.new(9)
#tree.Insert(item)
#
#item = Node.new(8)
#tree.Insert(item)
#
#item = Node.new(2)
#tree.Insert(item)
#
#item = Node.new(4)
#tree.Insert(item)
#
#
#
#item = Node.new(8)
#
#
#
#
#
#node = tree.rbTreeSarch(tree.root, 10)
#p node.key
##tree.rb_Delete(node)
##tree.printTree