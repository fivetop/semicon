#!/usr/local/bin/tclsh

while { [ eof stdin ] == 0 } {
    gets stdin line
    regsub {([A-Z]+)_([A-Z]+)([0-9]+)} $line {\2-\3\1} line
    puts $line
}
