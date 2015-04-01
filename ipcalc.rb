#!/usr/bin/env ruby
#
# ipcalc remake ;-) by Johannes Eiglsperger

def usage
  file = File.basename(__FILE__)

  puts "USAGE"
  puts "  #{file} <ipaddress>[/<prefixlen> | <netmask>]"
  puts
  puts "AUTHOR"
  puts "  Johannes Eiglsperger"
  puts "  https://github.com/reModding"

  exit
end

def calcNetmask(prefixlen)
  hostbits    = 32 - prefixlen
  netmask_bin = (-1 << hostbits) & 0xffffffff

  @netmask = []
  @netmask << (netmask_bin >> 24 & 0xff)
  @netmask << (netmask_bin >> 16 & 0xff)
  @netmask << (netmask_bin >>  8 & 0xff)
  @netmask << (netmask_bin >>  0 & 0xff)

  return @netmask.join(".")
end

def calcWildcard(prefixlen)
  hostbits     = 32 - prefixlen
  wildcard_bin = ~((-1 << hostbits) & 0xffffffff)

  @wildcard = []
  @wildcard << (wildcard_bin >> 24 & 0xff)
  @wildcard << (wildcard_bin >> 16 & 0xff)
  @wildcard << (wildcard_bin >>  8 & 0xff)
  @wildcard << (wildcard_bin >>  0 & 0xff)

  return @wildcard.join(".")
end

def calcPrefixLen(netmask)
  @netmask  = netmask.split(".")
  prefixlen = 0

  @netmask.each do |n|
    # convert into binary and count the ones
    prefixlen += n.to_i.to_s(2).count("1")
  end

  return prefixlen
end

def calcNetwork(ip, netmask)
  @ip      = ip.split(".")
  @netmask = netmask.split(".")

  @network = []

  @ip.each_index do |i|
    # ip AND netmask = network
    @network << [@ip[i].to_i & @netmask[i].to_i]
  end

  return @network.join(".")
end

def calcBroadcast(network, wildcard)
  @network  = network.to_s.split(".")
  @wildcard = wildcard.to_s.split(".")

  @broadcast = []

  @network.each_index do |i|
    # network OR wildcard = broadcast
    @broadcast << [@network[i].to_i | @wildcard[i].to_i]
  end

  return @broadcast.join(".")
end

def calcNumHosts(prefixlen)
  # 2 ** hostlen
  ips = 2 ** (32 - prefixlen)

  # special cases: /32 and /31 have no network- and broadcast addresses
  if ips >= 4
    return ips - 2
  else
    return ips
  end
end

ip        = ARGV[0] or usage
netmask   = -1
prefixlen = -1
network   = -1

# prefixlen defined? then overwrite the given netmask
if ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/(\d{1,3})/
  prefixlen = $1.to_i
  raise ArgumentError, "Invalid prefix length, got #{prefixlen}" unless (0..32).include?(prefixlen)

  ip      = ip.split("/")[0]
  netmask = calcNetmask(prefixlen)
else
  netmask   = ARGV[1] or usage
  raise ArgumentError, "Invalid netmask, got #{netmask}" unless netmask =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/

  # calculate the prefixlen
  prefixlen = calcPrefixLen(netmask)

  # anyway, calculate the netmask, if the given netmask is crap (only the prefixlen is explicit)
  netmask   = calcNetmask(prefixlen)
end

raise ArgumentError, "Invalid ip, got #{ip}" unless ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/

wildcard  = calcWildcard(prefixlen)
network   = calcNetwork(ip, netmask)
broadcast = calcBroadcast(network, wildcard)
numhosts  = calcNumHosts(prefixlen)

puts "IP-Adress: #{ip}/#{prefixlen}"
puts "Netmask:   #{netmask}"
puts "Wildcard:  #{wildcard}"
puts "Network:   #{network}/#{prefixlen}"
puts "Broadcast: #{broadcast}"
puts "Number of hosts: #{numhosts}"
