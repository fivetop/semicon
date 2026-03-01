#!/usr/local/bin/tclsh

package provide STACK 1.0

proc initStack { } {

    global spointer 
    
    set spointer 0
    
}


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

