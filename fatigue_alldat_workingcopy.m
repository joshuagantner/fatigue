%% FATIGUE v7

%% setup
run_script = 1;

% set root directory
%rootDir    = '/Volumes/smb fatigue'; % mac root
%rootDir = '\\JOSHUAS-MACBOOK\smb fatigue\database'; % windows root network
%rootDir = 'F:\database'; %windows root hd over usb
%rootDir = '\\jmg\home\Drive\fatigue\database'; %windows root nas
rootDir = 'D:\Joshua\fatigue\database'; %windows root internal hd

% distances to calculate
distances_to_calc = {...
    "adm";...
    "fdi";...
    "apb";...
    "fcr";...
    "bic";...
    ["fdi" "apb"];...
    ["fdi" "apb" "adm"];...
    ["fcr" "bic"];...
    ["fdi" "apb" "adm" "fcr" "bic"]...
    };

% struct for regression models
lin_reg_models = [];

% supress warnings
warning('off','MATLAB:table:RowsAddedNewVars')

%% print legend to cml

%display available operations
operations_list = ... "––––––––––––––––––––––––––––––––––––––––––––––––––––\n"+...
"<strong>Available operations:</strong>\n"+...
"\n"+...
"setup\n"+...
"11  set root directory\n"+...
"12  load data\n"+...
"13  create fatigue_alldat\n"+...
"\n"+...
"processing\n"+...
"21  process raw alldat\n"+...
"22  calculate mean trial\n"+...
"23  calculate variables\n"+...
"\n"+...
"regression analysis\n"+...
"30  view model\n"+...
"31  compare 1-day models\n"+...
"32  compare 2-day models\n"+...
"34  plot regression models\n"+...
"35  reapply model\n"+...
"\n"+...
"36  view skill model\n"+...
"37  plot skill model\n"+...
"38  plot var // learning\n"+...
"\n"+...
"41  styling options\n"+...
"42  empty legend\n"+...
"43  plot skill measire\n"+...
"44  ttest\n"+...
"\n"+...
"output\n"+...
"51  save…\n"+...
"\n"+...
"\n"+...
"clear cml & display operations with 0\n"+...
"terminate script with 666\n"+...
"clear workspace with 911\n";

fprintf(operations_list);

%% master while loop
while run_script == 1
    
%Select Operation
disp(' ')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
action = input('What would you like me to do? ');
disp(' ')

