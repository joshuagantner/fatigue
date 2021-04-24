% Fatigue | Approach 2 | v3 - Process EMG Data %

%% Setup
run_script = 1;
% rootDir    = '/Users/joshuagantner/Library/Mobile Documents/com~apple~CloudDocs/Files/Studium/2 Klinik/Masterarbeit/fatigue/database/'; % mac root
rootDir = '\\JOSHUAS-MACBOOK\smb fatigue\database'; % windows root

%% Code

%Display available operations
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
disp('Available operations:')
disp(' ')
disp(' SETUP')
disp(' 1  Load Parameters')
disp(' 2  Load Mising Trial')
disp(' 3  Create fatigue_alldat')
disp(' ')
disp(' PROCESSING')
disp(' 4  update status')
disp(' 5  process raw data')
disp(' 6  stnd4time')
disp(' 7  calculate mean trial per block')
disp(' 8  calculate variables')
disp(' ')
disp(' CLEANING')
disp(' ')
disp(' ')
disp(' SPSS STATISTICS')
disp(' ')
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

        %Setup Progress bar
        counter = 0;
        h = waitbar(0,'Processing Cut Trial EMG Data 0%');
        total = length(Parameters.SessN)*30;

        %Create allDat of Procesed Cut Trial EMG Data based on Parameters File
        fatigue_alldat = [];

        time_start = now;
        %create alldat
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
                new_line.adm_raw = D.ADM;
                new_line.apb_raw = D.APB;
                new_line.fdi_raw = D.FDI;
                new_line.bic_raw = D.BIC;
                new_line.fcr_raw = D.FCR;

                %Add Parameters
                new_line.type = "trial";
                new_line.exclude = {{}};
                new_line.trial_number = j;
                
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
        
%Case 4: Update Status | bool value, default true
    case 4
        [f,p] = uigetfile(fullfile(rootDir,"*.csv"),"Select the status update file","status_update.csv");
        status_update = table2struct(readtable(fullfile(p,f)),'ToScalar',true);
        
        for i = 1:length(fatigue_alldat.SubjN)
            fatigue_alldat.exclude(i) = {unique(status_update.lead(...
                                                status_update.subjn == fatigue_alldat.SubjN(i)&...
                                                status_update.day   == fatigue_alldat.day(i)&...
                                                status_update.BN    == fatigue_alldat.BN(i)&...
                                                status_update.trial_number == fatigue_alldat.trial_number(i)...
                                                ))};
        end
        
%Case 5: Process Raw Data
    case 5
        SRATE = 5000;
        freq_h = 10;
        freq_l = 6;
        ORDER = 4;
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Processing Raw Data ', num2str(counter*100),'%']);
        total = length(fatigue_alldat.SubjN);

        start_time = now;
        for i = 1:length(fatigue_alldat.SubjN)
            
            leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
            a = fatigue_alldat.exclude(i);
            a = a{1,1};
            if ~isempty(a)
                for j = 1:length(a)
                    leads(strcmpi(leads, a{j,1})) = [];
                end
            end
            
            for j = leads
                a = fatigue_alldat.(strcat(j,"_raw"))(i);
                fatigue_alldat.(strcat(j,"_proc"))(i,1) = {proc_std(a{1,1}, SRATE, freq_h, freq_l, ORDER)};
            end
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
        end
        disp(strcat("  -> completed | runtime: ",datestr(now-start_time,"MM:SS")))
        close(h)
        
%Cas 6: stnd4time
    case 6
        LENGTH = 100000;
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Standardising for Time ', num2str(counter*100),'%']);
        total = length(fatigue_alldat.SubjN);

        start_time = now;
        for i = 1:length(fatigue_alldat.SubjN)
            
            leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
            a = fatigue_alldat.exclude(i);
            a = a{1,1};
            if ~isempty(a)
                for j = 1:length(a)
                    leads(strcmpi(leads, a{j,1})) = [];
                end
            end
            
            for j = leads
                a = fatigue_alldat.(strcat(j,"_proc"))(i);
                fatigue_alldat.(strcat(j,"_stnd"))(i,1) = {stnd4time(a{1,1}, LENGTH)};
            end
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Standardising for Time ', num2str(round(counter/total*100)),'%']);
        end
        disp(strcat("  -> completed | runtime: ",datestr(now-start_time,"MM:SS")))
        close(h)
        
