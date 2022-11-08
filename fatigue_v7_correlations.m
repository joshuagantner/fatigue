%% FATIGUE v7 - correlations

%% setup
run_script = 1;

% set root directory
%rootDir    = '/Volumes/smb fatigue'; % mac root
%rootDir = '\\JOSHUAS-MACBOOK\smb fatigue\database'; % windows root network
%rootDir = 'F:\database'; %windows root hd over usb
%rootDir = '\\jmg\home\Drive\fatigue\database'; %windows root nas
rootDir = 'D:\Joshua\fatigue\database'; %windows root internal hd

% supress warnings
% warning('off','MATLAB:table:RowsAddedNewVars')
warning('off','stats:statrobustfit:IterationLimit')
warning('off','stats:statrobustfit:IterationLimit')
warning('off','MATLAB:polyfit:PolyNotUnique')

%% print legend to cml

%display available operations
operations_list = ... "––––––––––––––––––––––––––––––––––––––––––––––––––––\n"+...
"<strong>Available operations:</strong>\n"+...
"\n"+...
"setup\n"+...
"11  set root directory\n"+...
"12  load data\n"+...
"\n"+...
"correlation\n"+...
"21  visual inspection\n"+...
"\n"+...
"45  from session mean variability\n"+...
"452 from streched skill\n"+...
"453 from streched skill 80th percentile cutoff\n"+...
"46  from reapplied models\n"+...
"47  from regression coefficients manual\n"+...
"48  from regression coefficients manual\n"+...
"49  sams approach: skill difference\n"+...
"50  sams approach: skill model\n"+...
"\n"+...
"\n"+...
"\n"+...
"clear cml & display operations with 0\n"+...
"terminate script with 666\n"+...
"clear workspace with 911\n";

fprintf(operations_list);

%% master while loop
while run_script == 1
%%    
%Select Operation
disp(' ')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
action = input('What would you like me to do? ');
disp(' ')
%%

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


    
    case 21 % visual inspection
        %% create mean value tables for skill and variability
        emg_space = emgSpaceSelector(calc_variables);
        parameters = struct2table(Parameters);
        subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% plot by group and day
        figure();
        t = tiledlayout(2,3);
        title(t, "Scatter Plot: mean skill // mean variability all data");
        for group = 1:3
            for day = 1:2
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, day_range );
                variability = mean_variability_list( mean_variability_list(:,1) == group, day_range );

                % plot
                nexttile((day-1)*3+group)
                hold on

                scatter(transpose(skill), transpose(variability))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("variability")
                xlabel("skill")
                legend(string(mean_skill_list( mean_skill_list(:,1) == group, 2 )))
                
                hold off
            end
        end
        drawnow()
        %%

        %% create mean value 80 tables for skill and variability
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session = table2array( variability( variability.day == day & variability.session == session, emg_space) );
                    variability_session = variability_session(variability_session < prctile(variability_session, 80));
                    variability_session_mean = [variability_session_mean; mean(variability_session)];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% plot by group and day
        figure();
        u = tiledlayout(2,3);
        title(u, "Scatter Plot: mean skill // mean variability 80th percentile cutt-off");
        for group = 1:3
            for day = 1:2
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, day_range );
                variability = mean_variability_list( mean_variability_list(:,1) == group, day_range );

                % plot
                nexttile((day-1)*3+group)
                hold on

                scatter(transpose(skill), transpose(variability))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("variability")
                xlabel("skill")
                legend(string(mean_skill_list( mean_skill_list(:,1) == group, 2 )))
                
                hold off
            end
        end
        drawnow()
        %%

      %% create table of correlations -> export to csv to format
        %% create mean value tables for skill and variability
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% table by group and day
        fprintf("<strong>Correlation: mean skill // mean variability all data</strong>\n")
        for group = 1:3
            for day = 1:2
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, [ 2 day_range ] );
                variability = mean_variability_list( mean_variability_list(:,1) == group, [ 2 day_range ] );

                % plot
                disp("group " + group + " day " + day)
                correlation_table = nan(height(skill),2);

                for i = 1:height(skill)
                    a = transpose(skill(i,2:5));
                    b = transpose(variability(i,2:5));
                    [r, p] = corr(a, b,'Type','Spearman');
                    correlation_table(i,:) = [r p];
                end
                disp(correlation_table)
            end
        end
        %%
        %% create mean value 80 tables for skill and variability
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session = table2array( variability( variability.day == day & variability.session == session, emg_space) );
                    variability_session = variability_session(variability_session < prctile(variability_session, 80));
                    variability_session_mean = [variability_session_mean; mean(variability_session)];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% table by group and day
        fprintf("<strong>Correlation: mean skill // mean variability 80th percentile cutt-off</strong>\n")
        for group = 1:3
            for day = 1:2
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, [ 2 day_range ] );
                variability = mean_variability_list( mean_variability_list(:,1) == group, [ 2 day_range ] );

                % plot
                disp("group " + group + " day " + day)
                correlation_table = nan(height(skill),2);

                for i = 1:height(skill)
                    a = transpose(skill(i,2:5));
                    b = transpose(variability(i,2:5));
                    [r, p] = corr(a, b,'Type','Spearman');
                    correlation_table(i,:) = [r p];
                end
                disp(correlation_table)
            end
        end
        %%
      %%

        %% plot and table for model correlation
        figure()
        v = tiledlayout(2,3);
        title(v, 'scatter plots of robust models for skill and variability by group and day')

        correlation_table = array2table(zeros(3,5));
        correlation_table.Properties.VariableNames = {'group', 'day 1 | r', 'day 1 | p', 'day 2 | r', 'day 2 | p'};
        correlation_table(:, 'group') = {1; 2 ; 3};
        for group = 1:3
            for day = 1:2
                %% reapply variability model
                    % fit model
                        % emg space selector
        
                        % other input