switch action
    %% 
    case 11 % set root directory
        %%
        rootDir = uigetdir('','fatigue root directory');
        disp(' ')
        disp("  root directory set to '"+rootDir+"'")
        %% end Case 11: Set root directory

    case 12 % load data
        %%
        disp('1 alldat (w/wo emg data)')
        disp('2 parameters')
        disp('3 missing trials list')
        disp('4 load calc_variables')
        disp(' ')
        what_to_load = input('what to load: ');

        switch what_to_load
            case 1 %load alldat
                [f,p] = uigetfile(fullfile(rootDir,'*.mat'),'Select the fatigue_alldat');

                time_start = now;
                fatigue_alldat = load(fullfile(p,f));
                fatigue_alldat = fatigue_alldat.fatigue_alldat;

                disp('  -> fatigue_alldat loaded')
                disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))

            case 2 %load parameters
                [f,p] = uigetfile(fullfile(rootDir,'*.*'),'Select the Fatigue Parameter File (.tsv)');
                Parameters = dload(fullfile(p,f));
                disp('  -> Parameters loaded')

            case 3
                [f,p] = uigetfile(fullfile(rootDir,'*.*'),'Select the Missing Trials List (.tsv)');
                Missing_Trials = dload(fullfile(p,f));

                missing_trials = [];

                for i = 1:length(Missing_Trials.ID)
                    trial = [char(Missing_Trials.ID(i)),'.',num2str(Missing_Trials.day(i)),'.',char(Missing_Trials.BN(i)),'.',char(Missing_Trials.trial(i))];
                    missing_trials = [missing_trials; string(trial)];
                end
                disp('  -> Missing Trials loaded')

            case 4
                [f,p] = uigetfile(fullfile(rootDir,'*.*'),'Select calc_variables (.csv)');
                calc_variables = readtable(fullfile(p,f));
                % calc_variables.Properties.VariableNames = ["group" "subject" "day" "session" "trial" "time" transpose(cellfun(@strjoin, distances_to_calc))];

        end
        %% end Case 12: load data


    case 13 % create fatigue_alldat        
        %%
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
        %% end case 13 create alldat

    case 21 % process raw alldat
        %%
        disp('1 mark outliers')
        disp('2 filter & rectify raw emg')
        disp('3 standardize length/time')
        disp(' ')
        what_to_process = input('what to process: ');

        switch what_to_process
            case 1 % update inclusion status
                %%
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
                %% end subcase 1 update inclusion status

            case 2 % process included raw data
                %%
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
                %% end subcase 2 process raw data

            case 3 % standardize length/time
                %%
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
                %% end subcase 3 standardize length/time
        end % end
        %% case 21 process raw alldat

    case 22 % calculate mean trial
        %%
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
        
        %% end case 25 create mean trial table
        
    case 23 % calculate variables
        %%
        start_time = now;

      % setup table
        % get subtable from parameters
        calc_variables = unique([fatigue_alldat.label fatigue_alldat.SubjN fatigue_alldat.day fatigue_alldat.BN fatigue_alldat.trial_number],'rows');
        calc_variables = array2table (calc_variables,'VariableNames',["group" "subject" "day" "session" "trial"]);
        % create unified time column
        calc_variables_time = calc_variables.trial+(calc_variables.session-1)*30+(calc_variables.day-1)*120;
        calc_variables_time = array2table(calc_variables_time,'VariableNames',"time");
        % create columns for calculated variables
        calc_variables_addon = array2table(zeros([height(calc_variables) length(distances_to_calc)]),"VariableNames",cellfun(@strjoin, distances_to_calc));
        % combine tables
        calc_variables = [calc_variables calc_variables_time calc_variables_addon];

      % convert mean trials to table
        if ~istable(mean_trials)
            mean_trials = struct2table(mean_trials);
        end

      % convert alldat to table
        if ~istable(fatigue_alldat)
        fatigue_alldat = struct2table(fatigue_alldat); 
        end

      % set up progress bar
        counter = 0;
        h = waitbar(0,'Calculating Variables 0%');
        total = height(calc_variables);
        
      % for every row…
        for i=1:height(calc_variables)

            %   • get mean trial matrix
            mean_matrix = mean_trials(mean_trials.subjn  == calc_variables.subject(i) &...
                                      mean_trials.day    == calc_variables.day(i) &...
                                      mean_trials.BN     == calc_variables.session(i)...
                                    ,:); % end of mean_matrix getter

            %   • get trial matrix
            trial_matrix = fatigue_alldat(fatigue_alldat.SubjN        == calc_variables.subject(i) &...
                                          fatigue_alldat.day          == calc_variables.day(i) &...
                                          fatigue_alldat.BN           == calc_variables.session(i)&...
                                          fatigue_alldat.trial_number == calc_variables.trial(i)...
                                         ,["SubjN" "day" "BN" "trial_number" "lead" "stnd"]); % end of trial_matrix getter


            %rearrange matrices
            mean_matrix     = unstack(mean_matrix,"mean","lead");
            trial_matrix    = unstack(trial_matrix,"stnd","lead");

            %   • iterate distances to calculate
            for j=1:length(distances_to_calc)
                
                request = distances_to_calc{j};

                check = sum(cellfun(@sum, cellfun(@isnan, mean_matrix{:,request}, 'UniformOutput', false)));
                if check > 0
                    calc_variables(i,strjoin(request)) = {nan};
                    continue
                end

                request_mean = [mean_matrix{:,request}{:}];
                request_trial = [trial_matrix{:,request}{:}];
                
                if width(request_mean) ~= width(request_trial)
                    calc_variables(i,strjoin(request)) = {nan};
                    continue
                end

                result = Lpq_norm(2,1,request_trial-request_mean);

                calc_variables(i,strjoin(request)) = {result};
            end

            %Update Progress bar
            counter = counter+1;
            waitbar(counter/total,h,['Calculating Variables ', num2str(round(counter/total*100)),'%']);
        end

        % normalize distances for dimensions
        for i = 1:length(distances_to_calc)
            if length(distances_to_calc{i})>1
                calc_variables.(strjoin(distances_to_calc{i})+" normalized") = calc_variables{:,strjoin(distances_to_calc{i})}/length(distances_to_calc{i});
            end
        end

        close(h)
        disp("  -> Variables calculated")
        disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
        %% end case 25 calculate variables

    case 30 % view model
        %%
        %% input
        %  √ emg space
        %  √ group
        %  √ multiple or simple
        %  √ 1- or 2- day
        %   √ • which day
        % 

        % emg space selector
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
        end
        fprintf('\n')

        disp(' ')
        emg_space = input('emg space:  ')+6;
        emg_space = emg_spaces{emg_space};

        % other input
        group       = input('group:    ');
        multiple_yn = input('multiple: ','s');
        days_on_graph      = input('days:     ');

        if days_on_graph == 1
            day     = input('day:      ');
        else
            clear day
        end

        % get subset of calc_variables to be tested
        if days_on_graph == 1
            stencil = (calc_variables.group == group & calc_variables.day == day);
        else
            stencil = (calc_variables.group == group);
        end

        calc_variables_subset = calc_variables(stencil,:);

        % get observed values from calc_variables_subset
        dependant = calc_variables_subset(:, emg_space);
        dependant = table2array(dependant);

        % get regressors
        if multiple_yn == "n"
            regressors_names = "time";
        elseif days_on_graph == 2
            regressors_names = ["day" "session" "trial"];
        else
            regressors_names = ["session" "trial"];
        end

        regressors = calc_variables_subset(:, regressors_names);
        
