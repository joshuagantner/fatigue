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
disp(' 0  Load fatigue_alldat')
disp(' 1  Load Parameters')
disp(' 2  Load Mising Trial')
disp(' 3  Create fatigue_alldat')
disp(' 9  Save fatigue_alldat')
disp(' ')
disp(' PROCESSING')
disp(' 4  update status')
disp(' 5  process raw data')
disp(' 6  stnd4time')
disp(' 7  calculate mean trial per block')
disp(' 8  calculate variables')
disp(' ')
disp(' OUTPUT')
disp(' 10 save without emg')
disp(' 11 create pivot tables')
disp(' 12 plot trials')
disp(' 13 rmANOVA in SPSS by Subject')
disp(' 14 rmANOVA in SPSS by Trial')
disp(' 15 ttest')
disp(' ')
disp('terminate script with 666')
disp('clear workspace with 911')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')

%% process EMG Data
while run_script == 1
    
%Select Operation
disp(' ')
action = input('What would you like me to do? ');

switch action
%Case 0: Load fatigue_alldat
    case 0
        [f,p] = uigetfile(fullfile(rootDir,'*.mat*'),'Select the fatigue_alldat');
        
        time_start = now;
        fatigue_alldat = load(fullfile(p,f));
        
        disp('  -> fatigue_alldat loaded')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))
        
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
        total = length(Parameters.SessN)*30*5;

        %Create allDat of Procesed Cut Trial EMG Data based on Parameters File
        fatigue_alldat = [];
        leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
        LEADS = {'ADM' 'APB' 'FDI' 'BIC' 'FCR'};

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

                for k = 1:5
                    new_line = [];
                    
                    l = leads(k);
                    l = l{1,1};
                    L = LEADS(k);
                    L = L{1,1};

                    %Load the Trial File
                    file = strcat(id,'_EMG_d',num2str(day),'_b',num2str(block),'_t',num2str(j),'.txt');
                    D = dload(char(fullfile(p,folder,file)));

                    %Add EMG
                    new_line.raw = D.(L);

                    %Add Parameters
                    new_line.type = "trial";
                    new_line.lead = string(l);
                    new_line.exclude = "";
                    new_line.trial_number = j;

                    parameter_fields = fields(Parameters);
                    for m = 1:length(parameter_fields)
                        new_line.(char(parameter_fields(m))) = Parameters.(char(parameter_fields(m)))(i);
                    end

                    %Add Processed Trial to allDat 'EMG_clean'
                    fatigue_alldat = [fatigue_alldat new_line];
                    
                    %Update Progress bar
                    counter = counter+1;
                    waitbar(counter/total,h,['Processing Cut Trial EMG Data ', num2str(round(counter/total*100)),'%']);
                end

            end

        end %End of Paramtere Iteration
        
        fatigue_alldat = table2struct(struct2table(fatigue_alldat),'ToScalar',true);
        
        close(h);
        disp("  -> fatigue_alldat created")
        disp(strcat("     runtime: ", datestr(now - time_start,'HH:MM:SS')))
        
%Case 9: Save fatigue_alldat
    case 9
        [file, path] = uiputfile(fullfile(rootDir,'*.mat'));
        
        time_start = now;
        save(fullfile(path,file),'-struct','fatigue_alldat','-v7.3');
        
        disp('  -> fatigue_alldat saved')
        disp(strcat("     runtime ", datestr(now - time_start,'HH:MM')))
        
%Case 4: Update Status 
    case 4
        [f,p] = uigetfile(fullfile(rootDir,"*.csv"),"Select the status update file","status_update.csv");
        status_update = table2struct(readtable(fullfile(p,f)),'ToScalar',true);
        
        start_time = now;
        for i = 1:length(fatigue_alldat.SubjN)
            a = string(status_update.status(...
                        status_update.subjn == fatigue_alldat.SubjN(i)&...
                        status_update.day   == fatigue_alldat.day(i)&...
                        status_update.BN    == fatigue_alldat.BN(i)&...
                        (status_update.trial_number == fatigue_alldat.trial_number(i) | isnan(status_update.trial_number))  &...
                        status_update.lead  == fatigue_alldat.lead(i)...
                        ));
            if isempty(a)
                fatigue_alldat.exclude(i) = "FALSE";
            else
                fatigue_alldat.exclude(i) = a;
            end
        end
        disp("  -> Status updated")
        disp(" ")
        disp(strcat("     Total Trials excluded: ",num2str(sum(fatigue_alldat.exclude == "TRUE"))))
        disp("     compare total to excel to double check correct update ")
        
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

            if fatigue_alldat.exclude(i) == "TRUE"
                fatigue_alldat.proc(i,1) = {{}};
            else
                a = fatigue_alldat.raw(i);
                fatigue_alldat.proc(i,1) = {proc_std(a{1,1}, SRATE, freq_h, freq_l, ORDER)};
            end
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
        end
        disp("  -> Raw Data processed")
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
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

            if fatigue_alldat.exclude(i) == "TRUE"
                fatigue_alldat.stnd(i,1) = {{}};
            else
                a = fatigue_alldat.proc(i);
                fatigue_alldat.stnd(i,1) = {stnd4time(a{1,1}, LENGTH)};
            end
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Standardising for Time ', num2str(round(counter/total*100)),'%']);
        end
        disp("  -> Trials standardized for Time")
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
        close(h)
        
