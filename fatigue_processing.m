
% Fatigue | Approach 2 | v3 - Process EMG Data %

%% Setup

setup_check = input('Have you updated the rootDir, the allDat and the save function? [y/n] ','s');
disp(' ');

if setup_check == 'n'
    disp('Please stop, update and restart your script.');
    disp(' ');
end

% rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/Try 2/data/'; % mac root
rootDir = 'D:/Joshua/fatigue/data'; % windows root

% Processing Parameters
SRATE = 5000;
freq_h = 10;
freq_l = 6;
ORDER = 4;
LENGTH = 100000;

%% Code

%Create required arrays & load Parameters and Missing Trial Index

% Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_sample.tsv'));
Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_modified.tsv'));

Missing_Trials = dload(fullfile(rootDir,'0 Parameters','missing_trials.tsv'));

%create list of missing trials
missing_trials = [];

for i = 1:length(Missing_Trials.ID)
    trial = [char(Missing_Trials.ID(i)),'.',num2str(Missing_Trials.day(i)),'.',char(Missing_Trials.BN(i)),'.',char(Missing_Trials.trial(i))];
    missing_trials = [missing_trials; string(trial)];
end

%Display available operations
disp('Available operations:')
disp('  - Process Raw Cut Trial EMG Data -> Creates EMG_Clean (1)')
disp('  - Load EMG_clean (2)')
disp(' ')
disp(' Requires EMG_clean:')
disp('  - Standardise processed trial vectors for time (3)')
disp('  - Calculate mean Trial Vector per Block (4)')
disp('  - Calculate Spearman Correlation & Euclidean Distance for every Trial (5)')
disp('  - Add Spearman Correlation & Euclidean Distance to Blocks & Days (6)')
disp(' ')
disp('  - Save EMG_clean (8)')
disp('  - Save Correlations & Euclidean Distances only (9)')
disp('  - Terminate Script (666)')

%% process EMG Data
run_script = 1;

while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');
disp(' ')

switch action

%Case 1   
    case 1 %Process Raw Cut Trial EMG Data
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Processing Cut Trial EMG Data ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;

        %Create allDat of Procesed Cut Trial EMG Data based on Parameters File
        EMG_clean = [];
        
        for i = 1:length(Parameters.SessN)

            id = Parameters.ID(i);
            day = Parameters.day(i);
            block = Parameters.BN(i);

            %Check for missing day or block and skip if true
            test_str1 = char(strcat(id,'.',num2str(day),'.all.all'));
            test_str2 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.all'));
            if sum(contains(missing_trials,test_str1))>0
                continue
            end
            if sum(contains(missing_trials,test_str2))>0
                continue
            end

            folder = strcat(id,'_EMGAnalysis_d',num2str(day));

            for j = 1:30

                % check for missing trial and skip if true
                test_str3 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.',num2str(j)));
                if sum(contains(missing_trials,test_str3))>0
                    continue
                end

                final = [];

                %Load the Trial File
                file = strcat(id,'_EMG_d',num2str(day),'_b',num2str(block),'_t',num2str(j),'.txt');
                D = dload(char(fullfile(rootDir,'1 Trials Cut',folder,file)));

                %Process each Lead
                final.ADM = proc_std(D.ADM, SRATE, freq_h, freq_l, ORDER);
                final.APB = proc_std(D.APB, SRATE, freq_h, freq_l, ORDER);
                final.FDI = proc_std(D.FDI, SRATE, freq_h, freq_l, ORDER);        
                final.BIC = proc_std(D.BIC, SRATE, freq_h, freq_l, ORDER);
                final.FCR = proc_std(D.FCR, SRATE, freq_h, freq_l, ORDER);

                %Add Processed Trial to allDat 'EMG_clean'
                EMG_clean.proc_only.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]) = final;

                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total,h,['Processing Cut Trial EMG Data ', num2str(counter/total*100),'%']);
            end
            
            %Add Block Parameters
            parameter_fields = fields(Parameters);
            for j = 1:length(parameter_fields)
                EMG_clean.proc_only.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).parameters.(char(parameter_fields(j))) = Parameters.(char(parameter_fields(j)))(i);
            end % End of 'Add Block Parameters'
            
        end %End of Paramtere Iteration for Case 1
        close(h);
        disp('--- Process Raw Cut Trial EMG Data: Completed ---')
        disp(' ')
        
        %End of Case 1: Process Raw Cut Trial EMG Data

