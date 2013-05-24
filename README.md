SimpleTemplater
===================

A simple html template parser for TCL (inspired from Python Django)

Basically converts a HTML template like this
```
<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
            {% for addr in address_book %}
                <tr><td colspan="2" style="text-align:center;"><h4><i>{{ loop.count }}# {{ addr.name }}</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>{{ addr.name.0 }}</td></tr>
                <tr><td>Lastname</td><td>{{ addr.name.1 }}</td></tr>
                <tr><td>Place</td><td>{{ addr.place }}</td></tr>
                <tr><td>Phone</td><td>{{ addr.phone }}</td></tr>
                {% if addr.personal != '' %}
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>{{ addr.personal.phone }}</td></tr>
                    <tr><td>Email</td><td>{{ addr.personal.email }}</td></tr>
                {% else %}
                    <!-- optional else block -->
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal info not available]</i></b></td></tr>
                {% endif %}
                <tr/>
            {% endfor %}
        </table>
    </body>
</html>
```
When provided the necessary parameters as
```
:puts [::SimpleTemplater::renderHtml ex2.tpl {
    address_book {
        {
            name {John Doe}
            place {USA}
            phone {001}
            personal {
                phone   "001-123-12345"
                email   "john.doe@e-mail.com"
            }

        }

        {
            name {David Beck}
            place {England}
            phone {002}
            personal {}
        }

        {
            name "Sam Philip"
            place {Australia}
            phone {003}
            personal "[list \
                phone   "007-134-4567" \
                email   "sam.philip@e-mail.com" \
            ]"
        }
    }
}]
```    
Into this
```

<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
                <tr><td colspan="2" style="text-align:center;"><h4><i>1# John Doe</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>John</td></tr>
                <tr><td>Lastname</td><td>Doe</td></tr>
                <tr><td>Place</td><td>USA</td></tr>
                <tr><td>Phone</td><td>001</td></tr>                
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>001-123-12345</td></tr>
                    <tr><td>Email</td><td>john.doe@e-mail.com</td></tr>
                <tr/>
                <tr><td colspan="2" style="text-align:center;"><h4><i>2# David Beck</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>David</td></tr>
                <tr><td>Lastname</td><td>Beck</td></tr>
                <tr><td>Place</td><td>England</td></tr>
                <tr><td>Phone</td><td>002</td></tr>                
                    <!-- optional else block -->
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal info not available]</i></b></td></tr>
                <tr/>
                <tr><td colspan="2" style="text-align:center;"><h4><i>3# Sam Philip</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>Sam</td></tr>
                <tr><td>Lastname</td><td>Philip</td></tr>
                <tr><td>Place</td><td>Australia</td></tr>
                <tr><td>Phone</td><td>003</td></tr>                
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>007-134-4567</td></tr>
                    <tr><td>Email</td><td>sam.philip@e-mail.com</td></tr>
                <tr/>
        </table>
    </body>
</html>
```
Auto-escaping
=============
Any variable used within the template would be auto-escaped
Suppose the email id of a person is saved as 
```
<script type="text/javascript">alert('XSS');</script>
```
The variable would get automatically escaped by the parser
```
<tr><td>Email</td><td>{{ addr.personal.email }}</td></tr>
```
into
```
<tr><td>Email</td><td>&lt;script type=&quot;text/javascript&quot;&gt;alert(&#39;XSS&#39;);&lt;/script&gt;</td></tr>
```
You can explicitly mark a variable not to be escaped by applying the safe filter
```
<tr><td>Email</td><td>{{ addr.personal.email|safe }}</td></tr>
```