%Case 7: Calculate meanTrial per Block
    case 7
        
        mean_trials = [];
        
        blocks = unique([fatigue_alldat.SubjN fatigue_alldat.day fatigue_alldat.BN fatigue_alldat.lead],'rows');
        blocks = table2struct(cell2table([num2cell(arrayfun(@str2num,blocks(:,1:3))) num2cell(blocks(:,4))],'VariableNames',["subjn" "day" "BN" "lead"]),'ToScalar',true);
        
        %Create empty stuct
        for i = 1:length(blocks.subjn)

            leads = {'adm' 'apb' 'fdi' 'bic' 'fcr'};
            
            new_line = [];
            new_line.subjn  = blocks.subjn(i);
            new_line.day    = blocks.day(i);
            new_line.BN     = blocks.BN(i);
            new_line.lead   = blocks.lead(i);
            
            mean_trials = [mean_trials new_line];

        end
        mean_trials = table2struct(struct2table(mean_trials),'ToScalar',true);
            
        %Fill struct with means
        counter = 0;
        h = waitbar(0,'Calculating mean Trial per Block 0%');
        total = length(blocks.subjn);

        start_time = now;
        for i = 1:length(blocks.subjn)
            
            a = fatigue_alldat.stnd(fatigue_alldat.SubjN  == blocks.subjn(i) &...
                                    fatigue_alldat.day    == blocks.day(i) &...
                                    fatigue_alldat.BN     == blocks.BN(i) &...
                                    fatigue_alldat.lead   == blocks.lead(i) &...
                                    fatigue_alldat.exclude ~= "TRUE" ...
                                    );
                                
            a = a(~cellfun(@isempty,a));
            b = length(a);
            a = cellfun(@transpose,a,'UniformOutput',false);
            a = cell2mat(a);
            a = sum(a);
            a = {transpose(a/b)};

            mean_trials.mean(i,1) = a;
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Calculating mean Trial per Block ', num2str(round(counter/total*100)),'%']);
        end
        disp("  -> MeanTrials calculated")
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
        close(h)
        
%Case 8: Calculate Variables
    case 8
        %Add empty var columns
        vars    = {'dist' 'max' 'dist2zero' 'corr'};
        l       = length(fatigue_alldat.SubjN);
        for i = vars
            fatigue_alldat.(i{1,1}) = zeros(l,1);
        end
        
        %Calculate & fill var columns
        counter = 0;
        h = waitbar(0,['Calculating Variables ', num2str(counter*100),'%']);
        total = length(fatigue_alldat.SubjN);

        start_time = now;
        for i = 1:length(fatigue_alldat.SubjN)
                
            if fatigue_alldat.exclude(i) == "TRUE"
                %dist
                fatigue_alldat.dist(i) = nan;

                %max
                fatigue_alldat.max(i) = nan;

                %dist2zero
                fatigue_alldat.dist2zero(i) = nan;

                %correlation
                fatigue_alldat.corr(i) = nan;
            else
                %get trial_mean
                trial_mean = mean_trials.mean(mean_trials.subjn  == fatigue_alldat.SubjN(i) &...
                                              mean_trials.day    == fatigue_alldat.day(i) &...
                                              mean_trials.BN     == fatigue_alldat.BN(i) &...
                                              mean_trials.lead   == fatigue_alldat.lead(i)...
                                              );
                trial_mean = trial_mean{1};

                trial = fatigue_alldat.stnd(i);
                trial = trial{1,1};

                %dist
                a = dist([trial, trial_mean]);
                fatigue_alldat.dist(i) = a(1,2);

                %max
                fatigue_alldat.max(i) = max(trial);

                %dist2zero
                a = dist([trial, zeros(100000,1)]);
                fatigue_alldat.dist2zero(i) = a(1,2);

                %correlation
                a = corr([trial, trial_mean]);
                fatigue_alldat.corr(i) = a(1,2);
            end
            
            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Calculating Variables ', num2str(round(counter/total*100)),'%']);
        end
        disp("  -> Variables calculated")
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
        close(h)
        
