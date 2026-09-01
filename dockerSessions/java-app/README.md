# Todo REST API


The following is simple todo REST API using the [Spring Boot Framework](https://spring.io/projects/spring-boot). The API allow you to
add item to a to-do list, update, select and remove from the list.



##  Concepts used in this Application


* [@RestController](https://spring.io/guides/gs/rest-service/)
* [@Service](https://spring.io/guides/gs/rest-service/)
* [@Entity](https://spring.io/guides/gs/rest-service/)
* [CrudRepository](https://docs.spring.io/spring-data/data-commons/docs/1.6.1.RELEASE/reference/html/repositories.html)


## Project Setup Guide

Follow these steps to set up and run the Todo REST API on your local machine.

### Prerequisites

Ensure you have the following installed on your system:
- **Java Development Kit (JDK) 11**: The project requires JDK 11 (specified in `pom.xml`).
- **MySQL Database Server**: A running MySQL instance.
- **Maven** (Optional): A Maven installation, or you can use the bundled Maven wrapper (`./mvnw` / `mvnw.cmd`).

---

### Step 1: Database Setup

1. Log in to your MySQL server and create a database named `todo_db`:
   ```sql
   CREATE DATABASE todo_db;
   ```
2. Open [`src/main/resources/application.properties`](file:///home/manav/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/java-app/src/main/resources/application.properties) and update the database configuration if necessary:
   ```properties
   spring.datasource.url=jdbc:mysql://localhost:3306/todo_db?autoReconnect=true&
   spring.datasource.username=testUsername
   spring.datasource.password=testpasword
   ```
   *Replace `testUsername` and `testpasword` with your actual MySQL database credentials.*

---

### Step 2: Build and Run the Application

You can build and run the application using either the command line or an IDE.

#### Option A: Run via Command Line (Recommended)

1. Open a terminal in the root directory of the project.
2. Build the project using the Maven wrapper:
   ```bash
   ./mvnw clean package
   ```
3. Run the Spring Boot application:
   ```bash
   ./mvnw spring-boot:run
   ```

#### Option B: Run via IDE

1. Import the project as a Maven project into your preferred IDE (e.g., [IntelliJ IDEA](https://www.jetbrains.com/idea/) or [STS](https://spring.io/tools)).
2. Locate the main application class [`TodoApiApplication.java`](file:///home/manav/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/java-app/src/main/java/com/claykab/todo_api/TodoApiApplication.java).
3. Right-click and select **Run** or **Debug** as a Java Application.

---

### Step 3: Accessing the Application

Once started, the application will run at:
- Base URL: `http://localhost:8080/`




##  Application Demo with [Postman](https://www.postman.com/):



### Todo list :

<img src="https://github.com/claykabongok/Todo-REST-API-Spring-Boot/blob/master/readme/todolist.jpg?raw=true"  alt="Demo screen postman">


### Add  Item

<img src="https://github.com/claykabongok/Todo-REST-API-Spring-Boot/blob/master/readme/additem.jpg?raw=true"  alt="Demo screen postman">


### Update item
<img src="https://github.com/claykabongok/Todo-REST-API-Spring-Boot/blob/master/readme/updateItem.jpg?raw=true"  alt="Demo screen postman">





### Delete item
<img src="https://github.com/claykabongok/Todo-REST-API-Spring-Boot/blob/master/readme/deleteInvalidId.jpg?raw=true"  alt="Demo screen postman">



<img src="https://github.com/claykabongok/Todo-REST-API-Spring-Boot/blob/master/readme/deleteItem.jpg?raw=true"  alt="Demo screen postman">




