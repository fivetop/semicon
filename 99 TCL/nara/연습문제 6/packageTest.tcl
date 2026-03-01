#!/usr/local/bin/tclsh

lappend auto_path ./lib

package require STACK 1.0
package require QUEUE 1.0


#=======================
# Stack test
#=======================

initStack

puts "PUSH 3"
push 3

puts "PUSH 4"
push 4

puts "PUSH 5"
push 5

puts "TOP [ top ] "

puts "POP"
pop

puts "TOP [ top ] "

puts "POP"
pop

puts "TOP [ top ] "


#=======================
# Queue test
#=======================

initQ

puts "ENQUEUE 4 "
enQ 4
puts "ENQUEUE 5 "
enQ 5
puts "ENQUEUE 6 "
enQ 6

puts "FIRST : [ first ] "
puts "DEQUEUE"
deQ

puts "FIRST : [ first ] "
puts "DEQUEUE"
deQ

puts "FIRST : [ first ] "