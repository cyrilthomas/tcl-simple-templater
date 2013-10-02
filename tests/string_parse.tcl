#!/usr/bin/tclsh

source ../SimpleTemplater.tcl

proc Capitalize { context args } {
    set cap [list]
    foreach arg $context {
        lappend cap "[string toupper [string index $arg 0]][string tolower [string range $arg 1 end]]"
    }
    return [join $cap " "]
}

::SimpleTemplater::registerFilter -filter capitalize -proc Capitalize

set candidate "joHn dOe"
puts [::SimpleTemplater::renderString "
Hi {{ name|capitalize }},
    Welcome to our team!

Regards,
{{ ceo|capitalize }}
" [dict create \
    name $candidate \
    ceo "ALEX" \
]]
