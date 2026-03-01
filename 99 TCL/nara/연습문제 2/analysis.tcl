#!/usr/local/bin/tclsh


while { [ eof stdin ] != 1 } {
    gets stdin line

    if [ string match "#*" $line ] continue

    if { "$line" == "" } continue

    if [ string match "*:*" $line ] {

        set ll [ split $line : ]

        set type  [ lindex $ll 0 ]
        set value [ lindex $ll 1 ]
        
        set type  [ string trim  $type  " \t" ]
        set value [ string trim  $value " \t" ]

        switch -- $type {
             TITLE    { set title   $value }
             COMMENT  { set comment $value }
             DATA_NUM { set num     $value }
             LOT_NUM  { set lot     $value }
             FIELD_NAMES { set fieldNames $value }
        }

    } else {
       
       set ll [ split $line " \t" ]

       set first 1 
       set ll2 ""
       foreach i $ll {
           if { "$i" == "" }  continue
           set i [ string trim $i " \t" ]
           if { $first == 1 } {
              lappend field_name $i
              set first 0
           } else {
              lappend ll2 $i
           }
       }
       lappend field_data $ll2

    }

}

puts "title       : $title"
puts "comment     : $comment"
puts "data number : $num"
puts "lot number  : $lot"
puts "field names : $fieldNames"

foreach name $field_name data $field_data {
    puts "DATA : $name - $data"
}


