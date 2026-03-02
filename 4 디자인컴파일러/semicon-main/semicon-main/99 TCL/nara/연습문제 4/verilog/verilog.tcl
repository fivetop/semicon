#!/usr/local/bin/tclsh

set all_line ""

while { [ eof stdin ] == 0 } {

    gets stdin line
    

    append all_line $line
    
}

set each_line [ split $all_line ";" ]

foreach line $each_line {

    if [ regexp {module[ \t]+([a-zA-Z0-9_]+)} $line all mname ] {
        lappend module_names $mname
    }
    if       [ regexp    {input[ \t]+(.+)} $line all inputs ] {
         regsub -all {[ \t]+} $inputs {} inputs 
         set inlist [ split $inputs "," ]
         foreach e $inlist {
             lappend data($mname.inputs) $e
         }
    } elseif [ regexp    {output[ \t]+(.+)} $line all outputs ] {
         regsub -all {[ \t]+} $outputs {} outputs 
         set outlist [ split $outputs "," ]
         foreach e $outlist {
             lappend data($mname.outputs) $e
         }
    } elseif [ regexp    {inout[ \t]+(.+)} $line all inouts ] {
         regsub -all {[ \t]+} $inouts {} inouts 
         set iolist [ split $inouts "," ]
         foreach e $iolist {
             lappend data($mname.inouts) $e
         }
    }
    
}


foreach mn $module_names {
    puts "MODULE NAME : $mn"
    puts "    inputs : $data($mn.inputs)"
    puts "    outputs : $data($mn.outputs)"
    puts "    inouts : $data($mn.inouts)"
}

