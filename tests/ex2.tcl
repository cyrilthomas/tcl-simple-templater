#!/usr/bin/tclsh

lappend auto_path .
source microTemplateParser.tcl

set ::microTemplateParser::debug 0
set begin [clock milliseconds]

puts [::microTemplateParser::renderHtml ex2.tpl {
    address_book {
        {
            name {John Doe}
            place {USA}
            phone {001}
            personal {
                phone   "001-123-12345"
                email   "john.doe@e-mail.com"
            }

        }

        {
            name {David Beck}
            place {England}
            phone {002}
            personal {}
        }

        {
            name "Sam Philip"
            place {Australia}
            phone {003}
            personal "[list \
                phone   "007-134-4567" \
                email   "sam.philip@e-mail.com" \
            ]"
        }
    }
}]

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"