%Case 2
    case 2 %Load EMG_clean
        file_name = input('What file would you like to load as EMG_clean? ','s');
        EMG_clean = load(fullfile(rootDir,file_name));
        disp(' ')
        disp(['--- ',file_name,' has been loaded successfully ---'])
        disp('  You can now access it as "EMG_clean" in your code')
        disp(' ')
        
        %End of Case 2: Load EMG_Clean
       
%Case 3
    case 3 %Standardise processed trial vectors for time
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(counter,['Standardising processed trial vectors for time ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;
         
        %Standardise all Trial Vectors for Length
         for i = 1:length(Parameters.SessN)
    
            id = Parameters.ID(i);
            day = Parameters.day(i);
            block = Parameters.BN(i);
            
            %check for missing days or blocks and skip if true
            test_str1 = char(strcat(id,'.',num2str(day),'.all.all'));
            test_str2 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.all'));
 
            if sum(contains(missing_trials,test_str1))>0
                continue
            end
 
            if sum(contains(missing_trials,test_str2))>0
                continue
            end
    
            %Process all Trials of the Block
            for j = 1:30
 
                %Check for missing trial and skip if true
                test_str3 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.',num2str(j)));
                if sum(contains(missing_trials,test_str3))>0
                    continue
                end
        
                %Load the trial vector from EMG_clean.proc_only
                trial = EMG_clean.proc_only.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]);
 
                %Add standardised Trial Vector to EMG_clean.stnd_len
                EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).ADM = stnd4time(trial.ADM,LENGTH);
                EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).APB = stnd4time(trial.APB,LENGTH);
                EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).FDI = stnd4time(trial.FDI,LENGTH);
                EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).BIC = stnd4time(trial.BIC,LENGTH);
                EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).FCR = stnd4time(trial.FCR,LENGTH);
 
                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total, h, ['Standardising processed trial vectors for time ', num2str(counter/total*100),'%']);
            end %End of 'Process all Trials of the Block'
            
            %Copy Paramteres from porc_only
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).parameters = EMG_clean.proc_only.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).parameters; 
 
         end %End of Length Standardising For Loop
        
        close(h)
        disp('--- Standardise processed trial vectors for time: Completed ---')
        disp(' ')
         
        %End of Case 2: Standardise processed trial vectors for time

%Case 4
    case 4 %Calculate mean Trial Vector per Block
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(counter,['Calculate mean Trial Vector per Block ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;
        
        
        %Calculate mean Trial Vector per Block
        for i = 1:length(Parameters.SessN)
    
            id = Parameters.ID(i);
            day = Parameters.day(i);
            block = Parameters.BN(i);
            
            %check for missing days or blocks and skip if true
            test_str1 = char(strcat(id,'.',num2str(day),'.all.all'));
            test_str2 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.all'));
 
            if sum(contains(missing_trials,test_str1))>0
                continue
            end
 
            if sum(contains(missing_trials,test_str2))>0
                continue
            end
 
            %create mean vector
            trial_mean_adm = zeros(LENGTH,1);
            trial_mean_apb = zeros(LENGTH,1);
            trial_mean_fdi = zeros(LENGTH,1);
            trial_mean_bic = zeros(LENGTH,1);
            trial_mean_fcr = zeros(LENGTH,1);
            
            num_trials = 0;
            
            for j = 1:30
                
                %check for missing trials and skip if true
                test_str3 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.',num2str(j)));
    
                if sum(contains(missing_trials,test_str3))>0
                    continue
                end
    
                %loading trial and adding to running total
                trial = EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]);
                
                trial_mean_adm = trial_mean_adm + trial.ADM;
                trial_mean_apb = trial_mean_apb + trial.APB;
                trial_mean_fdi = trial_mean_fdi + trial.FDI;
                trial_mean_bic = trial_mean_bic + trial.BIC;
                trial_mean_fcr = trial_mean_fcr + trial.FCR;
                
                num_trials = num_trials + 1;
                
                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total, h,['Calculate mean Trial Vector per Block ', num2str(counter/total*100),'%']);
            end
            
            trial_mean_adm = trial_mean_adm/num_trials;
            trial_mean_apb = trial_mean_apb/num_trials;
            trial_mean_fdi = trial_mean_fdi/num_trials;
            trial_mean_bic = trial_mean_bic/num_trials;
            trial_mean_fcr = trial_mean_fcr/num_trials;
            
            %add mean Vector to EMG_clean
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean.ADM = trial_mean_adm;
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean.APB = trial_mean_apb;
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean.FDI = trial_mean_fdi;
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean.BIC = trial_mean_bic;
            EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean.FCR = trial_mean_fcr;
            
         end %End of Parameter Iteration for Mean Vector Calculation
         
        close(h)
        disp('--- Calculate mean Trial Vectors per Block: Completed ---')
        disp(' ')
        
       %End of Case 4: Calculate mean Trial Vectors per Block
    
