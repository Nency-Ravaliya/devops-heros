package com.claykab.todo_api.todo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.logging.Logger;

@Service
public class TodoService {
    private static Logger logger=Logger.getLogger(TodoService.class.getName());
    @Autowired
    private TodoRepository todoRepository;

    /**
     * Retrieve to-do list
     * @return
     */
    public List<Todo> getMyTodoList(){
        List<Todo> todoList= new ArrayList<>();
        todoRepository.findAll().forEach(todoList::add);

        return  todoList;
    }


    /**
     * retrieve to-do item
     * @param todoId
     * @return
     */
    public Optional<Todo> GetTodoByID(long todoId){
        return todoRepository.findById(todoId);
    }

    /**
     * Add item to the list and return the id of the new item
     * @param todo
     * @return
     */
    public long AddItemToThelist(Todo todo){
        long todoId=0;
        todoRepository.save(todo);
        todoId=todo.getTodoId();

        return todoId;


    }


    /**
     * Delete item from the list
     * @param id
     */
    public void DeleteItem(long id){
        long itemId=0;
        todoRepository.deleteById(id);
        logger.info("Item removed from the list");
    }

    /**
     * Update to-do item
     * @param todoId
     * @param todo
     * @return
     */
    public long UpdateTodoItem(long todoId, Todo todo){

        long updateTodoId=0;
        //Retrieve the value you want to update
        try {
            Todo updatedTodo=todoRepository.findById(todoId).get();

            updatedTodo.setTodoTitle(todo.getTodoTitle());
            updatedTodo.setTodoDescription(todo.getTodoDescription());
            updatedTodo.setTodoDate(todo.getTodoDate());
            updatedTodo.setComplete(todo.isComplete());
            todoRepository.save(updatedTodo);
            updateTodoId=updatedTodo.getTodoId();
            return updateTodoId;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return updateTodoId;

    }


    /**
     * Verify if the id provided is valid
     * @param todoId
     * @return
     */
    public boolean isTodoItemIdValid(long todoId){
        return todoRepository.findById(todoId).isPresent();
    }


    /**
     * returns number of items
     * @return
     */
    public long getNumberTodoItem(){
      return todoRepository.count();
    }


}
