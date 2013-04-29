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