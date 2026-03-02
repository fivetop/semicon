#!/usr/local/bin/tclsh

set files [ exec ls ]

set total 0

foreach file $files {
    set fID [ open $file r ]
    set lines [ split [ read $fID ] "\n" ]
    close $fID

    set lnum [ expr [ llength $lines ]  - 1 ]

    puts "    $lnum $file"
     
    set total [ expr $total + $lnum ]
}

puts " TOTAL $total lines"
