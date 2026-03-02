#!/usr/local/bin/wish

lappend auto_path ./menulib
package require MENU 1.0

Menu_Setup .menubar
Menu DemoMenu
Menu_Command DemoMenu Hello! { puts "Hello, World!" }
Menu_Check DemoMenu Boolean foo { puts "foo = $foo" }
Menu_Separator DemoMenu
Menu_Cascade DemoMenu Fruit
Menu_Radio Fruit apple fruit
Menu_Radio Fruit orange fruit
Menu_Radio Fruit kiwi fruit