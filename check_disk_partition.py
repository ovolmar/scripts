
import time
import os, sys
import string

def error(msg):
	print msg
	sys.exit(1)

def get_all_possible_dev_names():
  device_names = []
  a_to_z = []
  for x in string.lowercase:
    a_to_z.append(x)

  for x in a_to_z:
    device_names.append('/dev/xvd' + x)

  for x in a_to_z:
    for y in string.lowercase:
      device_names.append('/dev/xvd' + x + y)

  return device_names

def find_disk_mapping(vm):
  device_tuple_list = []
  all_dev_names = get_all_possible_dev_names()

  vm = getbyname(vm,foundry.getVirtualMachines)
  if not vm:
  	error("no such vm")

  # Grab the mappings for the VMs disks and pull the disk name
  for mapping in vm.getVmDiskMappings():
    device    = all_dev_names[mapping.getDiskTarget()]
    name      = mapping.getVirtualMachineDisk().getName()
    shareable = mapping.getVirtualMachineDisk().isShareable()
    device_tuple_list.append( (device, name, shareable) )
  
  return device_tuple_list

def find_net_mapping(vm):
  device_tuple_list = []
  vm = getbyname(vm,foundry.getVirtualMachines)

  if not vm:
    error("no such vm")

  for nic in vm.getVnics():
    mac       = nic.getMacAddress()
    network   = nic.getEthernetNetwork()
    name      = nic.getName()
    device_tuple_list.append( (mac, network, name) )

  return device_tuple_list

def find_time():
  local_time = foundry.getLocalTime()
  return local_time

if len(args)==0 or args[0]=='help' or args[0]=='-h' or args[0]=='-?':
  printhelp()
  sys.exit(8)

if args[0]=='print_diskmap':
  if len(args) == 2:
    node = args[1]
    disk_mapping = find_disk_mapping(node)
    for mapping in disk_mapping: 
      print "%s %s %s" % (mapping)
  else:
    error("You forgot the node name")
elif args[0]=='find_time':
  now = find_time()
  print now
elif args[0]=='print_netmapping':
  if len(args) == 2:
    node = args[1]
    network_mapping = find_net_mapping(node)
    for mapping in network_mapping: 
      print "%s %s %s" % (mapping)
  else:
    error("You forgot the node name")
else:
  error("unknown command")

sys.exit(0)