%       NOT RELEVANT UNLESS COMPARING GROUPS
%         add binary dummy regressor
%         binary = array2table(calc_variables_subset.group == test_group & calc_variables_subset.day == test_day, 'VariableNames', "binary");
%         regressors = [regressors binary];
% 
%         % create intercept terms: dummy*regressor
%         intercep_terms =    table(...
%                                     regressors{:,"binary"}.*regressors{:,"session"},...
%                                     regressors{:,"binary"}.*regressors{:,"trial"},...
%                                     'VariableNames', ["binary*session" "binary*trial"]...
%                                   ); % end of dummy*regressor creator
% 
%         % add intercept terms to regressors
%         regressors = [regressors intercep_terms];

        regressors_names = regressors.Properties.VariableNames;
        regressors = table2array(regressors);
        mdlr = fitlm(regressors,dependant,'RobustOpts','on');

        %%
        %output
        if days_on_graph == 2
            output_heading_days = " Both Days";
        else
            output_heading_days = " Day "+string(day);
        end
        
        disp(' ')
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        fprintf("<strong>Robust Multiple Linear Regression Model | Group "+string(group)+output_heading_days+"</strong>")
        disp(' ')
        disp("dependant:  "+emg_space)
        disp("regressors: " + strjoin(regressors_names+", "))
        disp(' ')
        %disp(coefficient_interpretation)
        disp(mdlr)
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        %%

    case 31 % compare 1-day models
        %
        % Model
        %
        %     y =	int +	x1*session +	x2*trial +	x3*gX_binary +	x4*gX_binary*session +	x5*gX_binary*trial
        %
        %
        % Interpretation of Coefficients
        %
        % 	             group A  |  group X vs group A
        %   ––––––––––––––––––––––––––––––––––––––––––––
        %   intercept |	intercept |	    x3
        %   session	  |    x1	  |     x4
        %   trial	  |    x2	  |     x5
        %

        %%
        coefficient_interpretation = table(["intercept"; "x1"; "x2"], ["x3"; "x4"; "x5"], ["intercept + x3"; "x1 + x4"; "x2 + x5"],'RowNames',["intercept" "session" "trial"]);

        % emg space selector
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
        end
        fprintf('\n')

        disp(' ')
        emg_space = input('emg space:  ')+6;
        emg_space = emg_spaces{emg_space};

        % other input
        disp('base')
        base_group = input(' • group: ');
        base_day   = input(' • day:   ');
        disp('test')
        test_group = input(' • group: ');
        test_day   = input(' • day:   ');

        % get subset of calc_variables to be tested
        calc_variables_subset = calc_variables( ...
                                    ... get rows according to input
                                    (calc_variables.group == base_group & calc_variables.day == base_day)| ...for base group
                                    (calc_variables.group == test_group & calc_variables.day == test_day), ...for test group
                                    ... get all columns
                                    :);

        % get observed values from calc_variables_subset
        dependant = calc_variables_subset(:, emg_space);
        dependant = table2array(dependant);

        % get regressors
        regressors = calc_variables_subset(:, ["session" "trial"]);

        % add binary dummy regressor
        binary = array2table(calc_variables_subset.group == test_group & calc_variables_subset.day == test_day, 'VariableNames', "binary");
        regressors = [regressors binary];

        % create intercept terms: dummy*regressor
        intercep_terms =    table(...
                                    regressors{:,"binary"}.*regressors{:,"session"},...
                                    regressors{:,"binary"}.*regressors{:,"trial"},...
                                    'VariableNames', ["binary*session" "binary*trial"]...
                                  ); % end of dummy*regressor creator

        % add intercept terms to regressors
        regressors = [regressors intercep_terms];
        regressors_names = regressors.Properties.VariableNames;

        regressors = table2array(regressors);

        % fit a robust linear regression model
        mdlr = fitlm(regressors,dependant,'RobustOpts','on');

        %output
        coefficient_interpretation.Properties.VariableNames = ["G"+base_group+"d"+base_day "G"+test_group+"d"+test_day+" vs G"+base_group+"d"+base_day "G"+test_group+"d"+test_day];
        disp(' ')
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        fprintf("<strong>RMLR - Group "+string(test_group)+" day "+string(test_day)+" vs Group "+string(base_group)+" day "+string(base_day)+"</strong>")
        disp(' ')
        disp("dependant:  "+emg_space)
        disp("regressors: " + strjoin(regressors_names+", "))
        disp(' ')
        disp(coefficient_interpretation)
        disp(mdlr)
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        %%
    
    case 32 % compare 2-day models
        %
        % Model
        %
        %     y =	int +	x1*day +	x2*session +	x3*trial +	x4*gX_binary +	x5*gX_binary*day +	x6*gX_binary*session +	x7*gX_binary*trial
        %
        %
        % Interpretation of Coefficients
        %
        % 	             group A  |  group X vs group A
        %   ––––––––––––––––––––––––––––––––––––––––––––
        %   intercept |	intercept |	    x4
        %   day	      |    x1	  |     x5
        %   session	  |    x2	  |     x6
        %   trial	  |    x3	  |     x7
        %

        %%
        coefficient_interpretation = table(["intercept"; "x1"; "x2"; "x3"], ["x4"; "x5"; "x6"; "x7"],'RowNames',["intercept" "day" "session" "trial"]);

        % emg space selector
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp("available emg spaces")
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            disp("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars))
        end

        disp(' ')
        emg_space = input('emg space:   ')+6;
        emg_space = emg_spaces{emg_space};
        base_group = input('base group: ');
        test_group = input('test group: ');

        % deduce excluded_group
        if base_group + test_group == 3
            excluded_group = 3;
        elseif base_group + test_group == 4
            excluded_group = 2;
        else 
            excluded_group = 1;
        end

        % get observed values from calc_variables
        dependant = calc_variables(calc_variables.group ~= excluded_group, emg_space);
        dependant = table2array(dependant);

        % get regressors
        regressors = calc_variables(calc_variables.group ~= excluded_group, ["day" "session" "trial"]);

        % add binary dummy regressor
        binary = array2table(calc_variables{calc_variables.group ~= excluded_group, "group"} == test_group, 'VariableNames', "binary");
        regressors = [regressors binary];
        
        % create intercept terms: dummy*regressor
        intercep_terms =    table(...
                                    regressors{:,"binary"}.*regressors{:,"day"},...
                                    regressors{:,"binary"}.*regressors{:,"session"},...
                                    regressors{:,"binary"}.*regressors{:,"trial"},...
                                    'VariableNames', ["binary*day" "binary*session" "binary*trial"]...
                                  ); % end of dummy*regressor creator

        % add intercept terms to regressors
        regressors = [regressors intercep_terms];

        regressors_names = regressors.Properties.VariableNames;
        regressors = table2array(regressors);

        % fit a robust linear regression model
        mdlr = fitlm(regressors,dependant,'RobustOpts','on');

        %output
        coefficient_interpretation.Properties.VariableNames = ["Group "+base_group "Group "+test_group+" vs "+base_group];
        disp(' ')
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        fprintf("<strong>RMLR - Group "+string(test_group)+" vs "+string(base_group)+"</strong>")
        disp(' ')
        disp("dependant:  "+emg_space)
        disp("regressors: " + strjoin(regressors_names+", "))
        disp(' ')
        disp(coefficient_interpretation)
        disp(mdlr)
        disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
        %%

    case 34 % plot regression models
        %%
        fprintf("<strong>creating regression plot</strong>\n")
        %% input
        % n_days
        days_on_graph = input('n_days: ');

        if days_on_graph == 1
            day = input('day:   ');
        else
            day = nan;
        end

        line_width = 2;

        legend_labels = [];
        legend_labels_plot1 = [];
        legend_labels_plot2 = [];
        individual_legends = false;

        y_dimensions = [];

        %% scaffold
        t = tiledlayout(1,days_on_graph,'TileSpacing','Compact');
        title(t,'Robust Multiple Linear Regression of Variability')

        % Tile 1 - training sessions
        if day == 1 || days_on_graph == 2
            nexttile
            emptyplot = plot(NaN,NaN,'b','Linewidth',line_width);
            set(gca,'box','off')
            set(gca,'XLim',[1 120],'XTick',15:30:105)
            xticklabels(["T1", "T2", "T3", "T4"])
            xlabel("session")
            ylabel("variability")
        end

        % Tile 2 - control sessions
        if day == 2 || days_on_graph == 2
            nexttile
            emptyplot2 = plot(NaN,NaN,'g','Linewidth',line_width);
            set(gca,'box','off')

            if days_on_graph == 1
                set(gca,'XLim',[1 120],'XTick',15:30:105)
            else
                set(gca,'XLim',[121 240],'XTick',135:30:225)
            end

            xticklabels(["C1", "C2", "C3", "C4"])
            xlabel("session")
            if day ~= 2
                ax1 = gca;                   % gca = get current axis
                ax1.YAxis.Visible = 'off';   % remove y-axis
            end
        end

        % Tile 3 - indifferent sessions
        if day == 3
            nexttile
            emptyplot = plot(NaN,NaN,'g','Linewidth',line_width);
            xlim([121 240])
            set(gca,'box','off')
            set(gca,'XLim',[1 120],'XTick',15:30:105)
            xticklabels(["1", "2", "3", "4"])
            xlabel("session")
            ylabel("variability")
        end

        %% loop plot models

        % show available emg spaces
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp(' ')
        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
        end
        fprintf('\n')

        disp(' ')
        disp(' ––––––––––––––––––––')
        plotting = input('  Plot a model? ','s');

        if plotting == 'y'
            plot_loop_state = 1;
            plot_counter = 0;
        end
        %%

        while plot_loop_state == 1

            plot_counter = plot_counter+1;

            %% generate model to plot
            %  √ emg space
            %  √ group
            %  √ multiple or simple
            %  √ 1- or 2- day
            %   √ • which day
            %

            % emg space selector
            disp(' ')
            emg_space   = input('  emg space: ')+6;
            emg_space = emg_spaces{emg_space};

            % other input
            group       = input('  group:     ');
            multiple_yn = input('  multiple:  ','s');
            days_in_model      = input('  days:      ');

            if days_in_model == 2
                clear day
            else %if day == 3
                day = input('  day:   ');
            end

            % get subset of calc_variables to be tested
            if days_in_model == 1
                stencil = (calc_variables.group == group & calc_variables.day == day);
            else
                stencil = (calc_variables.group == group);
            end

            calc_variables_subset = calc_variables(stencil,:);

            % get observed values from calc_variables_subset
            dependant = calc_variables_subset(:, emg_space);
            dependant = table2array(dependant);

            % get regressors
            if multiple_yn == "n"
                regressors_names = "time";
            elseif days_in_model == 2
                regressors_names = ["day" "session" "trial"];
            else
                regressors_names = ["session" "trial"];
            end

            regressors = calc_variables_subset(:, regressors_names);

            regressors_names = regressors.Properties.VariableNames;
            regressors = table2array(regressors);

            % create model
            mdlr = fitlm(regressors,dependant,'RobustOpts','on');

            %% reapply model
            if multiple_yn == 'n'
                intercept   = mdlr.Coefficients{1,1};
                effect      = mdlr.Coefficients{2,1};

                if days_in_model == 2
                    time_scaffold = 1:240;
                else
                    time_scaffold = transpose((1:120)+120*(day-1));
                end

                reapplied_model = intercept + effect*time_scaffold(:,1);

            elseif days_in_model == 2
                intercept       = mdlr.Coefficients{1,1};
                effect_day      = mdlr.Coefficients{2,1};
                effect_session  = mdlr.Coefficients{3,1};
                effect_trial    = mdlr.Coefficients{4,1};

                time_scaffold = [...
                    [ones([120,1]);ones([120,1])*2],... create day column
                    repmat([ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],[2 1]),... create session column
                    repmat(transpose(1:30),[8 1])... create trial column
                    ];

                reapplied_model = intercept + effect_day*time_scaffold(:,1) + effect_session*time_scaffold(:,2) + effect_trial*time_scaffold(:,3);
            else
                intercept       = mdlr.Coefficients{1,1};
                effect_session  = mdlr.Coefficients{2,1};
                effect_trial    = mdlr.Coefficients{3,1};

                time_scaffold = [...
                    [ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],... create session column
                    repmat(transpose(1:30),[4 1])... create trial column
                    ];

                reapplied_model = intercept + effect_session*time_scaffold(:,1) + effect_trial*time_scaffold(:,2);
            end

            %% plot reapplied model
            % asemble legend
            if multiple_yn == 'y'
                complexity = 'multiple';
            else
                complexity = 'simple';
            end

            % assemble legend
            if days_on_graph == 2 
                if days_in_model == 2
                    legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
                    legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
                else
                    if day == 1
                        legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
                        individual_legends = true;
                    else
                        legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
                        individual_legends = true;
                    end
                end
            else
                if day == 3
                    legend_labels = [legend_labels "G"+string(group)+"d"+string(day)+" "+emg_space+" "+complexity];
                else
                    legend_labels = [legend_labels "G"+string(group)+" "+emg_space+" "+complexity];
                end
            end

            % plot to tile
            if days_on_graph == 1
                %...in a 1 tile figure
                nexttile(1)
                hold on
                plot(reapplied_model,'Linewidth',line_width)
                if plot_counter == 1
                    delete(emptyplot)
                end
                legend(legend_labels,'Location','southoutside')
                hold off
                drawnow()

            else
                %...in a 2 tile figure

                if plot_counter == 1
                    hold on
                    nexttile(1)
                    delete(emptyplot)
                    hold off

                    hold on
                    nexttile(2)
                    delete(emptyplot2)
                    hold off
                end

                if days_in_model == 2 % plot 2 day model in 2 day figure
                    nexttile(1)
                    hold on
                    plot(reapplied_model,'Linewidth',line_width)
%                     if plot_counter == 1
%                         delete(emptyplot)
%                     end
                    
                    if individual_legends
                        legend(legend_labels_plot1,'Location','southoutside')
                    end
                    hold off

                    nexttile(2)
                    hold on
                    plot(reapplied_model,'Linewidth',line_width)
%                     if plot_counter == 1
%                         delete(emptyplot)
%                     end
                    legend(legend_labels_plot2,'Location','southoutside')
                    hold off

                else % plot 1 day model in 2 day figure
%                     if plot_counter == 1
%                         hold on
%                         nexttile(1)
%                         delete(emptyplot)
%                         nexttile(2)
%                         delete(emptyplot)
%                         hold off
%                     end

                    nexttile(day)
                    hold on

                    if day == 2
                        reapplied_model = [nan([120 1]); reapplied_model];
                    end

                    plot(reapplied_model,'Linewidth',line_width)

                    if day == 1 && individual_legends
                        legend(legend_labels_plot1,'Location','southoutside')
                    end

                    if day == 2
                        legend(legend_labels_plot2,'Location','southoutside')
                    end
                    hold off
                end

                drawnow()
                y_dimensions = [y_dimensions max(reapplied_model) min(reapplied_model)];
            end

            %% plot model query
            disp(' ')
            disp(' ––––––––––––––––––––')
            plotting = input('  Plot a model? ','s');
            if plotting == 'n'
                plot_loop_state = 0;
            end

            %% sync y limits in 2 tile figure
            if days_on_graph == 2
                y_max = ceil(max(y_dimensions));
                y_min = floor(min(y_dimensions));

                nexttile(1)
                ylim([y_min y_max])

                nexttile(2)
                ylim([y_min y_max])

                drawnow()
                disp('  y axis synced √')
            end
        end
        drawnow() % redundancy drawnow()
        %%

    case 35 % reapply model
        %%
        %% fit model
        % emg space selector
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
        end
        fprintf('\n')

        disp(' ')
        emg_space = input('emg space:  ')+6;
        emg_space = emg_spaces{emg_space};

        % other input
        group       = input('group:    ');
        multiple_yn = input('multiple: ','s');
        days_in_model      = input('days:     ');

        if days_in_model == 1
            day     = input('day:      ');
        else
            clear day
        end

        % get subset of calc_variables to be tested
        if days_in_model == 1
            stencil = (calc_variables.group == group & calc_variables.day == day);
        else
            stencil = (calc_variables.group == group);
        end

        calc_variables_subset = calc_variables(stencil,:);

        % get observed values from calc_variables_subset
        dependant = calc_variables_subset(:, emg_space);
        dependant = table2array(dependant);

        % get regressors
        if multiple_yn == "n"
            regressors_names = "time";
        elseif days_in_model == 2
            regressors_names = ["day" "session" "trial"];
        else
            regressors_names = ["session" "trial"];
        end

        regressors = calc_variables_subset(:, regressors_names);
        regressors_names = regressors.Properties.VariableNames;
        regressors = table2array(regressors);

        mdlr = fitlm(regressors,dependant,'RobustOpts','on');

        %% reapply model
        if multiple_yn == 'n'
                intercept   = mdlr.Coefficients{1,1};
                effect      = mdlr.Coefficients{2,1};

                if days_in_model == 2
                    time_scaffold = 1:240;
                else
                    time_scaffold = transpose((1:120)+120*(day-1));
                end

                reapplied_model = intercept + effect*time_scaffold(:,1);

            elseif days_in_model == 2
                intercept       = mdlr.Coefficients{1,1};
                effect_day      = mdlr.Coefficients{2,1};
                effect_session  = mdlr.Coefficients{3,1};
                effect_trial    = mdlr.Coefficients{4,1};

                time_scaffold = [...
                    [ones([120,1]);ones([120,1])*2],... create day column
                    repmat([ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],[2 1]),... create session column
                    repmat(transpose(1:30),[8 1])... create trial column
                    ];

                reapplied_model = intercept + effect_day*time_scaffold(:,1) + effect_session*time_scaffold(:,2) + effect_trial*time_scaffold(:,3);
            else
                intercept       = mdlr.Coefficients{1,1};
                effect_session  = mdlr.Coefficients{2,1};
                effect_trial    = mdlr.Coefficients{3,1};

                time_scaffold = [...
                    [ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],... create session column
                    repmat(transpose(1:30),[4 1])... create trial column
                    ];

                reapplied_model = intercept + effect_session*time_scaffold(:,1) + effect_trial*time_scaffold(:,2);
        end

        disp('reapplied model:')
        disp('  - start: '+string(reapplied_model(1)))
        disp('  - end:   '+string(reapplied_model(end)))
        disp('  - max:   '+string(max(reapplied_model)))
        disp('  - min:   '+string(min(reapplied_model)))
        %%

    case 36 % view model for skill
        %%
        %input
        disp(' ')
        disp(' Regression Model of Skill')
        disp(' ')
        group = input('  group:   ');
        day   = input('  day:     ');
        disp(' ')

        % get subset of calc_variables to be tested
        parameters = struct2table(Parameters);

        stencil = (parameters.label == group & parameters.day == day);
        dependant = table2array(parameters(stencil,'skillp'));
        regressor = table2array(parameters(stencil,'BN'));

        %plot(regressor, dependant)

        % fit model
        mdlr = fitlm(regressor,dependant,'RobustOpts','on')
        plot(mdlr)

        %%

    case 37 % plot skill model
        %%
        fprintf("<strong>creating regression plot</strong>\n")
        %% input
        % n_days
        days_on_graph = input('n_days: ');

        if days_on_graph == 1
            day = input('day:   ');
        else
            day = nan;
        end

        line_width = 2;

        legend_labels = [];
        legend_labels_plot1 = [];
        legend_labels_plot2 = [];
        individual_legends = false;

        y_dimensions = [];

        %% scaffold
        t = tiledlayout(1,days_on_graph,'TileSpacing','Compact');
        title(t,'Learning Rate')

        % Tile 1 - training sessions
        if day == 1 || days_on_graph == 2
            nexttile
            emptyplot = plot(NaN,NaN,'b','Linewidth',line_width);
            set(gca,'box','off')
            set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
            xticklabels(["T1", "T2", "T3", "T4"])
            xlabel("session")
            ylabel("skill")
        end

        % Tile 2 - control sessions
        if day == 2 || days_on_graph == 2
            nexttile
            emptyplot2 = plot(NaN,NaN,'g','Linewidth',line_width); % changed emptyplot2 to emptyplot
            set(gca,'box','off')
            set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
            xticklabels(["C1", "C2", "C3", "C4"])
            xlabel("session")
            if day ~= 2
                ax1 = gca;                   % gca = get current axis
                ax1.YAxis.Visible = 'off';   % remove y-axis
            end
        end

        % Tile 3 - indifferent sessions
        if day == 3
            nexttile
            emptyplot = plot(NaN,NaN,'g','Linewidth',line_width);
            set(gca,'box','off')
            set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
            xticklabels(["1", "2", "3", "4"])
            xlabel("session")
            ylabel("skill")
        end

        %% loop plot models
        disp(' ')
        plotting = input('  Plot a model? ','s');

        if plotting == 'y'
            plot_loop_state = 1;
            plot_counter = 0;
        end


        while plot_loop_state == 1

            plot_counter = plot_counter+1;

            %% generate model to plot
            %input
            disp(' ')
            group = input('  group:   ');
            day   = input('  day:     ');
            disp(' ')

            
            % get subset of calc_variables to be tested
            parameters = struct2table(Parameters);

            stencil = (parameters.label == group & parameters.day == day);
            dependant = table2array(parameters(stencil,'skillp'));
            regressor = table2array(parameters(stencil,'BN'));

            % create model
            mdlr = fitlm(regressor,dependant,'RobustOpts','on');

            %% reapply model
            intercept   = mdlr.Coefficients{1,1};
            effect      = mdlr.Coefficients{2,1};

            time_scaffold = 1:4; % transpose(1:4);

            reapplied_model = intercept + effect*time_scaffold; % reapplied_model = intercept + effect*time_scaffold(:,1);


            %% plot reapplied model
            % assemble legend
            if days_on_graph == 2 
                if day == 1
                    legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)];
                    individual_legends = true;
                else
                    legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)];
                    individual_legends = true;
                end
            else
                if day == 3
                    legend_labels = [legend_labels "G"+string(group)+"d"+string(day)];
                else
                    legend_labels = [legend_labels "G"+string(group)];
                end
            end

            % plot to tile
            if days_on_graph == 1 %...in a 1 tile figure
                
                nexttile(1)
                hold on
                plot(reapplied_model,'Linewidth',line_width)
                if plot_counter == 1
                    if day == 1 || day == 3
                        delete(emptyplot)
                    else
                        delete(emptyplot2)
                    end
                end
                legend(legend_labels,'Location','southoutside')
                hold off
                drawnow()

            else %...in a 2 tile figure

                if plot_counter == 1
                    nexttile(1)
                    hold on
                    delete(emptyplot)
                    hold off

                    nexttile(2)
                    hold on
                    delete(emptyplot2)
                    hold off
                end

                nexttile(day)
                hold on

                plot(reapplied_model,'Linewidth',line_width)

                if day == 1 && individual_legends
                    legend(legend_labels_plot1,'Location','southoutside')
                end

                if day == 2
                    legend(legend_labels_plot2,'Location','southoutside')
                end
                hold off

                drawnow()
                y_dimensions = [y_dimensions max(reapplied_model) min(reapplied_model)];
            end

            %% plot model query
            disp(' ')
            disp(' ––––––––––––––––––––')
            plotting = input('  Plot a model? ','s');
            if plotting == 'n'
                plot_loop_state = 0;
            end

            %% sync y limits in 2 tile figure
            if days_on_graph == 2
                y_max = 0.3; % ceil(max(y_dimensions));
                y_min = 0; % floor(min(y_dimensions));

                nexttile(1)
                ylim([y_min y_max])

                nexttile(2)
                ylim([y_min y_max])

                drawnow()
                disp('  y axis synced √')
            end
        end
        drawnow() % redundancy drawnow()
        %%

    case 38 % plot var & learning within group
        %%
        fprintf("<strong>creating plot</strong>\n")
        %% input
        % n_days
        days_on_graph = 2;

        % show available emg spaces
        emg_spaces = calc_variables.Properties.VariableNames;
        non_emg_calc_vars = 6;
        disp(' ')
        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(emg_spaces)-non_emg_calc_vars
            fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
        end
        fprintf('\n')

        % emg space selector
        disp(' ')
        emg_space   = input('  emg space: ')+6;
        emg_space = emg_spaces{emg_space};

        % group to plot
        group       = input('  group:     ');

        %% scaffold
        t = tiledlayout(1,days_on_graph,'TileSpacing','Compact');

        switch group
            case 1
                title_string = "Non-Fatigued Sham Depo";
            case 2
                title_string = "Fatigued Sham Depo";
            case 3
                title_string = "Fatigued Real Depo";
        end
        
        title(t,title_string)

        %% plot variability

        legend_array = [];
        for i = 1:2
            day = i;

            stencil = calc_variables.group == group & calc_variables.day == day;

            calc_variables_subset = calc_variables(stencil,:);

            % get observed values from calc_variables_subset
            dependant = calc_variables_subset(:, emg_space);
            dependant = table2array(dependant);

            % get regressors
            regressors_names = "time";

            regressors = calc_variables_subset(:, regressors_names);

            regressors_names = regressors.Properties.VariableNames;
            regressors = table2array(regressors);

            % create model
            mdlr = fitlm(regressors,dependant,'RobustOpts','on');

            % reapply model
            intercept   = mdlr.Coefficients{1,1};
            effect      = mdlr.Coefficients{2,1};
            time_scaffold = transpose((1:120)+120*(day-1));

            reapplied_model = intercept + effect*time_scaffold;


            % plot reapplied model
            % asemble legend
            %             if multiple_yn == 'y'
            %                 complexity = 'multiple';
            %             else
            %                 complexity = 'simple';
            %             end
            %
            %             % assemble legend
            %             if days_on_graph == 2
            %                 if days_in_model == 2
            %                     legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
            %                     legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
            %                 else
            %                     if day == 1
            %                         legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
            %                         individual_legends = true;
            %                     else
            %                         legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
            %                         individual_legends = true;
            %                     end
            %                 end
            %             else
            %                 if day == 3
            %                     legend_labels = [legend_labels "G"+string(group)+"d"+string(day)+" "+emg_space+" "+complexity];
            %                 else
            %                     legend_labels = [legend_labels "G"+string(group)+" "+emg_space+" "+complexity];
            %                 end
            %             end

            % plot to tile

            % plot 1 day model in 2 day figure
            %                     if plot_counter == 1
            %                         hold on
            %                         nexttile(1)
            %                         delete(emptyplot)
            %                         nexttile(2)
            %                         delete(emptyplot)
            %                         hold off
            %                     end

            nexttile(1)
            hold on

            plot(reapplied_model,'Linewidth',line_width)

            set(gca,'box','off')
            set(gca,'XLim',[1 120],'XTick',15:30:105)
            xticklabels(["1", "2", "3", "4"])
            xlabel("session")
            ylabel("variability")

            legend(["day 1" "day 2"],'Location','southoutside')

            hold off

            drawnow()
            % y_dimensions = [y_dimensions max(reapplied_model) min(reapplied_model)];


            %% sync y limits in 2 tile figure
            %             if days_on_graph == 2
            %                 y_max = ceil(max(y_dimensions));
            %                 y_min = floor(min(y_dimensions));
            %
            %                 nexttile(1)
            %                 ylim([y_min y_max])
            %
            %                 nexttile(2)
            %                 ylim([y_min y_max])
            %
            %                 drawnow()
            %                 disp('  y axis synced √')
            %             end

            drawnow() % redundancy drawnow()
        end
        %%

        %% plot skill
        for i = 1:2
            day = i;

            % get subset of calc_variables to be tested
            parameters = struct2table(Parameters);

            stencil = (parameters.label == group & parameters.day == day);
            dependant = table2array(parameters(stencil,'skillp'));
            regressor = table2array(parameters(stencil,'BN'));

            % create model
            mdlr = fitlm(regressor,dependant,'RobustOpts','on');

            % reapply model
            intercept   = mdlr.Coefficients{1,1};
            effect      = mdlr.Coefficients{2,1};

            time_scaffold = 1:4; % transpose(1:4);

            reapplied_model = intercept + effect*time_scaffold;


            % plot reapplied model
            % asemble legend
            %             if multiple_yn == 'y'
            %                 complexity = 'multiple';
            %             else
            %                 complexity = 'simple';
            %             end
            %
            %             % assemble legend
            %             if days_on_graph == 2
            %                 if days_in_model == 2
            %                     legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
            %                     legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
            %                 else
            %                     if day == 1
            %                         legend_labels_plot1 = [legend_labels_plot1 "G"+string(group)+" "+emg_space+" "+complexity];
            %                         individual_legends = true;
            %                     else
            %                         legend_labels_plot2 = [legend_labels_plot2 "G"+string(group)+" "+emg_space+" "+complexity];
            %                         individual_legends = true;
            %                     end
            %                 end
            %             else
            %                 if day == 3
            %                     legend_labels = [legend_labels "G"+string(group)+"d"+string(day)+" "+emg_space+" "+complexity];
            %                 else
            %                     legend_labels = [legend_labels "G"+string(group)+" "+emg_space+" "+complexity];
            %                 end
            %             end

            nexttile(2)
            hold on

            plot(reapplied_model,'Linewidth',line_width)

            set(gca,'box','off')
            set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
            xticklabels(["1", "2", "3", "4"])
            xlabel("session")
            ylabel("skill")

            %                     if day == 1 && individual_legends
            %                         legend(legend_labels_plot1,'Location','southoutside')
            %                     end
            %
            %                     if day == 2
            %                         legend(legend_labels_plot2,'Location','southoutside')
            %                     end

            hold off

            legend(["day 1" "day 2"],'Location','southoutside')

            drawnow()
            
            %y_dimensions = [y_dimensions max(reapplied_model) min(reapplied_model)];


            %% sync y limits in 2 tile figure
            %             if days_on_graph == 2
            %                 y_max = ceil(max(y_dimensions));
            %                 y_min = floor(min(y_dimensions));
            %
            %                 nexttile(1)
            %                 ylim([y_min y_max])
            %
            %                 nexttile(2)
            %                 ylim([y_min y_max])
            %
            %                 drawnow()
            %                 disp('  y axis synced √')
            %             end

            drawnow() % redundancy drawnow()
        end
        %%

        %%

    case 41 % styling options
        %% figure styling options
        set(findall(gcf,'-property','FontSize'),'FontSize',12);
        %legend(["Non-Fatigued shamDePo","Fatigued shamDePo","Fatigued realDePo"],'Location','southoutside');
        %t.Title.String = 'Robust Multiple Regression Models';
        t.Title.FontSize = 16;
        t.Title.FontWeight = 'normal';
        %legend([]);
        %%

    case 42 % empty legend
        %%
        figure(1)
        hold on
        emptyplot = plot(NaN,NaN,'Linewidth',line_width);
        plot(NaN,NaN,'Linewidth',line_width);
        plot(NaN,NaN,'Linewidth',line_width);
        plot(NaN,NaN,'Linewidth',line_width);
        hold off
        delete(emptyplot)
        legend(["Non-Fatigued shamDePo","Fatigued shamDePo","Fatigued realDePo"]);
        set(findall(gcf,'-property','FontSize'),'FontSize',20);
        legend('Location','bestoutside')
        %%

    case 43 % plot skill measure
        %%
        % calculate mean skill by group per session from parameters
        p = struct2table(Parameters);
        mean_skill_measure = [];
        for i = 1:3
            mean_skill_group = zeros([8 1]);
            for j = 1:2
                for k=1:4
                    mean_skill_group(k+((j-1)*4)) = mean(p(p.label == i & p.day == j & p.BN == k,:).skillp,'omitnan');
                end
            end
            mean_skill_measure = [mean_skill_measure mean_skill_group];
        end

        % create scaffold
        line_width = 2;
        t = tiledlayout(1,2,'TileSpacing','Compact');
        title(t,'Mean Skill Measure')

        % Tile 1 - training sessions
        nexttile
        emptyplot = plot(NaN,NaN,'Linewidth',line_width);
        set(gca,'box','off')
        set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
        xticklabels(["T1", "T2", "T3", "T4"])
        xlabel("session")
        ylim([min(min(mean_skill_measure)) max(max(mean_skill_measure))])
        ylabel("skill measure")

        % Tile 2 - control sessions
        nexttile
        emptyplot2 = plot(NaN,NaN,'Linewidth',line_width);
        set(gca,'box','off')
        set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
        xticklabels(["C1", "C2", "C3", "C4"])
        xlabel("session")
        ylim([min(min(mean_skill_measure)) max(max(mean_skill_measure))])
        ax1 = gca;                   % gca = get current axis
        ax1.YAxis.Visible = 'off';   % remove y-axis

        % plot skill measure
        nexttile(1)
        hold on
        plot(mean_skill_measure(1:4,:),'Linewidth',line_width)
        delete(emptyplot)
        hold off

        nexttile(2)
        hold on
        plot(mean_skill_measure(5:8,:),'Linewidth',line_width)
        delete(emptyplot)
        %legend(["Non-Fatigued shamDePo","Fatigued shamDePo","Fatigued realDePo"],'Location','eastoutside');
        hold off

        set(findall(gcf,'-property','FontSize'),'FontSize',20);
