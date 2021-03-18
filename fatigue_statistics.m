
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

%Display available operations
disp('Available operations:')
disp(' ')
disp(' manually load DB_Correlation or DB_Euclidean into "DB_input" with readtable')
disp(' ')
disp('SET UP')
disp('  - set varr_type (1)')
disp('  - Build Identifiers (2)')
disp('  - Load Parameters (4)')
disp(' ')
disp('OPERATIONS')
disp('  - Calculate Variance (3)')
disp('  - Add Parameters to DB_Variance (5)')
disp('  - Add Parameters to DB_input (6)')
disp(' ')
disp('  - Save DB_Variance (9)')
disp(' ')
disp('  - Output without Parameters (11)')
disp('  - Save DB_output (10)')
disp(' ')
disp('Requires Parameters & DB_Variance')
disp('  - Save DB_Variance for mANOVA repeated measure (12)')
disp(' ')
disp('END SCRIPT')
disp('  - Terminate Script (666)')
disp(' ')

%% process EMG Data

while run_script == 1
    
%Select Operation
action = input('What would you like me to do? ');
disp(' ')

switch action

%% Setup Actions
%Case 1: Load fatigue_corr&eucdist
    case 1
        varr_type = input('Correlation or Euclidean Distance? (c/e) ','s');
        
        if not(varr_type == 'c' | varr_type == 'e')
            disp('incorrect varr_type')
            run_script = 0;
        end
        
        disp(' ')
        disp(' varr_type has been set')
        disp(' ')

  %End of Case 1: Load fatigue_corr&eucdist
  
%Case 2: Build unique identifiers for blocks and days
    case 2
        for i = 1:height(DB_input)
            DB_input.ID_block(i) = strcat(string(DB_input.Subject(i)), num2str(DB_input.Day(i)), num2str(DB_input.Block(i)));
            DB_input.ID_day(i) = strcat(string(DB_input.Subject(i)), num2str(DB_input.Day(i)));
        end
        
        disp(' ')
        disp(' Identifiers added to DB_input')
        disp(' ')
        
  %End of Case 2

  
%Case 4: Load Parameters
    case 4
        
        file_name = input('What parameter file should I load? ','s');
        p = readtable(fullfile(rootDir,'Database','Parameters',file_name));
        
        disp(' ')
        disp(' parameters loaded')
        
        for i = 1:height(p)
            p.ID_block(i) = strcat(string(p.ID(i)), num2str(p.day(i)), num2str(p.BN(i)));
            p.ID_day(i) = strcat(string(p.ID(i)), num2str(p.BN(i)));
        end
        
        disp(' day & block identifiers added to parameters ')
        disp(' ')
        
  %End of Case 4
  
  
%% Operations

%Case 3: Calculate Variance
    case 3

        %Calculate Variance
        DB_Variance = table('Size',[0 8],'VariableTypes',{'string','int8','int8','double','double','double','double','double'});
        
        if varr_type == 'c' % Handle for DB_Correlation
            
            DB_Variance.Properties.VariableNames = {'Subject' 'Day' 'Block' 'Varr_Corr_ADM' 'Varr_Corr_APB' 'Varr_Corr_FDI' 'Varr_Corr_BIC' 'Varr_Corr_FCR'};
            
            blocks = unique(DB_input.ID_block);
        
            for i = 1:length(blocks)
                b = DB_input(DB_input.ID_block == blocks(i),:);
                DB_Variance(height(DB_Variance)+1,:) = table(unique(b.Subject), unique(b.Day), unique(b.Block), var(b.Corr_ADM), var(b.Corr_APB), var(b.Corr_FDI), var(b.Corr_BIC), var(b.Corr_FCR));
            end
            
        else % Handle fpr DB_Euclidean
            DB_Variance.Properties.VariableNames = {'Subject' 'Day' 'Block' 'Varr_Euc_ADM' 'Varr_Euc_APB' 'Varr_Euc_FDI' 'Varr_Euc_BIC' 'Varr_Euc_FCR'};
            
            blocks = unique(DB_input.ID_block);
        
            for i = 1:length(blocks)
                b = DB_input(DB_input.ID_block == blocks(i),:);
                DB_Variance(height(DB_Variance)+1,:) = table(unique(b.Subject), unique(b.Day), unique(b.Block), var(b.Euc_ADM), var(b.Euc_APB), var(b.Euc_FDI), var(b.Euc_BIC), var(b.Euc_FCR));
            end
        
        end

        disp(' Calculated Variance')
        
        for i = 1:height(DB_Variance)
            DB_Variance.ID_block(i) = strcat(string(DB_Variance.Subject(i)), num2str(DB_Variance.Day(i)), num2str(DB_Variance.Block(i)));
            DB_Variance.ID_day(i) = strcat(string(DB_Variance.Subject(i)), num2str(DB_Variance.Day(i)));
        end

        disp(' Identifiers added to DB_Variance')
        disp(' ')
        
        disp(' ')

  %End of Case 3: Create nanMean Group Arrays for Correlation & Euclidean Distance
  
  
%Case 5: Add Parameters to DB_Variance'
    case 5
        
        datatypes = varfun(@class,p,'OutputFormat','cell');
        p2add = table('Size',[1 width(p)],'VariableTypes',datatypes);
        p2add.Properties.VariableNames = p.Properties.VariableNames;
        
        for i = 1:height(DB_Variance)
            p2add(i,:) = p(p.ID_block == DB_Variance.ID_block(i),:);
        end

        DB_Variance = [DB_Variance p2add(:,[1:58])];
        
        disp(' Parameters added to DB_Variance')
        disp(' ')

  %End of Case 5: Add Parameters to v2p