%                 group         = input('group:    ');
                multiple_yn   = "n"; % input('multiple: ','s');
                days_in_model = 1;   % input('days:     ');
        
%                 if days_in_model == 1
%                     day     = input('day:      ');
%                 else
%                     clear day
%                 end
        
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
        
                % reapply
                if multiple_yn == 'n'
                        intercept   = mdlr.Coefficients{1,1};
                        effect      = mdlr.Coefficients{2,1};
        
                        if days_in_model == 2
                            time_scaffold = 1:240;
                        else
                            time_scaffold = transpose((1:120)+120*(day-1));
                        end
        
                        reapplied_model_variability = intercept + effect*time_scaffold(:,1);
        
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
        
                        reapplied_model_variability = intercept + effect_day*time_scaffold(:,1) + effect_session*time_scaffold(:,2) + effect_trial*time_scaffold(:,3);
                    else
                        intercept       = mdlr.Coefficients{1,1};
                        effect_session  = mdlr.Coefficients{2,1};
                        effect_trial    = mdlr.Coefficients{3,1};
        
                        time_scaffold = [...
                            [ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],... create session column
                            repmat(transpose(1:30),[4 1])... create trial column
                            ];
        
                        reapplied_model_variability = intercept + effect_session*time_scaffold(:,1) + effect_trial*time_scaffold(:,2);
                end
                %% reapply skill model
                % generate model to plot
                    %input
        %             disp(' ')
        %             group = input('  group:   ');
        %             day   = input('  day:     ');
        %             disp(' ')
        
                    
                    % get subset of calc_variables to be tested
