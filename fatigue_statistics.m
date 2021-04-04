% Fatigue | Approach 2 | v3 - Statistics %
%% Setup
run_script = 1;
rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/database/'; % mac root
% rootDir = 'D:/Joshua/fatigue/database'; % windows root

%% Code
%Display available operations
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp('Available operations:')
disp(' ')
disp('SET UP')
disp('  1  load Data')
disp('  2  load Parameters')
disp('  3  combine Data & Parameters')
disp(' ')
disp('OUTPUT')
disp('  4  rmANOVA')
disp(' ')
disp('terminate script with 666')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp(' ')


%% Script
while run_script == 1

action = input('• What would you like me to do? ');
disp(' ')

switch action
%Case 1: Load DB_correlation or DB_euclidean
    case 1
        
        [file, path] = uigetfile('*.*');
        DB = dload(fullfile(path,file));
        
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
        
        disp('   -> DB loaded & varr_type set')
  
%Case 2: Load Parameters
    case 2
        
        [file, path] = uigetfile('*.*');
        p = dload(fullfile(path,file));

        disp('   -> parameters loaded')

%Case 3: Combine DB & Parameters
    case 3

        
        for i = 1:length(DB.Subject)
            DB.label(i) =   unique(p.label(p.SubjN == DB.subjn(i)));
        end
        
        disp('   -> DB & Parameters combined')

% rmANOVA
    case 4 %output for rmANOVA of Mean
 
        disp(' ')
        disp('Output options:')
        output_type = input(' • Type (mean, var): ','s');
        output_lead = input(' • Type (ADM, APB, FDI, BIC, FCR): ','s');
        output_lead = ['Corr_', output_lead];
        
        S = tapply(D,...
            {'label','Subject'},...
            {output_lead, output_type, 'subset', D.Day == 1 & D.Block == 1 , 'name','d1b1'},...
            {output_lead, output_type, 'subset', D.Day == 1 & D.Block == 2 , 'name','d1b2'},...
            {output_lead, output_type, 'subset', D.Day == 1 & D.Block == 3 , 'name','d1b3'},...
            {output_lead, output_type, 'subset', D.Day == 1 & D.Block == 4 , 'name','d1b4'},...
            {output_lead, output_type, 'subset', D.Day == 2 & D.Block == 1 , 'name','d2b1'},...
            {output_lead, output_type, 'subset', D.Day == 2 & D.Block == 2 , 'name','d2b2'},...
            {output_lead, output_type, 'subset', D.Day == 2 & D.Block == 3 , 'name','d2b3'},...
            {output_lead, output_type, 'subset', D.Day == 2 & D.Block == 4 , 'name','d2b4'}); % End of tapply
        
        filename = [datestr(now,'yyyy-mm-dd HH.MM.SS'),' ',output_lead,' ',output_type,'.tsv'];
        dsave(fullfile(rootDir,'Database','fatigue_statistics output',filename),S)
        disp(' ')
        disp(['   -> ',filename,' saved to database'])

%Case 666: Terminate Script 
    case 666 %
        run_script = 0;
        
end %End of Action Switch
end %End of While Loop
disp(' SCRIPT TERMINATED')