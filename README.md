SimpleTemplater
===================

A simple html template parser for TCL (inspired from Python Django)
## Synopsis
Converts a HTML template like this
```html
<!-- File ex2.tpl -->
<html>
  <body>
    {% for addr in address_book %}
      <p>{{loop.count}}. <b>{{addr.name}}</b></p>
      <i>[Professional]</i>
      <ul>
        <li>Firstname : {{addr.name.0}}</li>
        <li>Lastname : {{addr.name.1}}</li>
        <li>Place : {{addr.place}}</li>
        <li>Phone : {{addr.phone}}</li>
      </ul>
      {% if addr.personal %}
        <i>[Personal]</i>
        <ul>
          <li>Phone : {{addr.personal.phone}}</li>
          <li>Email : {{addr.personal.email}}</li>
        </ul>
      {% else %}
        <i>[Personal info not available]</i>
      {% endif %}
    {% endfor %}
  </body>
</html>
```
when provided with the view data structure as
```tcl
puts [::SimpleTemplater::render "/home/user/templates/ex2.tpl" {
    address_book {
        {
            name "John Doe"
            place "USA"
            phone "001"
            personal {
                phone   "001-123-12345"
                email   "john.doe@e-mail.com"
            }

        }

        {
            name "David Beck"
            place "England"
            phone "002"
            personal ""
        }

        {
            name "Sam Philip"
            place "Australia"
            phone "003"
            personal {
                phone   "007-134-4567"
                email   "sam.philip@e-mail.com"
            }
        }
    }
}]
```    
into 
```html
<html>
  <body>
      <p>1. <b>John Doe</b></p>
      <i>[Professional]</i>
      <ul>
        <li>Firstname : John</li>
        <li>Lastname : Doe</li>
        <li>Place : USA</li>
        <li>Phone : 1369664972</li>
      </ul>
        <i>[Personal]</i>
        <ul>
          <li>Phone : 001-123-12345</li>
          <li>Email : john.doe@e-mail.com</li>
        </ul>
      <p>2. <b>David Beck</b></p>
      <i>[Professional]</i>
      <ul>
        <li>Firstname : David</li>
        <li>Lastname : Beck</li>
        <li>Place : England</li>
        <li>Phone : 1469664972</li>
      </ul>
        <i>[Personal info not available]</i>
      <p>3. <b>Sam Philip</b></p>
      <i>[Professional]</i>
      <ul>
        <li>Firstname : Sam</li>
        <li>Lastname : Philip</li>
        <li>Place : Australia</li>
        <li>Phone : 1569664972</li>
      </ul>
        <i>[Personal]</i>
        <ul>
          <li>Phone : 007-134-4567</li>
          <li>Email : sam.philip@e-mail.com</li>
        </ul>
  </body>
</html>
```
## Syntax
```tcl
::SimpleTemplater::render "<template_path>" "<view>"
```
## Usage
#### Render file templates
```tcl
package require "SimpleTemplater"
puts [::SimpleTemplater::render "<template_path>" {
    <[Template Object_Name]>    <[Value]>
}]
# eg.
puts [::SimpleTemplater::render "states.tpl" [dict create \
    states [list \
        [dict create \
            name "Alabama" \
            cities [list \
                [dict create \
                    name "auburn" \
                ] \
                [dict create \
                    name "birmingham" \
                ] \
            ] \
        ] \
        [dict create \
            name "Alaska" \
            cities [list \
                [dict create \
                    name "anchorage" \
                ] \
                [dict create \
                    name "fairbanks" \
                ] \
            ] \
        ] \
    ] \
]]
```
#### Pre-compiled templates for faster executions
```tcl
package require "SimpleTemplater"
set compiled_template [::SimpleTemplater::compile "<template_path>"]
puts [$compiled_template execute {
    <[Template Object_Name]>    <[Value]>
}]
$compiled_template destroy
```
#### Render string templates
```tcl
package require "SimpleTemplater"
puts [::SimpleTemplater::renderString "<template_string>" {
    <[Template Object_Name]>    <[Value]>
}]
```
### Template language
#### Simple variables
#####`View`
``` 
{
    name {John}
}
```
#####`Template`
```
<p>Hello {{name}}</p>
```
#####`Output`
```
<p>Hello John</p>
```
#### Nested data structures
#####`View`
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
#####`Template`
```
{% for addr in address %}
   <p>{{loop.count}} Firstname: {{addr.name.0}}</p>
{% endfor %}
```
#####`Output`
```
<p>1 Firstname: John</p>
<p>2 Firstname: Philip</p>
```
*A list element can be accessed by providing the numeric index `{{ context_var.index }}` and a key-value dictionary styled list element can be accessed providing the key as the index `{{ context_var.key }}`*
### For loop syntax
#### Single iterator
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    }
}
```
#####`Template`
```html
{% for person in players %}
<p>{{person}}</p>
{% endfor %}
```
#####`Output`
```html
<p>Rafael Nadal</p>
<p>Roger Federer</p>
```
#### Multi-iterator
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    	{Novak Djokovic}
    	{Andy Murray}
    }
}
```
#####`Template`
```html
{% for person1, person2 in players %}
<p>{{person1}}, {{person2}}</p>
{% endfor %}
```
#####`Output`
```html
<p>Rafael Nadal, Roger Federer</p>
<p>Novak Djokovic, Andy Murray</p>
```
#### Iterating simple static data
#####`Template`
```html
{% for a in "hello world" %}
<p>{{a}}</p> <!-- first hello second world -->
{% endfor %}
```
#####`Output`
```html
<p>hello</p>
<p>world</p>
```
#### Inbuit loop counter
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    }
}
```
#####`Template`
```html
{% for person in players %}
<p>{{ loop.count }}. {{ person }}</p>
{% endfor %}
```
#####`Output`
```html
<p>1. Rafael Nadal</p>
<p>2. Roger Federer</p>
```
### If loop syntax
##### If loop supports the operators `(in < > <= >= ni == !=)`
#####`View`
```
{
    name {John John}
}
```
#####`Template`
```html
{% if name.0 == name.1 %}
<p>You have an interesting name!</p>
{% endif %}
```
#####`Output`
```html
<p>You have an interesting name!</p>
```

```html
{% if name.0 == "John" %}
 <!-- do something -->
{% endif %}
```
#### Optional else block
```html
{% if name.0 == "John" %}
 <!-- do something -->
{% else %}
 <!-- do something else-->
{% endif %} 
```
#### Truthiness check
```html
{% if not name %}
 <!-- do something -->
{% endif %}
<!-- OR -->
{% if !name %}
 <!-- do something -->
{% endif %}
```
#####`View`
```
{
    members {
    	{
    		active 1
    		name "John Doe"
    	}
    	{
    		active 0
    		name "Philip Alex"
    	}
    }
}
```
#####`Template`
```html
Active members:
<table>
{% for mem in members %}
	{% if mem.active %}
		<tr><td>{{ mem.name }}</td></tr>
	{% endif %}
{% endfor %}
</table>

