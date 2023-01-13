-- 6
-- Print all students and all students from a given class.

CREATE OR REPLACE PROCEDURE print_students_of_dept (class_num department.class_number%TYPE) IS
    TYPE dept_students IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE all_students IS VARRAY(100) OF student%ROWTYPE;
    all_student_var all_students;
    students dept_students;
    curr_class_id department.class_id%TYPE;
BEGIN
    SELECT * BULK COLLECT INTO all_student_var FROM student;

    SELECT class_id INTO curr_class_id FROM department WHERE class_number = class_num;

    SELECT * BULK COLLECT INTO students FROM student WHERE class_id = curr_class_id;
    
    FOR i IN students.FIRST..students.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(students(i).first_name);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--------------------');

    FOR i IN all_student_var.FIRST..all_student_var.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(all_student_var(i).first_name || ' ' || all_student_var(i).last_name);
    END LOOP;
END;
/

BEGIN
    print_students_of_dept(152);
    print_students_of_dept(252);
    print_students_of_dept(251);
END;
/

-- 7
-- cursor parametrizat pentru universitatile dintr-un oras dat ca parametru
-- cursor dinamic pentru profesorii cu experienta mai mare sau mai mica de 10 ani

CREATE OR REPLACE PROCEDURE ex7 (city_name_par city.city_name%TYPE, cursor_option NUMBER) IS
    CURSOR univ_from_city (city_id_par city.city_id%TYPE) IS
        SELECT * FROM university WHERE city_id = city_id_par;
    TYPE tip_cursor IS REF CURSOR RETURN professor%ROWTYPE;
    professor_info tip_cursor;
    city_id_var city.city_id%TYPE;
    val university%ROWTYPE;
    professor_val professor%ROWTYPE;
BEGIN
    SELECT city_id INTO city_id_var FROM city WHERE city_name = city_name_par;
    OPEN univ_from_city(city_id_var);
	LOOP
		FETCH univ_from_city INTO val;
		EXIT WHEN univ_from_city%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE(val.university_name);
	END LOOP;
	CLOSE univ_from_city;

    DBMS_OUTPUT.PUT_LINE('-------------------');

    IF cursor_option = 1 THEN
        -- all professors that have more than 10 years of experience
        OPEN professor_info FOR
            SELECT * FROM professor WHERE experience > 10;
    ELSIF cursor_option = 2 THEN
        OPEN professor_info FOR
            SELECT * FROM professor WHERE experience <= 10;
    END IF;
    
    LOOP
        FETCH professor_info INTO professor_val;
        EXIT WHEN professor_info%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(professor_val.first_name || ' ' || professor_val.last_name);
    END LOOP;

END;
/
    
BEGIN 
     ex7('Bucuresti', 2);
     ex7('Oxford', 1);
     ex7('Paris', 2);
    ex7('Boston', 1);
END;
/

-- 8
-- INVALID_STRING exceptie definita pentru parametru dat gresit
-- NO_DATA_STUDENT exceptie definita pentru cazul in care nu sunt studenti la o anumita materie
-- functie care primeste ca parametru numele unei materii si returneaza numarul de studenti la acea materie
-- cele 3 tabele implicate sunt: student, student_course, course

CREATE OR REPLACE FUNCTION ex8 (course_name_par course.course_name%TYPE) RETURN NUMBER IS
    TYPE students_at_course IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
    students students_at_course;
    student_val student%ROWTYPE;
    course_val course%ROWTYPE;
    student_count NUMBER(10);
    course_id_val course.course_id%TYPE := NULL;
    INVALID_STRING EXCEPTION;
    NO_DATA_STUDENT EXCEPTION;
BEGIN
    IF course_name_par IS NULL THEN
        RAISE INVALID_STRING;
    END IF;

    SELECT course_id INTO course_id_val FROM course WHERE course_name = course_name_par;

    SELECT s.* BULK COLLECT INTO students FROM student s
    JOIN student_course sc ON sc.student_id = s.student_id
    JOIN course c ON c.course_id = sc.course_id
    WHERE c.course_id = course_id_val;

    IF students.COUNT = 0 THEN
        RAISE NO_DATA_STUDENT;
    END IF;

    student_count := students.COUNT;

    FOR i IN students.FIRST..students.LAST LOOP
        student_val := students(i);
        DBMS_OUTPUT.PUT_LINE(student_val.first_name || ' ' || student_val.last_name);
    END LOOP;

    RETURN student_count;

    EXCEPTION
        WHEN INVALID_STRING THEN
            DBMS_OUTPUT.PUT_LINE('Invalid parameter');
            RETURN -1;
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Multiple courses with the same name');
            RETURN -1;
        WHEN NO_DATA_STUDENT THEN
            DBMS_OUTPUT.PUT_LINE('No students for course with id ' || course_id_val);
            RETURN -1;
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No course with name ' || course_name_par || ' found');
            RETURN -1;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Other exception');
            RETURN -1;
END;
/
    
BEGIN
    DBMS_OUTPUT.PUT_LINE(ex8(NULL));
    DBMS_OUTPUT.PUT_LINE(ex8('TW'));
    DBMS_OUTPUT.PUT_LINE(ex8('GAL'));
    DBMS_OUTPUT.PUT_LINE(ex8('PF'));
END;
/


-- 9
-- INVALID_PARAMETER exceptie definita pentru parametrii dati gresit
-- NEGATIVE_NUMBER exceptie definita pentru cazul in care numarul de ani de experienta este negativ
-- NO_DATA_FOUND_STUDENTS exceptie definita pentru cazul in care nu exista studenti cu numele dat ca parametru
-- TOO_MANY_STUDENTS exceptie definita pentru cazul in care exista mai multi studenti cu numele dat ca parametru
-- NO_DATA_COURSES exceptie definita pentru cazul in care nu exista cursuri la care sa participe studentul cu numele dat ca parametru
-- NO_DATA_PROFESSORS exceptie definita pentru cazul in care nu exista profesori care sa predea la cursurile la care participa studentul cu numele dat ca parametru
-- OTHERS exceptia generala
-- procedura care primeste ca parametrii numele unui student si numarul de ani de experienta si returneaza numele si prenumele profesorilor care au mai mult de numarul 
-- de ani de experienta dat ca parametru si care preda la cursurile la care participa studentul cu numele dat ca parametru
-- cele 5 tabele implicate sunt: professor, professor_course, course, student_course, student

CREATE OR REPLACE PROCEDURE ex9 (student_name_par student.first_name%TYPE, experience_par NUMBER) IS
    TYPE student_type IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE course_type IS TABLE OF course%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE professor_type IS TABLE OF professor%ROWTYPE INDEX BY PLS_INTEGER;
    courses_studied_by_student course_type;
    students_with_given_name student_type;
    student_id_val student.student_id%TYPE;
    student_info student%ROWTYPE;
    professor_info professor_type;
    answer professor_type;
    professor_val professor%ROWTYPE;
    INVALID_PARAMETER EXCEPTION;
    NO_DATA_FOUND_STUDENTS EXCEPTION;
    TOO_MANY_STUDENTS EXCEPTION;
    NO_DATA_COURSES EXCEPTION;
    NO_DATA_PROFESSORS EXCEPTION;
    NEGATIVE_NUMBER EXCEPTION;
