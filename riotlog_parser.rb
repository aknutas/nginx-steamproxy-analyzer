# encoding: utf-8
require 'csv'

#Globs
$cgarray = Array.new
MEGABYTE = 1024.0 * 1024.0

#Classes
class CacheGet
  attr_accessor :downloadsize, :cachehit, :downloadtimestamp
  @downloadsize = 0
  @cachehit = false
  @downloadtimestamp = nil

  def initialize(downloadsize, cachehit)
    @downloadsize = downloadsize
    @cachehit = cachehit
  end
end

#Functions
def addorcreategame(downloadsize, cachehit, downloadtimestamp)
  newcg = CacheGet.new(downloadsize, cachehit)
  $cgarray << newcg
end

def bytesToMeg bytes
  bytes /  MEGABYTE
end

puts 'Processing Riot file...'
File.open('lancache-riot-access.log', 'r:UTF-8').each do |line|
  #Read or skip line
  next if (!line.include?('GET') || !line.include?('200') || !(line.include?('HIT') || line.include?('MISS')))

  #Regexp
  dlsize = /(?<=200 )\d+(?= ")/.match(line)

  next if dlsize.nil?
  next if dlsize.size < 1

  dlsize = dlsize[0].to_i

  ifhit = nil
  if line.include?('HIT') then ifhit = true else ifhit = false end

  #DEBUG
  # puts "Found hit #{ifhit.to_s} size #{dlsize} block from depot id #{depotid}"
  addorcreategame(dlsize, ifhit, '')

end
puts "Finished parsing."

totalsize = 0
totalmisssize = 0
totalhitsize = 0
totalhits = 0
totalmiss = 0

puts "Processing stats..."
#Process stats

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