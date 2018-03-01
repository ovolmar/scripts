#!/usr/bin/env ruby

print "Enter Greeting:"

greetings = gets.chomp

case greetings
when "French", "french"
  puts "Bonjour"
  exit
  
