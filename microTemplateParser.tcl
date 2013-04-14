#!/usr/bin/tclsh

# TCL micro template parser

namespace eval ::microTemplateParser {
    variable debug
    variable BufferOut
    variable functions
    variable operators
    variable block_pattern
    variable block_end_pattern
    variable lappendCmd
    variable loop
    variable loop_cnt

    set debug 0    
    set BufferOut ""
    set loop(last_loop) ""
    set loop_cnt 0
    set functions {
        for
        if
    }

    set operators {
        in
        <
        >
        <=
        >=
        ni
        ==
        !=        
    }

    set old_limiter "\\w+"
    set limiter ""
    set block_pattern       "{% *([join $functions |]) +(\\w+) +([join $operators |]) +(\\w+|'\\w+\\s*\\w*') *%}"
    set block_end_pattern   "{% *end([join $functions |]) *%}"
    set lappendCmd          "lappend ::microTemplateParser::html"

    proc dquoteEscape { str } {
        return [regsub -all {"} $str {\"}]
    }

    proc bufferOut { msg } {
        variable BufferOut
        lappend BufferOut $msg
    }

    proc processFunc_for { params } {
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]
        set operators {
            in
        }

        
        set ::microTemplateParser::loop($::microTemplateParser::loop(last_loop)) 0

        if { $operator ni $operators } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "foreach ::microTemplateParser::object($iter) \[list $new_limiter\] \{"    
        } else {
            return "foreach ::microTemplateParser::object($iter) \$::microTemplateParser::object($limiter) \{"
        }        
    }

    proc processFunc_if { params } {
        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]
        set operators {
            in
            <
            >
            <=
            >=
            ni
            ==
            !=
        }

        if { $operator ni $operators } { error "Unsupported operator '$operator' used!" }
        if { [regexp "'(.*)'" $limiter --> new_limiter] } {
            return "if \{ \$::microTemplateParser::object($iter) $operator \[list $new_limiter\] \} \{"    
        } else {
            return "if \{ \$::microTemplateParser::object($iter) $operator \$::microTemplateParser::object($limiter) \} \{"
        }
    }

    proc processLine { line } {
        variable debug
        variable lappendCmd
        variable loop

        regsub -all "{{ *loop.count *}}" $line "\$::microTemplateParser::loop(\$::microTemplateParser::loop(last_loop))" line

        if { [regexp "{{ *(\\w+) *}}" $line --> object] } {
            if { $debug } { puts "token : $object" }
            regsub -all "{{ *(\\w+) *}}" $line "\$::microTemplateParser::object(\\1)" line
        }

        if { [regexp "{{ *(\\w+)\[\[\](\\d+)\[\]\] *}}" $line --> object index] } {
            if { $debug } { puts "token: $object index: $index" }
            regsub "{{ *(\\w+)\[\[\](\\d+)\[\]\] *}}" $line "\[lindex \$::microTemplateParser::object(\\1) \\2\]" line
        }
        return "$lappendCmd \"[dquoteEscape $line]\""
    }

    proc parser { template_handle } {
        variable object
        variable debug
        variable BufferOut
        variable block_pattern
        variable block_end_pattern
        variable lappendCmd 

        set loop_enabled {
            for
        }

        set call_stack ""

        while { ![eof $template_handle] } {
            set line [gets $template_handle]

            if { [regexp "(^ *)$block_pattern" $line --> indent function iter operator limiter] } {
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
            }

            if { [regexp "(^ *)$block_end_pattern" $line --> indent function_close] } {
                set function [lindex $call_stack end]
                set call_stack [lrange $call_stack 0 end-1]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut " ${indent}\}"
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::microTemplateParser::loop(last_loop) \[incr ::microTemplateParser::loop_cnt -1\]"
                }
                continue
            }

            bufferOut [processLine $line]
        }

        return [join $BufferOut \n]
    }

    proc renderHtml { template obj } {
        variable object
        variable debug
        variable html

        set html ""
        set output ""
        catch { unset $object }
        array set object [uplevel subst "{$obj}"]
        set fh [open $template r]
        set output [parser $fh]
        close $fh
        if { $debug } { puts $output }
        eval $output
        # if { $debug } { puts $errMsg; return }
        return [join $html \n]
    }
}


if { $argv0 == [info script] } {
    set example {
<html>
    <body>
        <p style="bold">{{ item_no }}</p>
        {% if item_no == 'dance' %}
        <p><b>yes it is dance</b></p>
        {% endif %}
        <p>{{ legacy_order_no }}</p>
        <table>
            <tr>
                <td>
                    <table border="1">
                    {% for item_list in rows %}
                        <tr>
                            <td>{{ loop.count }}</td>
                            <td>Main:{{ item_list[0] }}</td>
                            <td>Main:{{ item_list[1] }}</td>
                            {% if legacy_order_no > '100' %}
                                {% for j in 'unit_test1 unit_test2' %}
                                <td>{{ loop.count }}</td>
                                <td>Inner:{{ j }}</td>
                                {% endfor %}
                            {% endif %}
                            <td>Last</td>
                            <td>{{ loop.count }}</td>
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