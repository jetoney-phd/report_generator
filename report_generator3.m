%{

Generate a simple text score report for MATLAB Grader exercises using downloaded
Excel score report.

Inputs:
   points: numerical vector containing point value of each problem; if not
   provided, score is reported as % for each problem

   penalty: late penalty in % (defaults to 20)

   list_of_names: string array containing names of students to include in
   report; defaults to all students

Output: text file with same base file name as Excel input file and
extension .txt

Examples:
    %Generate report for all students with standard late penalty, report
    result as % for each problem
    >>report_generator3()

    %Generate report for all students with standard late penalty, report
    point totals
    >>report_generator3([3,3,4])

    %Generate report for all students with no penalty, report point totals
    >>report_generator3([3,3,4], 0)

    %Generate report for selected students with standard late penalty, report point totals
    >>report_generator3([3,3,4], [], ["Smith", "Jones", "Toney"])
%}

function studentStruct = report_generator3(points, penalty, names)

%If late penalty is not supplied, use the default of 20 %

if nargin < 2 || isempty(penalty)
    penalty = 20;
end

    
%Open the report file from MATLAB Grader

[filename , filepath] = uigetfile('*.xls*','Select report file');
%[numData, textData] = xlsread([filepath,filename]);
textData = readcell([filepath, filename]);
%Create a struct array containing student name, problem name, and score for each
%entry

recordStruct = struct();
problemNames = [];

for recordNum = 1:size(textData,1)-1
    
    nameField = textData{recordNum+1,1};
    
    %find the space between first and last names and reverse them
     %Reverse name and pad with blanks to make it 20 chars, left-justified
     atIndex = find(' ' == nameField);
     num_blanks = 20-length(nameField);

    recordStruct(recordNum).Name = string([nameField(atIndex:end), ', ',nameField(1:atIndex-1), char(' '*ones(1,num_blanks))]);

     recordStruct(recordNum).Problem = string(textData{recordNum+1,13});
    
    %if this problem is not already in the list of problem names, add it
    if sum(strcmp(recordStruct(recordNum).Problem, problemNames)) == 0
        problemNames = [problemNames recordStruct(recordNum).Problem];
    end
    
    recordStruct(recordNum).Late = textData{recordNum+1,17};
    
    %strip off the % from the end of the score
    recordStruct(recordNum).Score = str2num(textData{recordNum+1, 11}(1:end-1));
end

%Build a list of unique student names

studentNames =[];
recordNames = [recordStruct(:).Name];

numStudents = 0;

%build a struct array with one element per student, containing all scores
for recordNum = 1:length(recordStruct)
    nextName = recordStruct(recordNum).Name;
    nextProblem = recordStruct(recordNum).Problem;
    
    if nargin == 0  || isempty(points) %If no array of weights was provided, report the percentage
        nextScore = recordStruct(recordNum).Score;
    else
        problemIndex = find(recordStruct(recordNum).Problem==problemNames);
        nextScore = recordStruct(recordNum).Score*points(problemIndex)/100;
    end
    
    nextLate = recordStruct(recordNum).Late;
    
    %If this name is not already in the list of names add it & make a new
    %struct entry
    if sum(strcmp(nextName, studentNames)) == 0
        studentNames = [studentNames nextName];
        nextStudent = struct('Name', nextName, 'Problem', nextProblem, 'Score', nextScore, 'Late', nextLate);
        studentStruct(numStudents+1) =  nextStudent;
        numStudents = numStudents+1;
    else
        %if there's already a struct for this student, add the score for
        %this problem
        thisStudent = find(strcmp(nextName, studentNames),1,'first');
        studentStruct(thisStudent).Problem = [studentStruct(thisStudent).Problem, nextProblem];
        
            studentStruct(thisStudent).Score = [studentStruct(thisStudent).Score, nextScore];
            
        studentStruct(thisStudent).Late = [studentStruct(thisStudent).Late nextLate];
    end
