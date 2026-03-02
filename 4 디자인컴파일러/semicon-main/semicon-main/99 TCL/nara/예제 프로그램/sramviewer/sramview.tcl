#!/usr/local/bin/wish
########################################
#
#  SRAM VIEWER Ver 0.0
#
#  	for SRAM Fail Analysis   
#
#  Copyright (c) System ID R&D in Hyundai Electronics Inc. , 1998
#
#
#  Programed by :
#	1998.8.18	Nara Won
#
########################################

#
# read resource file 
#

option readfile sramView.resource

#
# load package files 
#

lappend auto_path ../GUI

package require GUI 

#***************************************
# Global Variables
#---------------------------------------
# comments 
#	- comments list for print
# sramUnitX
#	- width of SRAM cell
# sramUnitY
#	- height of SRAM cell
# sramNumX
#	- width of SRAM
# sramNumY
#	- height of SRAM
# faultCells
#	- struct array for fault cell coordinates
#	- $faultCells($index,xi) : X index
#	- $faultCells($index,yi) : Y index
#	- $faultCells($index,color) : color of fault cell
# faultCellNum
#	- # of faulted cell
# colorComments
#	- array for comments about color
#	- $colorComments($color)
# canvas
#	- canvas widget to draw SRAM
# zoomFactor
#	- zoomFactor
# scrollOrgWidth, scrollOrgHeight
#	- orginal whole canvas width and height
#***************************************

#***************************************
# Subroutines
#***************************************


#========================================
# ReadDataFile
#	: Read SRAM Data File
#---------------------------------------
# Input :
#	fileName - SRAM Data File Name
#---------------------------------------
# Return Value :
#	1 - no error
#	0 - error occurred
#========================================

