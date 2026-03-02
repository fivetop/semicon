#!/usr/local/bin/tclsh

set qfirst 0
set qlast  0
set qsize  1000

proc enQ { data } {

    global qfirst
    global qlast
    global myQ
    global qsize

    set myQ($qlast) $data
    set qlast [ expr ( $qlast + 1 ) % $qsize ]
}

proc deQ { } {
    global qfirst
    global qlast
    global myQ
    global qsize

    set qfirst [ expr ( $qfirst + 1 ) % $qsize ]
}

proc first { } {
    global qfirst
    global qlast
    global myQ
    global qsize

    return $myQ($qfirst)
}

proc last { } {
    global qfirst
    global qlast
    global myQ
    global qsize

    return $myQ($qlast)
}

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
