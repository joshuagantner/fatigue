% Fatigue | Approach 3 | Data Clean Up

run_script = 1;
% rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/database/'; % mac root
rootDir = 'D:/Joshua/fatigue/database'; % windows root

%Display available operations
disp('Available operations:')
disp(' ')
disp('SETUP')
disp('  1 Load EMG_clean')
disp(' ')
disp('ACTIONS')
disp('  2 plot block')
disp('  3 plot trial')
disp(' ')
disp('* 666 Terminate Script *')

while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');
disp(' ')

switch action

%% SETUP
    case 1 %Load EMG_clean
        [file, path] = uigetfile(fullfile(rootDir,'*.*'),'What EMG_clean file should I load? ');
        EMG_clean = load(fullfile(path, file));
        
        disp('--- Load EMG_clean: completed ---')

%% ACTIONS 
    case 2 %plot block
        
    case 3 %plot trial
        
  
%% END OF SCRIPT      
    case 666 %Terminate Script
        run_script = 0;
        
end %End of Operation/Action Switch

end %End of While Loop

disp('—————————————')
disp('| SCRIPT TERMINATED |')
disp('—————————————')
disp(' ')