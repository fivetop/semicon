#!/usr/local/bin/tclsh

for { set ii 0 } { $ii < 10 } { incr ii } {
	for { set jj 0 } { $jj < 10 } { incr jj } {
		set array2d($ii.$jj) [ expr $ii + $jj ]
	}
}

for { set ii 0 } { $ii < 10 } { incr ii } {
	for { set jj 0 } { $jj < 10 } { incr jj } {
		puts $array2d($ii.$jj) 
	}
}