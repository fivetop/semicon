#!/usr/local/bin/wish

package provide MENU 1.0

proc Menu_Setup { menubar } {
        global menu
        menu $menubar        
        # Associated menu with its main window        
        set top [winfo parent $menubar]        
        $top config -menu $menubar        
        set menu(menubar) $menubar        
        set menu(uid) 0
 }
 
 proc Menu { label } {
        global menu        
        if [info exists menu(menu,$label)] {
                error "Menu $label already defined"        
        }        
 	# Create the cascade menu        
 	set menuName $menu(menubar).mb$menu(uid)        
 	incr menu(uid)        
 	menu $menuName -tearoff 1        
 	$menu(menubar) add cascade -label $label -menu $menuName        
 	# Remember the name to menu mapping        
 	set menu(menu,$label) $menuName
}

proc Menu_Command { menuName label command } {
        set m [MenuGet $menuName]        
        $m add command -label $label -command $command
}

proc Menu_Check { menuName label var { command {} } } {
        set m [MenuGet $menuName]        
        $m add check -label $label -command $command -variable $var
}

proc Menu_Radio { menuName label var {val {}} {command {}} } {
        set m [MenuGet $menuName]        
        if {[string length $val] == 0} {                
        	set val $label        
        }        
        $m add radio -label $label -command $command -value $val -variable $var
}

proc Menu_Separator { menuName } {
        [MenuGet $menuName] add separator
}

proc Menu_Cascade { menuName label } {
        global menu        
        set m [MenuGet $menuName]        
        if [info exists menu(menu,$label)] {                
        	error "Menu $label already defined"        
        }        
        set sub $m.sub$menu(uid)        
        incr menu(uid)        
        menu $sub -tearoff 0        
        $m add cascade -label $label -menu $sub        
        set menu(menu,$label) $sub
}

proc MenuGet {menuName} {
        global menu        
        if [catch {set menu(menu,$menuName)} m] {                
        	return -code error "No such menu: $menuName"        
        }        
        return $m
}

proc Menu_Bind { what sequence menuName label } {
        global menu        
        set m [MenuGet $menuName]        
        if [catch {$m index $label} index] {                
        	error "$label not in menu $menuName"        
        }        
        set command [$m entrycget $index -command]        
        bind $what $sequence $command        
        $m entryconfigure $index -accelerator $sequence
}

