
% Fatigue | Approach 2 | v3 - Statistics %

%% Setup

setup_check = input('Have you updated the rootDir, the allDat and the save function? [y/n] ','s');
disp(' ');

if setup_check == 'n'
    disp('Please stop, update and restart your script.');
    disp(' ');
end

rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/Try 2/data/'; % mac root
% rootDir = 'D:/Joshua/fatigue/data'; % windows root

% Processing Parameters
array_legend = ["d1 b1" "d1 b2" "d1 b3" "d1 b4" "d2 b1" "d2 b2" "d2 b3" "d2 b4"];

%% Code

%Create required arrays & load Parameters and Missing Trial Index

%Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_sample.tsv'));
%Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters.tsv'));


%% process EMG Data
run_script = 1;

fatigue_statset = []; %Set up struct to hold all Info relevant to our statistics analysis

%Display available operations
disp('Available operations:')
disp(' ')
disp('SET UP')
disp('  - Load fatigue_corr&eucdist (1)')
disp('  - Load EMG_clean (2)')
disp(' ')
disp('OPERATIONS')
disp('  - Calculate Variance (3)')
disp(' ')
disp('END SCRIPT')
disp('  - Terminate Script (666)')
disp(' ')

while run_script == 1
    
%Select Operation
action = input('What would you like me to do? ');
disp(' ')

switch action

%% Setup Actions
%Case 1: Load fatigue_corr&eucdist
    case 1
        file_name = input('What fatigue_corr&eucdist file should I load? ','s');
        
        fatigue_corr_eucdist_only = load(fullfile(rootDir,file_name));
        
        disp('--- Load fatigue_corr&eucdist: completed ---')
        disp(' ')
        
  %End of Case 1: Load fatigue_corr&eucdist
  
%Case 2: Load EMG_clean
    case 2
        file_name = input('What EMG_clean file should I load? ','s');
        
        EMG_clean = load(fullfile(rootDir,file_name));
        
        disp('--- Load EMG_clean: completed ---')
        disp(' ')
        
  %End of Case 2: Load EMG_clean
  
%% Operations

%Case 3: Calculate Variance
    case 3

        %Calculate Variance
        subj = fields(fatigue_corr_eucdist_only.stnd_len);
        for i = 1:length(subj)

            %enter each day
            days = fields(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))));
            days(strcmp('corr_array',days)) = [];
            days(strcmp('eucdist_array',days)) = [];
            days(strcmp('parameters',days)) = [];

            for j = 1:length(days)
                %enter each block
                blocks = fields(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))));
                blocks(strcmp('corr_array',blocks)) = [];
                blocks(strcmp('eucdist_array',blocks)) = [];
                blocks(strcmp('parameters',blocks)) = [];

                for k = 1:length(blocks) %Block Itteration

                  %enter corr & eucdist arrays
                  arrays = ["corr_array" "eucdist_array"];
                  arrays_2 = ["corr" "eucdist"];
                  
                    for l = 1:2
                        
                    %enter leads
                        leads = ["ADM","APB","FDI","BIC","FCR"];
                        
                        for m = 1:5
                            fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).variance.(char(arrays_2(l))).(char(leads(m))) = var(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(arrays(l))).(char(leads(m))));
                        end%End of Lead Itteration 
                    
                    end%End of corr & eucdist arrays

                end %End of Block Itteration

            end %End of Day Itteration

        end %End of Subject Itteration

        disp('--- Calculate Variance: Completed ---')
        disp(' ')

  %End of Case 3: Create nanMean Group Arrays for Correlation & Euclidean Distance

  
%Case 6
    case 6 %Add Spearman Correlation & Euclidean Distance to Blocks & Days

        subj = fields(fatigue_corr_eucdist_only.stnd_len);
        array_legend = ["d1 b1" "d1 b2" "d1 b3" "d1 b4" "d2 b1" "d2 b2" "d2 b3" "d2 b4"];

        %Create Templates for Group Arrays
        
%                TODO
        
        %Subject Itteration
        for i = 1:length(subj)

            %Create Template fo Subjects Varriance Arrays
            for j = ["corr" "eucdist"]
                for k = ["ADM","APB","FDI","BIC","FCR"]
                    subj_varr.(j).(k) = nan(30,8);
                end
            end

            %enter each day
            days = fields(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))));
            days(strcmp('corr_array',days)) = [];
            days(strcmp('eucdist_array',days)) = [];
            days(strcmp('parameters',days)) = [];
            
            %Day Itteration
            for j = 1:length(days)
                
                %Create Templates for Block Varriance Arrays
                for k = ["corr" "eucdist"]
                    for l = ["ADM","APB","FDI","BIC","FCR"]
                        day_varr.(k).(l) = nan(30,4);
                    end
                end
                
                %enter each block
                blocks = fields(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))));
                blocks(strcmp('corr_array',blocks)) = [];
                blocks(strcmp('eucdist_array',blocks)) = [];
                blocks(strcmp('parameters',blocks)) = [];
            

                %Block Itteration
                for k = 1:length(blocks)
                    
                    %code to be executed in each block

                    %Determine the position of open Block within whole
                    %Experiment and within the open Day
                    day_index = find(string([char(days(j)), ' ', char(blocks(k))]) == array_legend);
                    
                    if day_index > 4
                        block_row = day_index - 4;
                    else
                        block_row = day_index;
                    end
                    
                    %Enter every Trial of the Block and Add it to the
                    %day_var Array
                    trials = fields(fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))));
                    trials(strcmp('corr_array',trials)) = [];
                    trials(strcmp('eucdist_array',trials)) = [];
                    trials(strcmp('parameters',trials)) = [];
                    
                    for l = 1:length(trials)
                        %Load and Add Trial to day_varr and subj_varr
                        trial2add = fatigue_corr_eucdist_only.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(trials(l)));
                        trial_length = length(trial2add);
                        
                        for m = ["corr" "eucdist"]
                            for n = ["ADM","APB","FDI","BIC","FCR"]
                                day_varr.(m).(n)(1:trial_length,block_row) = trial2add;
                                subj_varr.(m).(n)(1:trial_length,day_index) = trial2add;
                            end
                        end
                        
                    end
                    
                    
                  %end of block code

                end %End of Block Itteration
                
                fatigue_statset.stnd_len.(char(subj(i))).(char(days(j))).varriance = day_varr;
            
            end %End of Day Itteration

            fatigue_statset.stnd_len.(char(subj(i))).varriance = subj_varr;
            
        end %End of Subject Itteration
      
        disp('--- Add Spearman Correlation & Euclidean Distance to Blocks & Days: Completed ---')
        disp(' ')
        
      %End of Case 6: Add Spearman Correlation & Euclidean Distance to Blocks & Days


%% End Script  
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop