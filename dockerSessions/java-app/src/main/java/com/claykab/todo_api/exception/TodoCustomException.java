package com.claykab.todo_api.exception;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;

import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;


@Data
@EqualsAndHashCode(callSuper = false)
@AllArgsConstructor
public class TodoCustomException  {
    private HttpStatus httpStatus;
    private int code;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "dd-MM-yyyy hh:mm:ss")
    private LocalDateTime localDateTime;
    private String message;
    private String ErrorMessage;


    private TodoCustomException(){
        localDateTime=LocalDateTime.now();
    }


    TodoCustomException(HttpStatus httpStatus){
        this();
        this.httpStatus=httpStatus;
        this.code=httpStatus.value();
    }

    TodoCustomException(HttpStatus httpStatus, Throwable error){
      this();
      this.httpStatus=httpStatus;
      this.message="An error has occured";
      this.ErrorMessage=error.getLocalizedMessage();
    }

    TodoCustomException(HttpStatus httpStatus, String message, Throwable error){
        this();
        this.httpStatus=httpStatus;
        this.message=message;
        this.ErrorMessage=error.getLocalizedMessage();
    }

     public HttpStatus getHttpStatus() {
     return httpStatus;
     }

     public void setMessage(String message) {
     this.message = message;
     }

     public String getErrorMessage() {
     return ErrorMessage;
     }

     public void setErrorMessage(String errorMessage) {
     ErrorMessage = errorMessage;
     }

     public int getCode() {
     return code;
     }

}