proc ReadDataFile { fileName } {

	global sramUnitX sramUnitY sramNumX sramNumY
	global faultCells faultCellNum
	global comments colorComments

	#
	# open file
	#

	if [catch { open $fileName } fileID ] {
		GUIErrorBox "$fileName is not found"
		return 0
	} 

	#
	# global variable initialize
	#
	
	set sramUnitX 	0
	set sramUnitY 	0
	set sramNumX 	0
	set sramNumY 	0
	set faultCellNum 0

	#
	# process file data
	#

	set color 0
	set lineNum 0

	foreach currLine [split [read $fileID] \n] {

		incr lineNum

		#
		# extract comment
		#

		if [regexp {^[ \t]*#(.*)$} $currLine match comment] {
			lappend comments $comment
			continue
		}

		#
		# extract color
		#
		# Note : color clause has comment.
		#	so it must be manipulted before white spaces are
		#	removed
		#

		if [regexp {^[ \t]*color[ \t]*=[ \t]*([a-z]+)[ \t]*:(.*)$} \
			$currLine match color comment] {

			set colorComments($color) $comment
			continue
		}


		#
		# remove all white spaces
		#
		# Note : \t must be matched with tab character.
		#	But in regsub, it does not work.
		#	I think this is bug of PC version wish80.exe
		#	So I replaced \t with real tab character.
		#

		regsub -all -- {[ 	]+} $currLine {} line

		#
		# null line skip
		#

		if {$line == ""} \
			continue

		#
		# extract xunit, yunit, width, height
		#

		if [regexp {^xunit=([0-9.]+)$} \
			$line match sramUnitX] {
			continue
		}
		if [regexp {^yunit=([0-9.]+)$} \
			$line match sramUnitY] {
			continue
		}
		if [regexp {^xnum=([0-9.]+)$} \
			$line match sramNumX] {
			continue
		}
		if [regexp {^ynum=([0-9.]+)$} \
			$line match sramNumY] {
			continue
		}

		#
		# extract fault cell geometry
		#

		if [regexp {^([0-9.]+),([0-9.]+)$} \
			$line match xi yi ] {

			if {$color == 0} {
				GUIErrorBox "$lineNum : Cell color not defiled\n$currLine" 
				return 0
			}
			set faultCells($faultCellNum,xi) $xi
			set faultCells($faultCellNum,yi) $yi
			set faultCells($faultCellNum,color) $color
			incr faultCellNum

			continue
		}

		#
		# if execution flow is here then error
		#

		GUIErrorBox "$lineNum : Invalide line \n$currLine"
		return 0

	}

	close $fileID

	#
	# Check all informations were given
	#

	if { $sramUnitX == 0 } { 
		GUIErrorBox "No information about xunit in \"$fileName\""
		return 0
	}

	if { $sramUnitY == 0 } {
		GUIErrorBox "No information about yunit in \"$fileName\""
		return 0
	}

	if { $sramNumX == 0 } {
		GUIErrorBox "No information about Width in \"$fileName\""
		return 0
	}

	if { $sramNumY == 0 } {
		GUIErrorBox "No information about Height in \"$fileName\""
		return 0
	}

	#puts $sramUnitX
	#puts $sramUnitY
	#puts $sramNumX
	#puts $sramNumY
	#puts $faultCellNum

	foreach color [array names colorComments] {
		switch -- $color {
			red - 
			green -
			blue -
			grey -
			black -
			yellow -
			magenta -
			violet -
			orange -
			pink -
			purple -
			brwon {
			}
			default {
				GUIErrorBox "$color is not valid color"
				return 0
			}
		}

	}

	return 1

}


#========================================
# Draw :
#	Draw SRAM (all cells and faulted cells )	
#========================================

proc Draw {} {
	global canvas 
	global sramUnitX sramUnitY sramNumX sramNumY
	global scrollOrgWidth scrollOrgHeight
	global comments colorComments

	set canvasMarginX 	30
	set canvasMarginY 	30


	#
	# Draw SRAM cells
	#


	DrawSRAMCells \
		$sramUnitX $sramUnitY $sramNumX $sramNumY \
		$canvasMarginX $canvasMarginY
	#
	# Print comments
	#

	set xstart $canvasMarginX
	set yStartText [expr $sramUnitY * $sramNumY + $canvasMarginY*2]

	foreach comment $comments {
		$canvas create text $xstart $yStartText \
			-text $comment -anchor nw -justify left
		set yStartText [expr $yStartText + 15]
	}

	#
	# Print color comments
	#

	set xstart 500
	set yStartColor [expr $sramUnitY * $sramNumY + $canvasMarginY*2]

	foreach color [array names colorComments] {
		set comment $colorComments($color)

		set xl [expr $xstart - 10]
		set xr [expr $xstart - 5]
		set yt [expr $yStartColor + 0]
		set yb [expr $yStartColor + 5]

		$canvas create rectangle $xl $yt $xr $yb -fill $color
		$canvas create text $xstart $yStartColor \
			-text $comment -anchor nw -justify left
		set yStartColor [expr $yStartColor + 15]
	}




	#
	# Set Scroll region
	#

	if { $yStartText > $yStartColor } {
		set ymax $yStartText
	} else {
		set ymax $yStartColor
	}



	set scrollOrgWidth [expr $sramUnitX * $sramNumX + $canvasMarginX*2]
	set scrollOrgHeight [expr $ymax + $canvasMarginY]

	$canvas configure -scrollregion [list 0 0 $scrollOrgWidth $scrollOrgHeight]
	$canvas config -width $scrollOrgWidth -height $scrollOrgHeight



}

#========================================
# DrawSRAMCells
#	: for drawing SRAM cells with rectangles
#---------------------------------------
# Input :
#	canvas - canvas widget path
#	xunit - cell width
#	yunit - cell height
#	xnum - # of cells on raw
#	ynum - # of cells on column
#	xmargin, ymargin - margine for SRAM
#---------------------------------------
# Output :
#	cellBoxes - 2 dimension array for cell rectangles on canvas 
#========================================

proc DrawSRAMCells { xunit yunit xnum ynum \
		     xmargin ymargin } {
		     


	global canvas colNormalFill colNormalLine
	global faultCellNum faultCells

	set xstart $xmargin
	set ystart $ymargin

	set xend [expr $xunit * $xnum + $xstart]
	set yend [expr $yunit * $ynum + $ystart]


	#
	# Draw Vertical lines
	#

	for { set w 1 } { $w < $xnum } { incr w } {

		set xl [expr $w * $xunit + $xstart]

		if { [expr $w % 10] != 0 } {

			$canvas create line $xl $ystart $xl $yend \
				-fill $colNormalLine
		}
	}

	#
	# Draw Horizontal lines
	#

	for { set h 1 } { $h < $ynum } { incr h } {

		set yb [expr $h * $yunit + $ystart]
		if { [expr $h % 10] == 0 } {
			set lineCol black
		} else {
			set lineCol $colNormalLine
		}
		$canvas create line $xstart $yb $xend $yb \
			-fill $lineCol
	}

	#
	# Draw Horizontal lines per 10 units
	#

	for { set w 10 } { $w < $xnum } { incr w 10 } {
		set xl [expr $w * $xunit + $xstart]
		$canvas create line $xl $ystart $xl $yend \
			-fill black
	}

	#
	# Draw border of SRAM
	#

	$canvas create rectangle $xstart $ystart $xend $yend


	#
	# Draw Faulted Cells
	#

	for { set i 0 } { $i < $faultCellNum } { incr i } {

		set xi $faultCells($i,xi)
		set yi $faultCells($i,yi)
		set col $faultCells($i,color)

		set xl [expr ($xi - 1) * $xunit + $xstart]
		set xr [expr $xi * $xunit + $xstart]
		set yt [expr ($ynum - $yi) * $yunit + $ystart]
		set yb [expr ($ynum - $yi + 1) * $yunit + $ystart]

		$canvas create rectangle $xl $yt $xr $yb -fill $col
	}
}

#========================================
#========================================

proc Zoom { how } {
	global zoomFactor canvas
	global scrollOrgWidth scrollOrgHeight


	set revFactor [expr 1.0 / $zoomFactor]


	if { $how == "in" } {
		set zoomFactor [expr $zoomFactor + 0.25]
		if { $zoomFactor > 4.0 } {
			set zoomFactor 4.0
			return
		}
			
	} else {
		set zoomFactor [expr $zoomFactor - 0.25]
		if { $zoomFactor < 0.25 } {
			set zoomFactor 0.25
			return
		}
	}


	foreach tag [$canvas find all] {
		$canvas scale $tag 0 0 $revFactor $revFactor
	}

	foreach tag [$canvas find all] {
		$canvas scale $tag 0 0 $zoomFactor $zoomFactor
	}

	set width [expr $scrollOrgWidth * $zoomFactor]
	set height [expr $scrollOrgHeight * $zoomFactor]
	$canvas configure -scrollregion [list 0 0 $width $height]
	
}

#========================================
# MenuOpen :
#	command routine for Open menu
#========================================

proc MenuOpen {} {

	set typelist {
		{ "SRAM Viewer Files" {"*.srv"} }
		{ "All Files" {*} }
	}

	set filename [tk_getOpenFile -filetypes $typelist -defaultextension srv]
	set ret [ReadDataFile $filename]

	if { $ret == 1 } {
		Draw
	}
}

#========================================
# MenuClose :
#	command routine for Close menu
#========================================

proc MenuClose {} {
	global	canvas

	foreach tag [$canvas find all] {
		$canvas delete $tag
	}
}

#========================================
# MenuPrint :
#	command routine for Print menu
#========================================

proc MenuPrint {} {
	global canvas

	set width [$canvas cget -width]
	set height [$canvas cget -height]
	set region [$canvas cget -scrollregion]

	set typelist {
		{ "Postscript Files" {"*.ps"} }
		{ "All Files" {*} }
	}	
	set filename [tk_getSaveFile -filetypes $typelist -defaultextension ps\
			-initialfile noname ]
	$canvas postscript -file $filename -rotate true\
		-pagewidth 27c -pageheight 18c
}

#========================================
# MenuQuit :
#	command routine for Quit menu
#========================================

proc MenuQuit {} {
	set answer [ GUIQuestionBox \
			"Do you want to quit SRAM Viewer?" \
			yes ]
	if { $answer == "yes" } {
		exit 0
	}
}

#========================================
# MenuZoomIn :
#	command routine for ZoomIn menu
#========================================

proc MenuZoomIn {} {
	puts "zoom in "

	Zoom in
}

#========================================
# MenuZoomOut :
#	command routine for ZoomOut menu
#========================================

proc MenuZoomOut {} {
	puts "zoom out "
	Zoom out
}

#========================================
# MenuAbout :
#	command routine for About menu
#========================================

proc MenuAbout {} {
	GUIMessageBox About \
		"    SRAM Viewer Ver 1.0\n\n  Copyright (c) System IC R&D \nin Hyundai Electronics Inc. , 1998\n\n    Program by Nara Won"
}

#***************************************
# Main routine
#***************************************

#========================================
#
# Temporary Data Setting
#
#========================================


if { $tcl_platform(platform) == "windows"} {
	#console show
}

#========================================
#
# Make Menu
#
#========================================

#
# Full Down Menu
#

GUIMenuSetup .menubar

GUIMenu File
GUIMenuCommand File Open 	MenuOpen
GUIMenuCommand File Close 	MenuClose
GUIMenuSeparator File
GUIMenuCommand File Print	MenuPrint
GUIMenuSeparator File
GUIMenuCommand File Quit 	MenuQuit

GUIMenu View
GUIMenuCommand View ZoomIn	MenuZoomIn 
GUIMenuCommand View ZoomOut 	MenuZoomOut 

GUIMenu Help
GUIMenuCommand Help About	MenuAbout 

#
# User Defined Tool Bar
#

GUIResourceButtonFrame .user User


#========================================
#
# Make canvas
#
#========================================

set colNormalFill	white
set colNormalLine	grey
set zoomFactor		1

set canvas [ GUIScrolledCanvas .c -width 300 -height 200 \
	-relief sunken -bd 2 -background white]

if { $argc > 0 } {

	set ret [ReadDataFile [lindex $argv 0]]
	if { $ret == 1 } {
		Draw
	}
}

pack .c -fill both -expand true


