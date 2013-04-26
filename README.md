microTemplateParser
===================

A micro html template parser for TCL (inspired from Python Django)

Basically converts a HTML template like this
```
<html>
    <body>
        <p style="bold">{{ item_no }}</p>
        {% if item_no == 'dance' %}
            <p><b>yes it is dance</b></p>
        {% else %}
            <p><b>yes it is not dance!</b></p>
        {% endif %}
        <table>
            <tr>
                <td>
                    <table border="1">
                    {% for item_list in rows %}
                        <tr>
                            <td>{{ loop.count }}</td>
                            <td>Main:{{ item_list.0 }} [Sample Text] </td>
                            <td>Main:{{ item_list.1 }}</td>
                            {% for j in 'unit_test1 unit_test2' %}
                                <td>{{ loop.count }}</td>
                                <td>Inner:{{ j }}</td>
                            {% endfor %}
                            <td>Last</td>
                            <td>{{ loop.count }}</td>
                            <td>$test [info hostname]</td>
                        </tr>
                    {% endfor %}
                    </table>
                </td>
            </tr>
        </table>
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
```
When provided the necessary parameters as
```
::microTemplateParser::renderHtml "/tmp/template.htm" {
        item_nos        "[list 10 20 30]"

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
```    
Into this
```
<html>
    <body>
        <p style="bold">dance</p>
        <p><b>yes it is dance</b></p>
        <table>
            <tr>
                <td>
                    <table border="1">
                        <tr>
                            <td>1</td>
                            <td>Main:hello [Sample Text] </td>
                            <td>Main:world</td>
                                <td>1</td>
                                <td>Inner:unit_test1</td>
                                <td>2</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                            <td>1</td>
                            <td>$test [info hostname]</td>
                        </tr>
                        <tr>
                            <td>2</td>
                            <td>Main:good [Sample Text] </td>
                            <td>Main:bye</td>
                                <td>1</td>
                                <td>Inner:unit_test1</td>
                                <td>2</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                            <td>2</td>
                            <td>$test [info hostname]</td>
                        </tr>
                        <tr>
                            <td>3</td>
                            <td>Main:dance [Sample Text] </td>
                            <td>Main:party</td>
                                <td>1</td>
                                <td>Inner:unit_test1</td>
                                <td>2</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                            <td>3</td>
                            <td>$test [info hostname]</td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
        <table border="1">
                <tr><td colspan="2"><h4>1. John Doe</h4></td></tr>
                <tr><td>Firstname</td><td>John</td></tr>
                <tr><td>Lastname</td><td>Doe</td></tr>
                <tr><td>Place</td><td>USA</td></tr>
                <tr><td>Phone</td><td>001</td></tr>
                <tr/>
                <tr><td colspan="2"><h4>2. David Beck</h4></td></tr>
                <tr><td>Firstname</td><td>David</td></tr>
                <tr><td>Lastname</td><td>Beck</td></tr>
                <tr><td>Place</td><td>England</td></tr>
                <tr><td>Phone</td><td>002</td></tr>
                <tr/>
        </table>
    </body>
</html>
```
