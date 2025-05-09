#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (or with sudo privileges)." >&2
    exit 1
fi

# Variables
COURSE_CODE="cybr371"
NUM_STUDENTS=112
ASSESSMENTS=("lab1" "lab2" "lab3" "lab4" "lab5" "assignment1" "assignment2" "midterm" "final") 
TUTORS=("alix" "annie" "david" "dedy" "krishna" "alvien")
LECTURERS=("arman" "lisa")



# Base course directory
COURSE_DIR="/courses/$COURSE_CODE"

echo "Creating directory structure..."

# Create main directories
mkdir -p "$COURSE_DIR/grades"
mkdir -p "$COURSE_DIR/assessments"
mkdir -p "$COURSE_DIR/submissions"


# Create the grades file
touch "$COURSE_DIR/grades/grades.xlsx"



# Create assessment directories and files
for assess in "${ASSESSMENTS[@]}"; do
    ASSESSMENT_DIR="$COURSE_DIR/assessments/$assess"
    mkdir -p "$ASSESSMENT_DIR"
    touch "$ASSESSMENT_DIR/questions.pdf"
    touch "$ASSESSMENT_DIR/solutions.pdf"
done



echo "Creating student users..."


# Creating Groups
groupadd cybr371-lecturers #groupadd creates a group
groupadd cybr371-tutors
groupadd cybr371

# Create users (without home directories)
for i in $(seq -w 1 $NUM_STUDENTS); do
    STUDENT="student$i"
    useradd --no-create-home --no-user-group "$STUDENT"
    usermod -aG cybr371 "$STUDENT" #add each student into the cybr371 group
done

# Create student submission directories
for i in $(seq -w 1 $NUM_STUDENTS); do
    STUDENT="student$i"
    STUDENT_SUBMISSION_DIR="$COURSE_DIR/submissions/$STUDENT"
    mkdir -p "$STUDENT_SUBMISSION_DIR"

    for assess in "${ASSESSMENTS[@]}"; do
        ASSESSMENT_SUBMISSION_DIR="$STUDENT_SUBMISSION_DIR/$assess"
        mkdir -p "$ASSESSMENT_SUBMISSION_DIR"
        touch "$ASSESSMENT_SUBMISSION_DIR/answers.docx"
        chown "$STUDENT:cybr371-tutors" "$ASSESSMENT_SUBMISSION_DIR/answers.docx" #change the ownership to the students owning their own answer files with tutors having group access
        chmod 640 "$ASSESSMENT_SUBMISSION_DIR/answers.docx" #setting owner to have full permissions while group (tutors) have only read permissions
        
    done
done

echo "Creating lecturer users..."

for lecturer in "${LECTURERS[@]}"; do
    useradd --no-create-home --no-user-group "$lecturer"
    usermod -aG cybr371-lecturers "$lecturer" #add lectuters to the cybr371-lectuters group
    usermod -aG cybr371-tutors "$lecturer" #add lectuters to the cybr371-tutors group so they can also mark work.
    usermod -aG cybr371 "$lecturer" #add lectuters to the cybr371 group

    
done

echo "Creating tutor users..."

for tutor in "${TUTORS[@]}"; do

    useradd --no-create-home --no-user-group "$tutor"
    usermod -aG cybr371-tutors "$tutor" #adds tutors into the cybr371-tutors group
    
done

echo "Initial directory structure (for layout 2) and users created."



# Setting owner for assessment dir
primary_lecturer="${LECTURERS[0]}"
chown "$primary_lecturer:cybr371-tutors" "$COURSE_DIR/grades/grades.xlsx" #change ownership of the grades file to the first lecturer in the lecturers array and group permissions to tutors
chmod 660 "$COURSE_DIR/grades/grades.xlsx" #set access control to only allowing owner and group to read and write the grades file



chown -R "$primary_lecturer:cybr371-lecturers" "$COURSE_DIR/assessments/" #the -R will apply to subdirectories and files as well






# set permissions for 
for dir in "$COURSE_DIR/assessments/"*/; do

    for file in "$dir"*; do
        chmod 770 "$file" #set the access control to only lecturers and lecturers group to making changes
        if [ "$(basename "$file")" == "solutions.pdf" ]; then   
            setfacl -m g:cybr371-tutors:r "$file" #use setfacl to allow tutors group to read solutions.pdf file
        fi
        if [ "$(basename "$file")" == "questions.pdf" ]; then
            setfacl -m g:cybr371-tutors:r "$file" #allow tutors to read questions file
            setfacl -m g:cybr371:r "$file" #allow students to read questions file
        fi
    done
done


