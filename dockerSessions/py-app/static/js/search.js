document.getElementById('searchInput').addEventListener('input', function(e) {
    const searchText = e.target.value.toLowerCase();
    const todos = document.querySelectorAll('#todoList .card');
    
    todos.forEach(todo => {
        const title = todo.querySelector('.card-title').textContent.toLowerCase();
        const description = todo.querySelector('.card-text').textContent.toLowerCase();
        
        if (title.includes(searchText) || description.includes(searchText)) {
            todo.parentElement.style.display = '';
        } else {
            todo.parentElement.style.display = 'none';
        }
    });
});

function updateStatus(id, completed) {
    fetch(`/api/todos/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ completed: completed })
    }).then(response => {
        if (!response.ok) {
            throw new Error('Failed to update todo status');
        }
    }).catch(error => {
        console.error('Error:', error);
        alert('Failed to update todo status');
    });
}

function deleteTodo(id) {
    if (confirm('Are you sure you want to delete this todo?')) {
        fetch(`/api/todos/${id}`, {
            method: 'DELETE'
        }).then(response => {
            if (response.ok) {
                location.reload();
            } else {
                throw new Error('Failed to delete todo');
            }
        }).catch(error => {
            console.error('Error:', error);
            alert('Failed to delete todo');
        });
    }
} 