%Case 7: Calculate meanTrial per Block
    case 7
        
        blocks = unique([fatigue_alldat.SubjN fatigue_alldat.day fatigue_alldat.BN],'rows');
        mean_trials = [];
        
        %Create empty stuct
        
            %% MY CODE %%
            
        %Fill struct with means
        
            %% MY CODE %%
        
%%
%         %Setup Progress bar
%         counter = 0;
%         h = waitbar(0,['Calculating mean Trial per Block ', num2str(counter*100),'%']);
%         total = length(blocks);
% 
%         start_time = now;
%         for i = 1:length(blocks)
%             
%             leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
%             a = fatigue_alldat.exclude(i);
%             a = a{1,1};
%             if ~isempty(a)
%                 for j = 1:length(a)
%                     leads(strcmpi(leads, a{j,1})) = [];
%                 end
%             end
%             
%             new_line = [];
%             new_line.subjn  = blocks(i,1);
%             new_line.day    = blocks(i,2);
%             new_line.BN     = blocks(i,3);
%             
%             for j = leads
% 
%                 a = fatigue_alldat.(strcat(j,"_stnd"))(fatigue_alldat.SubjN  == blocks(i,1) &...
%                                                        fatigue_alldat.day    == blocks(i,2) &...
%                                                        fatigue_alldat.BN     == blocks(i,3));
%                 a = a(~cellfun(@isempty,a));
%                 b = length(a);
%                 a = cellfun(@transpose,a,'UniformOutput',false);
%                 a = cell2mat(a);
%                 a = sum(a);
%                 a = a/b;
%                                                                               
%                 new_line.(strcat(j,"_mean")) = a;
%             end
%             
%             mean_trials = [mean_trials new_line];
%             
%             %Update Progress bar
%             counter = counter+1;
%             waitbar(counter/total,h,['Calculating mean Trial per Block ', num2str(round(counter/total*100)),'%']);
%         end
%         disp(strcat("  -> completed | runtime: ",datestr(now-start_time,"MM:SS")))
%         close(h)
        
%% -----------------------------------------------------------------------------------------------------------------------------------------        
% %Setup Progress bar
%         counter = 0;
%         h = waitbar(0,['___________ ', num2str(counter*100),'%']);
%         total = length(fatigue_alldat.SubjN);
% 
%         start_time = now;
%         for i = 1:length(fatigue_alldat.SubjN)
%             
%             leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
%             a = fatigue_alldat.exclude(i);
%             a = a{1,1};
%             if ~isempty(a)
%                 for j = 1:length(a)
%                     leads(strcmpi(leads, a{j,1})) = [];
%                 end
%             end
%             
%             for j = leads
%
%                 %% MY CODE %%
%
%             end
%             
%             %Update Progress bar
%             counter = counter+1;
%             waitbar(counter/total,h,['___________ ', num2str(round(counter/total*100)),'%']);
%         end
%         disp(strcat("  -> completed | runtime: ",datestr(now-start_time,"MM:SS")))
%         close(h)
%% -----------------------------------------------------------------------------------------------------------------------------------------

