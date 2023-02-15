%% FATIGUE v8 - further findings

%% setup
run_script = 1;

% set root directory
%rootDir    = '/Volumes/smb fatigue'; % mac root
%rootDir = '\\JOSHUAS-MACBOOK\smb fatigue\database'; % windows root network
%rootDir = 'F:\database'; %windows root hd over usb
%rootDir = '\\jmg\home\Drive\fatigue\database'; %windows root nas
rootDir = 'D:\Joshua\fatigue\database'; %windows root internal hd

% supress warnings
warning('off','MATLAB:table:ModifiedVarnamesUnstack')

%% print legend to cml

%display available operations
operations_list = ... "––––––––––––––––––––––––––––––––––––––––––––––––––––\n"+...
"<strong>Available operations:</strong>\n"+...
"\n"+...
"setup\n"+...
"1  set root directory\n"+...
"2  load data\n"+...
"\n"+...
"4  exploration of variability w/ variable resolution\n"+...
"5  histograms\n"+...
"6  tables\n"+...
"\n"+...
"\n"+...
"clear cml & display operations with 0\n"+...
"terminate script with 666\n"+...
"clear workspace with 911\n";

fprintf(operations_list);

%% master while loop
while run_script == 1
%% Select Operation
disp(' ')
disp('––––––––––––––––––––––––––––––––––––––––––––––––––––')
action = input('What would you like me to do? ');
disp(' ')
%%

