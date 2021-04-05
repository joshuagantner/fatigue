
% Fatigue | Approach 2 | v3 - Process EMG Data %

%% Setup
run_script = 1;
% rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/database/'; % mac root
rootDir = 'D:/Joshua/fatigue/database'; % windows root

%% Code

%Display available operations
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp('Available operations:')
disp(' ')
disp('SETUP')
disp(' 1  Load Parameters')
disp(' 2  Load Mising Trial')
disp(' 3  Load EMG_clean')
disp(' 4  Process Raw Cut Trial EMG Data -> Creates EMG_Clean')
disp('        • requires Parameters & Missing Trials')
disp(' ')
disp('OPERATIONS')
disp(' 5  Standardise processed trial vectors for time')
disp(' 6  Calculate mean Trial Vector per Block')
disp(' 7  Calculate Spearman Correlation & Euclidean Distance for every Trial')
disp(' ')
disp('SAVE')
disp(' 8  Save EMG_clean')
disp(' 9  Save Correlations & Euclidean Distances')
disp(' ')
disp('terminate script with 666')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')

%% process EMG Data
while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');
disp(' ')

switch action

%Case 1: Load Parameters
    case 1
        [f,p] = uigetfile(fullfile(rootDir,'*.*'),'Select the Fatigue Parameter File');
        Parameters = dload(fullfile(p,f));
        disp('  -> Parameters loaded')
        
%Case 2: Load Missing Trials
    case 2
        [f,p] = uigetfile(fullfile(rootDir,'*.*'),'Select the Missing Trials List');
        Missing_Trials = dload(fullfile(p,f));
        
        missing_trials = [];

        for i = 1:length(Missing_Trials.ID)
            trial = [char(Missing_Trials.ID(i)),'.',num2str(Missing_Trials.day(i)),'.',char(Missing_Trials.BN(i)),'.',char(Missing_Trials.trial(i))];
            missing_trials = [missing_trials; string(trial)];
        end
        disp('  -> Missing Trials loaded')
        
%Case 3: Load EMG_clean
    case 3
        [f,p] = uigetfile(rootDir,'Select the EMG_Clean matlab file');
        EMG_clean = load(fullfile(p,f));
        disp(['--- ',f,' has been loaded successfully ---'])
        disp('  You can now access it as "EMG_clean" in your code')
        
%Case 4: Process Raw Cut Trial EMG Data
    case 4
        
        [p] = uigetdir(rootDir,'Select the EMG Cut Trials folder');
        
        % Processing Parameters
        SRATE = 5000;
        freq_h = 10;
        freq_l = 6;
        ORDER = 4;
        LENGTH = 100000;

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
                D = dload(char(fullfile(p,folder,file)));

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
  
%Case 5: Standardise processed trial vectors for time
    case 5
        
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
         
%Case 6: Calculate mean Trial Vector per Block
    case 6
        
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
        
%Case 7: Calculate Spearman Correlation & Euclidean Distance for every Trial
    case 7
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(counter,['Calculate Spearman Correlation & Euclidean ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;
        
        %Setup DB_Tables
        %DB_Correlation
        DB_Correlation = table('Size',[0 10],'VariableTypes',{'string','int8','int8','int8','int8','double','double','double','double','double'});
        DB_Correlation.Properties.VariableNames = {'Subject' 'SubjN' 'Day' 'Block' 'Trial' 'Corr_ADM' 'Corr_APB' 'Corr_FDI' 'Corr_BIC' 'Corr_FCR'};
        
        %DB_Euclidean
        DB_Euclidean = table('Size',[0 10],'VariableTypes',{'string','int8','int8','int8','int8','double','double','double','double','double'});
        DB_Euclidean.Properties.VariableNames = {'Subject' 'SubjN' 'Day' 'Block' 'Trial' 'Euc_ADM' 'Euc_APB' 'Euc_FDI' 'Euc_BIC' 'Euc_FCR'};

        
        %Calculate Spearman Correlation & Euclidean Distance for every Trial
        for i = 1:length(Parameters.SessN)
    
            id = Parameters.ID(i);
            subjn = Parameters.SubjN(i);
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
                
                DB_Correlation(height(DB_Correlation)+1,:) = table(id, subjn, day, block, j, corr_trial.ADM, corr_trial.APB, corr_trial.FDI, corr_trial.BIC, corr_trial.FCR);
                
                %Euclidean Distance
                eucdist_trial = [];
                eucdist_trial.ADM = dist([trial.ADM,trial_mean.ADM]);
                eucdist_trial.APB = dist([trial.APB,trial_mean.APB]);
                eucdist_trial.FDI = dist([trial.FDI,trial_mean.FDI]);
                eucdist_trial.BIC = dist([trial.BIC,trial_mean.BIC]);
                eucdist_trial.FCR = dist([trial.FCR,trial_mean.FCR]);
                
                DB_Euclidean(height(DB_Euclidean)+1,:) = table(id, subjn, day, block, j, eucdist_trial.ADM(1,2), eucdist_trial.APB(1,2), eucdist_trial.FDI(1,2), eucdist_trial.BIC(1,2), eucdist_trial.FCR(1,2));
    
                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total, h,['Calculate Spearman Correlation & Euclidean ', num2str(counter/total*100),'%']);
            end
 
        end %End of Parameter Iteration for Spearman Corr & Euclidean Distance
        
        close(h)
        disp('--- Calculate Spearman Correlation & Euclidean Distance for every Trial: Completed ---')
        disp(' ')

%Case 8: Save EMG_clean
    case 8
        filename_suggestion = ['EMG_clean_',datestr(now,'yyyy-mm-dd_hhMMss'),'.mat'];
        [f,p] = uiputfile(fullfile(rootDir,'fatigue_processing output',filename_suggestion),'Where to save new EMG_Clean…');
        save(fullfile(p,f),'-struct','EMG_clean','-v7.3')
        disp('Saved succesfully')
        disp(' ')
    
%Case 9: Save Correlation & Euclidean Distances
    case 9
        
        d = datestr(now,'yyyy-mm-dd_hhMMss');
        
        filename = fullfile(rootDir,'fatigue_processing output',['DB_Correlation',d,'.txt']);
        dsave(filename,table2struct(DB_Correlation,'ToScalar',true));
        
        filename = fullfile(rootDir,'fatigue_processing output',['DB_Euclidean',d,'.txt']);
        dsave(filename,table2struct(DB_Euclidean,'ToScalar',true));
        
        disp('--- Correlation & Euclidean Distances saved to Database Folder ---')
        disp(' ')
        
%Case 666: Terminate Script   
    case 666
        run_script = 0;
        
end %End of Operation/Action Switch
end %End of While Loop
disp('SCRIPT TERMINATED')