%Case 10: save alldat without emg
    case 10
        export = [];
        
        alldat_fields = fields(fatigue_alldat);
        fields2remove = ["raw", "proc", "stnd"];
        
        start_time = now;
        for i = 1:length(alldat_fields)
            if ~ismember(fields2remove, alldat_fields(i))
                export.(char(alldat_fields(i))) = fatigue_alldat.(char(alldat_fields(i)));
            end    
        end
        disp('    export created, startin dsave')
        [f,p] = uiputfile(fullfile(rootDir,'*.tsv'),'Save alldat without emg');
        dsave(fullfile(p,f),export);
        disp('  -> fatigue_alldat saved without emg')
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
        
%Case 11: create pivot tables
    case 11
        p = uigetdir();
        
        % unique([fatigue_alldat.label fatigue_alldat.lead],'rows')
        groups  = ["CON" "FRD" "FSD"];
        leads   = ["adm" "apb" "fdi"];
        vars    = ["dist" "max"];
        ops     = ["max" "mean" "median" "var"];
        
        counter = 0;
        total = length(groups)*length(leads)*length(vars)*length(ops);
        h = waitbar(0,strcat("Saving Pivot Tables 0/", num2str(total)));
        
        start_time = now;
        for i = 1:3
            for j = leads
                for k = vars
                    for l = ops
                        
                        f = strcat("fatigue pivot - ", groups(i), "_", j, "_", k, "_", l,".csv");
                        
                        [FA,RA,CA]  =   pivottable(...
                                            fatigue_alldat.ID,...                       rows
                                            [fatigue_alldat.day fatigue_alldat.BN],...  columns
                                            fatigue_alldat.(k),...                      values
                                            (l),...                                     operation
                                            'subset',fatigue_alldat.label == i &...     filter
                                                     fatigue_alldat.lead  == j, ...     filter
                                            'datafilename', fullfile(p,f) ...           save option
                                        ); 
                                    
                        %Update Progress bar
                        counter = counter+1;
                        waitbar(counter/total,h,strcat("Saving Pivot Tables ",num2str(counter),"/", num2str(total)));
                    end
                end
            end
        end
        
        close(h)
        disp('  -> pivot tables saved')
        
