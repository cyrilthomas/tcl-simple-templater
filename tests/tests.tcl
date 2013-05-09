#!/usr/bin/tclsh

lappend auto_path .
source SimpleTemplater.tcl

set data {
        item_nos        "[list 10 20 30]"

        compare        "[list 10 10]"

        legacy_order_no {1000}

        rows            {
                            { hello world }
                            { good bye }
                            { sample value }
                            { blue sky }
                        }

        sample          "[list \
                            [list test00 test01] \
                            [list test10 test11] \
                            [list test12 test13] \
                            [list test14 test15] \
                        ]"
        item_no         {dance}

        address_book    {
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
                        }
}

proc execExample { html } {
    set tmpl_file "/tmp/tmpl_[pid].htm"
    set fh [open $tmpl_file w]
    puts $fh $html
    close $fh

    set ::SimpleTemplater::debug 1
    puts "Template:\n$html\nRendered:\n[::SimpleTemplater::renderHtml $tmpl_file $::data]"
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
                    <td>Main:Hello Modified - [Sample Text] </td>
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
<html>
    <body>
        <table border="1">
            {% for item_list in rows %}
                {% if item_list.0 == 'hello' %}
                    {% continue %}
                {% endif %}
                <td>{{ loop.count }}</td>
            {% endfor %}
        </table>
    </body>
</html>
}

execExample $example

set example {
<html>
    <body>
        <table border="1">
            {% for item_list in rows %}
                {% if item_list.0 == 'hello' %}
                    {% break %}
                {% endif %}
                <td>{{ loop.count }}</td>
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


set example {
<html>
{% if compare.0 == compare.1 %}
<p>they are equal</p>
{% endif %}
</html>
}

execExample $example


set example {
<html>
{% for a in rows.0 %}
<p>row:{{a}}</p>
{% endfor %}
{% for b in loop.count %}
{% endfor %}
<p>{{b}}</p>

{% for row in rows %}
    {% if row.0 == '1' %}
        <p><b>row:{{row}}</b></p>
    {% else %}
        <p>row:{{row}}</p>
    {% endif %}
{% endfor %}

</html>
}

execExample $example

set example {
<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
            {% for addr in address_book %}
                <tr><td colspan="2"><h4>{{ loop.count }}. {{ addr.name }}</h4></td></tr>
                <tr><td>Firstname</td><td>{{ addr.name.0 }}</td></tr>
                <tr><td>Lastname</td><td>{{ addr.name.1 }}</td></tr>
                <tr><td>Place</td><td>{{ addr.place }}</td></tr>
                <tr><td>Phone</td><td>{{ addr.phone }}</td></tr>
                <tr/>
            {% endfor %}
        </table>
    </body>
</html>
}

execExample $example
