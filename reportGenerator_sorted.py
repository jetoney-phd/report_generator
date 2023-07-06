# -*- coding: utf-8 -*-
"""
Created on Fri May 24 09:12:54 2019

@author: Jim
"""

#Reading a CSV file from MATLAB Grader
import csv

#Use tkinter for file dialog
import tkinter as tk

from tkinter import filedialog

#A class for a record in the report file

class record:
    def __init__(self, name, problem, score, late):
        self.name = name
        self.problem = problem
        self.score = score
        self.late = late
        
            
    def get_score(self, penaltyPCT):
        if self.late == 'Y':
            return self.score * (1-penaltyPCT/100)  
        else:
            return self.score
            
#This is just to prevent an extraneous window from remaining open
root = tk.Tk()
root.withdraw()

#Get the name of the report file

file_path = filedialog.askopenfilename()
#open the report file and read the contents

with open(file_path, 'r') as csvfile:
    

    fileData = csv.reader(csvfile)


    recordList = []
    recordNum = 0
    
    #Create a list of records, only containing the useful information
    
    for nextLine in fileData:
        
        #skip the header line of the file
        if recordNum != 0:
            
            #strip out the @osu.edu from the email address

            emailString = (nextLine[0].split('@'))

            #create a record containing the student name.number, problem name, score, and late:Y/N
            
            nextRecord = record(emailString[0], nextLine[11], float(nextLine[9][0:-1]), nextLine[15])
            recordList.append(nextRecord)  
        recordNum += 1   
    
    #make a dictionary containg the students and a list of records for each
    
    studentRecords = {}
    
    #make a list of unique problem names for use when printing the output file
    problemNames = []

    for nextRecord in recordList:
        if nextRecord.name in studentRecords:
            studentRecords[nextRecord.name].append(nextRecord)
        else:
            studentRecords[nextRecord.name]=[nextRecord]    


        if not nextRecord.problem in problemNames:
            problemNames.append(nextRecord.problem)
            
sortedNames = sorted(studentRecords)

#Write a text output file with each student's scores on one Line

outfilename = file_path[0:-3]+'txt'

with open(outfilename, 'w') as outputfile:    
    
    #Write a header line to the file
    problemNamesStr = ''
    for n in range(len(problemNames)):
        problemNamesStr += problemNames[n]+' '
    print('     Student Name   ' , problemNamesStr) 
    
    outputfile.write('     Student Name   '+problemNamesStr+'\n')
    
    
    #print each student's name & scores to the console and the output file

    
    for studentName in sortedNames:

        
        #Initialize the list of this student's scores to zeros
        studentScores = [0.0 for j in range(len(problemNames))]

        #look at each record for this student and compare the problem name
        #to the list of unique problem names. If it matches, put this score
        #in the list
        
        for nextRecord in studentRecords[studentName]:
            for k in range(len(problemNames)):
                if nextRecord.problem == problemNames[k]:
                    
                    #Get score with late penalty

                    studentScores[k] = nextRecord.get_score(20)

                       
        #Write each student's name and scores to the output file
        studentScoreString = '\t'
        for nextScore in studentScores:
            studentScoreString += str(nextScore)+'    '
        print('%20s %s' % (studentName, studentScoreString))

        outputfile.write('%20s' %studentName)
        for p in range(len(