Inactive members:
<table>
{% for mem in members %}
    {% if not mem.active %}
        <tr><td>{{ mem.name }}</td></tr>
    {% endif %}
{% endfor %}
</table>
```
#####`Output`
```html
Active members:
<table>
		<tr><td>John Doe</td></tr>
</table>
Inactive members:
<table>
		<tr><td>Philip Alex</td></tr>
</table>
```
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
You can explicitly mark a variable not to be escaped by applying a safe filter (filters mentioned below)
```html
<tr><td>Email</td><td>{{ addr.personal.email|safe }}</td></tr>
```

## Filters
### Inbuilt Filters
Usage: `{{ context_var|<filter> }}`
#### safe
`{{ context_var|safe }}` prevents your variable from being auto-escaped
#### tick
`{{ context_var|tick }}` converts all `'` in your variable to `´` after escaping

### Custom Filters
Create a new transformation procedure
```tcl
proc Modulus { context args } {
    return [expr { $context % [lindex $args 0] }]
}
```

Register the filter in your script
```tcl
::SimpleTemplater::registerFilter -filter modulus -proc Modulus
# optional -safe true|false
```
Syntax: `::SimpleTemplater::registerFilter -filter <filter_name> -safe <true|false> -proc <procedure_name>`

Apply the filter in your template
`{{ index|modulus:"10" }}`

#### Example using chained filters
View
```tcl
proc Modulus { context args } {
    if { ![regexp {^\d+$} [lindex $args 0]] } { return 0 }
	return [expr { $context % [lindex $args 0] }]
}

proc Class { context args } {
	return [lindex $args $context]
}

::SimpleTemplater::registerFilter -filter modulus -proc Modulus
::SimpleTemplater::registerFilter -filter class   -proc Class

puts [::SimpleTemplater::render "/home/user/templates/sample.tpl" {
    example {
        .... ....
    }
}]
```

Template
```
{% for ex in example %}
...
 <tr class="{{loop.count|modulus:"2"|class:"grey,white"}}">..</tr>
...
{% endfor %}
```

Output
```html
...
 <tr class="white">..</tr>
 <tr class="grey">..</tr>
 <tr class="white">..</tr>
 <tr class="grey">..</tr>
 <tr class="white">..</tr>
...
```