t.Title.String = 'Mean Skill Measure';
t.Title.FontSize = 20;
t.Title.FontWeight = 'normal';

        drawnow()

        %%

    case 44 % ttest
        %%
        %input
        disp(' ')
        disp(' T Test')
        what_to_test = input('  var or skill? ','s');
        disp(' ')
        disp(' Sample A')
        sample_a = zeros([1 3]);
        sample_a(1) = input('  group:   ');
        sample_a(2) = input('  day:     ');
        sample_a(3) = input('  session: ');
        disp(' ')
        disp(' Sample B')
        sample_b = zeros([1 3]);
        sample_b(1) = input('  group:   ');
        sample_b(2) = input('  day:     ');
        sample_b(3) = input('  session: ');

        switch what_to_test
            case 'var'
            % emg space selector
            emg_spaces = calc_variables.Properties.VariableNames;
            non_emg_calc_vars = 6;
            disp("  available emg spaces")
            fprintf(' ')
            for i = 1:length(emg_spaces)-non_emg_calc_vars
                fprintf("  "+string(i)+" "+emg_spaces(i+non_emg_calc_vars)+" |")
            end
            fprintf('\n')

            disp(' ')
            emg_space = input('emg space:  ')+6;
            emg_space = emg_spaces{emg_space};

            % get subset of calc_variables to be tested
            stencil = (calc_variables.group == sample_a(1) & calc_variables.day == sample_a(2) & calc_variables.session == sample_a(3));
            subset_a = table2array(calc_variables(stencil,emg_space));

            stencil = (calc_variables.group == sample_b(1) & calc_variables.day == sample_b(2) & calc_variables.session == sample_b(3));
            subset_b = table2array(calc_variables(stencil,emg_space));

            % test
