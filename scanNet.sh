#!/bin/bash
#Filename: scanNet.sh
#Purpose: Scan network subnet

printf "\nEnter first 3 (i.e 192.168.1) Octects of network to scan:"
read choice
for ip in $choice.{1..255} ;
do
  (
  ping $ip -c 2 &> /dev/null ;
  
  if [ $? -eq 0 ];
  then
    echo $ip is alive
  fi
  ) &
  
done
wait
#172.23.8.147
