package provide GUI 1.0

#########################################
#
# GUI package for Tcl/Tk applications
#
# Copyright (c) System IC R&D in Hyundai Electronics Inc. , 1998
#
# Programed by :
#	1998.8.18. 	Nara Won
#
#########################################


#========================================
# GUIScrollCanvas :   
#	Subroutine for making scrolled canvas
#---------------------------------------
# Input :
#	c - parent widget
#	args - options for canvas widget
#---------------------------------------
# Return vlaue :
#	canvas widget path
#========================================

proc GUIScrolledCanvas { c args } {
	frame $c
	eval {canvas $c.canvas \
		-xscrollcommand [list $c.xscroll set] \
		-yscrollcommand [list $c.yscroll set] \
		} $args
	scrollbar $c.xscroll -orient horizontal \
		-command [list $c.canvas xview]
	scrollbar $c.yscroll -orient vertical \
		-command [list $c.canvas yview]
	grid $c.canvas $c.yscroll -sticky news
	grid $c.xscroll -sticky ew
	grid rowconfigure $c 0 -weight 1
	grid columnconfigure $c 0 -weight 1
	return $c.canvas
}

#========================================
# GUIMenuSetup :
#	for initialize full down menu
#---------------------------------------
# Input :
#	menubar - Menu bar widget path
#========================================

proc GUIMenuSetup { menubar } {
	global menu
	menu $menubar
	set top [winfo parent $menubar ]
	$top config -menu $menubar
	set menu(menubar) $menubar
	set menu(uid) 0
}

#========================================
# GUIMenu :
#	Insert menu item in menu bar
#	and make subpane for submenus
#---------------------------------------
# Input :
#	label - name(text) of menu item
#========================================

proc GUIMenu { label } {
	global menu
	if [info exists menu(menu,$label)] {
		error "Menu $label already defined"
	}
	set menuName $menu(menubar).mb$menu(uid)
	incr menu(uid)
	menu $menuName -tearoff 1
	$menu(menubar) add cascade -label $label -menu $menuName
	set menu(menu,$label) $menuName
}

#========================================
# GUIMenuGet :
#	Get subpane handler with menu name
#	subpane was made in GUIMenu
#---------------------------------------
# Input :
#	menuName - menu name of subpane
#---------------------------------------
# Return :
#	subpane handler
#========================================

proc GUIMenuGet { menuName } {
	global menu
	if [ catch {set menu(menu,$menuName) } m] {
		return -code error "No such menu: $menuName"
	}
	return $m
}

#========================================
# GUIMenuCommand :
#	Bind command with menu item
#---------------------------------------
# Input :
#	menuName - name of parent menu
#	label - name of its own
#	command - command of the menu
#========================================

proc GUIMenuCommand { menuName label command } {
	set m [GUIMenuGet $menuName]
	$m add command -label $label -command $command
}

#========================================
# GUIMenuCheck :
#	Add check button menu
#---------------------------------------
# Input :
#	menuName - name of parent menu
#	label - name of its own
#	var - variable of the menu
#	command - command of the menu (option)
#========================================

proc GUIMenuCheck { menuName label var { command {} } } {
	set m [GUIMenuGet $menuName]
	$m add check -label $label -command $command\
		-variable $var
}

#========================================
# GUIMenuRadio :
#	Add radio button menu
#---------------------------------------
# Input :
#	menuName - name of parent menu
#	label - name of its own
#	var - variable of the menu
#	val - value of radio button (option)
#	command - command of the menu (option)
#========================================

proc GUIMenuRadio { menuName label var { val {} } {command {}} } {
	set m [GUIMenuGet $menuName]
	if{[string length $val] == 0} {
		set val $label
	}
	$m add radio -label $label -command $command\
		-value $val -varialbe $var
}

#========================================
# GUIMenuSeparator :
#	Insert separator to menu pane
#---------------------------------------
# Input :
#	menuName - name of parent menu
#========================================

proc GUIMenuSeparator { menuName } {
	[GUIMenuGet $menuName] add separator
}

#========================================
# GUIMenuCascade :
#	Insert cascade menu
#	cascade menu has submenu pane
#---------------------------------------
# Input :
#	menuName - name of parent menu
#	label - name of its own
#========================================

proc GUIMenuCascade { menuName label } {
	global menu
	set m [ GUIMenuGet $menuName]
	if [info exists menu(menu,$label)] {
		error "Menu $lable already defined"
	}
	set sub $m.sub$menu(uid)
	incr menu(uid)
	menu $sub -tearoff 0
	$m add cascade -label $label -menu $sub
	set menu(menu,$label) $sub
}

#========================================
# GUIResourceButtonFrame :
#	make user defined (at resource file) menu buttons
#---------------------------------------
# Input :
#	f - path of parent of user defined menu button frame
# 	class - class name of user defined menu button frame
#========================================

proc GUIResourceButtonFrame { f class } {
	frame $f -class $class -borderwidth 2 -relief groove
	pack $f -side top -fill x
	foreach b [option get $f buttonlist {} ] {
		if [catch {button $f.$b}] {
			button $f.$b -font fixed
		}
		pack $f.$b -side left -pady 2 
	}
}

#========================================
# GUIMessageBox :
#	Make simple message box dialog with only OK button
#---------------------------------------
# Input :
#	title - title of message box dialog
#	message - message of message box dialog
#========================================

proc GUIMessageBox { title message } {
	tk_messageBox -type ok -message $message -title $title
}

#========================================
# GUIQuestionBox :
#	Make simple question box dialog with YES and NO button
#---------------------------------------
# Input :
#	message - message of message box dialog
#	default - default choice of dialog (yes or no)
#========================================

proc GUIQuestionBox { message default} {
	return [tk_messageBox -type yesno -default $default -title Question\
		-message $message -icon question ]
}

#========================================
#---------------------------------------
#========================================

proc GUIErrorBox { message } {
	tk_messageBox -type ok -message $message -title Error -icon error
}
