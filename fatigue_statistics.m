
% Fatigue | Approach 2 | v3 - Statistics %

%% Setup
run_script = 1;
disp(' ');
setup_check = input('Have you updated the rootDir, the allDat and the save function? [y/n] ','s');
disp(' ');

if setup_check == 'n'
    disp('Please update and restart your script.');
    disp(' ');
    run_script = 0;
end

rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/Try 2/data/'; % mac root
% rootDir = 'D:/Joshua/fatigue/data'; % windows root

output = [];

%% Code

%Display available operations
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp('Available operations:')
disp(' ')
disp('SET UP')
disp('  1  load DB_correlation oder DB_euclidean')
disp('  2  load Parameters')
disp('  3  combine DB & Parameters')
disp(' ')
disp('OUTPUT')
disp(' rmANOVA')
disp('  4  Correlation / Euclidean Distance - no Parameters')
disp('  5  Variance of Correlation / Euclidean Distance - no Parameters')
disp(' ')
disp('* 666 to terminate script *')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp(' ')


%% process EMG Data

while run_script == 1
    
%Select Operation
action = input('• What would you like me to do? ');

switch action
    
%% Setup
%Case 1: Load DB_correlation or DB_euclidean
    case 1
        
        [file, path] = uigetfile('*.*');
        DB = readtable(fullfile(path,file));
        
        varr_type_mandatory = 1;
        while varr_type_mandatory == 1
            
            varr_type = input('Did you load correlation or euclidean data? (c/e) ','s');
            varr_type_mandatory = 0;
            
            if not(varr_type == 'c' | varr_type == 'e')
                disp('incorrect varr_type')
                disp('varr_type has to be specified as "c" oder "e" to proceed')
                varr_type_mandatory = 1;
            end
            
            disp(' ')
        
        end
        
        %Build unique identifiers
        for i = 1:height(DB)
            DB.ID_block(i) = strcat(string(DB.Subject(i)), num2str(DB.Day(i)), num2str(DB.Block(i)));
            DB.ID_day(i) = strcat(string(DB.Subject(i)), num2str(DB.Day(i)));
        end
        
        disp('   -> DB loaded & varr_type set')
        disp(' ')

  
%Case 2: Load Parameters
    case 2
        
        [file, path] = uigetfile('*.*');
        p = readtable(fullfile(path,file));
        
        %Build unique identifiers
        for i = 1:height(p)
            p.ID_block(i) = strcat(string(p.ID(i)), num2str(p.day(i)), num2str(p.BN(i)));
            p.ID_day(i) = strcat(string(p.ID(i)), num2str(p.BN(i)));
        end
        
        disp('   -> parameters loaded')
        disp(' ')
        
%Case 3: Combine DB & Parameters
    case 3
        datatypes = varfun(@class,p,'OutputFormat','cell');
        p2add = table('Size',[1 width(p)],'VariableTypes',datatypes);
        p2add.Properties.VariableNames = p.Properties.VariableNames;
        
        for i = 1:height(DB)
            p2add(i,:) = p(p.ID_block == DB.ID_block(i),:);
        end

        DB = [DB p2add(:,[1:58])];
        D = table2struct(DB,'ToScalar',true);
        
        disp('   -> DB & Parameters combined')
        disp(' ')
  
%% Output

% rmANOVA
    case 4 %output for rmANOVA of Mean
        output.mean = tapply(...
            D,...
            {'label','Subject'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 1 & D.Block == 1 , 'name','ADM_Corr_d1b1'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 1 & D.Block == 2 , 'name','ADM_Corr_d1b2'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 1 & D.Block == 3 , 'name','ADM_Corr_d1b3'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 1 & D.Block == 4 , 'name','ADM_Corr_d1b4'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 2 & D.Block == 1 , 'name','ADM_Corr_d2b1'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 2 & D.Block == 2 , 'name','ADM_Corr_d2b2'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 2 & D.Block == 3 , 'name','ADM_Corr_d2b3'},...
            {'Corr_ADM', 'mean', 'subset', D.Day == 2 & D.Block == 4 , 'name','ADM_Corr_d2b4'});
        
        disp('   -> rmANOVA for mean saved to Database')
        disp(' ')

    case 5 %output for rmANOVA of Variance
        output.var = tapply(...
            D,...
            {'label','Subject'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 1 & D.Block == 1 , 'name','ADM_Corr_d1b1'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 1 & D.Block == 2 , 'name','ADM_Corr_d1b2'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 1 & D.Block == 3 , 'name','ADM_Corr_d1b3'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 1 & D.Block == 4 , 'name','ADM_Corr_d1b4'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 2 & D.Block == 1 , 'name','ADM_Corr_d2b1'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 2 & D.Block == 2 , 'name','ADM_Corr_d2b2'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 2 & D.Block == 3 , 'name','ADM_Corr_d2b3'},...
            {'Corr_ADM', 'var', 'subset', D.Day == 2 & D.Block == 4 , 'name','ADM_Corr_d2b4'});
        
        disp('   -> rmANOVA for var saved to Database')
        disp(' ')
        
%% End Script  

%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop
disp(' SCRIPT TERMINATED')