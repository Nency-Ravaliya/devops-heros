# Todo List Manager

A Flask-based web application for managing todos with a clean interface and REST API support. This application provides a full-featured todo management system with database integration.

## Prerequisites

- Python 3.11 or higher
- pip (Python package installer)
- Git

## Installation Instructions

### Clone the Repository
```bash
git clone <repository-url>
cd todo-manager
```

### Setting Up Virtual Environment

#### For macOS/Linux:
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate
```

#### For Windows:
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
venv\Scripts\activate
```

### Install Dependencies

With the virtual environment activated, install the required packages:
```bash
pip install -r requirements.txt
```

## Running the Application

### First Time Setup
When running the application for the first time, the SQLite database will be automatically created.

### Starting the Server

#### For macOS/Linux:
```bash
# Make sure your virtual environment is activated
source venv/bin/activate

# Run the application
python3 app.py
```

#### For Windows:
```bash
# Make sure your virtual environment is activated
venv\Scripts\activate

# Run the application
python app.py
```

The application will be available at `http://localhost:5001`

## Application Features

- Create new todos with titles, descriptions, and due dates
- View list of todos in a card layout
- Update existing todos
- Mark todos as complete/incomplete
- Delete todos
- Search todos in real-time
- RESTful API endpoints
- Bootstrap-based responsive design

## API Endpoints

- GET `/api/todos` - List all todos
- GET `/api/todos/<id>` - Get a specific todo
- POST `/api/todos` - Create a new todo
- PUT `/api/todos/<id>` - Update a todo
- DELETE `/api/todos/<id>` - Delete a todo

## Project Structure
```
todo_manager/
├── app.py               # Main Flask application
├── models.py           # Database models
├── forms.py            # Form definitions
├── requirements.txt    # Project dependencies
├── templates/          # HTML templates
│   ├── base.html
│   ├── index.html
│   ├── add_todo.html
│   └── update_todo.html
└── static/
    └── js/
        └── search.js   # Client-side search functionality
```

## Troubleshooting

### Port Already in Use
If you get an error about port 5001 being in use:
1. Change the port number in `app.py`
2. Or kill the process using the port:
   ```bash
   # For macOS/Linux
   lsof -i :5001
   kill -9 <PID>
   
   # For Windows
   netstat -ano | findstr :5001
   taskkill /PID <PID> /F
   ```

### Virtual Environment Issues
If you have problems with the virtual environment:
1. Delete the `venv` directory
2. Re-create it following the installation steps above

### Database Issues
If you encounter database problems:
1. Delete the `todos.db` file
2. Restart the application to create a fresh database

## Deactivating Virtual Environment

When you're done working on the project:
```bash
deactivate
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details
