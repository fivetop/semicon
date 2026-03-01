#!/usr/local/bin/wish

set windowW  300
set windowH  500
set fighterX [ expr int( $windowW / 2 ) ]
set fighterY [ expr $windowH - 50 ]
set fighterD 5

set bulletExist 0
set bulletX 0
set bulletY 0

proc BulletMove { } {

    global bulletExist
    global bulletX
    global bulletY
    global bullet

    if { $bulletY < 10 } { 
        .ca delete $bullet
        set bulletExit 0
    } else {
        incr bulletY -10
        .ca move $bullet 0 -10
        update
        after 50 BulletMove
    }

}

proc FighterFire { } {

    global bulletExist
    global bulletX
    global bulletY
    global bullet

    global fighterX
    global fighterY

    if { $bulletExist == 1 } {
        return
    }

    set bulletX $fighterX
    set bulletY $fighterY


     set xl [ expr $fighterX - 1 ]
     set xr [ expr $fighterX + 1 ]
     set yt [ expr $fighterY - 5 ]
     set yb [ expr $fighterY ]

     set bullet [ .ca create rectangle $xl $yt $xr $yb -fill white ]
     set bulletExit 1

     after 50 BulletMove
    
}

proc FighterMove { where } {

    global fighterX 
    global fighterD
    global fighter

    switch $where {

        left {

            set delta [ expr -$fighterD ]

        }

        right {

            set delta $fighterD

        }
    }


    incr fighterX $delta
    .ca move $fighter $delta 0

    update

}

canvas .ca -width $windowW -height $windowH -bg black

set fighter [ .ca create poly 150 450 160 480 140 480 -fill yellow ]

bind . <Key-Left>  { FighterMove left }
bind . <Key-Right> { FighterMove right }
bind . <Key-space> { FighterFire }

pack .ca

