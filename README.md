# HMCTS Dev Test Backend
This will be the backend for the brand new HMCTS case management system. As a potential candidate we are leaving
this in your hands. Please refer to the brief for the complete list of tasks! Complete as much as you can and be
as creative as you want.

You should be able to run `./gradlew build` to start with to ensure it builds successfully. Then from that you
can run the service in IntelliJ (or your IDE of choice) or however you normally would.

There is an example endpoint provided to retrieve an example of a case. You are free to add/remove fields as you
wish.

-- 

### Case Model (Entity)

Each case includes:

- Unique ID (UUID)
- Case number (string)
- Description (string)
- Status (string)
- timestamp

### API Endpoints

This Spring Boot API manages cases. The main features include:

| Endpoint                       | Method | Description                            |
| ------------------------------ | ------ | -------------------------------------- |
| `/api/cases`                   | GET    | Retrieve all cases                     |

### Local Setup

Create a `local.properties` file in the location `hmcts-dev-test-backend/src/main/resources` following the template below. Update the file with the information for your local SQL database. Replace `your_db_username` with your username and `your_db_password` with your password. 

```
spring.datasource.url=jdbc:mysql://localhost:3306/cases

# Replace "root" with your database user, if applicable
spring.datasource.username=your_db_username

# Specify your database user's password, if applicable. If your database user doesn't have a password set, delete the line below
spring.datasource.password=your_db_password
```

### Database Setup 

1. Create the database

Make sure you are logged into your MySQL database. Create the database `cases_db` if it doesn't exist using the following command:

```sql
CREATE DATABASE cases_db;
```

It is essential that the database goes by this exact name because the application is configured to connect to it specifically.

2. Schema creation 

By default, Spring Boot with JPA/Hibernate will automatically create the `cases` table with the appropriate columns and data types based on the entity classes when the application starts.

Optional: If you want to manage the schema manually, you can use the provided `schema.sql` file with the following command within sql:

```
SOURCE /path/to/schema.sql;
```

3. Insert sample data (optional)

If required running the file `data.sql` within sql will populate example records by using this command: 

```sql
SOURCE path/to/data.sql;
```

The application can now query cases immediately.

4. Verify the setup

After setup, you can confirm the table is set up directly and has data (if populated per above) by running these SQL queries:

```
USE cases_db;
DESCRIBE cases;
SELECT * FROM cases;
```

### Run the application

Use the following command to start the application:

```
./gradlew run
```

The application will start on `http://localhost:8080`

## 🧪 Testing

In order to run the unit tests, use the `./gradlew test` command. This will execute all tests in the project.
