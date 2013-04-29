#!/usr/bin/tclsh

# TCL micro template parser

namespace eval ::microTemplateParser {

    set debug 0
    set functions {
        for
        if
    }

    set functions_with_index {
        if
    }

    array set function_operators {
        for { in }
        if  { in < > <= >= ni == != }
    }

    array set _op {}
    foreach { key val } [array get function_operators] {
        foreach v $val {
            set _op($v) ""
        }
    }
    set operators [array names _op]
    unset _op key val v

    set additional_attributes       "loop.count"
    set function_pattern            "{% *([join $functions |]) +(\\w+) +([join $operators |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additional_attributes |]|'.*') *%}"
    set function_pattern_with_index "{% *([join $functions_with_index |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additional_attributes |]|'.*') +([join $operators |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additional_attributes |]|'.*') *%}"
    set function_end_pattern        "{% *end([join $functions |]) *%}"

    set lappendCmd                  "lappend ::microTemplateParser::html"

    proc dquoteEscape { str } {
        return [regsub -all {"} $str {\"}]
    }

    proc error2Html { str } {
        regsub -all {(\{|\}|\")} $str {\\\1} str
        regsub -all {\r\n} $str {<br/>} str
        regsub -all {\n} $str {<br/>} str
        regsub -all { } $str {\&nbsp;} str
        return $str
    }

    proc bufferOut { msg } {
        variable BufferOut
        lappend BufferOut $msg
    }

    proc processObject { object } {
        lappend objSplit {*}[split $object "."]
        set mainObj [lindex $objSplit 0]
        set rest [lrange $objSplit 1 end]
        if { $mainObj == "loop" && $rest == "count" } {
            set newObj "\$::microTemplateParser::object(loop.count)"
        } else {
            set newObj "\$::microTemplateParser::object($mainObj)"
            foreach index $rest {
                if { [regexp "\\d+" $index] } {
                    set newObj "\[lindex $newObj $index\]"
                } elseif { [regexp "\\w+" $index]} {
                    set newObj "\[dict get $newObj $index\]"
                }
            }
        }
        return $newObj
    }

    proc processFunc_for { params } {
        variable function_operators
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $function_operators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "foreach ::microTemplateParser::object($iter) \[list $new_limiter\] \{"    
        } else {
            return "foreach ::microTemplateParser::object($iter) [processObject $limiter] \{"
        }
    }

    proc processFunc_if { params } {
        variable function_operators
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $function_operators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "if \{ [processObject $iter] $operator \[list $new_limiter\] \} \{"
        } else {
            return "if \{ [processObject $iter] $operator [processObject $limiter] \} \{"
        }
    }

    proc processFuncWithIndex_if { params } {
        processFunc_if $params
    }

    proc processLine { line } {
        variable debug
        variable loop

        regsub -all {([][$\\])} $line {\\\1} line ;# disable command executions

        set pos 0
        set char_list [split $line {}]
        set max_pos [llength $char_list]
        if { !$max_pos } { set max_pos -1 }
        set save ""
        set start 0
        set object ""
        set last_open end
        set str ""

        while { $pos <= $max_pos } {
            set double_char "[lindex $char_list $pos][lindex $char_list [expr $pos + 1]]"
            if { $double_char == "\{\{" } {
                set last_open [llength $save]
                lappend save [lindex $char_list $pos]
                incr pos
                set start 1
                set object ""
                set init 1
            } elseif { $start } {
                if { $init } {
                    incr pos
                    set init 0
                }
                if { $double_char == "\}\}" } {
                    lappend str [join [lrange $save 0 [expr $last_open - 1]] ""] [processObject [string trim [join $object ""]]]
                    set save ""
                    set object ""
                    set start 0
                    incr pos 2
                } else {
                    lappend object [lindex $char_list $pos]
                    lappend save [lindex $char_list $pos]
                    incr pos
                }
            } else {
                lappend str [lindex $char_list $pos]
                incr pos
            }
        }

        return [dquoteEscape [join $str ""]]
    }

    proc codeGenerator { code } {
        set fh [open generated_code.tcl w]
        puts $fh "#!/usr/bin/tclsh"
        puts $fh "namespace eval ::microTemplateParser {}"
        puts $fh "array set ::microTemplateParser::object {\n    [array get ::microTemplateParser::object]\n}\n"
        puts $fh "$code"
        close $fh
    }

    proc parser { template_var } {
        upvar $template_var template
        variable object
        variable debug
        variable BufferOut
        variable function_pattern
        variable function_end_pattern
        variable function_pattern_with_index
        variable lappendCmd 

        set loop_enabled {
            for
        }

        set call_stack ""

        foreach line $template {

            if { [regexp "(^ *)$function_pattern" $line --> indent function iter operator limiter] } {
                if { $debug } { puts "function:$function iter:$iter operator:$operator limiter:$limiter" }
                lappend call_stack $function
                set params [list $function $iter $operator $limiter]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::microTemplateParser::loop(last_loop) \[incr ::microTemplateParser::loop_cnt\]"
                    bufferOut "${indent}set ::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop)) 0"
                    bufferOut "${indent}set ::microTemplateParser::object(loop.count) \$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))"
                }
                bufferOut "${indent}[processFunc_${function} $params]"
                if { $function in $loop_enabled } {
                    bufferOut "[string repeat " " 4]${indent}incr ::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))"
                    bufferOut "[string repeat " " 4]${indent}set ::microTemplateParser::object(loop.count) \$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))"
                }
                continue
            } elseif { [regexp "(^ *)$function_pattern_with_index" $line --> indent function iter operator limiter] } {
                if { $debug } { puts "function:$function iter:$iter operator:$operator limiter:$limiter" }
                lappend call_stack $function
                set params [list $function $iter $operator $limiter]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut "${indent}[processFuncWithIndex_${function} $params]"
                continue
            }

            if {
                [apply { { line out_var } {
                    upvar $out_var out
                    set out ""
                    if { [regexp "(^ *){% *(else) *%}" $line --> indent object] } {
                        set out "${indent}\} else \{"
                        return 1
                    }
                    return 0
                }} $line else_block]
            } {
                set indent "[string repeat " " [string length $lappendCmd]]"
                bufferOut "${indent}$else_block"
                continue
            }

            if { [regexp "(^ *){% *continue *%}" $line --> indent] } {
                set indent "${indent}[string repeat " " [string length $lappendCmd]][string repeat " " 4]"
                bufferOut "${indent}continue"
                continue
            }

            if { [regexp "(^ *){% *break *%}" $line --> indent] } {
                set indent "${indent}[string repeat " " [string length $lappendCmd]][string repeat " " 4]"
                bufferOut "${indent}break"
                continue
            }

            if { [regexp "(^ *)$function_end_pattern" $line --> indent function_close] } {
                set function [lindex $call_stack end]
                set call_stack [lrange $call_stack 0 end-1]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut " ${indent}\}"
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::microTemplateParser::loop(last_loop) \[incr ::microTemplateParser::loop_cnt -1\]"
                    bufferOut "${indent}set ::microTemplateParser::object(loop.count) \$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))"
                }
                continue
            }

            bufferOut "$lappendCmd \"[processLine $line]\""
        }

        return [join $BufferOut \n]
    }

    proc renderHtml { template obj } {
        variable object
        variable debug
        variable html
        variable BufferOut
        variable loop
        variable loop_cnt

        set BufferOut ""
        set html ""
        set output ""
        set loop(last_loop) 0
        set loop(0) 0
        set loop_cnt 0
        array set object [uplevel subst "{$obj}"]

        set fh [open $template r]
        set template ""
        while { ![eof $fh] } {
            lappend template [gets $fh]
        }
        close $fh
        set output [parser template]

        if { $debug } {
            puts $output
            codeGenerator $output
        }
        eval $output
        unset object
        return [join $html \n]
    }
}