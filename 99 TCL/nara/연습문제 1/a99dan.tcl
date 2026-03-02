#!/usr/local/bin/tclsh

for { set i 2 } { $i < 10 } { incr i } {
    for { set j 1 } { $j < 10 } { incr j } {
        puts "$i * $j = [ expr $i * $j ] "
    }
    puts "---- Press Return Key to Continue --- "
    flush stdout
    gets stdin temp
}
