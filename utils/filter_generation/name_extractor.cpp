// <copyright file="name_extractor.cpp" organization="FORTH-ICS, Greece">
// Copyright (c) 2007, 2008 All Right Reserved, http://www.ics.forth.gr/
//
// All rights reserved.
// This file is solely the property of FORTH_ICS and is provided
// under a License from the Foundation of Research and Technology - Hellas
// (FORTH), Institute of Computer Science (ICS), Greece, and cannot be
// used or distributed without explicit permission from FORTH, Greece.
// If you are interested in obtaining a copy of the code please contact:
//
// Angelos Bilas (bilas@ics.forth.gr)
// FORTH-ICS
// 100 N. Plastira Av., Vassilika Vouton, Heraklion, GR-70013, Greece
// Tel: +4032810391669
// Email: bilas@ics.forth.gr
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
// KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// </copyright>
// <author>Spyridon Papageorgiou</author>
// <email>spapageo@ics.forth.gr</email>
// <date>04.06.2013</date>

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <boost/algorithm/string.hpp>

using namespace std;

vector< vector<string> > history;
ofstream output_file;

void process_file(string);
void extract_function_name();

int main(int argc, char *argv[]){
	string fname;

	if(argc != 3){
		cout << "usage: ./fname_extract <list_of_source_files> <output_file>\n";
		exit(0);
	}

	ifstream file_list(argv[1]);
	output_file.open(argv[2], ios::out | ios::app);

	//Read files from the list given in argv[1]
	if(file_list.is_open()){
		while(file_list.good()){
			//fname contains the names of the source files
			getline(file_list, fname);

			//output_file << fname << endl;

			process_file(fname);
		}
	}
}

void process_file(string fname){
	string line;
	vector<string> tokens;
	vector<string>::iterator it;

	ifstream input_file(fname.c_str());

	if(input_file.is_open()){
		while(input_file.good()){
			getline(input_file, line);
			boost::split(tokens, line, boost::is_any_of("\t "));

			for(it = tokens.begin(); it < tokens.end(); it++){
				if((*it).compare("{") == 0 && tokens.size() == 1){
					extract_function_name();
				}
			}
			history.push_back(tokens);
		}
	}

	input_file.close();
	//output_file << "\n\n";
}

void extract_function_name(){
	//cout << "\n----------------------extract_function_name called--------------!\n";
	vector<string> tmp_vector;
	string function_name;
	int tmp_vector_size, found;

	int history_size = history.size();

	for(int i=1; i <= history_size; i++){
		tmp_vector = history.at(history_size-i);
		tmp_vector_size = tmp_vector.size();

		for(int j=tmp_vector_size-1; j >=0; j--){
			found =tmp_vector.at(j).find("(");
			if(found != string::npos){
				function_name = tmp_vector.at(j).substr(0, found);

				//write to file
				output_file << function_name << endl;

				//flush the history vector
				history.erase(history.begin(), history.end());
				return;
			}
		}
	}
}