%Case 6: Add Parameters to DB_Input'
    case 6
        
        datatypes = varfun(@class,p,'OutputFormat','cell');
        p2add = table('Size',[1 width(p)],'VariableTypes',datatypes);
        p2add.Properties.VariableNames = p.Properties.VariableNames;
        
        for i = 1:height(DB_input)
            p2add(i,:) = p(p.ID_block == DB_input.ID_block(i),:);
        end

        DB_output = [DB_input p2add(:,[1:58])];
        
        disp(' Parameters added to DB_input -> now DB_output')
        disp(' ')

  %End of Case 6: Add Parameters to DB_input
  
  
%Case 9
    case 9 %Save DB_Varriance
        
        d = datestr(datetime(now,'ConvertFrom','datenum'));
        d = strrep(d, ':', '_');
        
        mkdir(fullfile(rootDir,'Database','fatigue_statistics output'), d);
        
        if varr_type == 'c'
            writetable(DB_Variance,fullfile(rootDir,'Database','fatigue_statistics output',d,'DB_Varriance_Correlation.csv'));
        else 
            writetable(DB_Variance,fullfile(rootDir,'Database','fatigue_statistics output',d,'DB_Varriance_Euclidean.csv'));
        end
        
        disp(' ')
        disp(' DB_Varriance saved to Database Folder')
        disp(' ')
        
     %End of Case 9: Save DB_Varriance

     
%Case 10
    case 10 %Save DB_output
        
        d = datestr(datetime(now,'ConvertFrom','datenum'));
        d = strrep(d, ':', '_');
        
        mkdir(fullfile(rootDir,'Database','fatigue_statistics output'), d);
        
        file_name = input('What should I name the file? ','s');
        
        writetable(DB_output,fullfile(rootDir,'Database','fatigue_statistics output',d,file_name));
        
        disp(' ')
        disp(' DB_output saved to Database Folder')
        disp(' ')
        
     %End of Case 10: Save DB_output
     
%Case 11
    case 11 % Output without Parameters
        DB_output = DB_input;
        
    %End of Case 11
    
%%     
%Case 12
    case 12 % Save DB_Variance for mANOVA repeated measure
        
        %Create DB_reapeated_measure
        list_subjects = unique(DB_Variance.Subject);
        
        DB_repeated_measure = table('Size',[0 42],'VariableTypes',{'string','int8','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double'});
        DB_repeated_measure.Properties.VariableNames = {'Subject','Label','ADM_1_1','ADM_1_2','ADM_1_3','ADM_1_4','ADM_2_1','ADM_2_2','ADM_2_3','ADM_2_4','APB_1_1','APB_1_2','APB_1_3','APB_1_4','APB_2_1','APB_2_2','APB_2_3','APB_2_4','FDI_1_1','FDI_1_2','FDI_1_3','FDI_1_4','FDI_2_1','FDI_2_2','FDI_2_3','FDI_2_4','BIC_1_1','BIC_1_2','BIC_1_3','BIC_1_4','BIC_2_1','BIC_2_2','BIC_2_3','BIC_2_4','FCR_1_1','FCR_1_2','FCR_1_3','FCR_1_4','FCR_2_1','FCR_2_2','FCR_2_3','FCR_2_4'};
        headers = ["Subject","Label","ADM_1_1","ADM_1_2","ADM_1_3","ADM_1_4","ADM_2_1","ADM_2_2","ADM_2_3","ADM_2_4","APB_1_1","APB_1_2","APB_1_3","APB_1_4","APB_2_1","APB_2_2","APB_2_3","APB_2_4","FDI_1_1","FDI_1_2","FDI_1_3","FDI_1_4","FDI_2_1","FDI_2_2","FDI_2_3","FDI_2_4","BIC_1_1","BIC_1_2","BIC_1_3","BIC_1_4","BIC_2_1","BIC_2_2","BIC_2_3","BIC_2_4","FCR_1_1","FCR_1_2","FCR_1_3","FCR_1_4","FCR_2_1","FCR_2_2","FCR_2_3","FCR_2_4"];
        
        for i = 1:length(list_subjects)
            
            index = DB_Variance.Subject == list_subjects(i);
            subtable = DB_Variance(index,:);
            
            %Get Subjects Label from p
            p_index = p.ID == list_subjects(i);
            p_subtable = p(p_index,:);
            subject_label = unique(p_subtable.label);
            
            %Create Subject Row
            DB_repeated_measure(i,:) = num2cell(NaN([1 42]));
            DB_repeated_measure.Subject(i) = list_subjects(i);
            DB_repeated_measure.Label(i) = subject_label;
            
            %Fill Subject Row
            for j = 1:5 % 5 -> 5 Leads | +3 because Leads start in the 4 Column of DB_Variance
                
                for k = 1:height(subtable)
                    day = table2array(subtable(k,2));
                    block = table2array(subtable(k,3));
                    
                    DB_repeated_measure.(headers(((j-1)*8)+(((day-1)*4)+block)+2))(i) = table2array(subtable(k,j+3));
                    
                end
            end
        end
        
        %Save DB_variance_corr/euc
        formatOut = 'yy-mm-dd HHMMSS';
        d = datestr(now,formatOut);
        
        %mkdir(fullfile(rootDir,'Database','fatigue_statistics output'), d);
        
        if varr_type == "c"
            file_name = ['DB_cor_var_rm ',d,'.csv'];
        else
            
            if varr_type == "e"
                file_name = ['DB_euc_var_rm ',d,'.csv'];
            else
                disp('you did not specify the varr_type')
            end
        end
        
        writetable(DB_repeated_measure,fullfile(rootDir,'Database','fatigue_statistics output',file_name));
        
    %End of Case 12: Save DB_Output for mANOVA repeated measuer without Parameters
    
    
%% End Script  
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop
disp(' ')
disp('SCRIPT TERMINATED')