switch action
    %% 
    case 1 % set root directory
        %%
        rootDir = uigetdir('','fatigue root directory');
        disp(' ')
        disp("  root directory set to '"+rootDir+"'")
        %% end Case 11: Set root directory

    case 2 % load data
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
                disp("calc_variables length: "+num2str(height(calc_variables)))
                % calc_variables.Properties.VariableNames = ["group" "subject" "day" "session" "trial" "time" transpose(cellfun(@strjoin, distances_to_calc))];

        end
        %% end Case 12: load data
    
    case 4 % explore variability - resolution variable
        %%
        emg_space = emgSpaceSelector(calc_variables);
        croped_boxplots   = input('boxplot by group y limit: ');
        percentile_cutoff = input('percentile cutoff:        ');
        descriptive_res   = input('descriptive resolution:   ');
        dname = uigetdir(rootDir);
        dname = dname+"/";

        % percentile cut calc_variables
        calc_variables_backup = calc_variables;
        calc_variables = calc_variables(calc_variables{:,emg_space}<=prctile(calc_variables{:,emg_space},percentile_cutoff),:);

        % boxplot by group
        f = figure();
        f.Position = [300 300 600 400];
        t = tiledlayout(2,3);
        t.Title.String = 'Exploration of Variability';
        for group = 1:3
            nexttile
            subset = calc_variables(calc_variables.group==group, :);
            subset.dayXsession = ((subset.day-1).*4)+subset.session;
            subset = subset(:,["subject" "trial" "dayXsession" emg_space]);
            subset = unstack(subset,emg_space,"dayXsession");
            boxplot(subset{:,3:10})
            title("group "+num2str(group))
            ylabel("variability by trial")
            xlabel("session")
        end
        for group = 1:3
            nexttile
            subset = calc_variables(calc_variables.group==group, :);
            subset.dayXsession = ((subset.day-1).*4)+subset.session;
            subset = subset(:,["subject" "trial" "dayXsession" emg_space]);
            subset = unstack(subset,emg_space,"dayXsession");
            boxplot(subset{:,3:10})
            ylim([0 croped_boxplots])
            title("group "+num2str(group))
            ylabel("variability by trial")
            xlabel("session")
        end

        saveas(f, dname+"boxplots-group.png")
        close(f)

        % boxplot by session
        f = figure();
        f.Position = [300 300 900 900];
        t = tiledlayout(4,4,"Padding","tight");
        t.Title.String = 'Exploration of Variability';
        
        subset = calc_variables;
        subset.dayXsession = ((subset.day-1).*4)+subset.session;
            
        for session = 1:8
            nexttile
            subsubset = subset(subset.dayXsession==session, :);
            subsubset = subsubset(:,["subject" "trial" "group" emg_space]);
            subsubset = unstack(subsubset,emg_space,"group");
            boxplot(subsubset{:,3:5})
            title("session "+num2str(session))
            ylabel("variability by trial")
            xlabel("group")
        end
        for session = 1:8
            nexttile
            subsubset = subset(subset.dayXsession==session, :);
            subsubset = subsubset(:,["subject" "trial" "group" emg_space]);
            subsubset = unstack(subsubset,emg_space,"group");
            boxplot(subsubset{:,3:5})
            ylim([0 croped_boxplots])
            title("session "+num2str(session))
            ylabel("variability by trial")
            xlabel("group")
        end
        
        saveas(f, dname+"boxplots-session.png")
        close(f)

        % calculate descriptive numbers
        subset = calc_variables;
        subset.dayXsession = ((subset.day-1).*4)+subset.session;
        subset = subset(:,["group" "dayXsession" "trial" emg_space]);

        group   = repelem(transpose(1:3),8*descriptive_res);
        session = repmat(repelem(transpose(1:8),descriptive_res),[3 1]);
        subsession = repmat(transpose(1:descriptive_res),[3*8 1]);
        var_exploration = table(group, session, subsession);

        operations = [
            "mean"  "mean(" ")"  
            "median"    "median(" ")"  
            "mode"  "mode(" ")"  
            "range" "range(" ")"  
            "quantiles"  "{quantile("    ",[.25 .50 .75])}"
            "var"   "var(" ")"  
            "std"   "std(" ")"  
            "skewness"  "skewness(" ")"  
            "kurtosis"  "kurtosis(" ")"  
            ];
        numbers = array2table(zeros([3*8*descriptive_res length(operations)]));
        numbers.Properties.VariableNames = operations(:,1);
        var_exploration = [var_exploration numbers];
        var_exploration.quantiles = num2cell(var_exploration.quantiles); 

        for group = 1:3
            for session = 1:8
                subsubset = subset(subset.group==group & subset.dayXsession==session,["trial" emg_space]);
                for res = 1:descriptive_res 
                    s = (30/descriptive_res)*(res-1)+1;
                    e = (30/descriptive_res)*(res);
                    subsubsubset = subsubset(s:e, emg_space);
                    for operation = 1:length(operations)
                        result = eval( sprintf("%ssubsubsubset{:,:}%s",operations(operation,2),operations(operation,3) ));
                        var_exploration{...
                                        var_exploration.group==group & ...
                                        var_exploration.session==session & ...
                                        var_exploration.subsession==res,...
                                        operations(operation,1)} = result;
                    end
                end
            end
        end

        writetable(var_exploration, dname+"values.txt")

        % plot descriptive numbers
        linewidth = 2.5;
        for group = 1:3
            for operation = 1:length(operations)

                if operation ~= 5
                    f = figure();
                    f.Position = [300 300 450 200];
                    t = tiledlayout(1,2);
                    t.Title.String = "Exploration of Variability: Group "+num2str(group)+" "+operations(operation,1);

                    nexttile
                    plot(var_exploration{var_exploration.group==group,operations(operation)}(1:4*descriptive_res),'LineWidth',linewidth);
                    title("day 1")
                    ylabel(operations(operation,1))
                    xlabel("session")
                    set(gca,'box','off')
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;

                    nexttile
                    plot(var_exploration{var_exploration.group==group,operations(operation)}(4*descriptive_res+1:8*descriptive_res),'LineWidth',linewidth);
                    title("day 2")
                    ylabel(operations(operation,1))
                    xlabel("session")
                    set(gca,'box','off')
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;
                    saveas(f, dname+num2str(group)+"-"+operations(operation)+".png")
                else
                    f = figure();
                    f.Position = [300 300 450 200];
                    t = tiledlayout(1,2);
                    t.Title.String = "Exploration of Variability: Group "+num2str(group)+" "+operations(operation,1);

                    nexttile
                    a = var_exploration{var_exploration.group==group,operations(operation)}(1:4*descriptive_res);
                    plot(cell2mat(a),'LineWidth',linewidth)
                    title("day 1")
                    ylabel(operations(operation,1))
                    xlabel("session")
                    set(gca,'box','off')
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;

                    nexttile
                    a = var_exploration{var_exploration.group==group,operations(operation)}(4*descriptive_res+1:8*descriptive_res);
                    plot(cell2mat(a),'LineWidth',linewidth)
                    title("day 2")
                    ylabel(operations(operation,1))
                    xlabel("session")
                    set(gca,'box','off')
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;
                    saveas(f, dname+num2str(group)+"-"+operations(operation)+".png")
                        
                end
                close(f)
            end
        end

        % correlate descriptive numbers with variability

        models = struct();

        group   = repelem(transpose(1:3),8*descriptive_res);
        session = repmat(repelem(transpose(1:8),descriptive_res),[3 1]);
        subsession = repmat(transpose(1:descriptive_res),[3*8 1]);
        variability = zeros([3*8*descriptive_res 1]);

        var_sessionmeans = table(group, session, subsession, variability);

        for group = 1:3
            for day = 1:2

                % fit model
                calc_variables_subset = calc_variables(calc_variables.group == group & calc_variables.day == day,:);
        
                % get observed values from calc_variables_subset
                dependant = calc_variables_subset(:, emg_space);
                dependant = table2array(dependant);
        
                % get regressors
                regressors = calc_variables_subset(:, "time");
                regressors_names = regressors.Properties.VariableNames;
                regressors = table2array(regressors);
        
                mdlr = fitlm(regressors,dependant,'RobustOpts','on');
        
                % reapply model
                intercept     = mdlr.Coefficients{1,1};
                effect        = mdlr.Coefficients{2,1};
                time_scaffold = transpose((1:120)+120*(day-1));
                reapplied_model = intercept + effect*time_scaffold(:,1);

                % write session means to table
                for session = 1:4
                    for subsession = 1:descriptive_res
                        s = (subsession-1)*30/res+(session-1)*30+1;
                        e = subsession*30/res+(session-1)*30;
                        z = session+(day-1)*4;
                        var_sessionmeans{var_sessionmeans.group==group & var_sessionmeans.session==z & var_sessionmeans.subsession==subsession, "variability"} = mean(reapplied_model(s:e));
                    end
                end

                % save reapplied models to struct
                eval(sprintf("models.g%s.g%s = reapplied_model;",num2str(group),num2str(day)))
            end
        end

        group   = repelem(transpose(1:3),2);
        day = repmat(transpose(1:2),[3 1]);
        var_exploration_corr = table(group, day);
        numbers = array2table(zeros([6 length(operations)]));
        numbers.Properties.VariableNames = operations(:,1);
        var_exploration_corr = [var_exploration_corr numbers];

        for group = 1:3
            for operation = 1:length(operations)
                    if operation ~= 5
                        % day 1
                        variability = var_sessionmeans(var_sessionmeans.group==group, "variability");
                        variability = variability{1:4*descriptive_res,:};
                        description = var_exploration(var_exploration.group==group, operations(operation));
                        description = description{1:4*descriptive_res,:};
                        [r, p] = corr(variability,description,"type","Spearman");
                        var_exploration_corr{var_exploration_corr.group==group & var_exploration_corr.day==1, operations(operation)} = r;
                        %day 2
                        variability = var_sessionmeans(var_sessionmeans.group==group, "variability");
                        variability = variability{4*descriptive_res+1:8*descriptive_res,:};
                        description = var_exploration(var_exploration.group==group, operations(operation));
                        description = description{4*descriptive_res+1:8*descriptive_res,:};
                        [r, p] = corr(variability,description,"type","Spearman");
                        var_exploration_corr{var_exploration_corr.group==group & var_exploration_corr.day==2, operations(operation)} = r;
                    end
            end
        end

        writetable(var_exploration_corr, dname+"correlations.txt")

        % plot descriptives & models overlay 
        for group = 1:3
            for operation = 1:length(operations)

                if operation ~= 5
                    f = figure();
                    f.Position = [300 300 450 200];
                    t = tiledlayout(1,2);
                    t.Title.String = "Exploration of Variability: Group "+num2str(group)+" "+operations(operation,1);

                    nexttile
                    plot(var_exploration{var_exploration.group==group,operations(operation)}(1:4*descriptive_res),'LineWidth',linewidth)
                    ylabel(operations(operation,1))
                    xlabel("session")
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;

                    yyaxis right
                    plot(var_sessionmeans{var_sessionmeans.group==group,"variability"}(1:4*descriptive_res),'LineWidth',linewidth)
                    ylabel("variability regression model")
                    ax = gca;
                    ax.YAxis(2).LineWidth = 2;
                    title("day 1")

                    nexttile
                    plot(var_exploration{var_exploration.group==group,operations(operation)}(4*descriptive_res+1:8*descriptive_res),'LineWidth',linewidth)
                    ylabel(operations(operation,1))
                    xlabel("session")
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;

                    yyaxis right
                    plot(var_sessionmeans{var_sessionmeans.group==group,"variability"}(4*descriptive_res+1:8*descriptive_res),'LineWidth',linewidth)
                    ylabel("variability regression model")
                    ax = gca;
                    ax.YAxis(2).LineWidth = 2;
                    title("day 2")

                    saveas(f, dname+"overlay-"+num2str(group)+"-"+operations(operation)+".png")
                else
                    f = figure();
                    f.Position = [300 300 450 200];
                    t = tiledlayout(1,2);
                    t.Title.String = "Exploration of Variability: Group "+num2str(group)+" "+operations(operation,1);
                    
                    nexttile
                    a = var_exploration{var_exploration.group==group,operations(operation)}(1:4*descriptive_res);
                    plot(cell2mat(a),'LineWidth',linewidth)
                    ylabel(operations(operation,1))
                    xlabel("session")
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;
                    yyaxis right
                    plot(var_sessionmeans{var_sessionmeans.group==group,"variability"}(1:4*descriptive_res),'LineWidth',linewidth)
                    ylabel("variability regression model")
                    ax = gca;
                    ax.YAxis(2).LineWidth = 2;
                    title("day 1")

                    nexttile
                    a = var_exploration{var_exploration.group==group,operations(operation)}(4*descriptive_res+1:8*descriptive_res);
                    plot(cell2mat(a),'LineWidth',linewidth)
                    ylabel(operations(operation,1))
                    xlabel("session")
                    ax = gca;
                    ax.XAxis.LineWidth = 2;
                    ax.YAxis.LineWidth = 2;
                    yyaxis right
                    plot(var_sessionmeans{var_sessionmeans.group==group,"variability"}(4*descriptive_res+1:8*descriptive_res),'LineWidth',linewidth)
                    ylabel("variability regression model")
                    ax = gca;
                    ax.YAxis(2).LineWidth = 2;
                    title("day 2")

                    saveas(f, dname+"overlay-"+num2str(group)+"-"+operations(operation)+".png")
                end
                close(f)
            end
        end
        
        %% plot groups by descriptive
        f = figure();
        f.Position = [300 300 600 600];
        t = tiledlayout(3,3);
        t.Title.String = ("Exploration of Variability");

        for i = 1:length(operations)
            nexttile()
            operation = operations(i,1);
            subset = var_exploration(:, ["group" "session" "subsession" operation]);
            plot(subset)

        end
        %% restore calc_variables
        calc_variables = calc_variables_backup;
        %%
    
    case 5 % histograms
        %%
        emg_space = emgSpaceSelector(calc_variables);
        percentile_cutoff = 90;
        dname = uigetdir(rootDir);
        dname = dname+"/";

        % percentile cut calc_variables
        calc_variables_backup = calc_variables;
        calc_variables = calc_variables(calc_variables{:,emg_space}<=prctile(calc_variables{:,emg_space},percentile_cutoff),:);

        % plot by count
        f = figure();
        f.Position = [0 0 1600 600];
        t = tiledlayout(3,8);
        t.Title.String = 'Exploration of Variability: Boxplots Count';
        for group = 1:3
            subset = calc_variables(calc_variables.group==group, :);
            subset.dayXsession = ((subset.day-1).*4)+subset.session;
            subset = subset(:,["subject" "trial" "dayXsession" emg_space]);
            subset = unstack(subset,emg_space,"dayXsession");
            for session = 1:8
                nexttile
                histogram(subset{:,session+2});
                title("session "+num2str(session))
                ylabel("count")
                xlabel("variability")
            end
        end

        saveas(f, dname+"count.png")
        close(f)
        
        % restore calc_variables
        calc_variables = calc_variables_backup;
        disp("calc_variables length: "+num2str(height(calc_variables)))
        %%

        % percentile cut calc_variables
        calc_variables_backup = calc_variables;
        calc_variables = calc_variables(calc_variables{:,emg_space}<=prctile(calc_variables{:,emg_space},percentile_cutoff),:);

        % plot by density
        f = figure();
        f.Position = [0 0 1600 600];
        t = tiledlayout(3,8);
        t.Title.String = 'Exploration of Variability: Boxplots Density';
        for group = 1:3
            subset = calc_variables(calc_variables.group==group, :);
            subset.dayXsession = ((subset.day-1).*4)+subset.session;
            subset = subset(:,["subject" "trial" "dayXsession" emg_space]);
            subset = unstack(subset,emg_space,"dayXsession");
            for session = 1:8
                nexttile
                histogram(subset{:,group+2},'Normalization','probability');
                title("session "+num2str(session))
                ylabel("density")
                xlabel("variability")
            end
        end

        saveas(f, dname+"density.png")
        close(f)
        
        % restore calc_variables
        calc_variables = calc_variables_backup;
        disp("calc_variables length: "+num2str(height(calc_variables)))
        %%
    
    case 6 % tables
        %%
        emg_space = emgSpaceSelector(calc_variables);
        percentile_cutoff = 90;
        % dname = uigetdir(rootDir);
        % dname = dname+"/";

        % percentile cut calc_variables
        calc_variables_backup = calc_variables;
        calc_variables = calc_variables(calc_variables{:,emg_space}<=prctile(calc_variables{:,emg_space},percentile_cutoff),:);

        % plot by count
        t = array2table(zeros(3,8));
        t.Properties.VariableNames = ["1" "2" "3" "4" "5" "6" "7" "8"];
        t.Properties.RowNames = ["Group 1" "Group 2" "Group 3"];

        skew_table = t;
        kurtosis_table = t;

        for group = 1:3
            subset = calc_variables(calc_variables.group==group, :);
            subset.dayXsession = ((subset.day-1).*4)+subset.session;
            subset = subset(:,["subject" "trial" "dayXsession" emg_space]);
            subset = unstack(subset,emg_space,"dayXsession");
            for session = 1:8
                skew_table{group, session}     =    skewness(subset{:,session+2});
                kurtosis_table{group, session} =    kurtosis(subset{:,session+2});
            end
        end

        skew_table
        kurtosis_table

        writetable(skew_table, dname+"skew_table.txt")
        writetable(kurtosis_table, dname+"kurtosis_table.txt")
        
        % restore calc_variables
        calc_variables = calc_variables_backup;
        disp("calc_variables length: "+num2str(height(calc_variables)))
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