%Case 5
    case 5 %Calculate Spearman Correlation & Euclidean Distance for every Trial
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(counter,['Calculate Spearman Correlation & Euclidean ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;
        
        %Setup DB_Tables
        %DB_Correlation
        DB_Correlation = table('Size',[1 9],'VariableTypes',{'string','int8','int8','int8','double','double','double','double','double'});
        DB_Correlation.Properties.VariableNames = {'Subject' 'Day' 'Block' 'Trial' 'Corr_ADM' 'Corr_APB' 'Corr_FDI' 'Corr_BIC' 'Corr_FCR'};

        
        %Calculate Spearman Correlation & Euclidean Distance for every Trial
        for i = 1:length(Parameters.SessN)
    
            id = Parameters.ID(i);
            day = Parameters.day(i);
            block = Parameters.BN(i);
            
            %check for missing day or block and skip if true
            test_str1 = char(strcat(id,'.',num2str(day),'.all.all'));
            test_str2 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.all'));

            if sum(contains(missing_trials,test_str1))>0
                continue
            end
 
            if sum(contains(missing_trials,test_str2))>0
                continue
            end
 
            %load trial mean
            trial_mean = EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).trial_mean;
            
            for j = 1:30
                
                %check for missing trial and skip if true
                test_str3 = char(strcat(id,'.',num2str(day),'.',num2str(block),'.',num2str(j)));
                if sum(contains(missing_trials,test_str3))>0
                    continue
                end
 
%%              %load trial and compare to mean
                trial = EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]);
                
                %Correlation
                corr_trial = [];
                corr_trial.ADM = corr(trial.ADM,trial_mean.ADM);
                corr_trial.APB = corr(trial.APB,trial_mean.APB);
                corr_trial.FDI = corr(trial.FDI,trial_mean.FDI);
                corr_trial.BIC = corr(trial.BIC,trial_mean.BIC);
                corr_trial.FCR = corr(trial.FCR,trial_mean.FCR);
                
                DB_Correlation(height(DB_Correlation)+1,:) = table(id, day, block, j, corr_trial.ADM, corr_trial.APB, corr_trial.FDI, corr_trial.BIC, corr_trial.FCR);
                
                %Euclidean Distance
                eucdist_trial = [];
                eucdist_trial.ADM = dist([trial.ADM,trial_mean.ADM]);
                eucdist_trial.APB = dist([trial.APB,trial_mean.APB]);
                eucdist_trial.FDI = dist([trial.FDI,trial_mean.FDI]);
                eucdist_trial.BIC = dist([trial.BIC,trial_mean.BIC]);
                eucdist_trial.FCR = dist([trial.FCR,trial_mean.FCR]);
                
                DB_Correlation(height(DB_Correlation)+1,:) = table(id, day, block, j, eucdist_trial.ADM(1,2), eucdist_trial.APB(1,2), eucdist_trial.FDI(1,2), eucdist_trial.BIC(1,2), eucdist_trial.FCR(1,2));
                
    %ADM
                %corr
%                 corr_trial = corr(trial.ADM,trial_mean.ADM);
%                 EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).corr.ADM = corr_trial;
%                 block_corr.ADM = [block_corr.ADM; corr_trial];
                
                %Euclidean Distance
%                 eucdist_trial = dist([trial_mean.ADM trial.ADM]);
%                 eucdist_trial = eucdist_trial(1,2);
%                 EMG_clean.stnd_len.(char(id)).(['d',num2str(day)]).(['b',num2str(block)]).(['t',num2str(j)]).eucdist.ADM = eucdist_trial;
%                 block_eucdist.ADM = [block_eucdist.ADM; eucdist_trial];

    
                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total, h,['Calculate Spearman Correlation & Euclidean ', num2str(counter/total*100),'%']);
            end
 
        end %End of Parameter Iteration for Spearman Corr & Euclidean Distance
        
        close(h)
        disp('--- Calculate Spearman Correlation & Euclidean Distance for every Trial: Completed ---')
        disp(' ')
        
      %End of Case 5: Calculate Spearman Correlation & Euclidean Distance for every Trial
      