%Case 3: Create fatigue_alldat
    case 33
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
        mean_trials = [];

        time_start = now;

        %create alldat
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
            
            new_mean = [];
            new_mean.adm_mean = zeros(LENGTH,1);
            new_mean.apb_mean = zeros(LENGTH,1);
            new_mean.fdi_mean = zeros(LENGTH,1);
            new_mean.bic_mean = zeros(LENGTH,1);
            new_mean.fcr_mean = zeros(LENGTH,1);
            num_trials = 0;

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
                
                new_line.adm_proc = proc_std(D.ADM, SRATE, freq_h, freq_l, ORDER);
                new_line.adm_stnd = stnd4time(new_line.adm_proc, LENGTH);
                new_mean.adm_mean = new_mean.adm_mean + new_line.adm_stnd;
                
                new_line.apb_proc = proc_std(D.APB, SRATE, freq_h, freq_l, ORDER);
                new_line.apb_stnd = stnd4time(new_line.apb_proc, LENGTH);
                new_mean.apb_mean = new_mean.apb_mean + new_line.apb_stnd;
                
                new_line.fdi_proc = proc_std(D.FDI, SRATE, freq_h, freq_l, ORDER);  
                new_line.fdi_stnd = stnd4time(new_line.fdi_proc, LENGTH);
                new_mean.fdi_mean = new_mean.fdi_mean + new_line.fdi_stnd;
                
                new_line.bic_proc = proc_std(D.BIC, SRATE, freq_h, freq_l, ORDER);
                new_line.bic_stnd = stnd4time(new_line.bic_proc, LENGTH);
                new_mean.bic_mean = new_mean.bic_mean + new_line.bic_stnd;
                
                new_line.fcr_proc = proc_std(D.FCR, SRATE, freq_h, freq_l, ORDER);
                new_line.fcr_stnd = stnd4time(new_line.fcr_proc, LENGTH);
                new_mean.fcr_mean = new_mean.fcr_mean + new_line.fcr_stnd;
                
                new_line.trial_number = j;

                %Add Block Parameters
                parameter_fields = fields(Parameters);
                for k = 1:length(parameter_fields)
                    new_line.(char(parameter_fields(k))) = Parameters.(char(parameter_fields(k)))(i);
                end

                %Add Processed Trial to allDat 'EMG_clean'
                fatigue_alldat = [fatigue_alldat new_line];
                num_trials = num_trials + 1;

                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total,h,['Processing Cut Trial EMG Data ', num2str(round(counter/total*100)),'%']);
            end
            
            %Calculate trial means
            new_mean.adm_mean = new_mean.adm_mean/num_trials;
            new_mean.apb_mean = new_mean.apb_mean/num_trials;
            new_mean.fdi_mean = new_mean.fdi_mean/num_trials;
            new_mean.bic_mean = new_mean.bic_mean/num_trials;
            new_mean.fcr_mean = new_mean.fcr_mean/num_trials;
            
            %Add Block Parameters to mean
            parameter_fields = fields(Parameters);
            for k = 1:length(parameter_fields)
                new_mean.(char(parameter_fields(k))) = Parameters.(char(parameter_fields(k)))(i);
            end

            %Add Means to allDat
            mean_trials = [mean_trials new_mean];

        end %End of Paramtere Iteration
        
        fatigue_alldat = table2struct(struct2table(fatigue_alldat),'ToScalar',true);
        mean_trials = table2struct(struct2table(mean_trials),'ToScalar',true);
        
        close(h);

        %% add euclidean distance & correlation
        
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Adding Distance & Correlation ', num2str(counter*100),'%']);
        total = length(fatigue_alldat.SubjN);
        
        z = zeros(LENGTH,1);
        for i = 1:length(fatigue_alldat.SubjN)
            subjn = fatigue_alldat.SubjN(i);
            day = fatigue_alldat.day(i);
            BN = fatigue_alldat.BN(i);
            
            %ADM
            a = fatigue_alldat.adm_stnd(i);
            b = mean_trials.adm_mean(mean_trials.SubjN == subjn & mean_trials.day == day & mean_trials.BN == BN);
            c = corr([a{1,1}, b{1,1}]);
            d = dist([a{1,1}, b{1,1}]);
            e = dist([a{1,1}, z]);
            fatigue_alldat.adm_corr(i,1) = c(1,2);
            fatigue_alldat.adm_dist(i,1) = d(1,2);
            fatigue_alldat.adm_dist2zero(i,1) = e(1,2);
            fatigue_alldat.adm_max(i,1) = max(a{1,1});
            
            %APB
            a = fatigue_alldat.apb_stnd(i);
            b = mean_trials.apb_mean(mean_trials.SubjN == subjn & mean_trials.day == day & mean_trials.BN == BN);
            c = corr([a{1,1}, b{1,1}]);
            d = dist([a{1,1}, b{1,1}]);
           	e = dist([a{1,1}, z]);
            fatigue_alldat.apb_corr(i,1) = c(1,2);
            fatigue_alldat.apb_dist(i,1) = d(1,2);
            fatigue_alldat.apb_dist2zero(i,1) = e(1,2);
            fatigue_alldat.apb_max(i,1) = max(a{1,1});
            
            %FDI
            a = fatigue_alldat.fdi_stnd(i);
            b = mean_trials.fdi_mean(mean_trials.SubjN == subjn & mean_trials.day == day & mean_trials.BN == BN);
            c = corr([a{1,1}, b{1,1}]);
            d = dist([a{1,1}, b{1,1}]);
            e = dist([a{1,1}, z]);
            fatigue_alldat.fdi_corr(i,1) = c(1,2);
            fatigue_alldat.fdi_dist(i,1) = d(1,2);
            fatigue_alldat.fdi_dist2zero(i,1) = e(1,2);
            fatigue_alldat.fdi_max(i,1) = max(a{1,1});
            
            %BIC
            a = fatigue_alldat.bic_stnd(i);
            b = mean_trials.bic_mean(mean_trials.SubjN == subjn & mean_trials.day == day & mean_trials.BN == BN);
            c = corr([a{1,1}, b{1,1}]);
            d = dist([a{1,1}, b{1,1}]);
            e = dist([a{1,1}, z]);
            fatigue_alldat.bic_corr(i,1) = c(1,2);
            fatigue_alldat.bic_dist(i,1) = d(1,2);
            fatigue_alldat.bic_dist2zero(i,1) = e(1,2);
            fatigue_alldat.bic_max(i,1) = max(a{1,1});
            
            %FCR
            a = fatigue_alldat.fcr_stnd(i);
            b = mean_trials.fcr_mean(mean_trials.SubjN == subjn & mean_trials.day == day & mean_trials.BN == BN);
            c = corr([a{1,1}, b{1,1}]);
            d = dist([a{1,1}, b{1,1}]);
            e = dist([a{1,1}, z]);
            fatigue_alldat.fcr_corr(i,1) = c(1,2);
            fatigue_alldat.fcr_dist(i,1) = d(1,2);
            fatigue_alldat.fcr_dist2zero(i,1) = e(1,2);
            fatigue_alldat.fcr_max(i,1) = max(a{1,1});
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Adding Distance & Correlation ', num2str(round(counter/total*100)),'%']);
        end
        
        close(h);
        disp('  -> fatigue_alldat created')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 4: Load fatigue_alldat        
    case 44
        [f,p] = uigetfile(fullfile(rootDir,'*.mat*'),'Select the fatigue_alldat');
        
        time_start = now;
        fatigue_alldat = load(fullfile(p,f));
        
        disp('  -> fatigue_alldat loaded')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 5: Save fatigue_alldat        
    case 55
        [file, path] = uiputfile(fullfile(rootDir,'*.mat'));
        
        time_start = now;
        save(fullfile(path,file),'-struct','fatigue_alldat','-v7.3');
        
        disp('  -> fatigue_alldat saved')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 6: Save alldat without EMG
    case 66
        
        export = [];
        
        alldat_fields = fields(fatigue_alldat);
        fields2remove = [...
            "adm_raw", "adm_proc", "adm_stnd",...
            "apb_raw", "apb_proc", "apb_stnd",...
            "fdi_raw", "fdi_proc", "fdi_stnd",...
            "bic_raw", "bic_proc", "bic_stnd",...
            "fcr_raw", "fcr_proc", "fcr_stnd"...
            ];
        
        for i = 1:length(alldat_fields)
            if ~ismember(fields2remove, alldat_fields(i))
                export.(char(alldat_fields(i))) = fatigue_alldat.(char(alldat_fields(i)));
            end    
        end
        
        [f,p] = uiputfile(fullfile(rootDir,'*.txt'),'Save outlier_analysis');
        dsave(fullfile(p,f),export);
        disp('  -> fatigue_alldat saved without emg')
        
