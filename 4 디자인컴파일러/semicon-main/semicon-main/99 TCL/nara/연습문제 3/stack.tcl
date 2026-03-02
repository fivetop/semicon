#!/usr/local/bin/tclsh

set spointer 0


proc push { data } {

   global mystack
   global spointer

   set mystack($spointer) $data
   incr spointer
    
}

proc pop { } {

   global mystack
   global spointer

   incr spointer -1
}

proc top { } {

   global mystack
   global spointer

   return $mystack([ expr $spointer - 1 ])
}


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
