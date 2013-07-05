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

        set html [::SimpleTemplater::render ex1.tpl {
            states {
                {
                    name    "Alabama"
                    cities  {
                        {
                            name    "auburn"
                            url     "http://auburn.craigslist.org"
                        }

                        {
                            name    "birmingham"
                            url     "http://bham.craigslist.org"
                        }

                        {
                            name    "dothan"
                            url     "http://dothan.craigslist.org"
                        }
                    }
                }

                {
                    name    "Alaska"
                    cities  {
                        {
                            name    "anchorage"
                            url     "http://anchorage.craigslist.org"
                        }

                        {
                            name "fairbanks"
                            url "http://fairbanks.craigslist.org"
                        }
                    }
                }
            }

            languages "$languages"
        }]
    } errMsg ]
} {
    # To be caught at the highest level
    set html [::SimpleTemplater::render "error.tpl" {
        error "[::SimpleTemplater::error2Html $errMsg]"
        info "[::SimpleTemplater::error2Html $::errorInfo]"
    }]
}

set end [clock milliseconds]
puts stderr "Completed rendering in [expr $end - $begin] ms"

puts [encoding convertfrom utf-8 $html]