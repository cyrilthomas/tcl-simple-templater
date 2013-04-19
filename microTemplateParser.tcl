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
    set function_pattern            "{% *([join $functions |]) +(\\w+) +([join $operators |]) +(\\w+|\\w+\.\\d+|[join $additional_attributes |]|'.*') *%}"
    set function_pattern_with_index "{% *([join $functions_with_index |]) +(\\w+\.?\\d*|[join $additional_attributes |]) +([join $operators |]) +(\\w+\.?\\d*|[join $additional_attributes |]|'.*') *%}"
    set function_end_pattern        "{% *end([join $functions |]) *%}"

    set lappendCmd                  "lappend ::microTemplateParser::html"

    proc dquoteEscape { str } {
        return [regsub -all {"} $str {\"}]
    }

    proc bufferOut { msg } {
        variable BufferOut
        lappend BufferOut $msg
    }

    proc processFunc_for { params } {
        variable function_operators
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        if { $operator ni $function_operators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "foreach ::microTemplateParser::object($iter) \[list $new_limiter\] \{"    
        } elseif { [regexp "(\\w+)\.(\\d+)" $limiter --> limiter limiter_index] } {
            return "foreach ::microTemplateParser::object($iter) \[lindex \$::microTemplateParser::object($limiter) $limiter_index\] \{"
        } else {
            return "foreach ::microTemplateParser::object($iter) \$::microTemplateParser::object($limiter) \{"
        }
    }

    proc processFunc_if { params } {
        variable function_operators
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        if { $operator ni $function_operators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "if \{ \$::microTemplateParser::object($iter) $operator \[list $new_limiter\] \} \{"    
        } else {
            return "if \{ \$::microTemplateParser::object($iter) $operator \$::microTemplateParser::object($limiter) \} \{"
        }
    }

    proc processFuncWithIndex_if { params } {
        variable function_operators
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        if { $operator ni $function_operators($function) } { error "Unsupported operator '$operator' used!" }
        set iter_index      ""
        set limiter_index   ""
        foreach { iter iter_index } [split $iter] break
        if { $iter_index == "" } { set iter_index 0 }
        if { $iter == "loop" && $iter_index== "count" } {
            set iter "\$::microTemplateParser::object(loop.count)"
        } else {
            set iter "\[lindex \$::microTemplateParser::object($iter) $iter_index\]"
        }

        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            set limiter "\"$new_limiter\""
        } else {
            foreach { limiter limiter_index } [split $limiter] break
            if { $limiter_index == "" } { set limiter_index 0 }
            set limiter "\[lindex \$::microTemplateParser::object($limiter) $limiter_index\]"
        }
        return "if \{ $iter $operator $limiter \} \{"
    }

    proc processLine { line } {
        variable debug
        variable loop

        regsub -all {([][$\\])} $line {\\\1} line ;# disable command executions
        # regsub -all "{{ *loop.count *}}" $line "\$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))" line
        regsub -all "{{ *loop.count *}}" $line "\$::microTemplateParser::object(loop.count)" line
        
        if { [regexp "{{ *(\\w+) *}}" $line --> object] } {
            if { $debug } { puts "token : $object" }
            regsub -all "{{ *(\\w+) *}}" $line "\$::microTemplateParser::object(\\1)" line
        }

        if { [regexp "{{ *(\\w+)\.(\\d+) *}}" $line --> object index] } {
            if { $debug } { puts "token: $object index: $index" }
            regsub -all "{{ *(\\w+)\.(\\d+) *}}" $line "\[lindex \$::microTemplateParser::object(\\1) \\2\]" line
        }

        return [dquoteEscape $line]
    }

    proc codeGenerator { code } {
        set fh [open generated_code.tcl w]
        puts $fh "#!/usr/bin/tclsh"
        puts $fh "namespace eval ::microTemplateParser {}"
        puts $fh "array set ::microTemplateParser::object {\n    [array get ::microTemplateParser::object]\n}\n"
        puts $fh "$code"
        close $fh
    }

    proc parser { template_handle } {
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

        while { ![eof $template_handle] } {
            set line [gets $template_handle]

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
                foreach { iter iter_index } [split $iter .] break
                foreach { limiter limiter_index } [split $limiter .] break
                if { $debug } { puts "function:$function iter:$iter index:$iter_index operator:$operator limiter:$limiter index:$limiter_index" }
                lappend call_stack $function
                set params [list $function [list $iter $iter_index] $operator [list $limiter $limiter_index]]
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
        set output [parser $fh]
        close $fh
        if { $debug } {
            puts $output
            codeGenerator $output
        }
        eval $output
        # if { $debug } { puts $errMsg; return }
        unset object
        return [join $html \n]
    }
}