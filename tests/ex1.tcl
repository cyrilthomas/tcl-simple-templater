#!/usr/bin/tclsh

source ../SimpleTemplater.tcl


# set ::SimpleTemplater::debug 1
set begin [clock milliseconds]

if { [catch {
    foreach { name desc } {
        en    English
        es    Spanish
        fr    French
        de    German
    } {
        dict set language lang $name
        dict set language desc $desc
        lappend languages [dict get $language]
    }
    # puts $languages

    set html [::SimpleTemplater::render ex1.tpl [dict create \
        states [list \
            [dict create \
                name "Alabama" \
                cities [list \
                    [dict create \
                        name "auburn" \
                        url  "http://auburn.craigslist.org" \
                    ] \
                    [dict create \
                        name "birmingham" \
                        url "http://bham.craigslist.org" \
                    ] \
                ] \
            ] \
            [dict create \
                name "Alaska" \
                cities [list \
                    [dict create \
                        name "anchorage" \
                        url  "http://anchorage.craigslist.org" \
                    ] \
                    [dict create \
                        name "fairbanks" \
                        url "http://fairbanks.craigslist.org" \
                    ] \
                ] \
            ] \
        ] \
        languages $languages \
    ]]
} errMsg] } {
    # To be caught at the highest level
    set html [::SimpleTemplater::render "error.tpl" [dict create \
        error [::SimpleTemplater::error2Html $errMsg] \
        info [::SimpleTemplater::error2Html $::errorInfo] \
    ]]
}

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"
puts [encoding convertfrom utf-8 $html]