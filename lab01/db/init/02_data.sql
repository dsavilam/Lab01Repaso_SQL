INSERT INTO department (name) VALUES 
('Engineering'), 
('HR'), 
('Finance') 
ON CONFLICT (name) DO NOTHING; 

INSERT INTO employees (full_name, email, dept_id, hired_at) VALUES 
('Ana Ruiz', 'ana.ruiz@example.com', (SELECT dept_id FROM department WHERE 
name='Engineering'), '2024-02-01'), 
('Luis Perez', 'luis.perez@example.com', (SELECT dept_id FROM department WHERE 
name='HR'), '2024-03-15'), 
('Camila Gomez', 'camila.gomez@example.com', (SELECT dept_id FROM department WHERE 
name='Finance'), '2024-05-10') 
ON CONFLICT (email) DO NOTHING; 