#!/usr/bin/tclsh

# A Simple Template Parser

namespace eval ::SimpleTemplater {

    set debug 0
    set functions {
        for
        if
    }

    set functionsWithIndex {
        if
    }

    array set functionOperators {
        for { in }
        if  { in < > <= >= ni == != }
    }

    array set _op {}
    foreach { key val } [array get functionOperators] {
        foreach v $val {
            set _op($v) ""
        }
    }
    set operators [array names _op]
    unset _op key val v

    set additionalAttributes        "loop.count"
    set functionPattern             "{% *([join $functions |]) +(\\w+) +([join $operators |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additionalAttributes |]|'.*') *%}"
    set functionPatternWithIndex    "{% *([join $functionsWithIndex |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additionalAttributes |]|'.*') +([join $operators |]) +(\\w+(?:\.\\d+|\.\\w+)*|[join $additionalAttributes |]|'.*') *%}"
    set functionEndPattern          "{% *end([join $functions |]) *%}"

    set lappendCmd                  "lappend ::SimpleTemplater::html"

    proc dquoteEscape { str } {
        return [regsub -all {"} $str {\"}]
    }

    proc error2Html { str } {
        # regsub -all {(\{|\}|\")} $str {\\\1} str
        regsub -all {\r\n} $str {<br/>} str
        regsub -all {\n} $str {<br/>} str
        regsub -all { } $str {\&nbsp;} str
        return $str
    }

    proc htmlEncode { str { tick 0 } } {
        regsub -all {&} $str {\&amp;}       str
        regsub -all {"} $str {\&quot;}      str
        regsub -all {<} $str {\&lt;}        str
        regsub -all {>} $str {\&gt;}        str

        if { $tick } {
            regsub -all {'} $str {\&#8217;}     str
        } else {
            regsub -all {'} $str {\&#39;}       str
        }
        return $str
    }

    proc bufferOut { msg } {
        variable _bufferOut

        lappend _bufferOut $msg
    }

    proc applyFilters { object filter html_encode_var tick_var } {
        upvar $html_encode_var html_encode
        upvar $tick_var tick

        switch $filter {
            safe {
                set html_encode 0
            }
            tick {
                set tick 1
            }
            test {
                # new filters could be added like-wise
                set object "\[list $object\]"
            }
            default {}
        }
        return $object
    }

    proc processObject { object { html_encode 0 } { tick 0 } } {
        variable debug

        lappend objSplit {*}[split $object |]
        set object [lindex $objSplit 0]
        set transformFuncs [lrange $objSplit 1 end]
        if { $debug } { puts stderr "object : '$object' transform functions: '$transformFuncs'" }
        set objSplit ""
        lappend objSplit {*}[split $object "."]
        set mainObj [lindex $objSplit 0]
        set rest [lrange $objSplit 1 end]
        if { $mainObj == "loop" && $rest == "count" } {
            set newObj "\$::SimpleTemplater::object(loop.count)"
        } else {
            set newObj "\$::SimpleTemplater::object($mainObj)"
            foreach index $rest {
                if { [regexp "^\\d+$" $index] } {
                    set newObj "\[lindex $newObj $index\]"
                } elseif { [regexp "^\\w+$" $index]} {
                    set newObj "\[dict get $newObj $index\]"
                }
            }
        }

        foreach filter $transformFuncs {
            set newObj [applyFilters $newObj $filter html_encode tick]
        }

        if { $html_encode } {
            return "\[::SimpleTemplater::htmlEncode $newObj $tick\]"
        }
        return $newObj
    }

    proc processFunc_for { params } {
        variable functionOperators

        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $functionOperators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "foreach ::SimpleTemplater::object($iter) \[list $new_limiter\] \{"
        } else {
            return "foreach ::SimpleTemplater::object($iter) [processObject $limiter] \{"
        }
    }

    proc processFunc_if { params } {
        variable functionOperators

        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $functionOperators($function) } { error "Unsupported operator '$operator' used!" }
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
                    lappend str [join [lrange $save 0 [expr $last_open - 1]] ""] [processObject [string trim [join $object ""]] 1]
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
        puts $fh "namespace eval ::SimpleTemplater {}"
        puts $fh "array set ::SimpleTemplater::object {\n    [array get ::SimpleTemplater::object]\n}\n"
        puts $fh "$code"
        close $fh
    }

    proc parser { template_var } {
        upvar $template_var template

        variable object
        variable debug
        variable functionPattern
        variable functionEndPattern
        variable functionPatternWithIndex
        variable lappendCmd
        variable _bufferOut

        set loop_enabled {
            for
        }

        set call_stack ""

        foreach line $template {

            if { [regexp "(^ *)$functionPattern" $line --> indent function iter operator limiter] } {
                if { $debug } { puts stderr "function:$function iter:$iter operator:$operator limiter:$limiter" }
                lappend call_stack $function
                set params [list $function $iter $operator $limiter]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"

                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::SimpleTemplater::loop(last_loop) \[incr ::SimpleTemplater::loopCnt\]"
                    bufferOut "${indent}set ::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop)) 0"
                    bufferOut "${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                bufferOut "${indent}[processFunc_${function} $params]"
                if { $function in $loop_enabled } {
                    bufferOut "[string repeat " " 4]${indent}incr ::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                    bufferOut "[string repeat " " 4]${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                continue
            } elseif { [regexp "(^ *)$functionPatternWithIndex" $line --> indent function iter operator limiter] } {
                if { $debug } { puts stderr "function:$function iter:$iter operator:$operator limiter:$limiter" }
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

            if { [regexp "(^ *)$functionEndPattern" $line --> indent function_close] } {
                set function [lindex $call_stack end]
                set call_stack [lrange $call_stack 0 end-1]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut " ${indent}\}"
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::SimpleTemplater::loop(last_loop) \[incr ::SimpleTemplater::loopCnt -1\]"
                    bufferOut "${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                continue
            }

            bufferOut "$lappendCmd \"[processLine $line]\""
        }

        return [join $_bufferOut \n]
    }

    proc renderHtml { template obj } {
        variable object
        variable debug
        variable html
        variable loop
        variable loopCnt
        variable _bufferOut

        set _bufferOut ""
        set html ""
        set output ""
        set loop(last_loop) 0
        set loop(0) 0
        set loopCnt 0
        # array set object [uplevel subst [list $obj]]
        array set object {}
        foreach { var val } $obj {
           array set object [list $var [uplevel subst [list $val]]]
        }
        # parray object

        set fh [open $template r]
        set template ""
        while { ![eof $fh] } {
            lappend template [gets $fh]
        }
        close $fh
        set output [parser template]

        if { $debug } {
            puts stderr $output
            codeGenerator $output
        }
        eval $output
        unset object
        return [join $html \n]
    }
}