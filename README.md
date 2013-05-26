SimpleTemplater
===================

A simple html template parser for TCL (inspired from Python Django)
## Synopsis
Converts a HTML template like this
```html
<!-- File ex2.tpl -->
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
when provided with the view data structure as
```tcl
puts [::SimpleTemplater::render ex2.tpl {
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
into 
```html
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
## Syntax
```tcl
::SimpleTemplater::render "<template_path>" "<view>"
```
## Usage
```tcl
source <file_path>/SimpleTemplater.tcl
puts [::SimpleTemplater::render "<template_path>" {
    <[Template Object Name]>    <[TCL Variable|String]>
}]

```
### Variables
#### Simple variables
View
``` 
{
    name {John}
}
```
Template
```
<p>Hello {{name}}</p>
```
Output
```
<p>Hello {{name}}</p>
```
#### Nested data structures
View
```
{
    address {
        {
            name {John Doe}
        }
        
        {
            name {Philip Alex}
        }
    }
}
```
Template
```
{% for addr in address %}
   <p>{{loop.count}} Firstname: {{addr.name.0}}</p>
{% endfor %}
```
Output
```
<p>1 Firstname: John</p>
<p>2 Firstname: Philip</p>
```
*A list element can be accessed by providing the numeric index `{{ context_var.index }}` and a key-value dictionary styled list element can be accessed providing the key as the index `{{ context_var.key }}`*
### For loop syntax
#### Single iterator
```
{% for a in addr %}
<p>{{a}}</p>
{% endfor %}
```
#### Multi-iterator
```html
{% for a,b,c,d in addr %}
<p>{{a}} {{b}} {{c}} {{d}}</p>
{% endfor %}
```
#### Iterating simple static data
```html
{% for a in 'hello world' %}
<p>{{a}}</p> <!-- first hello second world -->
{% endfor %}
```
#### For loop count
```html
{% for a in addr %}
<p>{{ loop.count }}</p>
{% endfor %}
```
#### Supports break and continue within for loops 
*(may get discontinued as they are not usually supported in standard template parsers)*
```html
{% for a in 'hello world' %}
  {% if a == 'hello' %}
    {% continue %}
  {% endif %}
  <!-- do something -->
{% endfor %}
```
*Break can be also used in a similar fashion ```{% break %}```*

### If loop syntax
```html
{% if name.0 == name.1 %}
<p>You have an interesting name!</p>
{% endif %}
```

```html
{% if name.0 == 'John' %}
 <!-- do something -->
{% endif %}
```
#### Optional else block
```html
{% if name.0 == 'John' %}
 <!-- do something -->
{% else %}
 <!-- do something else-->
{% endif %} 
```
if loop supports the following (in < > <= >= ni == !=)
## Auto-escaping
Any variable used within the template would be auto-escaped.
Consider an email id of a person saved as 
```javascript
<script type="text/javascript">alert('XSS');</script>
```
would make your site vulnerable to XSS.
SimpleTemplater would automatically get all your variables escaped
```html
<tr><td>Email</td><td>{{ addr.personal.email }}</td></tr>
```
into
```html
<tr><td>Email</td><td>&lt;script type=&quot;text/javascript&quot;&gt;alert(&#39;XSS&#39;);&lt;/script&gt;</td></tr>
```
instead of
```html
<tr><td>Email</td><td><script type="text/javascript">alert('XSS');</script></td></tr>
```
You can explicitly mark a variable not to be escaped by applying a safe filter
```html
<tr><td>Email</td><td>{{ addr.personal.email|safe }}</td></tr>
```
