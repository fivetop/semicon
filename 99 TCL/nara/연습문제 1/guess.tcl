#!/usr/local/bin/tclsh

set mynum [ exec date | cut -c18-19 ]
incr mynum

set score 100

while { 1 } {

    puts -nonewline "Input Your Guess \[ 1 ~ 60 \] : "
    flush stdout
    gets stdin yournum

    if { $yournum > $mynum } {
        puts "  Oh, too big"
    } elseif { $yournum < $mynum } {
        puts "  Oh, too small"
    } else {
       break
    }

    incr score -10

}


puts "Congratulation!!"
puts "Your Score is $score"
