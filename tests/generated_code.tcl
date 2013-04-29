#!/usr/bin/tclsh
namespace eval ::microTemplateParser {}
array set ::microTemplateParser::object {
    address_book {
                            {
                                name {John Doe}
                                place {USA}
                                phone {001}
                            }
                            {
                                name {David Beck}
                                place {England}
                                phone {002}
                            }
                        } legacy_order_no 1000 sample {{test00 test01} {test10 test11} {test12 test13} {test14 test15}} item_nos {10 20 30} item_no dance rows {
                            { hello world }
                            { good bye }
                            { sample value }
                            { blue sky }
                        } compare {10 10}
}

lappend ::microTemplateParser::html ""
lappend ::microTemplateParser::html "<html>"
lappend ::microTemplateParser::html "    <header>"
lappend ::microTemplateParser::html "        <script type=\"text/javascript\">"
lappend ::microTemplateParser::html "            alert('Welcome');"
lappend ::microTemplateParser::html "        </script>"
lappend ::microTemplateParser::html "    </header>"
lappend ::microTemplateParser::html "    <body>"
lappend ::microTemplateParser::html "        <table border=\"1\">"
                                               set ::microTemplateParser::loop(last_loop) [incr ::microTemplateParser::loop_cnt]
                                               set ::microTemplateParser::loop($::microTemplateParser::loop(last_loop)) 0
                                               set ::microTemplateParser::object(loop.count) $::microTemplateParser::loop($::microTemplateParser::loop(last_loop))
                                               foreach ::microTemplateParser::object(addr) $::microTemplateParser::object(address_book) {
                                                   incr ::microTemplateParser::loop($::microTemplateParser::loop(last_loop))
                                                   set ::microTemplateParser::object(loop.count) $::microTemplateParser::loop($::microTemplateParser::loop(last_loop))
lappend ::microTemplateParser::html "                <tr><td colspan=\"2\"><h4>$::microTemplateParser::object(loop.count). [dict get $::microTemplateParser::object(addr) name]</h4></td></tr>"
lappend ::microTemplateParser::html "                <tr><td>Firstname</td><td>[lindex [dict get $::microTemplateParser::object(addr) name] 0]</td></tr>"
lappend ::microTemplateParser::html "                <tr><td>Lastname</td><td>[lindex [dict get $::microTemplateParser::object(addr) name] 1]</td></tr>"
lappend ::microTemplateParser::html "                <tr><td>Place</td><td>[dict get $::microTemplateParser::object(addr) place]</td></tr>"
lappend ::microTemplateParser::html "                <tr><td>Phone</td><td>[dict get $::microTemplateParser::object(addr) phone]</td></tr>"
lappend ::microTemplateParser::html "                <tr/>"
                                                }
                                               set ::microTemplateParser::loop(last_loop) [incr ::microTemplateParser::loop_cnt -1]
                                               set ::microTemplateParser::object(loop.count) $::microTemplateParser::loop($::microTemplateParser::loop(last_loop))
lappend ::microTemplateParser::html "        </table>"
lappend ::microTemplateParser::html "    </body>"
lappend ::microTemplateParser::html "</html>"
lappend ::microTemplateParser::html ""
lappend ::microTemplateParser::html ""
