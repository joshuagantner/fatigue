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
disp(' 1  Load Parameters')
disp(' 2  Load Mising Trial')
disp(' 3  Create fatigue_alldat')
disp(' ')
disp(' 4  Load fatigue_alldat')
disp(' 5  Save fatigue_alldat')
disp(' ')
disp(' 6  Outlier analysis')
disp(' 7  Plot EMGs')
disp(' ')
disp('terminate script with 666')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')

%% process EMG Data
while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');

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
        
%Case 3: Create fatigue_alldat
    case 3
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
        fatigue_alldat = [];

        time_start = now;

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

                new_line = [];

                %Load the Trial File
                file = strcat(id,'_EMG_d',num2str(day),'_b',num2str(block),'_t',num2str(j),'.txt');
                D = dload(char(fullfile(p,folder,file)));

                %Process each Lead
                new_line.type = "trial";
                new_line.EMG_ADM = proc_std(D.ADM, SRATE, freq_h, freq_l, ORDER);
                new_line.EMG_APB = proc_std(D.APB, SRATE, freq_h, freq_l, ORDER);
                new_line.EMG_FDI = proc_std(D.FDI, SRATE, freq_h, freq_l, ORDER);        
                new_line.EMG_BIC = proc_std(D.BIC, SRATE, freq_h, freq_l, ORDER);
                new_line.EMG_FCR = proc_std(D.FCR, SRATE, freq_h, freq_l, ORDER);
                new_line.trial_number = j;

                %Add Block Parameters
                parameter_fields = fields(Parameters);
                for k = 1:length(parameter_fields)
                    new_line.(char(parameter_fields(k))) = Parameters.(char(parameter_fields(k)))(i);
                end

                %Add Processed Trial to allDat 'EMG_clean'
                fatigue_alldat = [fatigue_alldat new_line];

                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total,h,['Processing Cut Trial EMG Data ', num2str(round(counter/total*100)),'%']);
            end

        end %End of Paramtere Iteration
        
        fatigue_alldat = table2struct(struct2table(fatigue_alldat),'ToScalar',true);

        close(h);
        disp('  -> fatigue_alldat created')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 4: Load fatigue_alldat        
    case 4
        [f,p] = uigetfile(fullfile(rootDir,'*.mat*'),'Select the fatigue_alldat');
        
        time_start = now;
        fatigue_alldat = load(fullfile(p,f));
        
        disp('  -> fatigue_alldat loaded')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 5: Save fatigue_alldat        
    case 5
        [file, path] = uiputfile(fullfile(rootDir,'*.mat'));
        
        time_start = now;
        save(fullfile(path,file),'-struct','fatigue_alldat','-v7.3');
        
        disp('  -> fatigue_alldat saved')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 6: Outlier analysis
    case 6
        outlier_analysis = [];
        S = [];
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Creating outlier analysis ', num2str(counter*100),'%']);
        total = length(Parameters.SessN)*30;
        
        time_start = now;
        
        for i = 1:length(fatigue_alldat.SubjN)
            
           outlier_analysis.ID(i,1)           = fatigue_alldat.ID(i);
           outlier_analysis.SubjN(i,1)        = fatigue_alldat.SubjN(i);
           outlier_analysis.label(i,1)        = fatigue_alldat.label(i);
           outlier_analysis.day(i,1)          = fatigue_alldat.day(i);
           outlier_analysis.BN(i,1)           = fatigue_alldat.BN(i);
           outlier_analysis.trial_number(i,1) = fatigue_alldat.trial_number(i);
           
           %ADM
           outlier_analysis.adm_auc(i,1)          = trapz(fatigue_alldat.EMG_ADM{i,1});
           outlier_analysis.adm_max(i,1)          = max(fatigue_alldat.EMG_ADM{i,1});
           outlier_analysis.adm_euc(i,1)          = max(fatigue_alldat.EMG_ADM{i,1});
           %APB
           outlier_analysis.apb_auc(i,1)          = trapz(fatigue_alldat.EMG_APB{i,1});
           outlier_analysis.apb_max(i,1)          = max(fatigue_alldat.EMG_APB{i,1});
           %FDI
           outlier_analysis.fdi_auc(i,1)          = trapz(fatigue_alldat.EMG_FDI{i,1});
           outlier_analysis.fdi_max(i,1)          = max(fatigue_alldat.EMG_FDI{i,1});
           %BIC
           outlier_analysis.bic_auc(i,1)          = trapz(fatigue_alldat.EMG_BIC{i,1});
           outlier_analysis.bic_max(i,1)          = max(fatigue_alldat.EMG_BIC{i,1});
           %FCR
           outlier_analysis.fcr_auc(i,1)          = trapz(fatigue_alldat.EMG_FRC{i,1});
           outlier_analysis.fcr_max(i,1)          = max(fatigue_alldat.EMG_FCR{i,1});

           %Update Progress bar
           counter = counter+1;
           waitbar(counter/total,h,['Creating outlier analysis ', num2str(round(counter/total*100)),'%']);
           
        end
 
        close(h);
        disp('  -> outlier_analysis created')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 7: Plot Trials
    case 7
        disp(' ')
        BorT = input('  Plot Block or Trial? (B/T) ','s');
        p = uigetdir(rootDir,'Where to save the plots…');
        run = 1;
        
        switch BorT
            
            case 'B'
                while run == 1
                    disp(' ')
                    subjn   = input("  Subject-Number or 'end': " ,'s');
                    if subjn == "end"
                        run = 0;
                    else
                        subjn   = str2double(subjn);
                        day     = input("  Day: ");
                        block   = input("  Block: ");
                        lead    = input("  Lead (ADM, APB, FDI, BIC, FCR): ",'s');
                        
                        data    = fatigue_alldat.(strcat('EMG_',lead))(...
                                                                        fatigue_alldat.SubjN == subjn &...
                                                                        fatigue_alldat.day == day & ...
                                                                        fatigue_alldat.BN == block...
                                                                       );
                        
                        for i = 1:length(test_data)
                            plot(data{i})
                            hold on
                        end  
                        figure_title = strcat('F',num2str(subjn+1),'-Day',num2str(day),'-Block ',num2str(block));
                        title(figure_title);
                        savefig(fullfile(p,figure_title));
                        hold off
                    end
                end
                
            case 'T'
                while run == 1
                    disp(' ')
                    subjn   = input("  Subject-Number or 'end': " ,'s');
                    if subjn == "end"
                        run = 0;
                    else
                        subjn   = str2double(subjn);
                        day     = input("  Day: ");
                        block   = input("  Block: ");
                        trial   = input("  Trial: ");
                        lead    = input("  Lead (ADM, APB, FDI, BIC, FCR): ",'s');
                        
                        data    = fatigue_alldat.(strcat('EMG_',lead))(...
                                                                        fatigue_alldat.SubjN == subjn &...
                                                                        fatigue_alldat.day == day & ...
                                                                        fatigue_alldat.BN == block & ...
                                                                        fatigue_alldat.trial_number == trial...
                                                                       );
                        plot(data{1})
                        figure_title = strcat('F',num2str(subjn+1),'-Day',num2str(day),'-Block ',num2str(block),'-Trial',num2str(trial));
                        title(figure_title);
                        savefig(fullfile(p,figure_title));
                    end
                end
        end
        close()
        disp(' |- End of Plotting -|')
            
%Case 666: Terminate Script   
    case 666
        run_script = 0;
        
end %End of Operation/Action Switch
end %End of While Loop
disp('SCRIPT TERMINATED')