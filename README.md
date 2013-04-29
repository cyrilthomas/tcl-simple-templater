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
                            <td>Main:{{ item_list.0 }} [Sample Text] </td>
                            <td>Main:{{ item_list.1 }}</td>
                            {% if legacy_order_no > '100' %}
                                {% for j in 'unit_test1 unit_test2' %}
                                <td>{{ loop.count }}</td>
                                <td>Inner:{{ j }}</td>
                                {% endfor %}
                            {% endif %}
                            <td>Last</td>
                            <td>{{ loop.count }}</td>
                            <td>$test [info hostname]</td>
                        </tr>
                    {% endfor %}
                    </table>
                </td>
            </tr>
        </table>
        <select id="search_lang" name="language">
            {% for language in languages %}
            <option value="{{ language.lang }}" lang="{{ language.lang }}">{{ language.desc }}</option>
            {% endfor %}
        </select>
    </body>
</html>
```
When provided the necessary parameters as
```
::microTemplateParser::renderHtml "/tmp/template.htm" {
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

        languages       {
                            {
                                lang "en"
                                desc "English"
                            }

                            {
                                lang "es"
                                desc "Spanish"
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
        <p>1000</p>
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
        <select id="search_lang" name="language">
            <option value="en" lang="en">English</option>
            <option value="es" lang="es">Spanish</option>        
        </select>
    </body>
</html>
```
