#!/usr/local/bin/wish

text .out -bg white -yscrollcommand { .sy set }
scrollbar .sy -command { .out yview }

grid .out .sy -sticky news


for { set i 2 } { $i < 10 } { incr i } {
    for { set j 2 } { $j < 10 } { incr j } {
        .out insert end "$i x $j = [ expr $i * $j ]\n"
        update
    }
    .out insert end "-----------\n"
}

.out yview end
.out config -state disabled
