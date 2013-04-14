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
                                <td>Inner:{{ j }}</td>
                                {% endfor %}
                            {% endif %}
                            <td>Last</td>
                        </tr>
                    {% endfor %}
                    </table>
                </td>
            </tr>
        </table>
    </body>
</html>
```
When provided the necessary parameters as
```
::microTemplateParser::renderHtml "/tmp/template.htm" {
        item_nos        "[list 10 20 30]"

        legacy_order_no {1000}

        rows            "$rows"

        sample          "[list \
                            [list test00 test01] \
                            [list test10 test11] \
                            [list test12 test13] \
                            [list test14 test15] \
                        ]"
        item_no         {dance}
}
```    
Into this
```
<html>
    <body>
        <p style="bold">dance</p>
        <p><b>yes it is dance</b></p>
        <p>1000</p>
        <table>
            <tr>
                <td>
                    <table border="1">
                        <tr>
                            <td>1</td>
                            <td>Main:hello</td>
                            <td>Main:world</td>
                                <td>Inner:unit_test1</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                        </tr>
                        <tr>
                            <td>2</td>
                            <td>Main:good</td>
                            <td>Main:bye</td>
                                <td>Inner:unit_test1</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                        </tr>
                        <tr>
                            <td>3</td>
                            <td>Main:dance</td>
                            <td>Main:party</td>
                                <td>Inner:unit_test1</td>
                                <td>Inner:unit_test2</td>
                            <td>Last</td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
</html>
```
