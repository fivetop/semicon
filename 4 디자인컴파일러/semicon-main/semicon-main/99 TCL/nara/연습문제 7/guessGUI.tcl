#!/usr/local/bin/wish

proc NewGame { } {
    global message
    global myguess
    global user

    set myguess [ exec date | cut -c18-19 ]
    incr myguess
    set message "I have a number 1~60"
    set user "Enter your guess"
    update
}

proc Quit { } {
    exit
}

proc Yes { } {
    global message
    global myguess
    global user
    global score

    update
 
    if       { $user > $myguess } {

        set message "Too Big!!"
        incr score -10

    } elseif { $user < $myguess } {

        set message "Too Small!!"
        incr score -10

    } else {
        set message "Your Score is $score"
    }
    update
}

frame  .top
button .top.new    -text "New Game" -fg blue -command { NewGame }
button .top.quit   -text Quit -fg red        -command { Quit }
label  .mess       -textvariable message
frame  .bot
entry  .bot.ent    -textvariable user -bg white
button .bot.yes    -text "Enter"             -command { Yes }

pack .top.new .top.quit -side left
pack .top
pack .mess
pack .bot.ent .bot.yes -side left
pack .bot

set score 100

NewGame
