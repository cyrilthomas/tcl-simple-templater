<html>
    <body>
        <ul>
        {% for gender,data in gender_list %}
            <li><b>{{ gender }}:</b>
            <ul>
                {% for item in data.list %}
                    <li>{{ item.first_name }} {{ item.last_name }}</li>
                {% endfor %}
            </ul>
            </li>
        {% endfor %}
        </ul>
    </body>
</html>