CREATE TABLE IF NOT EXISTS department ( 
  dept_id SERIAL PRIMARY KEY, 
name TEXT NOT NULL UNIQUE 
); 
CREATE TABLE IF NOT EXISTS employees ( 
  emp_id SERIAL PRIMARY KEY, 
  full_name TEXT NOT NULL, 
  email TEXT UNIQUE, 
  dept_id INT REFERENCES department(dept_id), 
  hired_at DATE NOT NULL DEFAULT CURRENT_DATE 
);