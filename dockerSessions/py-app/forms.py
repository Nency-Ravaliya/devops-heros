from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, DateTimeField, BooleanField
from wtforms.validators import DataRequired, Length

class TodoForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(min=1, max=100)])
    description = TextAreaField('Description')
    due_date = DateTimeField('Due Date', format='%Y-%m-%dT%H:%M', validators=[])
    completed = BooleanField('Completed') 