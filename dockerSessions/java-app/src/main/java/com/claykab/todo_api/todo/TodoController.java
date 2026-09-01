package com.claykab.todo_api.todo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.logging.Logger;

@RestController
@RequestMapping(TodoController.BASE_URL)
public class TodoController {
    public static final String BASE_URL="api/v1/todo";
    private static final Logger logger=Logger.getLogger(TodoController.class.getName());

    @Autowired
    private TodoService todoService;


    /**
     *Use the following to add an item to the list
     * {
     *         "todoTitle": "Buy  Java book",
     *         "todoDescription": "Buy java book online",
     *         "isComplete": false,
     *         "todoDate": "20-05-2020"
     *
     *     }
     */
    /**
     * endpoint for add item
     * @param todo
     * @return
     */

    @RequestMapping(method = RequestMethod.POST, value = "/additem")
    public ResponseEntity<ResponseTodoList> AddItemTolist(@Valid @RequestBody Todo todo){
        long todoId=0;
        todoId=todoService.AddItemToThelist(todo);

        if(todoId>0){
            ResponseTodoList responseTodoList= new ResponseTodoList("Item added to todo list", HttpStatus.CREATED);
            logger.info(responseTodoList.getMessage()+". code: "+responseTodoList.getCode());
            return new ResponseEntity<ResponseTodoList>(responseTodoList,HttpStatus.CREATED);

        }else{
            ResponseTodoList responseTodoList= new ResponseTodoList("Item Not added to todo list", HttpStatus.BAD_REQUEST);
            logger.info(responseTodoList.getMessage()+". code: "+responseTodoList.getCode());
            return new ResponseEntity<ResponseTodoList>(responseTodoList,HttpStatus.BAD_REQUEST);
        }

    }


    /**
     * endpoint for add item
     * @param todo
     * @return
     */
    @RequestMapping(method = RequestMethod.PUT, value = "/updateitem/{updateTodoId}")
    public ResponseEntity<ResponseTodoList> UpdateItem(@PathVariable long updateTodoId, @Valid @RequestBody Todo todo){

        //verify if the id provided is valid before update
        boolean isTodoIdValid=todoService.isTodoItemIdValid(updateTodoId);

        if(isTodoIdValid){
            long todoId=0;
            todoId=todoService.UpdateTodoItem(updateTodoId,todo);

            if(todoId>0){
                ResponseTodoList responseTodoList= new ResponseTodoList("Item with the following title "+todo.getTodoTitle()+" updated", HttpStatus.OK);
                logger.info(responseTodoList.getMessage()+". code: "+responseTodoList.getCode());
                return new ResponseEntity<ResponseTodoList>(responseTodoList,HttpStatus.OK);

            }else{
                ResponseTodoList responseTodoList= new ResponseTodoList("Item Not updated", HttpStatus.BAD_REQUEST);
                logger.info(responseTodoList.getMessage()+". code: "+responseTodoList.getCode());
                return new ResponseEntity<ResponseTodoList>(responseTodoList,HttpStatus.BAD_REQUEST);
            }


        }else {
            ResponseTodoList responseTodoList = new ResponseTodoList("Request not successful, invalid information provided. Please try again.", HttpStatus.NOT_FOUND);

            return new ResponseEntity<ResponseTodoList>(responseTodoList, HttpStatus.NOT_FOUND);

        }






    }


    /**
     * return to-do list
     * @return
     */
    @RequestMapping(method = RequestMethod.GET, value = "/todolist")
    public List<Todo> getTodoList(){
        return todoService.getMyTodoList();

    }



    /**
     * endpoint  delete item
     * @param deleteTodoId
     * @return
     */
    @RequestMapping(method = RequestMethod.DELETE, value = "/deleteitem/{deleteTodoId}")
    public ResponseEntity<ResponseTodoList> DeleteItem(@PathVariable long deleteTodoId){

        //verify if the id provided is valid before deleting
        boolean isTodoIdValid=todoService.isTodoItemIdValid(deleteTodoId);

        if(isTodoIdValid){

            todoService.DeleteItem(deleteTodoId);


                ResponseTodoList responseTodoList= new ResponseTodoList("Item deleted", HttpStatus.OK);
                logger.info(responseTodoList.getMessage()+". code: "+responseTodoList.getCode());
                return new ResponseEntity<ResponseTodoList>(responseTodoList,HttpStatus.OK);



        }else {
            ResponseTodoList responseTodoList = new ResponseTodoList("Request not successful, invalid information provided. Please try again.", HttpStatus.NOT_FOUND);

            return new ResponseEntity<ResponseTodoList>(responseTodoList, HttpStatus.NOT_FOUND);

        }






    }






    /**
     * Return number of to-do item
     * @return
     */
    @RequestMapping(method = RequestMethod.GET, value = "/todocount")
    public long getNumberTodo(){
        return todoService.getNumberTodoItem();
    }








}
