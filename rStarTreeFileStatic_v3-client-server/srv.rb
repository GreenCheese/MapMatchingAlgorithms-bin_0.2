require 'drb/drb'
$:.unshift((File.dirname(__FILE__)+"/../rStarTreeFileStatic_v3-readOnly/"))
require 'rStarTreeFileStatic_user.rb'

#URI="druby://192.168.79.95:8787"
#URI="druby://192.168.77.211:8787"
#URI="druby://10.68.41.55:8787"
URI="druby://10.0.0.20:8787"


tl = TreeLoad.new
treeL = tl.load
treeL.setLoader(tl)
FRONT_OBJECT=treeL
#$SAFE = 1 

puts "STARTING SEGMENT SEARCHER SERVER..."
DRb.start_service(URI, FRONT_OBJECT)
puts "SERVER STARTED"
DRb.thread.join
puts "SERVER STOPPED"