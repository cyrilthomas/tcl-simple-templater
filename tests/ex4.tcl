#!/usr/bin/tclsh

lappend auto_path ../
package require "SimpleTemplater"
source ../helper_filters.tcl

set begin [clock milliseconds]
# ::SimpleTemplater::setConfig -debug                     "true"
puts [::SimpleTemplater::render ex4.tpl {
    gender_list {
        Male {
            list {
                {
                    "first_name" "George"
                    "last_name" "Bush"
                    "gender" "Male"
                }
                {
                    "first_name" "Bill"
                    "last_name" "Clinton"
                    "gender" "Male"
                }
            }
        }
        Female {
            list {
                {
                    "first_name" "Margaret"
                    "last_name" "Thatcher"
                    "gender" "Female"
                }
                {
                    "first_name" "Condoleezza"
                    "last_name" "Rice"
                    "gender" "Female"
                }
            }
        }
        Unknown {
            list {
                {
                    "first_name" "Pat"
                    "last_name" "Smith"
                    "gender" "Unknown"
                }
            }
        }
    }
}]

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"


