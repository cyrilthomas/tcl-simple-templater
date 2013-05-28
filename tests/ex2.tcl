#!/usr/bin/tclsh

lappend auto_path .
source SimpleTemplater.tcl
source helper_filters.tcl

# set ::SimpleTemplater::debug 1
set begin [clock milliseconds]


proc FormatPrefixedPhoneNumber { context } {
    return [regsub {(\d{1})(\d{3})(\d{3})(\d{3})} $context {+\1 \2 \3 \4}]
}

proc RegSub { context } {
    return [regsub -all {\-} $context { }]
}

proc HyperLink { context } {
    return "<a href=\"$context\">$context</a>"
}

proc Modulus { context args } {
    return [expr { $context % [lindex $args 0] }]
}

proc Color { context } {
    if { $context == 1 } {
        return "background-color:#EEE"
    } else {
        return "background-color:transparent"
    }
}

::SimpleTemplater::registerFilter -safe false -filter phone     -proc RegSub
::SimpleTemplater::registerFilter -safe false -filter prefix_ph -proc FormatPrefixedPhoneNumber
::SimpleTemplater::registerFilter -safe false -filter bold      -proc ::SimpleTemplater::helper::filters::bold
::SimpleTemplater::registerFilter -safe true  -filter italic    -proc ::SimpleTemplater::helper::filters::italic
::SimpleTemplater::registerFilter -safe false -filter ulist     -proc ::SimpleTemplater::helper::filters::ulist
::SimpleTemplater::registerFilter -safe true  -filter link      -proc HyperLink
::SimpleTemplater::registerFilter -safe false -filter modulus   -proc Modulus
::SimpleTemplater::registerFilter -safe false -filter color     -proc Color

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
            url {http://www.google.com}
        }

        {
            name {David's Beck}
            place {England}
            phone {1469664972}
            personal {}
            url {http://www.facebook.com}
        }

        {
            name "Sam Philip"
            place {Australia}
            phone {1569664972}
            personal "[list \
                phone   "007-134-4567" \
                email   "sam.philip@e-mail.com" \
            ]"
            url {http://www.yahoo.com}
        }
    }

    sample {
        a b c d
        e f g h
    }
}]

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"