%                     parameters = struct2table(Parameters);
        
                    stencil = (parameters.label == group & parameters.day == day);
                    dependant = table2array(parameters(stencil,'skillp'));
                    regressor = table2array(parameters(stencil,'BN'));
        
                    % create model
                    mdlr = fitlm(regressor,dependant,'RobustOpts','on');
        
                    % reapply model
                    intercept   = mdlr.Coefficients{1,1};
                    effect      = mdlr.Coefficients{2,1};
        
                    time_scaffold = transpose(1:3/120:3.99); % 1:4; % transpose(1:4);
        
                    reapplied_model_skill = intercept + effect*time_scaffold; % reapplied_model = intercept + effect*time_scaffold(:,1);
                    
                %% correlate & plot reapplied models
                % plot
                nexttile((day-1)*3+group)
                hold on

                scatter(reapplied_model_skill, reapplied_model_variability)
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("variability")
                xlabel("skill")
                
                
                hold off

                % correlate
                [r, p] = corr(reapplied_model_skill, reapplied_model_variability, 'Type', 'Spearman' );
                correlation_table(group, day*2) = {r};
                correlation_table(group, day*2+1) = {p};
                %%
            end
        end
        drawnow()
        fprintf("<strong>Correlation: reapplied models for skill and variability</strong>\n")
        disp(correlation_table)
        %%

        %% scatter and correlation for pooled data points
        %% create mean value tables for skill and variability
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% plot by group and day
        figure();
        t = tiledlayout(2,3);
        title(t, "Scatter Plot of pooled data: mean skill // mean variability");

        correlation_table = array2table(zeros(3,5));
        correlation_table.Properties.VariableNames = {'group', 'day 1 | r', 'day 1 | p', 'day 2 | r', 'day 2 | p'};
        correlation_table(:, 'group') = {1; 2 ; 3};
        for group = 1:3
            for day = 1:2
                % plot
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, day_range );
                skill = [skill(:,1); skill(:,2); skill(:,3); skill(:,4)];

                variability = mean_variability_list( mean_variability_list(:,1) == group, day_range );
                variability = [variability(:,1); variability(:,2); variability(:,3); variability(:,4)];

                % plot
                nexttile((day-1)*3+group)
                hold on

                scatter(transpose(skill), transpose(variability))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("variability")
                xlabel("skill")
                % legend(string(mean_skill_list( mean_skill_list(:,1) == group, 2 )))
                
                hold off

                % correlate -> table
                [r, p] = corr(skill, variability, 'Type', 'Spearman', 'rows', 'complete');
                correlation_table(group, day*2) = {r};
                correlation_table(group, day*2+1) = {p};
            end
        end
        drawnow()
        fprintf("<strong>Correlation: pooled data for skill and variability</strong>\n")
        disp(correlation_table)
        %%

        %% scatter and correlation for pooled data points with 80 percentil cutt-off
        %% create mean value tables for skill and variability
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
    
        % subject_list = [5	6	8	9	10  11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 45
        
        mean_skill_list       = nan( length(subject_list), 10);
        mean_variability_list = nan( length(subject_list), 10);

        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            
            variability_session_mean = [];
            for day = 1:2
                for session = 1:4
                    variability_session = table2array( variability( variability.day == day & variability.session == session, emg_space) );
                    variability_session = variability_session(variability_session < prctile(variability_session, 80));
                    variability_session_mean = [variability_session_mean; mean(variability_session)];
                end
            end

            mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
            mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];

        end

        

        %% plot by group and day
        figure();
        t = tiledlayout(2,3);
        title(t, "Scatter Plot of pooled data with 80th percentile cutt-off: mean skill // mean variability");

        correlation_table = array2table(zeros(3,5));
        correlation_table.Properties.VariableNames = {'group', 'day 1 | r', 'day 1 | p', 'day 2 | r', 'day 2 | p'};
        correlation_table(:, 'group') = {1; 2 ; 3};
        for group = 1:3
            for day = 1:2
                % plot
                % set range for day recall from table
                if day == 1
                    day_range = 3:6;
                else
                    day_range = 7:10;
                end

                % get subsets
                skill       = mean_skill_list( mean_skill_list(:,1) == group, day_range );
                skill = [skill(:,1); skill(:,2); skill(:,3); skill(:,4)];

                variability = mean_variability_list( mean_variability_list(:,1) == group, day_range );
                variability = [variability(:,1); variability(:,2); variability(:,3); variability(:,4)];

                % plot
                nexttile((day-1)*3+group)
                hold on

                scatter(transpose(skill), transpose(variability))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("variability")
                xlabel("skill")
                % legend(string(mean_skill_list( mean_skill_list(:,1) == group, 2 )))
                
                hold off

                % correlate -> table
                [r, p] = corr(skill, variability, 'Type', 'Spearman', 'rows', 'complete');
                correlation_table(group, day*2) = {r};
                correlation_table(group, day*2+1) = {p};
            end
        end
        drawnow()
        fprintf("<strong>Correlation: pooled data with 80th percentile cutt-off for skill and variability</strong>\n")
        disp(correlation_table)
        %%

        %%

    case 45 % correlation mean variability of session
        %%
        emg_space = emgSpaceSelector(calc_variables);

        % 1 | get list of volunteers to itterate
        % subject_list = unique(Parameters.SubjN);
    
        subject_list = [5	6	8	9	11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 10, 45
        

        % 2 | create list to store intra subject r values
        correlation_list = nan( length(subject_list), 6);
        mean_variability_list = nan( length(subject_list), 8);

        for i = 1:length(subject_list)
            subject = subject_list(i);

        % 3 | get skill and variability values
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

        % 4 | ¿ Match vector length ? -> calculate variability mean of
        % block OR stnd4time(skill)

            version = "variability_session_mean";
            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            switch version

                case "variability_session_mean"
                    variability_session_mean = [];
                    for day = 1:2
                        for session = 1:4
                            variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                        end
                    end

                    mean_variability_list(i,:) = transpose(variability_session_mean);
                
                    [day1_r, day1_p] = corr( skill(1:4, :), variability_session_mean(1:4, :), 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill(5:8, :), variability_session_mean(5:8, :), 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];

                case "stnd_skill"
                    variability_day1 = table2array(variability(variability.day == 1, emg_space));
                    skill_day1 = stnd4time(skill(1:4,:), length(variability_day1));
                    variability_day2 = table2array(variability(variability.day == 2, emg_space));
                    skill_day2 = stnd4time(skill(5:8,:), length(variability_day2));
                    

                    [day1_r, day1_p] = corr( skill_day1, variability_day1, 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill_day1, variability_day1, 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];
            end

        end

        % mean_variability_list
                
        correlation_list

        for i = 1:3
            disp('group '+string(i))
            corrleation_con = correlation_list(correlation_list(:, 1) == i, :)
            mean(corrleation_con, "omitnan")
            std(corrleation_con, "omitnan")
        end

        % 6 | plot by group ¿only lines or including data points?

        %%

    
    case 452% correlation streched skill
        %%
        emg_space = emgSpaceSelector(calc_variables);

        % 1 | get list of volunteers to itterate
        % subject_list = unique(Parameters.SubjN);
    
        subject_list = [5	6	8	9	11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 10, 45
        

        % 2 | create list to store intra subject r values
        correlation_list = nan( length(subject_list), 6);
        mean_variability_list = nan( length(subject_list), 8);

        for i = 1:length(subject_list)
            subject = subject_list(i);

        % 3 | get skill and variability values
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

        % 4 | ¿ Match vector length ? -> calculate variability mean of
        % block OR stnd4time(skill)

            version = "stnd_skill";
            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            switch version

                case "variability_session_mean"
                    variability_session_mean = [];
                    for day = 1:2
                        for session = 1:4
                            variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                        end
                    end

                    mean_variability_list(i,:) = transpose(variability_session_mean);
                
                    [day1_r, day1_p] = corr( skill(1:4, :), variability_session_mean(1:4, :), 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill(5:8, :), variability_session_mean(5:8, :), 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];

                case "stnd_skill"
                    variability_day1 = table2array(variability(variability.day == 1, emg_space));
                    skill_day1 = stnd4time(skill(1:4,:), length(variability_day1));
                    variability_day2 = table2array(variability(variability.day == 2, emg_space));
                    skill_day2 = stnd4time(skill(5:8,:), length(variability_day2));
                    

                    [day1_r, day1_p] = corr( skill_day1, variability_day1, 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill_day2, variability_day2, 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];
            end

        end

        % mean_variability_list
                
        correlation_list

        for i = 1:3
            disp('group '+string(i))
            corrleation_con = correlation_list(correlation_list(:, 1) == i, :)
            disp('mean')
            disp(mean(corrleation_con, "omitnan"))
            disp('median')
            disp(median(corrleation_con, "omitnan"))
            disp('stdev')
            disp(std(corrleation_con, "omitnan"))
        end

        % 6 | plot by group ¿only lines or including data points?

        %%

    case 453% correlation streched skill 80th percentila cutoff
        %%
        emg_space = emgSpaceSelector(calc_variables);

        % 1 | get list of volunteers to itterate
        % subject_list = unique(Parameters.SubjN);
    
        subject_list = [5	6	8	9	11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 10, 45
        

        % 2 | create list to store intra subject r values
        correlation_list = nan( length(subject_list), 6);
        mean_variability_list = nan( length(subject_list), 8);

        for i = 1:length(subject_list)
            subject = subject_list(i);

        % 3 | get skill and variability values
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group" emg_space]);

        % 4 | ¿ Match vector length ? -> calculate variability mean of
        % block OR stnd4time(skill)

            version = "stnd_skill";
            corr_type = 'Spearman'; % 'Pearson', 'Spearman' or 'Kendall'
            switch version

                case "variability_session_mean"
                    variability_session_mean = [];
                    for day = 1:2
                        for session = 1:4
                            variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
                        end
                    end

                    mean_variability_list(i,:) = transpose(variability_session_mean);
                
                    [day1_r, day1_p] = corr( skill(1:4, :), variability_session_mean(1:4, :), 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill(5:8, :), variability_session_mean(5:8, :), 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];

                case "stnd_skill"
                    variability_day1 = table2array(variability(variability.day == 1, emg_space));
                    variability_day1 = variability_day1(variability_day1(:, 1) < prctile(variability_day1, 80), :);
                    skill_day1 = stnd4time(skill(1:4,:), length(variability_day1));

                    variability_day2 = table2array(variability(variability.day == 2, emg_space));
                    variability_day2 = variability_day2(variability_day2(:, 1) < prctile(variability_day2, 80), :);
                    skill_day2 = stnd4time(skill(5:8,:), length(variability_day2));
                    

                    [day1_r, day1_p] = corr( skill_day1, variability_day1, 'Type', corr_type );
                    [day2_r, day2_p] = corr( skill_day2, variability_day2, 'Type', corr_type );
                    correlation_list(i, :) = [unique(variability.group), subject, day1_r, day1_p, day2_r, day2_p];
            end

        end

        % mean_variability_list
                
        correlation_list

        for i = 1:3
            disp('group '+string(i))
            corrleation_con = correlation_list(correlation_list(:, 1) == i, :)
            disp('mean')
            disp(mean(corrleation_con, "omitnan"))
            disp('median')
            disp(median(corrleation_con, "omitnan"))
            disp('stdev')
            disp(std(corrleation_con, "omitnan"))
        end

        % 6 | plot by group ¿only lines or including data points?

        %%

    
    case 46 % correlate reapplied models
       
        %% reapply variability model
            % fit model
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
        group         = input('group:    ');
        multiple_yn   = "n"; % input('multiple: ','s');
        days_in_model = 1;   % input('days:     ');

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

        % reapply
        if multiple_yn == 'n'
                intercept   = mdlr.Coefficients{1,1};
                effect      = mdlr.Coefficients{2,1};

                if days_in_model == 2
                    time_scaffold = 1:240;
                else
                    time_scaffold = transpose((1:120)+120*(day-1));
                end

                reapplied_model_variability = intercept + effect*time_scaffold(:,1);

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

                reapplied_model_variability = intercept + effect_day*time_scaffold(:,1) + effect_session*time_scaffold(:,2) + effect_trial*time_scaffold(:,3);
            else
                intercept       = mdlr.Coefficients{1,1};
                effect_session  = mdlr.Coefficients{2,1};
                effect_trial    = mdlr.Coefficients{3,1};

                time_scaffold = [...
                    [ones([30,1]);ones([30,1])*2;ones([30,1])*3;ones([30,1])*4],... create session column
                    repmat(transpose(1:30),[4 1])... create trial column
                    ];

                reapplied_model_variability = intercept + effect_session*time_scaffold(:,1) + effect_trial*time_scaffold(:,2);
        end
        %% reapply skill model
        % generate model to plot
            %input
%             disp(' ')
%             group = input('  group:   ');
%             day   = input('  day:     ');
%             disp(' ')

            
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

            time_scaffold = transpose(1:3/120:3.99); % 1:4; % transpose(1:4);

            reapplied_model_skill = intercept + effect*time_scaffold; % reapplied_model = intercept + effect*time_scaffold(:,1);
            
        %% correlate reapplied models
        disp('spearman')
        [r, p] = corr(reapplied_model_skill, reapplied_model_variability, 'Type', 'Spearman' )
        disp(' ')
        disp('kendall')
        [r, p] = corr(reapplied_model_skill, reapplied_model_variability, 'Type', 'Kendall' )
        disp(' ')
        disp('pearson')
        [r, p] = corr(reapplied_model_skill, reapplied_model_variability, 'Type', 'Pearson' )
        %%

    case 47 % correlation coefficient from intercept
        %% fit variability model
            % fit model
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
        group         = input('group:    ');
        multiple_yn   = "n"; % input('multiple: ','s');
        days_in_model = 1;   % input('days:     ');

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

        mdlr_variability = fitlm(regressors,dependant,'RobustOpts','on');

        %% fit skill model
        % generate model to plot
            %input
%             disp(' ')
%             group = input('  group:   ');
%             day   = input('  day:     ');
%             disp(' ')

            
            % get subset of calc_variables to be tested
            parameters = struct2table(Parameters);

            stencil = (parameters.label == group & parameters.day == day);
            dependant = table2array(parameters(stencil,'skillp'));
            regressor = table2array(parameters(stencil,'BN'));

            % create model
            mdlr_skill = fitlm(regressor,dependant,'RobustOpts','on');

        %% calcualte r | https://www.toppr.com/ask/question/find-the-coefficient-of-correlation-from-the-regression-lines-x2y30/
        effect_skill = mdlr_skill.Coefficients{'x1','Estimate'}
        effect_variability = mdlr_variability.Coefficients{'x1','Estimate'}

        r2 = effect_skill * (-1/effect_variability)
        r = sqrt(effect_skill * (-1/effect_variability))
        %%

    case 48 % correlation coefficient from intercept
        %%

        emg_space = emgSpaceSelector(calc_variables);

        for group = 1:3
            for day = 1:2

                %% fit variability model
                % fit model
%                 group         = input('group:    ');
                multiple_yn   = "n"; % input('multiple: ','s');
                days_in_model = 1;   % input('days:     ');
        
%                 if days_in_model == 1
%                     day     = input('day:      ');
%                 else
%                     clear day
%                 end
        
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
        
                mdlr_variability = fitlm(regressors,dependant,'RobustOpts','on');
        
                %% fit skill model
                % generate model to plot
                    %input
        %             disp(' ')
        %             group = input('  group:   ');
        %             day   = input('  day:     ');
        %             disp(' ')
        
                    
                    % get subset of calc_variables to be tested
                    parameters = struct2table(Parameters);
        
                    stencil = (parameters.label == group & parameters.day == day);
                    dependant = table2array(parameters(stencil,'skillp'));
                    regressor = table2array(parameters(stencil,'BN'));
        
                    % create model
                    mdlr_skill = fitlm(regressor,dependant,'RobustOpts','on');
        
                %% calcualte r | https://www.toppr.com/ask/question/find-the-coefficient-of-correlation-from-the-regression-lines-x2y30/
                
                disp('group ' + string(group) + ' day ' + string(day))
                effect_skill = mdlr_skill.Coefficients{'x1','Estimate'}
                effect_variability = mdlr_variability.Coefficients{'x1','Estimate'}
        
                r2 = effect_skill * (-1/effect_variability)
                r = sqrt(effect_skill * (-1/effect_variability))
                

            end
        end
        %%

    case 49 % sams approach with skill difference
        fprintf("<strong>sams approach</strong>\n")
        %% calculations
        emg_space = emgSpaceSelector(calc_variables);
        parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
        
        subject_list = [5	6	8	9   11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30	31	32	33	34	35	36	37	38	39	40	41	42	43	44];
            % manually excluded: 10, 45
        change_table = array2table(zeros(80, 5));
        change_table.Properties.VariableNames = {'subject', 'group', 'day', 'variability_slope', 'skill_slope'};


        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group", "time", emg_space]);
            
            variability_session_mean = [];
            for day = 1:2

                %% variability
                % get observed values from calc_variables_subset
                dependant = variability(variability.day == day, emg_space);
                dependant = table2array(dependant);
        
                % get regressors
                regressors = variability(variability.day == day, "time");
                regressors = table2array(regressors);

                % fit model
                if subject == 10 || 45
                    robust_on = 'off';
                else
                    robust_on = 'on';
                end

                mdlr = fitlm(regressors,dependant,'RobustOpts',robust_on);
                variability_slope = mdlr.Coefficients{2,1};

                %% skill
                % get observed values from calc_variables_subset
                if day == 1
                    skill_slope = skill(4)-skill(1);
                else
                    skill_slope = skill(8)-skill(5);
                end

                %% add to change table
                change_table((i-1)*2+day, :) = array2table([subject, group, day, variability_slope, skill_slope]);

            end

        end

        %% plotting
        corr_table = array2table(zeros(6,4));
        corr_table.Properties.VariableNames = ["group" "day" "coefficient" "p"];
        figure();
        t = tiledlayout(2,3);
        title(t, "Scatter Plot: Skill Change and Variability Slope");
        for group = 1:3
            for day = 1:2

                nexttile((day-1)*3+group)
                hold on

                scatter(change_table.variability_slope(change_table.day == day & change_table.group == group), change_table.skill_slope(change_table.day == day & change_table.group == group))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("skill slope")
                xlabel("variability slope")
                
                hold off

                % print r & p to console
                [r, p] = corr(change_table.variability_slope(change_table.day == day & change_table.group == group), change_table.skill_slope(change_table.day == day & change_table.group == group),'Type','Spearman','rows','complete');
                corr_table{(group-1)*2+day , :} = [group day r p];
            end
        end
        drawnow()
        disp(' ')
        fprintf("<strong>Spearman: Variability Slope x Skill Difference</strong>\n")
        disp(corr_table);
        %%

    case 50 % sams approach with skill model
        fprintf("<strong>sams approach</strong>\n")
        %% calculations
        emg_space = emgSpaceSelector(calc_variables);
        parameters = struct2table(Parameters);
        subject_list = unique(Parameters.SubjN);

        change_table = array2table(zeros(80, 5));
        change_table.Properties.VariableNames = {'subject', 'group', 'day', 'variability_slope', 'skill_slope'};


        for i = 1:length(subject_list)
            subject = subject_list(i);
            group = unique(parameters{parameters.SubjN == subject,"label"});
        
            skill       = Parameters.skillmeas(Parameters.SubjN == subject);
            variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group", "time", emg_space]);
            
            variability_session_mean = [];
            for day = 1:2

                %% variability
                % get observed values from calc_variables_subset
                dependant = variability(variability.day == day, emg_space);
                dependant = table2array(dependant);
        
                % get regressors
                regressors = variability(variability.day == day, "time");
                regressors = table2array(regressors);

                % fit model
                if subject == 10 || 45
                    robust_on = 'off';
                else
                    robust_on = 'on';
                end

                mdlr = fitlm(regressors,dependant,'RobustOpts',robust_on);
                variability_slope = mdlr.Coefficients{2,1};

                %% skill
                % get observed values from calc_variables_subset
                if day == 1
                    dependant = skill(1:4);
                else
                    dependant = skill(5:8);
                end
        
                % get regressors
                regressors = transpose(1:4);

                % fit model
                mdlr = fitlm(regressors,dependant,'RobustOpts','on');
                skill_slope = mdlr.Coefficients{2,1};

                %% add to change table
                change_table((i-1)*2+day, :) = array2table([subject, group, day, variability_slope, skill_slope]);

            end

        end

        %% plotting
        figure();
        t = tiledlayout(2,3);
        title(t, "Scatter Plot: mean skill // mean variability all data");
        for group = 1:3
            for day = 1:2

                nexttile((day-1)*3+group)
                hold on

                scatter(change_table.variability_slope(change_table.day == day & change_table.group == group), change_table.skill_slope(change_table.day == day & change_table.group == group))
                
                h = lsline;

                title("group " + group + " day " + day)
                ylabel("skill slope")
                xlabel("variability slope")
                
                hold off

                % print r & p to console
                disp("group " + group + " day " + day)
                [r, p] = corr(change_table.variability_slope(change_table.day == day & change_table.group == group), change_table.skill_slope(change_table.day == day & change_table.group == group));
                disp("r: " + r + " p: " + p)
            end
        end
        drawnow()
        %%

    

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

function emg_space = emgSpaceSelector(calc_variables)
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
end

%%  template
%         emg_space = emgSpaceSelector(calc_variables);
%         parameters = struct2table(Parameters);
%         subject_list = unique(Parameters.SubjN);
%     
% 
%         for i = 1:length(subject_list)
%             subject = subject_list(i);
%             group = unique(parameters{parameters.SubjN == subject,"label"});
%         
%             skill       = Parameters.skillmeas(Parameters.SubjN == subject);
%             variability = calc_variables(calc_variables.subject == subject, ["day", "session", "group", emg_space]);
%             
%             variability_session_mean = [];
%             for day = 1:2
%                 for session = 1:4
%                     variability_session_mean = [variability_session_mean; mean( table2array( variability( variability.day == day & variability.session == session, emg_space) ), 'omitnan')];
%                 end
%             end
% 
%             mean_skill_list(i,:)       = [ group, subject, transpose(skill)];
%             mean_variability_list(i,:) = [ group, subject, transpose(variability_session_mean)];
% 
%         end