BEGIN
    IF student_name_par IS NULL OR student_name_par = '' OR experience_par IS NULL THEN
        RAISE INVALID_PARAMETER;
    END IF;

    IF experience_par < 0 THEN
        RAISE NEGATIVE_NUMBER;
    END IF;

    SELECT * BULK COLLECT INTO students_with_given_name FROM student WHERE first_name = student_name_par;
    IF students_with_given_name.COUNT = 0 THEN
        RAISE NO_DATA_FOUND_STUDENTS;
    END IF;
    IF students_with_given_name.COUNT > 1 THEN
        RAISE TOO_MANY_STUDENTS;
    END IF;

    student_info := students_with_given_name(1);
    student_id_val := student_info.student_id;

    SELECT c.* BULK COLLECT INTO courses_studied_by_student FROM course c
    JOIN student_course sc ON sc.course_id = c.course_id
    JOIN student s ON s.student_id = sc.student_id
    WHERE s.student_id = student_id_val;

    IF courses_studied_by_student.COUNT = 0 THEN
        RAISE NO_DATA_COURSES;
    END IF;

    SELECT p.* BULK COLLECT INTO professor_info FROM professor p
    JOIN professor_course pc ON pc.professor_id = p.professor_id
    JOIN course c ON c.course_id = pc.course_id
    JOIN student_course sc ON sc.course_id = c.course_id
    JOIN student s ON s.student_id = sc.student_id
    WHERE s.student_id = student_id_val;

    IF professor_info.COUNT = 0 THEN
        RAISE NO_DATA_PROFESSORS;
    END IF;

    FOR i IN professor_info.FIRST..professor_info.LAST LOOP
        professor_val := professor_info(i);
        IF professor_val.experience >= experience_par THEN
            answer(i) := professor_val;
        END IF;
    END LOOP;


    FOR i IN answer.FIRST..answer.LAST LOOP
        professor_val := answer(i);
        DBMS_OUTPUT.PUT_LINE(professor_val.first_name || ' ' || professor_val.last_name);
    END LOOP;


    EXCEPTION
        WHEN INVALID_PARAMETER THEN
            DBMS_OUTPUT.PUT_LINE('Invalid parameter');
        WHEN NEGATIVE_NUMBER THEN
            DBMS_OUTPUT.PUT_LINE('Negative experience number');
        WHEN TOO_MANY_STUDENTS THEN
            DBMS_OUTPUT.PUT_LINE('Multiple students with the same name');
        WHEN NO_DATA_FOUND_STUDENTS THEN
            DBMS_OUTPUT.PUT_LINE('No students with name ' || student_name_par || ' found');
        WHEN NO_DATA_COURSES THEN
            DBMS_OUTPUT.PUT_LINE('No courses for student with id ' || student_id_val);
        WHEN NO_DATA_PROFESSORS THEN
            DBMS_OUTPUT.PUT_LINE('No professors for student with id ' || student_id_val);
        WHEN OTHERS THEN
            NULL;
--            DBMS_OUTPUT.PUT_LINE('code error ' || SQLCODE);
--            DBMS_OUTPUT.PUT_LINE('message error ' || SQLERRM);
        
END;
/

BEGIN
    ex9('Radu', 10); -- TOO_MANY_STUDENTS
    ex9('John', 10); -- NO_DATA_FOUND_STUDENTS
    ex9('Robert', -10); -- NEGATIVE_NUMBER
    ex9('', NULL); -- INVALID_PARAMETER
    ex9('Cornel', 10); -- NO_DATA_COURSES
    ex9('Gigel', 10); -- NO_DATA_PROFESSORS
    ex9('Robert', 10);
END;
/


-- 10
-- trigger de tip LMD la nivel de comanda
-- Create a trigger that will not allow any modification of the table student outside working hours (8-16) and on weekends.

CREATE OR REPLACE TRIGGER ex10 
    BEFORE INSERT OR UPDATE OR DELETE ON student