%             if sample_a(1) == sample_b(1)
%                 kind = 'onesample';
%             else
%                 kind = 'independent';
%             end

            kind = 'independent';

            [t,p] = ttest(subset_a, subset_b, 2, kind);

            case 'skill'
                % get subset of calc_variables to be tested
                parameters = struct2table(Parameters);

                stencil = (parameters.label == sample_a(1) & parameters.day == sample_a(2) & parameters.BN == sample_a(3));
                subset_a = table2array(parameters(stencil,'skillp'));

                stencil = (parameters.label == sample_b(1) & parameters.day == sample_b(2) & parameters.BN == sample_b(3));
                subset_b = table2array(parameters(stencil,'skillp'));

                % test
%                 if sample_a(1) == sample_b(1)
%                     kind = 'onesample';
%                 else
%                     kind = 'independent';
%                 end

                kind = 'independent';

                [t,p] = ttest(subset_a, subset_b, 2, kind);

        end
        disp(' ')
        %%

    case 51 % save
        %%
        disp('1 alldat as struct')
        disp('2 alldat as table')
        disp('3 calc_variables table')
        disp(' ')
        what_to_save = input('save: ');

        switch what_to_save
            case 1
                if istable(fatigue_alldat)
                    fatigue_alldat = table2struct(fatigue_alldat,"ToScalar",true);
                end

                [file, path] = uiputfile(fullfile(rootDir,'*.mat'));

                time_start = now;
                save(fullfile(path,file),'-struct','fatigue_alldat','-v7.3');

                disp('  -> fatigue_alldat saved')
                disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))

            case 2
                if isstruct(fatigue_alldat)
                    fatigue_alldat = struct2table(fatigue_alldat,"ToScalar",true);
                end

                [f,p] = uiputfile(fullfile(rootDir,'*.csv'),'save alldat table');
                time_start = now;
                writetable(fatigue_alldat,[p,f]);
                disp(['   -> ',f,' saved to ',p]);
                disp(strcat("     runtime ", datestr(now - time_start,'HH:MM:SS')))

            case 3
                [f,p] = uiputfile(fullfile(rootDir,'*.csv'),'save calc_variables table');
                writetable(calc_variables,[p,f]);
                disp(['   -> ',f,' saved to ',p]);
        end
        %% end case 51 save

    case 0 % reset cml view
        %%
        clc
        fprintf(operations_list);
        %% end of case 0
    
    case 666 %%Case 666: Terminate Script   
        run_script = 0;
        
    case 911 %Case 911: Clear Workspace
        clearvars -except action fatigue_alldat mean_trials Missing_Trials Parameters rootDir run_script status_update calc_variables lin_reg_models distances_to_calc

end % end of master switch
end % end of master while loop

