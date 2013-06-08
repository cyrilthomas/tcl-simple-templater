#!/usr/bin/tclsh

# A Simple Template Parser

namespace eval ::SimpleTemplater {

    set debug 0
    set invalidTemplateString ""
    array set customFilter {}
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
    set objectExpression_1          "(\\w+(?:\\.\\d+|\\.\\w+|\\|\\S+)*|[join $additionalAttributes |]|'.*')"
    set functionPattern             "{% *([join $functions |]) +(\\w+(?: *, *\\w+)*) +([join $operators |]) +$objectExpression_1 *%}"
    set functionPatternWithIndex    "{% *([join $functionsWithIndex |]) +$objectExpression_1 +([join $operators |]) +$objectExpression_1 *%}"
    set functionEndPattern          "{% *end([join $functions |]) *%}"

    set lappendCmd                  "lappend ::SimpleTemplater::html"

    proc setConfig { args } {
        variable debug
        variable invalidTemplateString

        foreach key [dict keys $args]  {
            switch -exact -- $key {
                "-debug" {
                    if { [dict get $args $key] == "true" } {
                        set debug 1
                    } elseif { [dict get $args $key] == "false" } {
                        set debug 0
                    }
                }
                "-invalid_template_string" {
                    set invalidTemplateString [dict get $args $key]
                }
                default {}
            }
        }
    }

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

    proc executeCommand { cmd } {
        variable debug
        if { $debug } { puts stderr "\[$cmd\]" }
        return "\[$cmd\]"
    }

    proc debugHint { context_var } {
        return [regsub {.*SimpleTemplater::object\((.*)\)} $context_var {\1}]
    }

    proc objectExists { obj_var index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug
        upvar $obj_var object

        set out ""
        set found 0
        if { [info exists object($index)] } {
            set found 1
            set out $object($index)
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }
        if { !$found && $debug } {
            puts stderr "Please check your template var $index"
            # TODO: throw errors
        }
        return $out
    }

    proc listExists { context index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug

        set out ""
        set found 0
        if { $index > -1 && $index < [llength $context] } {
            set found 1
            set out [lindex $context $index]
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }

        if { !$found && $debug } {
            puts stderr "Index ($index) out of range"
            # TODO: throw errors
        }
        return $out
    }

    proc dictExists { context index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug

        set out ""
        set found 0
        if { ![catch { dict exists $context $index } errMsg] && [dict exists $context $index] } {
            set found 1
            set out [dict get $context $index]
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }

        if { !$found && $debug } {
            puts stderr "Key ($index) not found"
            # TODO: throw errors
        }
        return $out
    }