%Case 7: Plot Trials
    case 77
        disp(' ')
        p = uigetdir(rootDir,'Where to save the plots…');
        input_type = input('  Creat plots manualy or upload file? (m/f) ','s');
        
        switch input_type
            
        %manual plotting
            case "m"
                
                BorT = input('  Plot Block or Trial? (B/T) ','s');
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
                                lead    = input("  Lead (adm, apb, fdi, bic, fcr): ",'s');

                                data    = fatigue_alldat.(strcat(lead,"_stnd"))(...
                                                                                fatigue_alldat.SubjN == subjn &...
                                                                                fatigue_alldat.day == day & ...
                                                                                fatigue_alldat.BN == block...
                                                                               );
                                leg = {};
                                f = figure;
                                f.Position(1:4) = [500 500 800 500];
                                hold on
                                for i = 1:length(data)
                                    plot(data{i})
                                    leg{end+1} = strcat('t',num2str(i));
                                end  
                                figure_title = strcat(char(unique(fatigue_alldat.ID(fatigue_alldat.SubjN == subjn)))," Day ",num2str(day)," Block ",num2str(block)," ",lead);
                                title(figure_title);
                                legend(leg);
                                savefig(fullfile(p,figure_title));
                                hold off
                                close(f);
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
                                lead    = input("  Lead (adm, apb, fdi, bic, fcr): ",'s');

                                data    = fatigue_alldat.(strcat(lead,"_stnd"))(...
                                                                                fatigue_alldat.SubjN == subjn &...
                                                                                fatigue_alldat.day == day & ...
                                                                                fatigue_alldat.BN == block & ...
                                                                                fatigue_alldat.trial_number == trial...
                                                                               );
                                plot(data{1})
                                figure_title = strcat(char(unique(fatigue_alldat.ID(fatigue_alldat.SubjN == subjn)))," Day ",num2str(day)," Block ",num2str(block)," Trial ",num2str(trial," ",lead));
                                title(figure_title);
                                savefig(fullfile(p,figure_title));
                            end
                        end
                end
                
        %serial plotting based on file | file structure '.csv' [plot_type(B,T), ID(string), day(int), BN(int), trial(int,'all'), lead(string)]
            case "f"
                [f,p] = uigetfile(fullfile(rootDir,'*.csv'),'file of plot requests','plot_requests.csv');
                request = table2struct(readtable(fullfile(p,f)),'ToScalar',true);
                
                %Setup Progress bar
                counter = 0;
                h = waitbar(0,['Adding Distance & Correlation ', num2str(counter*100),'%']);
                total = length(request.plot_type);

                for i = 1:length(request.plot_type)
                    if request.plot_type(i) == "B"
                        
                        subjn   = request.subjn(i);
                        day     = request.day(i);
                        block   = request.BN(i);
                        lead    = request.lead(i);
                        
                        data    = fatigue_alldat.(strcat(lead,"_stnd"))(...
                                                                                fatigue_alldat.SubjN == subjn &...
                                                                                fatigue_alldat.day == day & ...
                                                                                fatigue_alldat.BN == block...
                                                                               );
                        leg = {};
                        f = figure;
                        f.Position(1:4) = [500 500 800 500];
                        hold on
                        for i = 1:length(data)
                            plot(data{i})
                            leg{end+1} = strcat('t',num2str(i));
                        end  
                        figure_title = strcat(char(unique(fatigue_alldat.ID(fatigue_alldat.SubjN == subjn)))," Day ",num2str(day)," Block ",num2str(block)," ",lead);
                        title(figure_title);
                        legend(leg);
                        savefig(fullfile(p,figure_title));
                        hold off
                        close(f);
                        
                    elseif request.plot_type(i) == "T"
                        disp("plot trials from file has not been implemented yet")
                    else
                        disp(strcat("Unknown Plot_Type on line ",num2str(i)))
                    end
                    
                    %Update Progress bar
                    counter = counter+1;
                    waitbar(counter/total,h,['Adding Distance & Correlation ', num2str(counter),'/',num2str(total)]);
                end
        end
        
        close()
        disp(' |- End of Plotting -|')
        
