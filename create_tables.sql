DROP TABLE student;
CREATE TABLE student(
    student_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    year_of_study INT NOT NULL,
    class_id INT NOT NULL,
    project_id INT NOT NULL,
    PRIMARY KEY(student_id),
    FOREIGN KEY(class_id) REFERENCES department(class_id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES final_project(project_id) ON DELETE CASCADE
);


CREATE SEQUENCE student_sequence
  START WITH 1
  INCREMENT BY 1
  MINVALUE 1
  MAXVALUE 100
  NOCYCLE;

DROP TABLE department;
CREATE TABLE department(
    class_id INT NOT NULL,
    class_number INT NOT NULL,
    facebook_group VARCHAR(50) NOT NULL,
    wapp_group VARCHAR(50) NOT NULL,
    PRIMARY KEY(class_id)
);

DROP TABLE final_project;
CREATE TABLE final_project(
    project_id INT NOT NULL,
    project_name VARCHAR(50) NOT NULL,
    advisor VARCHAR(50) NOT NULL,
    deadline DATE NOT NULL,
    PRIMARY KEY(project_id)
);

DROP TABLE professor;
CREATE TABLE professor(
    professor_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    experience INT NOT NULL,
    PRIMARY KEY(professor_id)
);

DROP TABLE course;
CREATE TABLE course(
    course_id INT NOT NULL,
    course_name VARCHAR(50) NOT NULL,
    dificulty INT NOT NULL,
    evaluation_type VARCHAR(50) NOT NULL,
    PRIMARY KEY(course_id)
);


DROP TABLE university;
CREATE TABLE university(
    university_id INT NOT NULL,
    university_name VARCHAR(50) NOT NULL,
    field_of_study VARCHAR(50) NOT NULL,
    date_of_foundation DATE NOT NULL,
    city_id INT NOT NULL,
    PRIMARY KEY(university_id),
    FOREIGN KEY(city_id) REFERENCES city(city_id) ON DELETE CASCADE
);


DROP TABLE city;
CREATE TABLE city(
    city_id INT NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    PRIMARY KEY(city_id)
);

DROP TABLE club;
CREATE TABLE club(
    club_id INT NOT NULL,
    club_name VARCHAR(50) NOT NULL,
    club_type VARCHAR(50) NOT NULL,
    address VARCHAR(50) NOT NULL,
    PRIMARY KEY(club_id)
);

DROP TABLE student_club;
CREATE TABLE student_club(
    student_id INT NOT NULL,
    club_id INT NOT NULL,
    PRIMARY KEY(student_id, club_id),
    FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE,
    FOREIGN KEY(club_id) REFERENCES club(club_id) ON DELETE CASCADE
);

DROP TABLE student_course;
CREATE TABLE student_course(
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    PRIMARY KEY(student_id, course_id),
    FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE,
    FOREIGN KEY(course_id) REFERENCES course(course_id) ON DELETE CASCADE
);

DROP TABLE professor_course;
CREATE TABLE professor_course(
    professor_id INT NOT NULL,
    course_id INT NOT NULL,
    PRIMARY KEY(professor_id, course_id),
    FOREIGN KEY(professor_id) REFERENCES professor(professor_id) ON DELETE CASCADE,
    FOREIGN KEY(course_id) REFERENCES course(course_id) ON DELETE CASCADE
);

DROP TABLE student_university;
CREATE TABLE student_university(
    student_id INT NOT NULL,
    university_id INT NOT NULL,
    PRIMARY KEY(student_id, university_id),
    FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE,
    FOREIGN KEY(university_id) REFERENCES university(university_id) ON DELETE CASCADE
);