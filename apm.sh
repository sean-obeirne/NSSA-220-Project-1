#!/bin/bash

# NSSA 220 Project 1: APM Tool
# Sean O'Beirne, Mani Perez, Joshua Sylvester

spawn_processes(){
   # grab NIC ip
   local ip=$(ifconfig ens33 | grep "inet" | head -1 | cut -f 10 -d " ")

   # cleanup old metrics files
   rm -f APM?_metrics.csv system_metrics.csv

   # spawn procs & create files
   for (( i = 1; i <= $PROCS; i++ ))
   {
      ./project1_executables/APM$i $ip &
      echo "seconds,%CPU,%memory" > 'APM'$i'_metrics.csv'
   }
   echo "seconds,RX data rate,TX data rate,disk writes,available disk capacity" > system_metrics.csv
   ifstat -a -d 1 ens33
}

cleanup(){
   killall -r "APM[1-6]"
   killall "ifstat"
}

PROCS=6
f1="APM1_metrics.csv"

trap cleanup EXIT

spawn_processes
f=1
sec=1
sleep 1
while [ $f -eq 1 ];
do
   if ! (( sec % 5 ));
   then
      echo $sec

      #process-level metrics
      for (( i = 1; i <= $PROCS; i++ )){
         echo -n "$sec," >> 'APM'$i'_metrics.csv'
         ps u -C "APM$i" | grep "APM" | awk '{printf $3 "," $4 "\n"}' >> APM$i'_'metrics.csv
      }
   
      # system-level metrics
      echo -n "$sec," >> system_metrics.csv
      ifstat -t 1 2> /dev/null | grep "ens33" | awk '{printf $6 "," $7 ","}' >> system_metrics.csv
      iostat | grep "sda" | awk '{printf $4 ","}' >>  system_metrics.csv
      df -hm / | grep "root" | awk '{printf $4 "\n"}' >> system_metrics.csv
   fi
   sleep 1
   sec=$((sec + 1));
done
