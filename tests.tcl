#!/usr/bin/tclsh

lappend auto_path .
source microTemplateParser.tcl

set data {
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
}

proc execExample { html } {
    set tmpl_file "/tmp/tmpl_[pid].htm"
    set fh [open $tmpl_file w]
    puts $fh $html
    close $fh

    set ::microTemplateParser::debug 1
    puts "Template:\n$html\nRendered:\n[::microTemplateParser::renderHtml $tmpl_file $::data]"
    file delete $tmpl_file
}



set example {
<html>
    <body>
        <p style="color:green">{{ item_no }}</p>
        
        {% if item_no == 'dance' %}
        <p><b>yes it is dance</b></p>
        {% else %}
        <p><b>no it is not dance</b></p>
        {% endif %}

    </body>        
</html>        
}

execExample $example

set example {
<html>
    <body>  
        <table border="1">
            
            {% for item_list in rows %}
                <td>{{ loop.count }}</td>
                {% if item_list.0 == 'hello' %}
                    {% continue %}
                {% else %}
                    <td>Main:{{ item_list.0 }} [Sample Text] </td>
                {% endif %}
                <td>Main:{{ item_list.1 }}</td>
                <td>Main Full:'{{ item_list.0 }}:{{ item_list.1 }}'</td>                
                {% if legacy_order_no > '100' %}                
                    {% for j in item_list %}
                        <td>{{ loop.count }}</td>
                        <td>Inner:{{ j }}</td>
                    {% endfor %}
                {% endif %}
                <td>Last</td>
                <td>Current loop#{{ loop.count }}</td>            
                </tr>
            {% endfor %}
        </table>               
    </body>
</html>
}

execExample $example

set example {
<html><body><td>"$test [info hostname]"</td></body>
}

execExample $example

set example {
<html>
{% for run in '0 1 2 3' %}
    {% if loop.count == '2' %}
    {% endif %}
    <p>{{ loop.count }}</p>    
{% endfor %}
</html>
}

execExample $example