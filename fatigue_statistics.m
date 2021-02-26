
% Fatigue | Approach 2 | v3 - Statistics %

%% Setup
run_script = 1;

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


%% process EMG Data

fatigue_statset = []; %Set up struct to hold all Info relevant to our statistics analysis

%Display available operations
disp('Available operations:')
disp(' ')
disp('SET UP')
disp('  - Load data (1)')
disp('  - Build Identifiers (2)')
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
        file_name = input('What file should I load? ','s');
        
        v2p = load(fullfile(rootDir,file_name));
        
        disp('--- Loading file: completed ---')
        disp(' ')

  %End of Case 1: Load fatigue_corr&eucdist
  
%Case 2: Build unique identifiers for blocks and days
    case 2
        for i = 1:height(v2p)
            v2p.ID_block(i) = strcat(string(v2p.Subject(i)), num2str(v2p.Day(i)), num2str(v2p.Block(i)));
            v2p.ID_day(i) = strcat(string(v2p.Subject(i)), num2str(v2p.Day(i)));
        end
        
  %End of Case 2
  
%% Operations

%Case 3: Calculate Variance
    case 3

        %Calculate Variance
        DB_Varriance = table('Size',[1 8],'VariableTypes',{'string','int8','int8','double','double','double','double','double'});
        DB_Varriance.Properties.VariableNames = {'Subject' 'Day' 'Block' 'Varr_Corr_ADM' 'Varr_Corr_APB' 'Varr_Corr_FDI' 'Varr_Corr_BIC' 'Varr_Corr_FCR'};
        
        blocks = unique(v2p.ID_block);
        
        for i = 1:length(blocks)
            b = v2p(v2p.ID_block == blocks(i),:);
            DB_Varriance(height(DB_Varriance)+1,:) = table(unique(b.Subject), unique(b.Day), unique(b.Block), var(b.Corr_ADM), var(b.Corr_APB), var(b.Corr_FDI), var(b.Corr_BIC), var(b.Corr_FCR));
        end

        disp('--- Calculate Variance: Completed ---')
        disp(' ')

  %End of Case 3: Create nanMean Group Arrays for Correlation & Euclidean Distance



%% End Script  
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop
disp(' ')
disp('SCRIPT TERMINATED')