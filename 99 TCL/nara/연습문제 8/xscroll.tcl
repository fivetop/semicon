#!/usr/local/bin/wish

scrollbar .sy -orient vertical -command { .lbox yview }
scrollbar .sx -orient horizontal -command { .lbox xview }

listbox .lbox -xscrollcommand { .sx set } -yscrollcommand { .sy set }

for { set num 1 } { $num < 20 } { incr num } {
	.lbox insert end "This is list item $num. long line is need for x scroll"
}

grid .lbox .sy -sticky news
grid .sx -sticky news