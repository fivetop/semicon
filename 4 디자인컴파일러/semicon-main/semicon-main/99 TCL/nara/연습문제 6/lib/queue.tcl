#!/usr/local/bin/tclsh

package provide QUEUE 1.0

proc initQ { } {

    global qfirst qlast qsize
    
    set qfirst 0
    set qlast  0
    set qsize  1000
}

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