%Case 8: extend alldat
    case 88
        %Setup Progress bar
        counter = 0;
        h = waitbar(0,['Extending fatigue_alldat ', num2str(counter*100),'%']);
        total = length(fatigue_alldat.SubjN);

        for i = 1:length(fatigue_alldat.SubjN)
            
%% Add length
%             a = fatigue_alldat.adm_proc(i);
%             fatigue_alldat.adm_len(i,1) = length(a{1,1});
%             a = fatigue_alldat.apb_proc(i);
%             fatigue_alldat.apb_len(i,1) = length(a{1,1});
%             a = fatigue_alldat.fdi_proc(i);
%             fatigue_alldat.fdi_len(i,1) = length(a{1,1});
%             a = fatigue_alldat.bic_proc(i);
%             fatigue_alldat.bic_len(i,1) = length(a{1,1});
%             a = fatigue_alldat.fcr_proc(i);
%             fatigue_alldat.fcr_len(i,1) = length(a{1,1});
            
            % % % % % % %
            % your code %
            % % % % % % %
            
           %Update Progress bar
           counter = counter+1;
           waitbar(counter/total,h,['Extending fatigue alldat ', num2str(round(counter/total*100)),'%']);
           
        end
 
        close(h);
        disp('  -> fatigue_alldat extended')
        
