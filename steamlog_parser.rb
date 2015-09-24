# encoding: utf-8
require 'csv'

#Globs
$sgarray = Array.new
$cgarray = Array.new
MEGABYTE = 1024.0 * 1024.0

#Classes
class SteamGame
  attr_accessor :downloadsize, :cachehit, :depotid, :cachegets
  @depotid
  @downloadsize
  @cachegets

  def initialize(depotid)
    @depotid = depotid
    @downloadsize = 0
    @cachegets = Array.new
  end
end

class CacheGet
  attr_accessor :downloadsize, :cachehit, :depotid, :downloadtimestamp
  @downloadsize = 0
  @cachehit = false
  @depotid = nil
  @downloadtimestamp = nil

  def initialize(downloadsize, cachehit, depotid)
    @downloadsize = downloadsize
    @cachehit = cachehit
    @depotid = depotid
  end
end

#Functions
def addorcreatesteamgame(downloadsize, cachehit, depotid, downloadtimestamp)
  newcg = CacheGet.new(downloadsize, cachehit, depotid)
  $cgarray << newcg
  if $sgarray[depotid]
    $sgarray[depotid].cachegets << newcg
    $sgarray[depotid].downloadsize = $sgarray[depotid].downloadsize + newcg.downloadsize
  else
    newsid = SteamGame.new(depotid)
    newsid.cachegets << newcg
    $sgarray[depotid] = newsid
    newsid.downloadsize = newsid.downloadsize + newcg.downloadsize
  end
  return newcg
end

def bytesToMeg bytes
  bytes /  MEGABYTE
end

puts 'Processing Steam file...'
File.open('lancache-steam-access.log', 'r:UTF-8').each do |line|
  #Read or skip line
  next if (!line.include?('GET') || !line.include?('200') || !line.include?('depot') || !(line.include?('HIT') || line.include?('MISS')))

  #Regexp
  dlsize = /(?<=200 )\d+(?= ")/.match(line)
  depotid = /(?<=\/depot\/)\d+(?=\/)/.match(line)

  next if dlsize.nil? || depotid.nil?
  next if dlsize.size < 1 || depotid.size < 1

  dlsize = dlsize[0].to_i
  depotid = depotid[0].to_i

  ifhit = nil
  if line.include?('HIT') then ifhit = true else ifhit = false end

  #DEBUG
  # puts "Found hit #{ifhit.to_s} size #{dlsize} block from depot id #{depotid}"
  addorcreatesteamgame(dlsize, ifhit, depotid, '')

end
puts "Finished parsing."

totalsize = 0
totalmisssize = 0
totalhitsize = 0
totalhits = 0
totalmiss = 0

puts "Processing stats..."
#Process stats
sortedgames = Array.new

$sgarray.each do |item|
  sortedgames << item unless item.nil?
end
sortedgames.sort!{ |x,y| y.downloadsize <=> x.downloadsize || 0 }

$cgarray.each do |cg|
  totalsize = totalsize + cg.downloadsize
  if cg.cachehit
    totalhits = totalhits + 1
    totalhitsize = totalhitsize + cg.downloadsize
  else
    totalmiss = totalmiss + 1
    totalmisssize = totalmisssize + cg.downloadsize
  end
end

puts "Finished stats calc"
# Original sizes in bytes
puts "Total size #{bytesToMeg(totalsize)}; total hits #{totalhits}; total misses #{totalmiss}"
puts "Total hit size #{bytesToMeg(totalhitsize)} MB; total miss size #{bytesToMeg(totalmisssize)} MB"

totalsizeverify = 0

#DEBUG
#sortedgames.each do |item|
#  totalsizeverify = totalsizeverify + item.downloadsize
#end
#puts bytesToMeg(totalsizeverify)

for i in 1..30
  puts "#{i}. downloaded game: #{sortedgames[i].depotid}; size #{bytesToMeg(sortedgames[i].downloadsize)} MB"
end