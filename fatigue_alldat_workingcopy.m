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
operations_list = ...
    "––––––––––––––––––––––––––––––––––––––––––––––––––––\n"+...
    "Available operations:\n"+...
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
    "24  multiple models overall\n"+...
    "25  multiple models by day\n"+...
    "26  simple models\n"+...
    "\n"+...
    "27  add comparison variables\n"+...
    "28  compare models\n"+...
    "\n"+...
    "31  compare 2 overall multiple linear regression models\n"+...
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
                calc_variables.Properties.VariableNames = ["group" "subject" "day" "session" "trial" "time" transpose(cellfun(@strjoin, distances_to_calc))];

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
        what_to_process = input('what to porcess: ');

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

    case 24 % multiple models across days
        %%
        regression_models = array2table([]);

        for i=1:length(distances_to_calc)
            emg_space = strjoin(distances_to_calc{i});
            for j=1:3
                group = j;

                % get observed values from calc_variables
                dependant = calc_variables(calc_variables.group == group, emg_space);
                dependant = table2array(dependant);

                % get explanatory values from calc_variables
                regressor = calc_variables(calc_variables.group == group, ["day" "session" "trial"]);
                regressor = table2array(regressor);

                % add 1s for intercept
                %regressor = [regressor ones([height(regressor) 1])];

                % fit a robust linear regression model
                mdlr = fitlm(regressor,dependant,'RobustOpts','on');

                % save model to table
                regression_models(j,emg_space) = {mdlr};
            end
        end
        regression_models.Properties.RowNames = ["group 1" "group 2" "group 3"];
        disp(regression_models)
        lin_reg_models.multiple_overall = regression_models;
        %%

    case 25 % multiple models within days
        %%
        regression_models_day = array2table([]);

        for i=1:length(distances_to_calc)
            emg_space = strjoin(distances_to_calc{i});

            for j=1:3
                group = j;
                subtable = array2table([]);
                for k = 1:2
                    column_names = ["day_1" "day_2"];
                    % get observed values from calc_variables
                    dependant = calc_variables(calc_variables.group == group & calc_variables.day == k, emg_space);
                    dependant = table2array(dependant);

                    % get explanatory values from calc_variables
                    regressor = calc_variables(calc_variables.group == group & calc_variables.day == k, ["session" "trial"]);
                    regressor = table2array(regressor);

                    % add 1s for intercept
                    %regressor = [regressor ones([height(regressor) 1])];

                    % fit a robust linear regression model
                    mdlr = fitlm(regressor,dependant,'RobustOpts','on');

                    % save model to table
                    subtable(1,column_names(k)) = {mdlr};
                end
                %save day models to overall table
                regression_models_day(j,emg_space) = {subtable};
            end
        end
        regression_models_day.Properties.RowNames = ["group 1" "group 2" "group 3"];
        disp(regression_models_day)
        lin_reg_models.multiple_day = regression_models_day;
        %%

    case 26 % simple models
        %% simple models across days
        simple_models_overall = array2table([]);

        for i=1:length(distances_to_calc)
            emg_space = strjoin(distances_to_calc{i});
            for j=1:3
                group = j;

                % get observed values from calc_variables
                dependant = calc_variables(calc_variables.group == group, emg_space);
                dependant = table2array(dependant);

                % get explanatory values from calc_variables
                regressor = calc_variables(calc_variables.group == group, "time");
                regressor = table2array(regressor);

                % add 1s for intercept
                %regressor = [regressor ones([height(regressor) 1])];

                % fit a robust linear regression model
                mdlr = fitlm(regressor,dependant,'RobustOpts','on');

                % save model to table
                simple_models_overall(j,emg_space) = {mdlr};
            end
        end
        simple_models_overall.Properties.RowNames = ["group 1" "group 2" "group 3"];
        disp(simple_models_overall)
        lin_reg_models.simple_overall = simple_models_overall;
        %%

        %%
        simple_models_day = array2table([]);

        for i=1:length(distances_to_calc)
            emg_space = strjoin(distances_to_calc{i});

            for j=1:3
                group = j;
                subtable = array2table([]);
                for k = 1:2
                    column_names = ["day_1" "day_2"];
                    % get observed values from calc_variables
                    dependant = calc_variables(calc_variables.group == group & calc_variables.day == k, emg_space);
                    dependant = table2array(dependant);

                    % get explanatory values from calc_variables
                    regressor = calc_variables(calc_variables.group == group & calc_variables.day == k, "time");
                    regressor = table2array(regressor);

                    % add 1s for intercept
                    %regressor = [regressor ones([height(regressor) 1])];

                    % fit a robust linear regression model
                    mdlr = fitlm(regressor,dependant,'RobustOpts','on');

                    % save model to table
                    subtable(1,column_names(k)) = {mdlr};
                end
                %save day models to overall table
                simple_models_day(j,emg_space) = {subtable};
            end
        end
        simple_models_day.Properties.RowNames = ["group 1" "group 2" "group 3"];
        disp(simple_models_day)
        lin_reg_models.simple_day = simple_models_day;
        %%
    case 27 % add comparison variables
        %%
        % normalize distances for dimensions
        for i = 1:length(distances_to_calc)
            if length(distances_to_calc{i})>1
                calc_variables.(strjoin(distances_to_calc{i})+" normalized") = calc_variables{:,strjoin(distances_to_calc{i})}/length(distances_to_calc{i});
            end
        end

        % add dummy variables
        calc_variables.g1_binary = calc_variables.group == 1;
        calc_variables.g2_binary = calc_variables.group == 2;
        calc_variables.g3_binary = calc_variables.group == 3;

        % dummy * regressor
        % group 2
        calc_variables.day_g2       = calc_variables.day     .*double(calc_variables.g2_binary);
        calc_variables.session_g2   = calc_variables.session .*double(calc_variables.g2_binary);
        calc_variables.trial_g2     = calc_variables.trial   .*double(calc_variables.g2_binary);
        
        % group 3
        calc_variables.day_g3       = calc_variables.day     .*double(calc_variables.g3_binary);
        calc_variables.session_g3   = calc_variables.session .*double(calc_variables.g3_binary);
        calc_variables.trial_g3     = calc_variables.trial   .*double(calc_variables.g3_binary);

        disp(' success')
        %%
    
    case 28 % compare regression model
        %%
        % regression_models{"group 1", "fdi"}{:,:}
        % regression_models_day{"group 1","adm"}{:,"day_1"}{:,:}

        % We can use the same approach even when there are more than two 
        % samples. For example, with three samples S0, S1 and S2, we use 
        % two dummy variables d1 = 1 if the data comes from sample S1 and 
        % d1 = 0 otherwise and d2 = 1 if the data comes from sample S2 and 
        % d2 = 0 otherwise.
        % 
        % The regression model takes the form: 
        % 
        %               y = b0 + b1x + b2d1 + b3d2 + b4d1x+ b5d2x
        %         

        i=1;
        j=1;

        emg_space = strjoin(distances_to_calc{i});
        group = j;

        % get observed values from calc_variables
        dependant = calc_variables(:, emg_space);
        dependant = table2array(dependant);
        
        % get explanatory values from calc_variables
        regressor = calc_variables(:, ["day" "session" "trial" "g2_binary" "g3_binary" "day_g2" "day_g3" "session_g2" "session_g3" "trial_g2" "trial_g3"]); 
        regressor_names = regressor.Properties.VariableNames;
        regressor = table2array(regressor);
        
        % fit a robust linear regression model
        mdlr = fitlm(regressor,dependant,'RobustOpts','on')
        disp("regressors:")
        disp(regressor_names)

        %%

    case 31 % compare 2 overall multiple linear regression model
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