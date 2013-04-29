<html>
    <body>
        {% for state in states %}
        <h4>{{ state.name }}</h4>
        <ul>
            {% for city in state.cities %}
            <li><a href="{{ city.url }}">{{ city.name }}</a></li>
            {% endfor %}
        </ul>
        {% endfor %}
        <select id="search_lang" name="language">
            {% for language in languages %}
            <option value="{{ language.lang }}" lang="{{ language.lang }}">{{ language.desc }}</option>
            {% endfor %}
        </select>
    </body>
</html>