%Case 12: plot trials
    case 12
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

                                data    = fatigue_alldat.stnd(...
                                                                fatigue_alldat.SubjN == subjn &...
                                                                fatigue_alldat.day   == day & ...
                                                                fatigue_alldat.BN    == block &...
                                                                fatigue_alldat.lead  == lead ...
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

                                data    = fatigue_alldat.stnd(...
                                                                fatigue_alldat.SubjN == subjn &...
                                                                fatigue_alldat.day == day & ...
                                                                fatigue_alldat.BN == block & ...
                                                                fatigue_alldat.trial_number == trial &...
                                                                fatigue_alldat.lead  == lead ...
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
                h = waitbar(0,'Plotting trials 0%');
                total = length(request.plot_type);

                for i = 1:length(request.plot_type)
                    if request.plot_type(i) == "B"
                        
                        subjn   = request.subjn(i);
                        day     = request.day(i);
                        block   = request.BN(i);
                        lead    = request.lead(i);
                        
                        data    = fatigue_alldat.stnd(...
                                                        fatigue_alldat.SubjN == subjn &...
                                                        fatigue_alldat.day   == day & ...
                                                        fatigue_alldat.BN    == block &...
                                                        fatigue_alldat.lead  == lead ...
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
                    waitbar(counter/total,h,['Plotting trials ', num2str(counter),'/',num2str(total)]);
                end
        end
        
        close()
        disp(' |- End of Plotting -|')
        
%Case 13: rmANOVA in SPSS by Subject
    case 13
        disp(' ')
        disp('Output options:')
        lead = input(' • Type (adm, apb, fdi, bic, fcr): ','s');
        operation = input(' • Operation (var, mean, median): ','s');
        
        S = tapply(fatigue_alldat,{'label','SubjN'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==1 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b1'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==2 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b2'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==3 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b3'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==4 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b4'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==1 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b1'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==2 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b2'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==3 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b3'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==4 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b4'}...
            ); % End of tapply
        
        [f,p] = uiputfile(fullfile(rootDir,'*.tsv'),'Where to save Data for rmANOVA...');
        dsave(fullfile(p,f),S)
        disp(['   -> ',f,' saved to ',p])
        
%Case 14: rmANOVA in SPSS by Trial
    case 14
        disp(' ')
        disp('Output options:')
        lead = input(' • Type (adm, apb, fdi, bic, fcr): ','s');
        operation = 'mean';
        
        S = tapply(fatigue_alldat,{'label','SubjN','trial_number'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==1 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b1'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==2 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b2'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==3 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b3'},...
             {'dist', operation, 'subset', fatigue_alldat.day==1 & fatigue_alldat.BN==4 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd1b4'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==1 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b1'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==2 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b2'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==3 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b3'},...
             {'dist', operation, 'subset', fatigue_alldat.day==2 & fatigue_alldat.BN==4 & fatigue_alldat.lead==lead & fatigue_alldat.exclude ~= "TRUE", 'name', 'd2b4'}...
            ); % End of tapply
        
        [f,p] = uiputfile(fullfile(rootDir,'*.tsv'),'Where to save Data for rmANOVA...');
        dsave(fullfile(p,f),S)
        disp(['   -> ',f,' saved to ',p])
        
%Case 15: ttest
    case 15
        disp(' ')
        input_type = input('  ttest manualy or upload request file? (m/f) ','s');
        
        switch input_type
            
        %manual plotting
            case "m"
                run = 1;
                n = 'n';

                while run == 1
                    
                    disp(' ')
                    disp(' Block A')
                    a_group   = input("  Group label: " );
                    a_day     = input("  Day: ");
                    a_block   = input("  Block: ");
                    a_lead    = input("  Lead (adm, apb, fdi, bic, fcr): ",'s');

                    disp(' Block B')
                    b_group   = input("  Group label: ");
                    b_day     = input("  Day: ");
                    b_block   = input("  Block: ");
                    b_lead    = input("  Lead (adm, apb, fdi, bic, fcr): ",'s');

                    a    = fatigue_alldat.dist(...
                                                    fatigue_alldat.label == a_group &...
                                                    fatigue_alldat.day   == a_day & ...
                                                    fatigue_alldat.BN    == a_block &...
                                                    fatigue_alldat.lead  == a_lead & ...
                                                    fatigue_alldat.exclude ~= "TRUE");
                    b    = fatigue_alldat.dist(...
                                                    fatigue_alldat.label == b_group &...
                                                    fatigue_alldat.day   == b_day & ...
                                                    fatigue_alldat.BN    == b_block &...
                                                    fatigue_alldat.lead  == b_lead & ...
                                                    fatigue_alldat.exclude ~= "TRUE");

                    disp(' ')
                    disp(strcat("TTest | G",num2str(a_group),"-d",num2str(a_day),"b",num2str(a_block),"-",a_lead," x G",num2str(b_group),"-d",num2str(b_day),"b",num2str(b_block),"-",b_lead))
                    ttest(a,b,2,'independent')
                    
                    disp(' ')
                    n = input(" next test or end? (n/e) ",'s');
                    if n == "e"
                        run = 0;
                    end
                    
                end
                
        %serial plotting based on file | file structure '.csv' [...]
            case "f"
                disp(' serial ttesting from request file has not been implemented yet')
%                 [f,p] = uigetfile(fullfile(rootDir,'*.csv'),'file of test requests','test_requests.csv');
%                 request = table2struct(readtable(fullfile(p,f)),'ToScalar',true);
%                 
%                 %Setup Progress bar
%                 counter = 0;
%                 h = waitbar(0,'TTest 0%');
%                 total = length(request.plot_type);
% 
%                 for i = 1:1 %length(request)
%                     
%                     %% MY CODE %%
%                     
%                     %Update Progress bar
%                     counter = counter+1;
%                     waitbar(counter/total,h,['Plotting trials ', num2str(counter),'/',num2str(total)]);
%                 end
%                 close(h)
        end
                   
%Case 666: Terminate Script   
    case 666
        run_script = 0;
        
%Case 911: Clear Workspace
    case 911
        clearvars -except action fatigue_alldat mean_trials Missing_Trials Parameters rootDir run_script status_update
        
end %End of Operation/Action Switch
end %End of While Loop
disp('SCRIPT TERMINATED')