%Case 6
    case 6 %Add Spearman Correlation & Euclidean Distance to Blocks & Days

        subj = fields(EMG_clean.stnd_len);
        array_legend = ["d1 b1" "d1 b2" "d1 b3" "d1 b4" "d2 b1" "d2 b2" "d2 b3" "d2 b4"];

        for i = 1:length(subj)

            %subj_array = NaN(30,8);
            subj_corr.ADM = nan(30,8);
            subj_corr.APB = nan(30,8);
            subj_corr.FDI = nan(30,8);
            subj_corr.BIC = nan(30,8);
            subj_corr.FCR = nan(30,8);
            
            subj_eucdist.ADM = nan(30,8);
            subj_eucdist.APB = nan(30,8);
            subj_eucdist.FDI = nan(30,8);
            subj_eucdist.BIC = nan(30,8);
            subj_eucdist.FCR = nan(30,8);
            
            subj_parameters = [];

            %enter each day
            days = fields(EMG_clean.stnd_len.(char(subj(i))));
            days(strcmp('corr_array',days)) = [];
            days(strcmp('eucdist_array',days)) = [];
            days(strcmp('parameters',days)) = [];
            
            for j = 1:length(days)
                %enter each block
                blocks = fields(EMG_clean.stnd_len.(char(subj(i))).(char(days(j))));
                blocks(strcmp('corr_array',blocks)) = [];
                blocks(strcmp('eucdist_array',blocks)) = [];
                blocks(strcmp('parameters',blocks)) = [];
            
                %subj_array = NaN(30,8);
                block_corr.ADM = nan(30,4);
                block_corr.APB = nan(30,4);
                block_corr.FDI = nan(30,4);
                block_corr.BIC = nan(30,4);
                block_corr.FCR = nan(30,4);

                block_eucdist.ADM = nan(30,4);
                block_eucdist.APB = nan(30,4);
                block_eucdist.FDI = nan(30,4);
                block_eucdist.BIC = nan(30,4);
                block_eucdist.FCR = nan(30,4);
                
                block_parameters = [];

                for k = 1:length(blocks) %Block Itteration
                    
                  %code to be executed in each block

                    block_row = find(string([char(days(j)), ' ', char(blocks(k))]) == array_legend);
                    
                    if block_row > 4
                        block_row_2 = block_row - 4;
                    else
                        block_row_2 = block_row;
                    end
                    
                    %Fill Subj_Corr
                    insert = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).corr_array;

                    subj_corr.ADM(1:length(insert.ADM),block_row) = insert.ADM;
                    subj_corr.APB(1:length(insert.APB),block_row) = insert.APB;
                    subj_corr.FDI(1:length(insert.FDI),block_row) = insert.FDI;
                    subj_corr.BIC(1:length(insert.BIC),block_row) = insert.BIC;
                    subj_corr.FCR(1:length(insert.FCR),block_row) = insert.FCR;

                    %Fill Subj_EucDist
                    insert = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).eucdist_array;

                    subj_eucdist.ADM(1:length(insert.ADM),block_row) = insert.ADM;
                    subj_eucdist.APB(1:length(insert.APB),block_row) = insert.APB;
                    subj_eucdist.FDI(1:length(insert.FDI),block_row) = insert.FDI;
                    subj_eucdist.BIC(1:length(insert.BIC),block_row) = insert.BIC;
                    subj_eucdist.FCR(1:length(insert.FCR),block_row) = insert.FCR;
                    
                    %Fill Block_Corr
                    insert = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).corr_array;

                    block_corr.ADM(1:length(insert.ADM),block_row_2) = insert.ADM;
                    block_corr.APB(1:length(insert.APB),block_row_2) = insert.APB;
                    block_corr.FDI(1:length(insert.FDI),block_row_2) = insert.FDI;
                    block_corr.BIC(1:length(insert.BIC),block_row_2) = insert.BIC;
                    block_corr.FCR(1:length(insert.FCR),block_row_2) = insert.FCR;

                    %Fill Block_EucDist
                    insert = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).eucdist_array;

                    block_eucdist.ADM(1:length(insert.ADM),block_row_2) = insert.ADM;
                    block_eucdist.APB(1:length(insert.APB),block_row_2) = insert.APB;
                    block_eucdist.FDI(1:length(insert.FDI),block_row_2) = insert.FDI;
                    block_eucdist.BIC(1:length(insert.BIC),block_row_2) = insert.BIC;
                    block_eucdist.FCR(1:length(insert.FCR),block_row_2) = insert.FCR;
                    
                    %Add parameters
                    block_parameters.(char(blocks(k))) = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).parameters;
                    subj_parameters.(char(days(j))).(char(blocks(k))) = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).parameters;

                  %end of block code

                end %End of Block Itteration
                
                EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).corr_array = block_corr;
                EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).eucdist_array = block_eucdist;
                EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).parameters = block_parameters;
            
            end %End of Day Itteration

            EMG_clean.stnd_len.(char(subj(i))).corr_array = subj_corr;
            EMG_clean.stnd_len.(char(subj(i))).eucdist_array = subj_eucdist;
            EMG_clean.stnd_len.(char(subj(i))).parameters = subj_parameters;
            
        end %End of Subject Itteration
      
        disp('--- Add Spearman Correlation & Euclidean Distance to Blocks & Days: Completed ---')
        disp(' ')
        
      %End of Case 6: Add Spearman Correlation & Euclidean Distance to Blocks & Days

