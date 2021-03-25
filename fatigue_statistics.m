
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

% Processing Parameters
array_legend = ["d1 b1" "d1 b2" "d1 b3" "d1 b4" "d2 b1" "d2 b2" "d2 b3" "d2 b4"];

%% Code

%Create required arrays & load Parameters and Missing Trial Index

%Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_sample.tsv'));
%Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters.tsv'));

%Display available operations
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp('Available operations:')
disp(' ')
disp('SET UP')
disp('  1  load DB_correlation oder DB_euclidean')
disp('  2  load Parameters')
disp(' ')
disp('OUTPUT')
disp(' rmANOVA')
disp('  3  Correlation / Euclidean Distance')
disp('  4  Variance of Correlation / Euclidean Distance')
disp(' ')
disp('* 666 to terminate script *')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp(' ')


%% process EMG Data

while run_script == 1
    
%Select Operation
action = input('What would you like me to do? ');
disp(' ')

switch action

%% Setup Actions
%Case 1: Load DB_correlation or DB_euclidean
    case 1
        
        [file, path] = uigetfile('*.*');
        DB_input = readtable(fullfile(path,file));
        
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
        for i = 1:height(DB_input)
            DB_input.ID_block(i) = strcat(string(DB_input.Subject(i)), num2str(DB_input.Day(i)), num2str(DB_input.Block(i)));
            DB_input.ID_day(i) = strcat(string(DB_input.Subject(i)), num2str(DB_input.Day(i)));
        end
        
        disp(' DB loaded & varr_type set')
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
        
        disp(' parameters loaded')
        disp(' ')
  
  
%% Output

%% rmANOVA

%Case 3: Output rmANOVA Correlation / Euclidean
    case 3
        
        %Merge Input & Parameters
        datatypes = varfun(@class,p,'OutputFormat','cell');
        p2add = table('Size',[1 width(p)],'VariableTypes',datatypes);
        p2add.Properties.VariableNames = p.Properties.VariableNames;
        
        for i = 1:height(DB_input)
            p2add(i,:) = p(p.ID_block == DB_input.ID_block(i),:);
        end

        DB_output = [DB_input p2add(:,[1:58])];
        
        %Format for rmANOVE
        D = table2struct(DB_output,'ToScalar',true);

        if var_type == 'c'
            disp(' Your Pivot: Correlation')
        else
            disp(' Your Pivot: Euclidean Distance')
        end
        
        pivottable([D.label D.SubjN], [D.Day D.Block], [D.Corr_ADM], "mean");
        disp(' ')
        
%Case 3: Output rmANOVA Variance Correlation / Euclidean
    case 4
        
        %Merge Input & Parameters
        datatypes = varfun(@class,p,'OutputFormat','cell');
        p2add = table('Size',[1 width(p)],'VariableTypes',datatypes);
        p2add.Properties.VariableNames = p.Properties.VariableNames;
        
        for i = 1:height(DB_input)
            p2add(i,:) = p(p.ID_block == DB_input.ID_block(i),:);
        end

        DB_output = [DB_input p2add(:,[1:58])];
        
        %Format for rmANOVE
        D = table2struct(DB_output,'ToScalar',true);

        if var_type == 'c'
            disp(' Your Pivot: Variance of Correlation')
        else
            disp(' Your Pivot: Variance of Euclidean Distance')
        end
        pivottable([D.label D.SubjN], [D.Day D.Block], [D.Corr_ADM], "var");
        disp(' ')
        
        
%% End Script  
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop
disp(' SCRIPT TERMINATED')