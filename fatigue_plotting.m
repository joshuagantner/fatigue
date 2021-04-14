% Fatigue | Approach 2 

run_script = 1;

% rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/database/'; % mac root
rootDir = 'D:/Joshua/fatigue/database'; % windows root

array_legend = ["d1 b1" "d1 b2" "d1 b3" "d1 b4" "d2 b1" "d2 b2" "d2 b3" "d2 b4"];

%% process EMG Data

%Display available operations
disp('Available operations:')
disp(' ')
disp('SETUP')
disp('  1 Load fatigue_corr&eucdist')
disp('  2 Load EMG_clean')
disp('  3 Load parameters')
disp('  4 Load missing trials')
disp(' ')
disp('actions old')
disp('  5 Create nanMean Group Arrays for Correlation & Euclidean Distance')
disp('  6 Plot Results')
disp('  7 Lineplots per Block')
disp('  8 Save Group Arrays')
disp(' ')
disp('actions new')
disp('   9 plot block')
disp('  10 plot trial')
disp(' ')
disp('* 666 Terminate Script *')

while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');
disp(' ')

switch action

%% SETUP

    case 1 %Load fatigue_corr&eucdist
        [file, path] = uigetfile(fullfile(rootDir,'*.*'),'What fatigue_corr&eucdist file should I load? ');
        fatigue_corr_eucdist_only = load(fullfile(path,file));
        
        disp('--- Load fatigue_corr&eucdist: completed ---')
       
    case 2 %Load EMG_clean
        [file, path] = uigetfile(fullfile(rootDir,'*.*'),'What EMG_clean file should I load? ');
        EMG_clean = load(fullfile(path, file));
        
        disp('--- Load EMG_clean: completed ---')
       
    case 3 %Load Parameters
        [file, path] = uigetfile(fullfile(rootDir,'*.*'),'What parameters tsv file should I load? ');
        Parameters = dload(fullfile(path,file));
        
        disp('--- Load parameters: completed ---')
       
    case 4 %Load Missing Trials
        [file, path] = uigetfile(fullfile(rootDir,'*.*'),'What Missing_Trials file should I load? ');
        Missing_Trials = dload(fullfile(path,file));
        
        missing_trials = [];

        for i = 1:length(Missing_Trials.ID)
            trial = [char(Missing_Trials.ID(i)),'.',num2str(Missing_Trials.day(i)),'.',char(Missing_Trials.BN(i)),'.',char(Missing_Trials.trial(i))];
            missing_trials = [missing_trials; string(trial)];
        end

        disp('--- Load missing trials: completed ---')