%Case 8
    case 8 %Save EMG_clean
        disp('EMG_clean will be saved to your rootDir.')
        disp(' ')
        file_name = input('What should I name the file? ','s');
        file_name = [file_name, '.mat'];
        save(fullfile(rootDir,file_name),'-struct','EMG_clean','-v7.3')
        disp('Saved succesfully')
        disp(' ')
    %End of Case 8: Save EMG_clean
    
%Case 9
    case 9 %Save Correlation & Euclidean Distances only
        output = [];
        
        subj = fields(EMG_clean.stnd_len);

        for i = 1:length(subj)

            %enter each day
            days = fields(EMG_clean.stnd_len.(char(subj(i))));
            days(strcmp('corr_array',days)) = [];
            days(strcmp('eucdist_array',days)) = [];
            days(strcmp('parameters',days)) = [];
            
            for j = 1:length(days)
                
                %enter each block
                blocks = fields(EMG_clean.stnd_len.(char(subj(i))).(char(days(j))));
                blocks(strcmp('corr_array',blocks)) = [];
                blocks(strcmp('eucdist_array',blocks)) = [];
                blocks(strcmp('parameters',blocks)) = [];
                

                for k = 1:length(blocks) %Block Itteration
                    
                  %enter each trial
                  trials = fields(EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))));
                  trials(strcmp('parameters',trials)) = [];
                  trials(strcmp('trial_mean',trials)) = [];
                  trials(strcmp('corr_array',trials)) = [];
                  trials(strcmp('eucdist_array',trials)) = [];
                  
                  for l = 1:length(trials)
                      
                      trial = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(trials(l)));
                      output.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(trials(l))).corr = trial.corr;
                      output.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(trials(l))).eucdist = trial.eucdist;
                      
                  end %End of Trial Itteration
                  
                  block = EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k)));
                  output.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).corr_array = block.corr_array;
                  output.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).eucdist_array = block.eucdist_array;
                  output.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).parameters = block.parameters;

                end %End of Block Itteration
            
                day = EMG_clean.stnd_len.(char(subj(i))).(char(days(j)));
                output.stnd_len.(char(subj(i))).(char(days(j))).corr_array = day.corr_array;
                output.stnd_len.(char(subj(i))).(char(days(j))).eucdist_array = day.eucdist_array;
                output.stnd_len.(char(subj(i))).(char(days(j))).parameters = day.parameters;
                output.stnd_len.(char(subj(i))).parameters.(char(days(j))) = day.parameters;
                  
            end %End of Day Itteration
            
            subject = EMG_clean.stnd_len.(char(subj(i)));
            output.stnd_len.(char(subj(i))).corr_array = subject.corr_array;
            output.stnd_len.(char(subj(i))).eucdist_array = subject.eucdist_array;
                
        end %End of Subject Itteration
        
        file_name = input('What should I name the file? ','s')
        save(fullfile(rootDir,file_name),'-struct','output')
        disp(' ')
        disp('--- Save Correlation & Euclidean Distances only: Completed ---')
        disp(' ')
        
     %End of Case 9: Save Correlation & Euclidean Distances only
        
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop