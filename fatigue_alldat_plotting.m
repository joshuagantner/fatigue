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
"\n"+...
"20 variability & skill by day\n"+...
"\n"+...
"30  view model\n"+...
"34  plot regression models\n"+...
"38  plot var // learning\n"+...
"\n"+...
"42  empty legend\n"+...
"43  plot skill measure\n"+...
"432 plot skill measure\n"+...
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

    case 20 % variability & skill by day
        %%
        figure()
        t = tiledlayout(1,2);
        emg_space = emgSpaceSelector(calc_variables);
        day = input('  day:   ');

        %% scaffold
%         t = tiledlayout(1,days_on_graph,'TileSpacing','Compact');
%         title(t,'Robust Multiple Linear Regression of Variability')
% 
%         % Tile 1 - training sessions
%         if day == 1 || days_on_graph == 2
%             nexttile
%             emptyplot = plot(NaN,NaN,'b','Linewidth',line_width);
%             set(gca,'box','off')
%             set(gca,'XLim',[1 120],'XTick',15:30:105)
%             xticklabels(["T1", "T2", "T3", "T4"])
%             xlabel("session")
%             ylabel("variability")
%         end
% 
%         % Tile 2 - control sessions
%         if day == 2 || days_on_graph == 2
%             nexttile
%             emptyplot2 = plot(NaN,NaN,'g','Linewidth',line_width);
%             set(gca,'box','off')
% 
%             if days_on_graph == 1
%                 set(gca,'XLim',[1 120],'XTick',15:30:105)
%             else
%                 set(gca,'XLim',[121 240],'XTick',135:30:225)
%             end
% 
%             xticklabels(["C1", "C2", "C3", "C4"])
%             xlabel("session")
%             if day ~= 2
%                 ax1 = gca;                   % gca = get current axis
%                 ax1.YAxis.Visible = 'off';   % remove y-axis
%             end
%         end
% 
%         % Tile 3 - indifferent sessions
%         if day == 3
%             nexttile
%             emptyplot = plot(NaN,NaN,'g','Linewidth',line_width);
%             xlim([121 240])
%             set(gca,'box','off')
%             set(gca,'XLim',[1 120],'XTick',15:30:105)
%             xticklabels(["1", "2", "3", "4"])
%             xlabel("session")
%             ylabel("variability")
%         end

        %% loop plot models
        for group = 1:3

            %% generate model to plot
            % get subset of calc_variables to be tested

%                 stencil = (calc_variables.group == group & calc_variables.day == day);

            calc_variables_subset = calc_variables(calc_variables.group == group & calc_variables.day == day, :); % calc_variables(stencil,:);

            % get observed values from calc_variables_subset
            dependant = calc_variables_subset{:, emg_space};
%             dependant = table2array(dependant);

            % get regressors
            regressors = calc_variables_subset{:, "time"};

            % create model
            mdlr = fitlm(regressors,dependant,'RobustOpts','on');

            %% reapply model
            intercept   = mdlr.Coefficients{1,1};
            effect      = mdlr.Coefficients{2,1};
            time_scaffold = transpose((1:120)+120*(day-1));
            reapplied_model = intercept + effect*time_scaffold(:,1);

            %% plot reapplied model

            % plot to tile
                %...in a 1 tile figure
                nexttile(1)
                hold on
                plot(reapplied_model,'Linewidth',line_width)
                if plot_counter == 1
                    if day == 1
                        delete(emptyplot)
                    else
                        delete(emptyplot2)
                    end
                end
                legend(legend_labels,'Location','southoutside')
                hold off
                drawnow()

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

        % plot skill
        nexttile(2)
        
        %%
    
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
                    if day == 1
                        delete(emptyplot)
                    else
                        delete(emptyplot2)
                    end
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
        legend(["Non-Fatigued shamDePo","Fatigued shamDePo","Fatigued realDePo"],'Location','southoutside');
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

    case 432 % plot skill measure
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
        t = tiledlayout(1,1,'TileSpacing','Compact');
        title(t,'Mean Skill Measure')

%         % Tile 1 - training sessions
%         nexttile
%         emptyplot = plot(NaN,NaN,'Linewidth',line_width);
%         set(gca,'box','off')
%         set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
%         xticklabels(["T1", "T2", "T3", "T4"])
%         xlabel("session")
%         ylim([min(min(mean_skill_measure)) max(max(mean_skill_measure))])
%         ylabel("skill measure")

        % Tile 2 - control sessions
        nexttile
        emptyplot2 = plot(NaN,NaN,'Linewidth',line_width);
        set(gca,'box','off')
        set(gca,'XLim',[0.5 4.5],'XTick',1:1:4)
        xticklabels(["C1", "C2", "C3", "C4"])
        xlabel("session")
        ylim([min(min(mean_skill_measure)) max(max(mean_skill_measure))])
        ylabel("skill measure")
        % ax1 = gca;                   % gca = get current axis
        % ax1.YAxis.Visible = 'off';   % remove y-axis

         % plot skill measure
%         nexttile(1)
%         hold on
%         plot(mean_skill_measure(1:4,:),'Linewidth',line_width)
%         delete(emptyplot)
%         hold off

        nexttile(1) %nexttile(2)
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