end

%make sure the first letter of each name is upper case
for k = 1:length(studentStruct)

    name_char = char (studentStruct(k).Name);
    first_letter = find(name_char>=65 & name_char<= 122, 1, 'first');
    name_char(first_letter) = upper(name_char(first_letter));
    studentStruct(k).Name = string(name_char);
end

studentStruct = sort_struct(studentStruct, 'Name');
%Output a table
outFileName = [filepath,filename(1:end-5), '.txt'];
outputFile = fopen(outFileName, 'w');

fprintf(outputFile,'\n%s\n\n',['     Score Report for ',filename(1:end-5)]);
fprintf(outputFile,'%s', '      Name            ');

for prob = 1:length(problemNames)
    fprintf(outputFile,'%13s', problemNames(prob));
end

if nargin ~= 0 && ~isempty(points)
   fprintf(outputFile,'      Total\n');
else
    fprintf(outputFile,'\n');
end

%if no list of students provided, output all students; otherwise, only
%include those in the list
for studentN = 1:length(studentStruct)
    if nargin<3 || name_in_list (studentStruct(studentN).Name, names)
    fprintf(outputFile,'%s ', studentStruct(studentN).Name);
    for prob = 1:length(problemNames)
        
        problemIndex = find(studentStruct(studentN).Problem==problemNames(prob));
        if ~isempty(problemIndex)
            if strcmp(studentStruct(studentN).Late(problemIndex), 'N')
                
                fprintf(outputFile,'%10.1f   ', studentStruct(studentN).Score(problemIndex));
            else
                studentStruct(studentN).Score(problemIndex) = studentStruct(studentN).Score(problemIndex)*(1-penalty/100)
                fprintf(outputFile,'%10.1f   ', studentStruct(studentN).Score(problemIndex));
            end
        else
            fprintf(outputFile,'%10i   ', 0);            
        end
    end
    
    %If points were given as an argument, print the total
    if nargin ~= 0 && ~isempty(points)
        fprintf(outputFile, '%10.1f', sum(studentStruct(studentN).Score));
        
        
        if sum(studentStruct(studentN).Score) ~= sum(points)
            fprintf(outputFile, ' ******')
        end
        
    end
    fprintf(outputFile, '\n');
    end
end
fclose(outputFile);
type (outFileName)

end

function [ sortedStruct ] = sort_struct( inputStruct, sortField)

%This function sorts a struct array based on the specified field
%The field name must be a char array, for example, 'Name' or 'Value'

%use merge sort - base case is one item in list

if length(inputStruct) == 1
    sortedStruct = inputStruct;
else
    %divide into two parts and call this function recursively
    
    divider = floor(length(inputStruct)/2);
    list1 = inputStruct(1:divider);
    list2 = inputStruct(divider+1:end);
    
    sortedList1 = sort_struct(list1, sortField);
    sortedList2 = sort_struct(list2,sortField);
    
    sortedStruct = [];
    
    %Merge the two sorted lists
    %As each element is added to the merged list, delete it from the
    %sub-list
    while ~isempty(sortedList1) && ~isempty(sortedList2)
        
        if sortedList1(1).(sortField) < sortedList2(1).(sortField)
            sortedStruct = [sortedStruct sortedList1(1)];
            sortedList1(1) = [];
        else
            sortedStruct = [sortedStruct sortedList2(1)];
            sortedList2(1) = [];
        end
    end
    
    %When one of the sublists is empty, the other one can be added to the
    %merged list as is
    
    if isempty(sortedList1)
        sortedStruct = [sortedStruct sortedList2];
    else
        sortedStruct = [sortedStruct sortedList1];
    end
    
    


end
end

function found_it = name_in_list(student_name, list_of_names)

found_it = false;

for k = 1:length(list_of_names)
    
    if contains(student_name,list_of_names(k))
       found_it = true;
    end
end
end