    proc registerFilter { args } {
        variable customFilter

        set name [dict get $args "-filter"]
        set proc [dict get $args "-proc"]
        set customFilter($name) $proc
        set customFilter($name,html_encode) 1
        set customFilter($name,tick) 0

        if { [dict exists $args "-safe"] } {
            if { [dict get $args "-safe"] == "true" } {
                set customFilter($name,html_encode) 0
            } elseif { [dict get $args "-safe"] == "false" } {
                set customFilter($name,html_encode) 1
            }
        }

        if { [dict exists $args "-tick"] } {
            if { [dict get $args "-tick"] == "true" } {
                set customFilter($name,tick) 1
            } elseif { [dict get $args "-tick"] == "false" } {
                set customFilter($name,tick) 0
            }
        }
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
                # set object "\[::SimpleTemplater::newFilterProc $object\]"
            }
            default {}
        }
        return $object
    }

    proc processObject { object { not_loop 0 } } {

        variable debug
        variable customFilter
        variable additionalAttributes

        set htmlEncode 0
        set tick 0
        if { $not_loop } {
            set htmlEncode 1
        }

        lappend objSplit {*}[split $object |]
        set object [lindex $objSplit 0]
        set transformFuncs [lrange $objSplit 1 end]
        if { $debug } { puts stderr "object : '$object' transform functions: '$transformFuncs'" }
        set objSplit ""
        lappend objSplit {*}[split $object "."]
        set mainObj [lindex $objSplit 0]
        set rest [lrange $objSplit 1 end]
        if { $object in $additionalAttributes } {
            set newObj "\[::SimpleTemplater::objectExists ::SimpleTemplater::object $object $not_loop\]"
        } else {
            set newObj "\[::SimpleTemplater::objectExists ::SimpleTemplater::object $mainObj $not_loop\]"
            foreach index $rest {
                if { [regexp "^\\d+$" $index] } {
                    set newObj "\[::SimpleTemplater::listExists $newObj $index $not_loop\]"
                } elseif { [regexp "^\\w+$" $index]} {
                    set newObj "\[::SimpleTemplater::dictExists $newObj $index $not_loop\]"
                }
            }
        }

        foreach _filter $transformFuncs {
            foreach { filter _args } [split $_filter :] { break }
            set filter [string trim $filter]
            set args ""
            set _args [string trim [string trim $_args] "\""]
            foreach  arg [split $_args ,] {
                lappend args [string trim $arg]
            }
            if { $debug } { puts stderr "filter : $filter args : $args" }
            if [info exists customFilter($filter)] {
                if { $args != "" } {
                    set newObj "\[$customFilter($filter) $newObj $args\]"
                } else {
                    set newObj "\[$customFilter($filter) $newObj\]"
                }
                if { !$customFilter($filter,html_encode) } {
                    set htmlEncode 0
                }
                if { $customFilter($filter,tick) } {
                    set tick 1
                }
                continue
            }
            set newObj [applyFilters $newObj $filter htmlEncode tick]
        }

        if { $htmlEncode } {
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
        foreach it [split $iter ,] {
            set it [string trim $it]
            lappend newIter ::SimpleTemplater::object($it)
        }
        if { [regexp "'(.*)'" $limiter --> newLimiter] } {
            set limiter "\[list $newLimiter\]"
        } else {
            set limiter [processObject $limiter]
        }
        return "foreach \{ $newIter \} $limiter \{"
    }

    proc processFunc_if { params } {
        variable functionOperators

        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $iter {\\\1} iter       ;# disable command executions
        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $functionOperators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> newLimiter] } {
            set limiter "\[list $newLimiter\]"
        } else {
            set limiter [processObject $limiter]
        }
        if { [regexp "'(.*)'" $iter --> newIter] } {
            set iter "\[list $newIter\]"
        } else {
            set iter [processObject $iter]
        }
        return "if \{ $iter $operator $limiter \} \{"
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

            if { [regexp "(^\\s*)$functionPattern" $line --> indent function iter operator limiter] } {
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
            } elseif { [regexp "(^\\s*)$functionPatternWithIndex" $line --> indent function iter operator limiter] } {
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
                    if { [regexp "(^\\s*){% *(else) *%}" $line --> indent object] } {
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

            if { [regexp "(^\\s*){% *continue *%}" $line --> indent] } {
                set indent "${indent}[string repeat " " [string length $lappendCmd]][string repeat " " 4]"
                bufferOut "${indent}continue"
                continue
            }

            if { [regexp "(^\\s*){% *break *%}" $line --> indent] } {
                set indent "${indent}[string repeat " " [string length $lappendCmd]][string repeat " " 4]"
                bufferOut "${indent}break"
                continue
            }

            if { [regexp "(^\\s*)$functionEndPattern" $line --> indent function_close] } {
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

    proc render { template obj } {
        variable object
        variable debug
        variable html
        variable loop
        variable loopCnt
        variable _bufferOut
        variable invalidTemplateLoopString

        set _bufferOut ""
        set html ""
        set output ""
        set loop(last_loop) 0
        set loop(0) 0
        set loopCnt 0
        set invalidTemplateLoopString ""
        # array set object [uplevel subst [list $obj]]
        catch { unset object }
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