%% ACTIONS OLD
    case 5 %Create nanMean Group Arrays for Correlation & Euclidean Distance

        %Add Spearman Correlation & Euclidean Distance to Blocks & Days
        subjects = fields(fatigue_corr_eucdist_only.stnd_len);

        %label = 1
        CON_corr = [];
        CON_corr.ADM = [];
        CON_corr.APB = [];
        CON_corr.FDI = [];
        CON_corr.BIC = [];
        CON_corr.FCR = [];

        CON_eucdist = [];
        CON_eucdist.ADM = [];
        CON_eucdist.APB = [];
        CON_eucdist.FDI = [];
        CON_eucdist.BIC = [];
        CON_eucdist.FCR = [];

        CON_counter = 0;

        %label = 2
        FRD_corr = [];
        FRD_corr.ADM = [];
        FRD_corr.APB = [];
        FRD_corr.FDI = [];
        FRD_corr.BIC = [];
        FRD_corr.FCR = [];

        FRD_eucdist = [];
        FRD_eucdist.ADM = [];
        FRD_eucdist.APB = [];
        FRD_eucdist.FDI = [];
        FRD_eucdist.BIC = [];
        FRD_eucdist.FCR = [];

        FRD_counter = 0;

        %label = 3
        FSD_corr = [];
        FSD_corr.ADM = [];
        FSD_corr.APB = [];
        FSD_corr.FDI = [];
        FSD_corr.BIC = [];
        FSD_corr.FCR = [];

        FSD_eucdist = [];
        FSD_eucdist.ADM = [];
        FSD_eucdist.APB = [];
        FSD_eucdist.FDI = [];
        FSD_eucdist.BIC = [];
        FSD_eucdist.FCR = [];

        FSD_counter = 0;

        %Create nanMean Group Arrays for Correlation & Euclidean Distance
        for i = 1:length(subjects)

            %Find Group of Subject
            days = fields(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).parameters(1));
            blocks = fields(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).parameters(1).(char(days(1))));
            group = fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).parameters(1).(char(days(1))).(char(blocks(1))).label;

            %Calculate nanMean of Correlation & Euclidean Distance for all Leads
            nanMean_corr = [];
            nanMean_eucdist = [];

            nanMean_corr.ADM = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).corr_array.ADM);
            nanMean_corr.APB = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).corr_array.APB);
            nanMean_corr.FDI = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).corr_array.FDI);
            nanMean_corr.BIC = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).corr_array.BIC);
            nanMean_corr.FCR = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).corr_array.FCR);

            nanMean_eucdist.ADM = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).eucdist_array.ADM);
            nanMean_eucdist.APB = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).eucdist_array.APB);
            nanMean_eucdist.FDI = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).eucdist_array.FDI);
            nanMean_eucdist.BIC = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).eucdist_array.BIC);
            nanMean_eucdist.FCR = nanmean(fatigue_corr_eucdist_only.stnd_len.(char(subjects(i))).eucdist_array.FCR);


            %Add nanMeans to Group Total
            switch group
                case 1 %CON
                    CON_corr.ADM = [CON_corr.ADM; nanMean_corr.ADM];
                    CON_corr.APB = [CON_corr.APB; nanMean_corr.APB];
                    CON_corr.FDI = [CON_corr.FDI; nanMean_corr.FDI];
                    CON_corr.BIC = [CON_corr.BIC; nanMean_corr.BIC];
                    CON_corr.FCR = [CON_corr.FCR; nanMean_corr.FCR];

                    CON_eucdist.ADM = [CON_eucdist.ADM; nanMean_eucdist.ADM];
                    CON_eucdist.APB = [CON_eucdist.APB; nanMean_eucdist.APB];
                    CON_eucdist.FDI = [CON_eucdist.FDI; nanMean_eucdist.FDI];
                    CON_eucdist.BIC = [CON_eucdist.BIC; nanMean_eucdist.BIC];
                    CON_eucdist.FCR = [CON_eucdist.FCR; nanMean_eucdist.FCR];

                    CON_counter = CON_counter + 1;

                case 2 %FRD
                    FRD_corr.ADM = [FRD_corr.ADM; nanMean_corr.ADM];
                    FRD_corr.APB = [FRD_corr.APB; nanMean_corr.APB];
                    FRD_corr.FDI = [FRD_corr.FDI; nanMean_corr.FDI];
                    FRD_corr.BIC = [FRD_corr.BIC; nanMean_corr.BIC];
                    FRD_corr.FCR = [FRD_corr.FCR; nanMean_corr.FCR];

                    FRD_eucdist.ADM = [FRD_eucdist.ADM; nanMean_eucdist.ADM];
                    FRD_eucdist.APB = [FRD_eucdist.APB; nanMean_eucdist.APB];
                    FRD_eucdist.FDI = [FRD_eucdist.FDI; nanMean_eucdist.FDI];
                    FRD_eucdist.BIC = [FRD_eucdist.BIC; nanMean_eucdist.BIC];
                    FRD_eucdist.FCR = [FRD_eucdist.FCR; nanMean_eucdist.FCR];

                    FRD_counter = FRD_counter + 1;

                case 3 %FSD
                    FSD_corr.ADM = [FSD_corr.ADM; nanMean_corr.ADM];
                    FSD_corr.APB = [FSD_corr.APB; nanMean_corr.APB];
                    FSD_corr.FDI = [FSD_corr.FDI; nanMean_corr.FDI];
                    FSD_corr.BIC = [FSD_corr.BIC; nanMean_corr.BIC];
                    FSD_corr.FCR = [FSD_corr.FCR; nanMean_corr.FCR];

                    FSD_eucdist.ADM = [FSD_eucdist.ADM; nanMean_eucdist.ADM];
                    FSD_eucdist.APB = [FSD_eucdist.APB; nanMean_eucdist.APB];
                    FSD_eucdist.FDI = [FSD_eucdist.FDI; nanMean_eucdist.FDI];
                    FSD_eucdist.BIC = [FSD_eucdist.BIC; nanMean_eucdist.BIC];
                    FSD_eucdist.FCR = [FSD_eucdist.FCR; nanMean_eucdist.FCR];

                    FSD_counter = FSD_counter + 1;
            end


        end %End of Subject Itteration

        
        %Create fatigue_results
        fatigue_results = [];

        fatigue_results.CON.corr = CON_corr;
        fatigue_results.CON.eucdist = CON_eucdist;

        fatigue_results.FRD.corr = FRD_corr;
        fatigue_results.FRD.eucdist = FRD_eucdist;

        fatigue_results.FSD.corr = FSD_corr;
        fatigue_results.FSD.eucdist = FSD_eucdist;

        disp('--- Create nanMean Group Arrays for Correlation & Euclidean Distance: Completed ---')
  

