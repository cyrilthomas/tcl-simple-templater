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

    set function_pattern            "{% *([join $functions |]) +(\\w+) +([join $operators |]) +(\\w+|'\\w+\\s*\\w*') *%}"
    set function_pattern_with_index "{% *([join $functions_with_index |]) +(\\w+\.?\\d*) +([join $operators |]) +(\\w+\.?\\d*|'\\w+\\s*\\w*') *%}"
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
        set iter "\[lindex \$::microTemplateParser::object($iter) $iter_index\]"

        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            set limiter "\"$new_limiter\""
        } else {
            foreach { limiter limiter_index } [split $limiter] break
            if { $limiter_index == "" } { set limiter_index 0 }
            set limiter "\[lindex \$::microTemplateParser::object($limiter) $limiter_index\]"
            return "if \{ \$::microTemplateParser::object($iter) $operator \$::microTemplateParser::object($limiter) \} \{"
        }
        return "if \{ $iter $operator $limiter \} \{"
    }

    proc processLine { line } {
        variable debug
        variable loop

        regsub -all {([][$\\])} $line {\\\1} line ;# disable command executions
        regsub -all "{{ *loop.count *}}" $line "\$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))" line
        
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
                }
                bufferOut "${indent}[processFunc_${function} $params]"
                if { $function in $loop_enabled } {
                    bufferOut "[string repeat " " 4]${indent}incr ::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))"
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
                    if { [regexp "{% *(else) *%}" $line --> object] } {
                        set out "\} else \{"
                        return 1
                    }
                    return 0
                }} $line else_block]
            } {
                bufferOut "${indent}$else_block"
                continue
            }
            if { [regexp "(^ *)$function_end_pattern" $line --> indent function_close] } {
                set function [lindex $call_stack end]
                set call_stack [lrange $call_stack 0 end-1]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut " ${indent}\}"
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::microTemplateParser::loop(last_loop) \[incr ::microTemplateParser::loop_cnt -1\]"
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
        if { $debug } { puts $output }
        eval $output
        # if { $debug } { puts $errMsg; return }
        unset object
        return [join $html \n]
    }
}

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------
if { $argv0 == [info script] } {
    set example {
<html>
    <body>
        <p style="bold">{{ item_no }}</p>
        {% if item_no == 'dance' %}
        <p><b>yes it is dance</b></p>
        {% else %}
        <p><b>no it is not dance</b></p>
        {% endif %}
        <p>{{ legacy_order_no }}</p>
        <table>
            <tr>
                <td>
                    <table border="1">
                    {% for item_list in rows %}
                        <tr>
                            <td>{{ loop.count }}</td>
                            {% if item_list.0 == 'hello' %}
                            <td>Main:Special text </td>
                            {% else %}
                            <td>Main:{{ item_list.0 }} [Sample Text] </td>
                            {% endif %}
                            <td>Main:{{ item_list.1 }}</td>
                            <td>Main Full:'{{ item_list.0 }}:{{ item_list.1 }}'</td>
                            {% if legacy_order_no > '100' %}
                                {% for j in 'unit_test1 unit_test2' %}
                                <td>{{ loop.count }}</td>
                                <td>Inner:{{ j }}</td>
                                {% endfor %}
                            {% endif %}
                            <td>Last</td>
                            <td>{{ loop.count }}</td>
                            <td>"$test [info hostname]"</td>
                        </tr>
                    {% endfor %}
                    </table>
                </td>
            </tr>
        </table>
    </body>
</html>
    }


    set fh [open /tmp/template.htm w]
    puts $fh $example
    close $fh
     
    # set ::microTemplateParser::debug 1
    set html [::microTemplateParser::renderHtml "/tmp/template.htm" {
        item_nos        "[list 10 20 30]"

        legacy_order_no {1000}

        rows            {
                            {hello world}
                            {good bye}
                            {dance party}
                        }

        sample          "[list \
                            [list test00 test01] \
                            [list test10 test11] \
                            [list test12 test13] \
                            [list test14 test15] \
                        ]"
        item_no         {dance}
    }]

    # parray ::microTemplateParser::object
    puts "$html"
}