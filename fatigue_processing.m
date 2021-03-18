
% Fatigue | Approach 2 | v3 - Process EMG Data %

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
SRATE = 5000;
freq_h = 10;
freq_l = 6;
ORDER = 4;
LENGTH = 100000;

%% Code

%Create required arrays & load Parameters and Missing Trial Index

Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_sample.tsv'));
%Parameters = dload(fullfile(rootDir,'0 Parameters','fatigue_parameters_modified.tsv'));

Missing_Trials = dload(fullfile(rootDir,'0 Parameters','missing_trials.tsv'));

%create list of missing trials
missing_trials = [];

for i = 1:length(Missing_Trials.ID)
    trial = [char(Missing_Trials.ID(i)),'.',num2str(Missing_Trials.day(i)),'.',char(Missing_Trials.BN(i)),'.',char(Missing_Trials.trial(i))];
    missing_trials = [missing_trials; string(trial)];
end

%Display available operations
disp('Available operations:')
disp(' ')
disp('  - Process Raw Cut Trial EMG Data -> Creates EMG_Clean (1)')
disp('  - Load EMG_clean (2)')
disp(' ')
disp(' Requires EMG_clean:')
disp('  - Standardise processed trial vectors for time (3)')
disp('  - Calculate mean Trial Vector per Block (4)')
disp(' ')
disp(' Requires mean Trial Vectors:')
disp('  - Calculate Spearman Correlation & Euclidean Distance for every Trial (5)')
disp(' ')
disp('  - Save EMG_clean (8)')
disp('  - Save Correlations & Euclidean Distances(9)')
disp(' ')
disp('  - Terminate Script (666)')

%% process EMG Data

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
        
        %DB_Correlation
        DB_Euclidean = table('Size',[1 9],'VariableTypes',{'string','int8','int8','int8','double','double','double','double','double'});
        DB_Euclidean.Properties.VariableNames = {'Subject' 'Day' 'Block' 'Trial' 'Corr_ADM' 'Corr_APB' 'Corr_FDI' 'Corr_BIC' 'Corr_FCR'};

        
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
                
                DB_Euclidean(height(DB_Euclidean)+1,:) = table(id, day, block, j, eucdist_trial.ADM(1,2), eucdist_trial.APB(1,2), eucdist_trial.FDI(1,2), eucdist_trial.BIC(1,2), eucdist_trial.FCR(1,2));
    
                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total, h,['Calculate Spearman Correlation & Euclidean ', num2str(counter/total*100),'%']);
            end
 
        end %End of Parameter Iteration for Spearman Corr & Euclidean Distance
        
        close(h)
        disp('--- Calculate Spearman Correlation & Euclidean Distance for every Trial: Completed ---')
        disp(' ')
        
      %End of Case 5: Calculate Spearman Correlation & Euclidean Distance for every Trial
      

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
    case 9 %Save Correlation & Euclidean Distances
        
        d = datestr(datetime(now,'ConvertFrom','datenum'));
        
        mkdir(fullfile(rootDir,'Database'), d);
        
        writetable(DB_Correlation,fullfile(rootDir,'Database','fatigue_processing output',d,'DB_Correlation.csv'));
        writetable(DB_Euclidean,fullfile(rootDir,'Database','fatigue_processing output',d,'DB_Euclidean.csv'));
        
        disp(' ')
        disp('--- Correlation & Euclidean Distances saved to Database Folder ---')
        disp(' ')
        
     %End of Case 9: Save Correlation & Euclidean Distances only
        
%Case 666      
    case 666 %Terminate Script
        run_script = 0;
      %End of Case 666: Terminate Script
        
end %End of Operation/Action Switch

end %End of While Loop
disp(' ')
disp('SCRIPT TERMINATED')