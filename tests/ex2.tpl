<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
            {% for addr in address_book %}
                {% if loop.count|modulus:"2" == "1" %}
                <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style='text-align:center;'><b><i>[Modulus]</i></b></td></tr>
                {% else %}
                <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style='text-align:center;'><b><i>[Not Modulus]</i></b></td></tr>
                {% endif %}
                <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style="text-align:center;"><h4><i>{{ loop.count }}# {{ addr.name }}</i></h4></td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Firstname</td><td>{{ addr.name.0|bold|italic }}</td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Lastname</td><td>{{ addr.name.1 }}</td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Place</td><td>{{ addr.place }}</td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Phone</td><td>{{ addr.phone|prefix_ph }}</td></tr>
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Website</td><td>{{ addr.url|link }}</td></tr>
                {% if addr.personal != "" %}
                    <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr style="{{ loop.count|modulus:"2"|color }}"><td>Phone</td><td>{{ addr.personal.phone|phone   }}</td></tr>
                    <tr style="{{ loop.count|modulus:"2"|color }}"><td>Email</td><td>{{ addr.personal.email }}</td></tr>
                {% else %}
                    <!-- optional else block -->
                    <tr style="{{ loop.count|modulus:"2"|color }}"><td colspan="2" style='text-align:center;'><b><i>[Personal info not available]</i></b></td></tr>
                {% endif %}
                {% for v1, v2, v3, v4 in "sample1 sample2 sample3 sample5" %}
                {% endfor %}
                <tr style="{{ loop.count|modulus:"2"|color }}"><td>Notes {{loop.count}}</td><td>{{ v1|addname:"addr.name" }} {{ v2 }} {{ v3 }} {{ v4 }}</td></tr>
                <tr/>
            {% endfor %}
        </table>
        {{ sample|safe|ulist }}
        <ol>
        {% for a in splittest.data|hsplit %}
            <li>{{a}}</li>
        {% endfor %}
        </ol>
        {% for x in samplex %}
            <p>I am a non-existant tag
        {% endfor %}
    </body>
</html>