%Case 4: Plot Results
    case 6
        % Get Input
        %Variable to plot
        disp('What variables would you like to plot?')
        plot_eucdist = input(' ??? Euclidean Distances (y/n): ','s');
        plot_corr = input(' ??? Spearman Correlations (y/n): ','s');
        disp(' ')
        
        vars2plot = [];
        
        if plot_eucdist == 'y'
            vars2plot = [vars2plot "eucdist"];
        end
    
        if plot_corr == 'y'
            vars2plot = [vars2plot "corr"];
        end
        
        %Kinds of Plots to be drawn
        disp('What kinds of plots would you like me to draw?')
        plot_boxplot = input(' ??? Boxplots (y/n): ','s');
        plot_datapoints = input(' ??? Data Points in Blocks (y/n): ','s');
        plot_exceltables = input(' ??? Excel Tables (y/n): ','s');
        disp(' ')
        
        plots2plot = [];
        
        if plot_boxplot == 'y'
            plots2plot = [plots2plot "boxplot"];
        end
        
        if plot_datapoints == 'y'
            plots2plot = [plots2plot "datapoints"];
        end
        
        if plot_exceltables == 'y'
            plots2plot = [plots2plot "excel"];
        end
        
        %Leads to be plotted
        disp('What leads would you like me to plot? (y/n)')
        plot_adm = input(' ??? ADM: ','s');
        plot_apb = input(' ??? APB: ','s');
        plot_fdi = input(' ??? FDI: ','s');
        plot_bic = input(' ??? BIC: ','s');
        plot_fcr = input(' ??? FCR: ','s');
        disp(' ')
        
        leads2plot = [];
        
        if plot_adm == 'y'
            leads2plot = [leads2plot "ADM"];
        end
        
        if plot_apb == 'y'
            leads2plot = [leads2plot "APB"];
        end
        
        if plot_fdi == 'y'
            leads2plot = [leads2plot "FDI"];
        end
        
        if plot_bic == 'y'
            leads2plot = [leads2plot "BIC"];
        end
        
        
        if plot_fcr == 'y'
            leads2plot = [leads2plot "FCR"];
        end
        
        %Create & Save Figures
        groups = ["CON" "FRD" "FSD"];
        
        folder_name = datestr(datetime);
        mkdir(fullfile(rootDir,'z results',folder_name));
        
        for i = groups
            for j = vars2plot
               for k = leads2plot
                   
                   data2plot = fatigue_results.(i).(j).(k);
                   
                   for l = plots2plot
                       
                       switch l
                           case 'datapoints'
                               
                               boxplot(data2plot)
                               title(strcat(k," ",j," ",i))
                               ylim([0 25])
                               xticklabels(array_legend)
                               
                               hold on
                               
                               for m = 1:8
                                   scatter(ones(length(data2plot),1)*m.*(1+(rand(size(data2plot(:,m)))-0.5)/10), data2plot(:,m),'r','filled')
                               end
                               
                               savefig(fullfile(rootDir,'z results',folder_name,strcat(l," ",k," ",j," ",i)))
                               hold off
                               close

                           case 'boxplot'
                               
                               boxplot(data2plot)
                               title(strcat(k," ",j," ",i))
                               ylim([0 25])
                               xticklabels(array_legend)

                               savefig(fullfile(rootDir,'z results',folder_name,strcat(l," ",k," ",j," ",i)))
                               close
                               
                           case 'excel'
                               lead_mean = nanmean(data2plot);
                               lead_std = nanstd(data2plot);
                               %lead_skill = 
                       end
                       
                   end
               end
            end
        end
        
        disp('--- Plot Results: completed ---')
  
    case 7 %Lineplots per Block
        
        %Leads to be plotted
        disp('What leads would you like me to plot? (y/n)')
        plot_adm = input(' ??? ADM: ','s');
        plot_apb = input(' ??? APB: ','s');
        plot_fdi = input(' ??? FDI: ','s');
        plot_bic = input(' ??? BIC: ','s');
        plot_fcr = input(' ??? FCR: ','s');
        disp(' ')
        
        leads2plot = [];
        
        if plot_adm == 'y'
            leads2plot = [leads2plot "ADM"];
        end
        
        if plot_apb == 'y'
            leads2plot = [leads2plot "APB"];
        end
        
        if plot_fdi == 'y'
            leads2plot = [leads2plot "FDI"];
        end
        
        if plot_bic == 'y'
            leads2plot = [leads2plot "BIC"];
        end
        
        
        if plot_fcr == 'y'
            leads2plot = [leads2plot "FCR"];
        end
        
        %Create Plots
        subj = fields(EMG_clean.stnd_len);
        folder_name = datestr(datetime);
        strrep(folder_name,':','-');
        warning('off', 'MATLAB:MKDIR:DirectoryExists');
        
        counter = 0;
        h = waitbar(0,['Creating Lineplots per Block ', num2str(counter*100),'%']);
        total = length(subj)*length(leads2plot)*2*4;

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
                    trials(strcmp('corr',trials)) = [];
                    trials(strcmp('eucdist',trials)) = [];
                    trials(strcmp('parameters',trials)) = [];
                    trials(strcmp('trial_mean',trials)) = [];
                    
                    

                    for m = 1:length(leads2plot) %Lead Itteration
                        
                        try
                            mkdir(fullfile(rootDir,'z results','Trial Line Plots',folder_name,char(leads2plot(m)),char(subj(i)),char(days(j))));
                        catch ME
                            
                        end
                           
                        figure('visible','off')
                        hold on
                        
                        for l = 1:length(trials) %Trial Itteration

                            plot(EMG_clean.stnd_len.(char(subj(i))).(char(days(j))).(char(blocks(k))).(char(trials(l))).(char(leads2plot(m))))

                        end %End of Trial Itteration

                        title([char(leads2plot(m)),' ',char(subj(i)),' ',char(days(j)),' ',char(blocks(k))])
                        savefig(fullfile(rootDir,'z results','Trial Line Plots',folder_name,char(leads2plot(m)),char(subj(i)),char(days(j)),char(blocks(k))));
                        figure('visible','on')
                        close
                        
                        counter = counter+1;
                        waitbar(counter/total,h,['Creating Lineplots per Block ', num2str(counter/total*100),'%']);
                        
                    end %End of Lead Itteration

                end %End of Block Itteration

            end %End of Day Itteration

        end %End of Subject Itteration
        
        figure('visible','on')
        close(h)
        disp('--- Lineplots per Block: completed ---')
   
    case 8 %Save Group Arrays
        file_date = datestr(datetime);
        save(fullfile(rootDir,['fatigue_group_arrays_',file_date]),'fatigue_results');
        
        disp('--- Save Group Arrays: completed ---')
        
%% ACTIONS NEW

    case 9 %plot block
        
    case 10 %plot trial
        
  
%% END OF SCRIPT      
    case 666 %Terminate Script
        run_script = 0;
        
end %End of Operation/Action Switch

end %End of While Loop
disp('—————————————')
disp('| SCRIPT TERMINATED |')
disp('—————————————')
disp(' ')