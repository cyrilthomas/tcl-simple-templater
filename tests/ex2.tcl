#!/usr/bin/tclsh

lappend auto_path .
source SimpleTemplater.tcl

# set ::SimpleTemplater::debug 1
set begin [clock milliseconds]


proc FormatPrefixedPhoneNumber { context } {
    return [regsub {(\d{1})(\d{3})(\d{3})(\d{3})} $context {+\1 \2 \3 \4}]
}

proc RegSub { context } {
    return [regsub -all {\-} $context { }]
}

::SimpleTemplater::registerFilter phone     RegSub
::SimpleTemplater::registerFilter prefix_ph FormatPrefixedPhoneNumber
::SimpleTemplater::registerFilter bold      ::SimpleTemplater::helper::filters::bold
::SimpleTemplater::registerFilter italic    ::SimpleTemplater::helper::filters::italic
::SimpleTemplater::registerFilter ulist     ::SimpleTemplater::helper::filters::ulist

puts [::SimpleTemplater::render ex2.tpl {
    address_book {
        {
            name {John Doe}
            place {USA}
            phone {1369664972}
            personal {
                phone   "001-123-12345"
                email   "john.doe@e-mail.com"
            }

        }

        {
            name {David Beck}
            place {England}
            phone {1469664972}
            personal {}
        }

        {
            name "Sam Philip"
            place {Australia}
            phone {1569664972}
            personal "[list \
                phone   "007-134-4567" \
                email   "sam.philip@e-mail.com" \
            ]"
        }
    }

    sample {
        a b c d
        e f g h
    }
}]

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"