BEGIN
    IF (TO_CHAR(SYSDATE,'HH24') NOT BETWEEN 8 AND 16) OR (TO_CHAR(SYSDATE, 'DY') IN ('SAT', 'SUN')) THEN
        -- RAISE_APPLICATION_ERROR(-20000, 'You can not modify the table student outside working hours');
        IF INSERTING THEN
	   		RAISE_APPLICATION_ERROR(-20001,'Inserarea in tabel este permisa doar in timpul 
	   			programului de lucru!');
	   	ELSIF DELETING THEN
	   		RAISE_APPLICATION_ERROR(-20002,'Stergerea este permisa doar in timpul 
	   			programului de lucru!');
	   	ELSE
	   		RAISE_APPLICATION_ERROR(-20003,'Actualizarile sunt permise doar in timpul 
	   			programului de lucru!');
		END IF; 
    END IF;
END;
/

BEGIN 
    UPDATE student SET first_name = 'Robert' WHERE student_id = 1; -- change working hours to see the error
END;
/

-- 11
-- trigger de tip LMD la nivel de linie
-- Create a trigger that raises an error when the date of foundation of a university is modified.

CREATE OR REPLACE TRIGGER ex11
    BEFORE UPDATE OF DATE_OF_FOUNDATION ON university
    FOR EACH ROW WHEN (NEW.DATE_OF_FOUNDATION <> OLD.DATE_OF_FOUNDATION)
BEGIN
    RAISE_APPLICATION_ERROR(-20000, 'You can not modify the date of foundation');
END;
/

BEGIN
    UPDATE university SET date_of_foundation = TO_DATE('01-01-2000', 'DD-MM-YYYY') WHERE university_id < 5;
END;
/


-- 12
-- trigger de tip LDD
-- Create a trigger that records user actions on the database in a table.

CREATE TABLE audit_user (
    nume_bd VARCHAR2(50),
	user_logat VARCHAR2(30),
	eveniment VARCHAR2(20),
	tip_obiect_referit VARCHAR2(30),
	nume_obiect_referit VARCHAR2(30),
	eveniment_data TIMESTAMP(3)
);

CREATE OR REPLACE TRIGGER ex12
    AFTER CREATE OR DROP OR ALTER ON SCHEMA
BEGIN
    INSERT INTO audit_user VALUES (SYS.DATABASE_NAME, SYS.LOGIN_USER, SYS.SYSEVENT, SYS.DICTIONARY_OBJ_TYPE,
		SYS.DICTIONARY_OBJ_NAME, SYSTIMESTAMP(3));
END;
/

CREATE TABLE ex12_table (id NUMBER(10));
ALTER TABLE ex12_table ADD (val NUMBER(2));
INSERT INTO ex12_table VALUES(1,2);
CREATE INDEX ind_tabel ON ex12_table(id);

SELECT * FROM audit_user;

-- 13
-- Create a package that contains all the procedures and functions from the previous exercises.
CREATE OR REPLACE PACKAGE ex13 AS 
    PROCEDURE ex6 (class_num department.class_number%TYPE); -- ex6
    PROCEDURE ex7 (city_name_par city.city_name%TYPE, cursor_option NUMBER); -- ex7
    FUNCTION ex8 (course_name_par course.course_name%TYPE) RETURN NUMBER; -- ex8
    PROCEDURE ex9 (student_name_par student.first_name%TYPE, experience_par NUMBER); -- ex9
END ex13;
/

CREATE OR REPLACE PACKAGE BODY ex13 AS
    -- ex6
    PROCEDURE ex6 (class_num department.class_number%TYPE) AS
        TYPE dept_students IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
        TYPE all_students IS VARRAY(100) OF student%ROWTYPE;
        all_student_var all_students;
        students dept_students;
        curr_class_id department.class_id%TYPE;
    BEGIN
        SELECT * BULK COLLECT INTO all_student_var FROM student;

        SELECT class_id INTO curr_class_id FROM department WHERE class_number = class_num;

        SELECT * BULK COLLECT INTO students FROM student WHERE class_id = curr_class_id;
        
        FOR i IN students.FIRST..students.LAST LOOP
            DBMS_OUTPUT.PUT_LINE(students(i).first_name);
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('--------------------');

        FOR i IN all_student_var.FIRST..all_student_var.LAST LOOP
            DBMS_OUTPUT.PUT_LINE(all_student_var(i).first_name || ' ' || all_student_var(i).last_name);
        END LOOP;
    END;
    
    -- ex7
    PROCEDURE ex7 (city_name_par city.city_name%TYPE, cursor_option NUMBER) AS
        CURSOR univ_from_city (city_id_par city.city_id%TYPE) IS
        SELECT * FROM university WHERE city_id = city_id_par;
        TYPE tip_cursor IS REF CURSOR RETURN professor%ROWTYPE;
        professor_info tip_cursor;
        city_id_var city.city_id%TYPE;
        val university%ROWTYPE;
        professor_val professor%ROWTYPE;
    BEGIN
        SELECT city_id INTO city_id_var FROM city WHERE city_name = city_name_par;

        OPEN univ_from_city(city_id_var);
        LOOP
            FETCH univ_from_city INTO val;
            EXIT WHEN univ_from_city%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(val.university_name);
        END LOOP;
        CLOSE univ_from_city;

        DBMS_OUTPUT.PUT_LINE('-------------------');

        IF cursor_option = 1 THEN
            -- all professors that have more than 10 years of experience
            OPEN professor_info FOR
                SELECT * FROM professor WHERE experience > 10;
        ELSIF cursor_option = 2 THEN
            OPEN professor_info FOR
                SELECT * FROM professor WHERE experience <= 10;
        END IF;
        
        LOOP
            FETCH professor_info INTO professor_val;
            EXIT WHEN professor_info%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(professor_val.first_name || ' ' || professor_val.last_name);
        END LOOP;
    END;
    
     -- ex8
    FUNCTION ex8 (course_name_par course.course_name%TYPE) RETURN NUMBER AS
        TYPE students_at_course IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
        students students_at_course;
        student_val student%ROWTYPE;
        course_val course%ROWTYPE;
        student_count NUMBER(10);
        course_id_val course.course_id%TYPE := NULL;
        INVALID_STRING EXCEPTION;
        NO_DATA_STUDENT EXCEPTION;
    BEGIN
        IF course_name_par IS NULL THEN
            RAISE INVALID_STRING;
        END IF;

        SELECT course_id INTO course_id_val FROM course WHERE course_name = course_name_par;

        SELECT s.* BULK COLLECT INTO students FROM student s
        JOIN student_course sc ON sc.student_id = s.student_id
        JOIN course c ON c.course_id = sc.course_id
        WHERE c.course_id = course_id_val;

        IF students.COUNT = 0 THEN
            RAISE NO_DATA_STUDENT;
        END IF;

        student_count := students.COUNT;

        FOR i IN students.FIRST..students.LAST LOOP
            student_val := students(i);
            DBMS_OUTPUT.PUT_LINE(student_val.first_name || ' ' || student_val.last_name);
        END LOOP;

        RETURN student_count;

        EXCEPTION
            WHEN INVALID_STRING THEN
                DBMS_OUTPUT.PUT_LINE('Invalid parameter');
                RETURN -1;
            WHEN TOO_MANY_ROWS THEN
                DBMS_OUTPUT.PUT_LINE('Multiple courses with the same name');
                RETURN -1;
            WHEN NO_DATA_STUDENT THEN
                DBMS_OUTPUT.PUT_LINE('No students for course with id ' || course_id_val);
                RETURN -1;
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No course with name ' || course_name_par || ' found');
                RETURN -1;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Other exception');
                RETURN -1;
    END;
    -- ex9
    PROCEDURE ex9 (student_name_par student.first_name%TYPE, experience_par NUMBER) AS 
        TYPE student_type IS TABLE OF student%ROWTYPE INDEX BY PLS_INTEGER;
        TYPE course_type IS TABLE OF course%ROWTYPE INDEX BY PLS_INTEGER;
        TYPE professor_type IS TABLE OF professor%ROWTYPE INDEX BY PLS_INTEGER;
        courses_studied_by_student course_type;
        students_with_given_name student_type;
        student_id_val student.student_id%TYPE;
        student_info student%ROWTYPE;
        professor_info professor_type;
        answer professor_type;
        professor_val professor%ROWTYPE;
        INVALID_PARAMETER EXCEPTION;
        NO_DATA_FOUND_STUDENTS EXCEPTION;
        TOO_MANY_STUDENTS EXCEPTION;
        NO_DATA_COURSES EXCEPTION;
        NO_DATA_PROFESSORS EXCEPTION;
        NEGATIVE_NUMBER EXCEPTION;
    BEGIN
        IF student_name_par IS NULL OR student_name_par = '' OR experience_par IS NULL THEN
            RAISE INVALID_PARAMETER;
        END IF;

        IF experience_par < 0 THEN
            RAISE NEGATIVE_NUMBER;
        END IF;

        SELECT * BULK COLLECT INTO students_with_given_name FROM student WHERE first_name = student_name_par;
        IF students_with_given_name.COUNT = 0 THEN
            RAISE NO_DATA_FOUND_STUDENTS;
        END IF;
        IF students_with_given_name.COUNT > 1 THEN
            RAISE TOO_MANY_STUDENTS;
        END IF;

        student_info := students_with_given_name(1);
        student_id_val := student_info.student_id;

        SELECT c.* BULK COLLECT INTO courses_studied_by_student FROM course c
        JOIN student_course sc ON sc.course_id = c.course_id
        JOIN student s ON s.student_id = sc.student_id
        WHERE s.student_id = student_id_val;

        IF courses_studied_by_student.COUNT = 0 THEN
            RAISE NO_DATA_COURSES;
        END IF;

        SELECT p.* BULK COLLECT INTO professor_info FROM professor p
        JOIN professor_course pc ON pc.professor_id = p.professor_id
        JOIN course c ON c.course_id = pc.course_id
        JOIN student_course sc ON sc.course_id = c.course_id
        JOIN student s ON s.student_id = sc.student_id
        WHERE s.student_id = student_id_val;

        IF professor_info.COUNT = 0 THEN
            RAISE NO_DATA_PROFESSORS;
        END IF;

        FOR i IN professor_info.FIRST..professor_info.LAST LOOP
            professor_val := professor_info(i);
            IF professor_val.experience >= experience_par THEN
                answer(i) := professor_val;
            END IF;
        END LOOP;


        FOR i IN answer.FIRST..answer.LAST LOOP
            professor_val := answer(i);
            DBMS_OUTPUT.PUT_LINE(professor_val.first_name || ' ' || professor_val.last_name);
        END LOOP;


        EXCEPTION
            WHEN INVALID_PARAMETER THEN
                DBMS_OUTPUT.PUT_LINE('Invalid parameter');
            WHEN NEGATIVE_NUMBER THEN
                DBMS_OUTPUT.PUT_LINE('Negative experience number');
            WHEN TOO_MANY_STUDENTS THEN
                DBMS_OUTPUT.PUT_LINE('Multiple students with the same name');
            WHEN NO_DATA_FOUND_STUDENTS THEN
                DBMS_OUTPUT.PUT_LINE('No students with name ' || student_name_par || ' found');
            WHEN NO_DATA_COURSES THEN
                DBMS_OUTPUT.PUT_LINE('No courses for student with id ' || student_id_val);
            WHEN NO_DATA_PROFESSORS THEN
                DBMS_OUTPUT.PUT_LINE('No professors for student with id ' || student_id_val);
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('code error ' || SQLCODE);
                DBMS_OUTPUT.PUT_LINE('message error ' || SQLERRM);
            
    END;

    
END ex13;
/

-- test package ex13
BEGIN
--     ex13.ex6(251);
--     ex13.ex7('Bucuresti', 2);
--    DBMS_OUTPUT.PUT_LINE(ex13.ex8(NULL));
--    DBMS_OUTPUT.PUT_LINE(ex13.ex8('TW'));
--    DBMS_OUTPUT.PUT_LINE(ex13.ex8('PAO'));
--    DBMS_OUTPUT.PUT_LINE(ex13.ex8('PF'));
--    ex13.ex9('Radu', 10); -- TOO_MANY_STUDENTS
--    ex13.ex9('John', 10); -- NO_DATA_FOUND_STUDENTS
--    ex13.ex9('Robert', -10); -- NEGATIVE_NUMBER
--    ex13.ex9('', NULL); -- INVALID_PARAMETER
--    ex13.ex9('Cornel', 10); -- NO_DATA_COURSES
--    ex13.ex9('Gigel', 10); -- NO_DATA_PROFESSORS
--    ex13.ex9('Robert', 10);
END;
/

CREATE OR REPLACE PACKAGE ex14 AS
    TYPE club_type IS TABLE OF club%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE final_project_type IS TABLE OF final_project%ROWTYPE;
    TYPE student_type IS VARRAY(100) OF student%ROWTYPE;
    FUNCTION get_student_clubs (student_id_par student.student_id%TYPE) RETURN club_type;
    PROCEDURE print_student_clubs(student_clubs club_type);
    FUNCTION get_final_projects(year_par NUMBER) RETURN final_project_type;
    PROCEDURE print_final_projects(final_projects final_project_type);
    PROCEDURE update_student_new_year(student_id_par student.student_id%TYPE);
    PROCEDURE print_graduated_students;
END ex14;
/

CREATE OR REPLACE PACKAGE BODY ex14 AS
    FUNCTION get_student_clubs(student_id_par student.student_id%TYPE) RETURN club_type IS
        answer club_type;
    BEGIN
        SELECT c.* BULK COLLECT INTO answer FROM student s
        JOIN student_club sc ON sc.student_id = s.student_id
        JOIN club c ON c.club_id = sc.club_id
        WHERE s.student_id = student_id_par;

        RETURN answer;

        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                RETURN club_type();
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('code error ' || SQLCODE);
                DBMS_OUTPUT.PUT_LINE('message error ' || SQLERRM);
                RETURN club_type();
    END;

    PROCEDURE print_student_clubs(student_clubs club_type) IS
        club_info club%ROWTYPE;
    BEGIN
        FOR i IN student_clubs.FIRST..student_clubs.LAST LOOP
            club_info := student_clubs(i);
            DBMS_OUTPUT.PUT_LINE(i || '.');
            DBMS_OUTPUT.PUT_LINE('club name: ' || club_info.club_name);
            DBMS_OUTPUT.PUT_LINE('club type: ' || club_info.club_type);
            DBMS_OUTPUT.PUT_LINE('club address: ' || club_info.address);
        END LOOP;
    END;

    FUNCTION get_final_projects(year_par NUMBER) RETURN final_project_type IS
        answer final_project_type;
        INVALID_PARAMETER EXCEPTION;
    BEGIN
        IF year_par IS NULL OR year_par < 2000 THEN
            RAISE INVALID_PARAMETER;
        END IF;

        SELECT fp.* BULK COLLECT INTO answer FROM final_project fp
        WHERE EXTRACT(YEAR FROM fp.deadline) = year_par;

        RETURN answer;

        EXCEPTION 
            WHEN INVALID_PARAMETER THEN
                DBMS_OUTPUT.PUT_LINE('Invalid parameter');
                RETURN final_project_type();
            WHEN NO_DATA_FOUND THEN
                RETURN final_project_type();
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('code error ' || SQLCODE);
                DBMS_OUTPUT.PUT_LINE('message error ' || SQLERRM);
                RETURN final_project_type();
    END;
    PROCEDURE print_final_projects(final_projects final_project_type) IS
        final_project_info final_project%ROWTYPE;
        student_for_project student_type;
        student_info student%ROWTYPE;
        NO_DATA_STUDENT EXCEPTION;
    BEGIN
        student_for_project := student_type();
        FOR i IN final_projects.FIRST..final_projects.LAST LOOP
            student_for_project.extend();
            SELECT * INTO student_info FROM student s WHERE s.project_id = final_projects(i).project_id;
            IF SQL%NOTFOUND THEN
                RAISE NO_DATA_STUDENT;
            END IF;
            student_for_project(student_for_project.COUNT) := student_info;
        END LOOP;

        FOR i IN final_projects.FIRST..final_projects.LAST LOOP
            final_project_info := final_projects(i);
            DBMS_OUTPUT.PUT_LINE(i || '.');
            DBMS_OUTPUT.PUT_LINE('Student name: ' || student_for_project(i).first_name || ' ' || student_for_project(i).last_name);
            DBMS_OUTPUT.PUT_LINE('Project name: ' || final_project_info.project_name);
            DBMS_OUTPUT.PUT_LINE('Deadline: ' || final_project_info.deadline);
        END LOOP;

        EXCEPTION
            WHEN NO_DATA_STUDENT THEN
                DBMS_OUTPUT.PUT_LINE('No student for project');
                RETURN;
            WHEN NO_DATA_FOUND THEN
                RETURN;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('code error ' || SQLCODE);
                DBMS_OUTPUT.PUT_LINE('message error ' || SQLERRM);
                RETURN;
    END;
    PROCEDURE update_student_new_year(student_id_par student.student_id%TYPE) IS
        student_info student%ROWTYPE;
    BEGIN
        UPDATE student SET year_of_study = year_of_study + 1 WHERE student_id = student_id_par;
        SELECT * INTO student_info FROM student WHERE student_id = student_id_par;
        IF student_info.year_of_study > 4 THEN
            -- DELETE FROM student WHERE student_id = student_id_par;
            DBMS_OUTPUT.PUT_LINE('Student ' || student_info.first_name || ' ' || student_info.last_name || ' graduated');
        END IF;
    END;

    PROCEDURE print_graduated_students IS
        student_info student%ROWTYPE;
        CURSOR c IS SELECT * FROM student WHERE year_of_study > 4;
    BEGIN
        FOR student_info IN c LOOP
            DBMS_OUTPUT.PUT_LINE('Student ' || student_info.first_name || ' ' || student_info.last_name || ' graduated');
        END LOOP;
    END;

END ex14;
/

BEGIN
     ex14.print_student_clubs(ex14.get_student_clubs(2));
     ex14.print_final_projects(ex14.get_final_projects(2018)); 
     -- ex14.update_student_new_year(10); --disable trigger to run this command
     ex14.print_graduated_students();
END;
/