%Case 9: create all pivot tables
    case 99
        p = uigetdir(rootDir);
        
        groups  = ["CON" "FRD" "FSD"];
        leads   = ["adm" "apb" "fdi" "bic" "fcr"];
        vars    = ["dist" "max" "dist2zero" "corr" "len"];
        ops     = ["max" "mean" "median" "var"];
        
        counter = 0;
        h = waitbar(0,['Saving Pivot Tables ', num2str(counter*100),'%']);
        total = length(groups)*length(leads)*length(vars)*length(ops);
        
        for i = 1:3
            for j = leads
                for k = vars
                    for l = ops
                        
                        f = strcat("fatigue pivot - ", groups(i), "_", j, "_", k, "_", l,".csv");
                        
                        [FA,RA,CA]  =   pivottable(...
                                            fatigue_alldat.ID,...                       rows
                                            [fatigue_alldat.day fatigue_alldat.BN],...  columns
                                            fatigue_alldat.(strcat(j,'_',k)),...        values
                                            (l),...                                     operation
                                            'subset',fatigue_alldat.label == i,...     filter
                                            'datafilename', fullfile(p,f) ...                    save option
                                        ); 
                                    
                        %Update Progress bar
                        counter = counter+1;
                        waitbar(counter/total,h,['Saving Pivot Tables ', num2str(round(counter/total*100)),'%']);
                    end
                end
            end
        end
        
        close(h)
        disp('  -> pivot tables saved')
            
%Case 666: Terminate Script   
    case 666
        run_script = 0;
        
end %End of Operation/Action Switch
end %End of While Loop
disp('SCRIPT TERMINATED')