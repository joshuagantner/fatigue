%% FATIGUE v8

run_script = 1;
%rootDir    = '/Volumes/smb fatigue'; % mac root
%rootDir = '\\JOSHUAS-MACBOOK\smb fatigue\database'; % windows root network
%rootDir = 'F:\database'; %windows root hd over usb
%rootDir = '\\jmg\home\Drive\fatigue\database'; %windows root nas
% rootDir = 'D:\Joshua\fatigue\database'; %windows root internal hd
% distances_to_calc = {...
%     "adm";...
%     "fdi";...
%     "apb";...
%     "fcr";...
%     "bic";...
%     ["fdi" "apb"];...
%     ["fdi" "apb" "adm"];...
%     ["fcr" "bic"];...
%     ["fdi" "apb" "adm" "fcr" "bic"]...
%     };

% import python functions for mongodb interaction
%   path on windows tower
functions_path = "C:\Users\joshg\Documents\GitHub\fatigue-matlabfunctions";
%   path on macbook
%functions_path = '/Users/joshuagantner/science/fatigue/code/functions/Functions Joshua';
if count(py.sys.path, functions_path) == 0
    insert(py.sys.path, int32(0), functions_path);
end
pyModule = py.importlib.import_module('mongodb');
pyModule = py.importlib.reload(pyModule);
get_data = pyModule.get_data;
find_unique = pyModule.find_unique;
put_data = pyModule.put_data;
aggregate = pyModule.aggregate;
data_type = ""; % set initial datatype to empty string


% supress warnings
warning('off','MATLAB:table:RowsAddedNewVars')

% print legend to cml
operations_list = ...
    " \n"+...
    "1 table of contents\n"+...
    "2 filter, rectify & stnd4time\n"+...
    "3 mean trials\n"+...
    "4 measure euclidean distances\n"+...
    "5 describe variability\n"+...
    "6 describe emg\n"+...
    " \n"+...
    "7 view model\n" + ...
    "8 comparative model\n"+...
    "9 create graphs\n"+...
    "10 correlations\n"+...
    "12 violins\n"+...
    "\n";
fprintf(operations_list);

%% master while loop
db_name = 'fatigue';

while run_script == 1

    % Select Operation
    disp(' ')
    action = input('What would you like me to do? ');
    disp(' ')

    switch true % master switch
        case action == 1 % db content table
    
            % get unique participant identifiers
            collection = input('collection: ','s');
            participants = find_unique(db_name,collection,'identifier');
            participants = string(participants);
            db_tableOfContents = array2table(zeros(240,length(participants)));
            db_tableOfContents.Properties.VariableNames = participants;
            db_tableOfContents.Properties.RowNames = string(1:240);
    
            % get data
            what_to_process = input(' overview or lead (o/_): ','s');
            if what_to_process == "o"
                query = py.dict(pyargs('data type','EMG'));
            else
                lead = input('lead: ','s');
                query = py.dict(pyargs('data type','EMG','lead',lead));
            end
            projection = py.dict(pyargs('identifier',1,'day',1,'block',1,'trial',1));
            data = get_data(db_name,collection,query, projection, batch_size = int8(10));
            data = transpose(string(data));
    
            data = strrep(data, "'", '"'); % Replace single quotes with double quotes
            data = strrep(data, "ObjectId(", ""); % Remove "ObjectId("
            data = strrep(data, ")", ""); % Remove ")"
    
            disp('data fetched - now building table ')
    
            for i = 1:length(data)
                datapoint = jsondecode(data(i));
                row =   (datapoint.day-1)*120+...
                        (datapoint.block-1)*30+...
                         datapoint.trial;
                column = datapoint.identifier;
                db_tableOfContents{row,column} = db_tableOfContents{row,column}+1;
            end
    
            % pass table on
            disp(' ')
            disp('1 show | 2 save | 3 latex | 4 continue')
            todo = input('next: ');
            switch todo
                case 1
                    fig = figure;
                    % create a uitable object and set its position in the figure window
                    uit = uitable(fig, 'Data', db_tableOfContents{:,:}, 'ColumnName', T.Properties.VariableNames, 'Position', [0 0 1000 500]);
                    % set the column widths to fit the data
                    uit.ColumnWidth = {'auto','auto','auto'};
                case 2
                    % prompt user to choose a file
                    [filename, pathname] = uiputfile('*.csv', 'Save File As');
    
                    % if user clicked 'cancel', exit script
                    if isequal(filename,0) || isequal(pathname,0)
                        disp('File not saved');
                        return
                    end
                    
                    % Save table to a file in the selected folder
                    writetable(db_tableOfContents, fullfile(pathname, filename));
                    disp('Table saved successfully');
                case 3
                    % convert to latx
                    output = table2latex(db_tableOfContents);
    
                    % prompt user to choose a file
                    [filename, pathname] = uiputfile('*.txt', 'Save File As');
                    
                    % if user clicked 'cancel', exit script
                    if isequal(filename,0) || isequal(pathname,0)
                        disp('File not saved');
                        return
                    end
                    
                    % create full file path
                    filepath = fullfile(pathname, filename);
                    
                    % open file for writing
                    fileID = fopen(filepath, 'w');
                    
                    % write data to file
                    for i = 1:length(output)
                        fprintf(fileID, '%s\n', output{i});
                    end
                    
                    % close file
                    fclose(fileID);
                    
                    disp('Latex saved successfully');
            end
        
        case action == 2 % process included raw data
            disp('getting ids…')
            % processing parameters
            SRATE = 5000;
            freq_h = 10;
            freq_l = 6;
            ORDER = 4;
            LENGTH = 100000;

            % get unique object ids
            query = py.dict(pyargs('data type','EMG'));
            object_ids = find_unique(db_name,'raw','_id',query);
            disp('ids done')

            % progress bar
            counter = 0;
            h = waitbar(0,['Processing Raw Data ', num2str(counter*100),'%']);
            total = length(object_ids);

            % itterate & process objects
            start_time = datetime;
            for i = 1:length(object_ids)

                % get, process & put trial data
                query = py.dict(pyargs('_id',object_ids{i}));
                data_in = get_data(db_name,'raw',query);
                data = double(string(data_in{1}{'data'}));
                data = proc_std(data, SRATE, freq_h, freq_l, ORDER);
                data = stnd4time(data, LENGTH);
                data_in{1}{'data'} = py.list(data);
                data_in{1}.pop('_id');
                put_data(db_name,'processed',data_in{1});

                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
            end

            % timer output
            disp("  -> Raw Data processed")
            disp("     runtime: " + string(datetime-start_time));
            close(h)

        case action == 3 % calculate mean trials
            pipeline = py.list({py.dict(pyargs("$group", py.dict(pyargs("_id", py.dict(pyargs("identifier", "$identifier", "day", "$day", "block", "$block","lead","$lead"))))))});
            sessions = aggregate(db_name,'processed',pipeline);

            h = waitbar(0, 'Calculating mean trials...');  % initialize progress bar
            start_time = datetime;
            for i = 1:length(sessions)
                session = sessions{i}{'_id'};
%                                 filter = py.dict(pyargs('identifier',session{'ID'},'day',session{'day'},'block',session{'BN'},'data type','EMG'));
%                                 query = py.dict(pyargs('_id','$lead'));
%                                 pipeline = py.list({py.dict(pyargs("$match",filter,"$group",query))});

                data = get_data(db_name,'processed',session,batch_size=int8(10));
                mean_trial = zeros(1,100000);
                for j = 1:length(data)
                    mean_trial = mean_trial + double(data{j}{'data'});
                end
                mean_trial = mean_trial/length(data);
                
                output = py.dict(pyargs('identifier',session{'identifier'},'day',session{'day'},'block',session{'block'},'lead',session{'lead'},'mean trial',py.list(mean_trial)));
                put_data(db_name,'mean',output);

                waitbar(i/length(sessions), h, sprintf('Calculating mean trials... %d%%', round(100*i/length(sessions))));  % update progress bar

            end
            disp("  -> Mean trials calculated")
            disp("     runtime: " + string(datetime-start_time));
            close(h);  % close progress bar

        case action == 4 % measure euclidean distances
            spaces = {["ADM" "APB" "FDI" "BIC" "FCR"] ["ADM" "APB" "FDI"] ["BIC" "FCR"] ["ADM"] ["APB"] ["FDI"] ["BIC"] ["FCR"]};
            start_time = datetime;
            for i = 1:length(spaces)
                space = spaces{i};
                disp(string(datetime) + " " + strjoin(space,' '))
                measure_space(db_name, space);
            end
            disp("  -> spaces measure")
            disp("     runtime: " + string(datetime-start_time));

        case action == 5 % describe variability
            % get variability by subject & block
            pipeline = py.list({ ...
                                py.dict(pyargs('$group', py.dict(pyargs( ...
                                    '_id', py.dict(pyargs( ...
                                        'identifier', '$identifier', ...
                                        'day', '$day', ...
                                        'block', '$block', ...
                                        'space', '$space'...
                                    )) ...
                                )))) ...
                            });
            data = aggregate(db_name, 'variability', pipeline);

            % measure descriptives [ skew, kurtosis ]
            h = waitbar(0, 'Analyzing variability...');  % initialize progress bar
            start_time = datetime;
            for i = 1:length(data)
                % Define the subject, day, block and space inputs
                data_in = data{i}{'_id'};
                identifier_input = data_in{'identifier'};
                day_input = data_in{'day'};
                block_input = data_in{'block'};
                space_input = data_in{'space'};
                
                % Define the pipeline
                pipeline = py.list({ ...
                    py.dict(pyargs('$match', py.dict(pyargs( ...
                        'identifier', identifier_input, ...
                        'day', day_input, ...
                        'block', block_input, ...
                        'space', space_input...
                    )))), ...
                    py.dict(pyargs('$group', py.dict(pyargs( ...
                        '_id', py.None, ...
                        'distance', py.dict(pyargs( ...
                            '$push', '$distance' ...
                        )) ...
                    )))), ...
                    py.dict(pyargs('$project', py.dict(pyargs( ...
                        '_id', py.False, ...
                        'distance', py.True ...
                    )))) ...
                });
                variability = aggregate(db_name, 'variability', pipeline);

                % determine skew & kurtosis
                variability = double(string(variability{1}{'distance'}));
                skew = skewness(variability);
                kurt = kurtosis(variability);
                n = length(variability);
                if n ~= 2 % at n = 2 the se = infinity, which would throw an error
                    se_skew = sqrt(6*n*(n-1)/((n-2)*(n+1)*(n+3)));
                    se_kurt = sqrt(24*n*(n-1)/((n-2)*(n-3)*(n+3)*(n+5)));
                else
                    se_skew = nan;
                    se_kurt = nan;
                end

                % determine range
                max_var = max(variability);
                min_var = min(variability);
                range_var = range(variability);
                mean_var =  mean(variability);
                median_var = median(variability);
                
                % put data
                output = data_in;
                output{'skew'} = skew;
                output{'se_skew'} = se_skew;
                output{'kurtosis'} = kurt;
                output{'se_kurtosis'} = se_kurt;
                output{'max'} = max_var;
                output{'min'} = min_var;
                output{'range'} = range_var;
                output{'mean'} = mean_var;
                output{'median'} = median_var;
                put_data(db_name, 'describe_variability', output);
                waitbar(i/length(data), h, sprintf('Analyzing variability... %d%%', round(100*i/length(data))));  % update progress bar
            end
            close(h) % close progress bar
            disp("  -> variability explored")
            disp("     runtime: " + string(datetime-start_time));

        case action == 6 % describe emg
            % like case 4 euc dists
            %     • what to do with multidimensional spaces?
            %     add/avarage/only compare 1D/time and lead as regressors?
            SRATE = 5000;
            % get unique object ids                              % to get only emg data when multiple data types in collection 'processed'
                                                                 % query = py.dict(pyargs('data type','EMG'));
            object_ids = find_unique(db_name,'processed','_id'); % find_unique(db_name,'processed','_id',query);
            disp('ids done')

            h = waitbar(0, 'Analyzing EMG...');  % initialize progress bar
            start_time = datetime;

            % itterate & measure emg tracks
            for i = 1:length(object_ids)
                % get data
                query = py.dict(pyargs('_id',object_ids{i}));
                data = get_data(db_name,'processed',query);
                data = data{1};
                emg = data.pop('data');
                % can I do double directly or must it be via string?
                emg = double(string(emg));
                data.pop('_id'); % remove unnecessary data
                data.pop('data type');

                % calculate descriptives
                emg_max = max(emg); % find maximal amplitude
                emg_rms = rms(emg); % calculate the root mean square
                % ...find the median power frequency
                 % ...find the median power frequency
                nfft = 2^nextpow2(length(emg)); % Set the parameters for the PSD calculation
                win_length = min(nfft, length(emg));
                overlap_length = round(win_length/2);
                window = hanning(win_length);
                [Pxx, f] = pwelch(emg, window, overlap_length, nfft, SRATE); % Calculate the power spectral density of the EMG signal using Welch's method
                emg_mpf = medfreq(Pxx,f);

                % write descriptives to db
                data{'max'} = emg_max;
                data{'rms'} = emg_rms;
                data{'mpf'} = emg_mpf;
                put_data(db_name, 'describe_emg', data);
                waitbar(i/length(object_ids), h, sprintf('Analyzing EMG... %d%%', round(100*i/length(object_ids))));  % update progress bar
            end
            close(h) % close progress bar
            disp("  -> emg description completed")
            disp("     runtime: " + string(datetime-start_time));

        case action == 7 % view model
            % input
            disp('view model')
            data_type = setDataType(data_type);
            [pipeline, collection, dependant_name, emg_space] = createPipeline(db_name, data_type);
            data = aggregate(db_name, collection, pipeline);
            
            % convert mongodb result to matlab table
            t = mongoquery2table(data);

            % get dependant
            dependant = t{:, dependant_name};
            
            % calculate regressors
            switch data_type
                case 'variability'
                    regressors = ((t.block-1)*30)+t.trial;

                case 'skill'
                    regressors = t.BN;
                    
                case 'v_d'
                    regressors = t.block;

                case 'emg_d'
                    regressors = ((t.block-1)*30)+t.trial;
            end

            % fit model
            mdlr = fitlm(regressors,dependant,'RobustOpts','on');
            
            % output
            if data_type == "variability"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " ");
                regressor_info = "regressor: ((t.block-1)*30)+t.trial";
            elseif data_type == "v_d"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " "); 
                regressor_info = "regressor: block";
            elseif data_type == "skill"
                dependant_info = "dependant:  " + dependant_name;
                regressor_info = "regressor: block";
            elseif data_type == "emg_d"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " "); 
                regressor_info = "regressor: ((t.block-1)*30)+t.trial";
            end
            disp(' ')
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––");
            fprintf("<strong>Robust Linear Regression Model</strong>"); %fprintf("<strong>Robust Multiple Linear Regression Model | Group "+string(group)+" Day "+string(day)+"</strong>");
            disp(' ');
            disp(dependant_info);
            disp(regressor_info);
            disp(' ')
            disp(mdlr)
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")

        case action == 8 % comparative model
            % same code as view model, just twice. 
            %  once for test and base group
            %  and then the additional dummy regressor
            %
            % Model:
            %     y =	int +	x1*time +	x2*gX_binary +	x3*gX_binary*session
            %
            % Interpretation of Coefficients
            %
            % 	             group A  |  group X vs group A
            %   ––––––––––––––––––––––––––––––––––––––––––––
            %   intercept |	intercept |	    x2
            %   time	  |    x1	  |     x3
            %
            coefficient_interpretation = table(["intercept"; "x1"], ["x2"; "x3"], ["intercept + x2"; "x1 + x3"],'RowNames',["intercept" "time"]);

            % input
            disp('creating comparative model')
            data_type = setDataType(data_type);
            disp(' ')
            disp('choose test group')
            [pipeline, collection, test_dependant_name, test_emg_space] = createPipeline(db_name, data_type);
            test_data = aggregate(db_name, collection, pipeline);

            disp(' ')
            disp('choose base group')
            [pipeline, collection, base_dependant_name, base_emg_space] = createPipeline(db_name, data_type);
            base_data = aggregate(db_name, collection, pipeline);
            
            % convert mongodb result to matlab table
            test_table = mongoquery2table(test_data);
            base_table = mongoquery2table(base_data);

            % get dependant
            test_dependant = test_table{:, test_dependant_name};
            base_dependant = base_table{:, base_dependant_name};
            dependant = [test_dependant; base_dependant];
            
            % calculate regressors
            switch data_type
                case 'variability'
                    test_regressors = ((test_table.block-1)*30)+test_table.trial;
                    base_regressors = ((base_table.block-1)*30)+base_table.trial;

                case 'skill'
                    test_regressors = test_table.BN;
                    base_regressors = base_table.BN;
                    
                case 'v_d'
                    test_regressors = test_table.block;
                    base_regressors = base_table.block;

                case 'emg_d'
                    test_regressors = ((test_table.block-1)*30)+test_table.trial;
                    base_regressors = ((base_table.block-1)*30)+base_table.trial;
            end

            % ... add binaries
            test_binary = [test_regressors ones([height(test_regressors) 1])];
            base_binary = [base_regressors zeros([height(base_regressors) 1])];
            % ... add intercept term (time*binary)
            regressors = [test_binary; base_binary];
            regressors = [regressors regressors(:,1).*regressors(:,2)];

            % fit model
            mdlr = fitlm(regressors,dependant,'RobustOpts','on');
            
            % output
            %coefficient_interpretation.Properties.VariableNames = ["G"+base_group+"d"+base_day "G"+test_group+"d"+test_day+" vs G"+base_group+"d"+base_day "G"+test_group+"d"+test_day];
            if data_type == "variability"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " ");
                regressor_info = "regressor: ((t.block-1)*30)+t.trial";
            elseif data_type == "v_d"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " "); 
                regressor_info = "regressor: block";
            elseif data_type == "skill"
                dependant_info = "dependant:  " + dependant_name;
                regressor_info = "regressor: block";
            elseif data_type == "emg_d"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " "); 
                regressor_info = "regressor: ((t.block-1)*30)+t.trial";
            end
            disp(' ')
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
            fprintf("<strong>Comparative Robust Linear Regression Model</strong>"); %fprintf("<strong>RMLR - Group "+string(test_group)+" day "+string(test_day)+" vs Group "+string(base_group)+" day "+string(base_day)+"</strong>")
            disp(' ');
            disp(dependant_info);
            disp(regressor_info);
            disp(' ')
            disp(coefficient_interpretation)
            disp(mdlr)
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
          
        case action == 9 % create graphs
            disp('create graph')
            % initiate figure
            titletext = input('title: ','s');
            f = figure();
            drawnow();
            hold on;

            % set title
            title(titletext, 'FontSize', 25, 'FontWeight', 'bold');
            drawnow()

            % plot models
            ylabeltext = input("y label: ","s");
            legendcontent = [];
            while true
                % input
                disp(' ');
                data_type = setDataType(data_type);
                [pipeline, collection, dependant_name, emg_space] = createPipeline(db_name, data_type);
                data = aggregate(db_name, collection, pipeline);
                
                % convert mongodb result to matlab table
                t = mongoquery2table(data);
    
                % get dependant
                dependant = t{:, dependant_name};
                
                % calculate regressors
                switch data_type
                    case 'variability'
                        regressors = ((t.block-1)*30)+t.trial;
    
                    case 'skill'
                        regressors = t.BN;
                        
                    case 'v_d'
                        regressors = t.block;
    
                    case 'emg_d'
                        regressors = ((t.block-1)*30)+t.trial;
                end
    
                % fit model
                mdlr = fitlm(regressors,dependant,'RobustOpts','on');

                % reapply model
                intercept   = mdlr.Coefficients{1,1};
                effect      = mdlr.Coefficients{2,1};
                switch true % calcualte scafold
                    case data_type == "variability" || data_type == "emg_d"
                        time_scaffold = transpose(1:120);
                        set(gca,'XLim',[1 120],'XTick',15:30:105);
    
                    case data_type == "skill" || data_type == "v_d"
                        time_scaffold = transpose(1:4);
                        set(gca,'XLim',[0.5 4.5],'XTick',1:1:4);
                end
                reapplied_model = intercept + effect*time_scaffold(:,1);

                %plot model
                linewidth = input("linewidth: ");
                linecolor = input("linecolor: ","s");
                plotlabel = input("legend label: ","s");

                legendcontent = [legendcontent string(plotlabel)];

                plot(reapplied_model, 'LineWidth', linewidth, 'Color', linecolor);
                legend(legendcontent);

                set(gca,'box','off');
                set(findall(gcf,'-property','FontSize'),'FontSize',20);
                xticklabels(["1", "2", "3", "4"]);
                xlabel("session");
                ylabel(ylabeltext);
                drawnow();

                % continue?
                action2 = input("continue (y/n): ","s");
                if action2 == "n"
                    break
                end
            end

            % post creation edits
            while true
                listofedits = ...
                        " \n"+...
                        "1 reset x\n"+...
                        "2 set y\n"+...
                        "9 save\n"+...
                        "0 end\n"+...
                        "\n";
                fprintf(listofedits);
                editing = input("edit: ");
    
                switch editing
                    case 1 % reset x
                        switch data_type % calcualte scafold
                            case data_type == "variability" || data_type == "emg_d"
                                time_scaffold = transpose(1:120);
                                set(gca,'XLim',[1 120],'XTick',15:30:105);
            
                            case data_type == "skill" || data_type == "v_d"
                                time_scaffold = transpose(1:4);
                                set(gca,'XLim',[0.5 4.5],'XTick',1:1:4);
                        end
    
                    case 2 % set y
                        disp('y lim:')
                        high = input(' upper: ');
                        low  = input(' lower: ');
                        ylim([low high]);
    
                    case 9 % save
                        set(f, 'Renderer', 'painters');
                        [filename, pathname] = uiputfile('*.pdf', 'Save Graph');
                        if isequal(filename,0) || isequal(pathname,0) % if user clicked 'cancel', exit script
                            disp('File not saved');
                            return
                        end
                        print(fullfile(pathname, filename), '-dpdf'); % save as pdf
                        savefig(f,fullfile(pathname, filename)); % save as matlab figure
                        disp("Figure saved as " + filename + " to " + pathname);
    
                    case 0 % finish edit
                        break
                end
                drawnow()
            end

        case action == 10 % correlate delta 4-1
            disp('determine correlation')
            % get 2 continuous variabes
            % var 1, session 1 & 4
            disp(' ')
            disp(' variable 1')
            data_type = setDataType(data_type);
            var1 = data_type;
            [pipeline, collection, dependant_name, emg_space] = createPipeline(db_name, data_type); % returns full day
            data = aggregate(db_name, collection, pipeline);
            t = mongoquery2table(data);
            if data_type == "skill" % rename columns of skill table to match all other data
                t.Properties.VariableNames = {'identifier', 'day', 'block', 'skillp'};
            end

            % percentile cutt-off
            switch true
                case data_type == "variability"
                    
        
                case data_type == "v_d" 


                case data_type == "emg_d"
                    
            end

            session_1 = t(t{:,'block'}==1,:); % get subtable for session 1
            session_4 = t(t{:,'block'}==4,:); % get subtable for session 4
            % compound to session resolution
            if data_type == "variability" || data_type == "emg_d"
                % session_1 = removevars(session_1, 'space');
                session_1 = varfun(@mean, session_1, 'GroupingVariables', {'identifier', 'day', 'block'}, 'InputVariables', dependant_name);
                session_1 = removevars(session_1, 'GroupCount');
                % session_4 = removevars(session_4, 'space');
                session_4 = varfun(@mean, session_4, 'GroupingVariables', {'identifier', 'day', 'block'}, 'InputVariables', dependant_name);
                session_4 = removevars(session_4, 'GroupCount');
                dependant_name = "mean_"+dependant_name;
            end
            t1 = intersect(session_1(:,{'identifier'}), session_4(:,{'identifier'}), 'rows');
            t1 = addvars(t1, zeros(height(t1),1),'NewVariableNames','delta_4_1');
             
            for i = 1:height(t1)
                id = t1{i,'identifier'};
                t1{i,'delta_4_1'} = session_4{session_4.identifier==id,dependant_name}-session_1{session_1.identifier==id,dependant_name};
            end

            % var 2, session 1 & 4
            disp(' ')
            disp(' variable 2')
            data_type = setDataType(data_type);
            var2 = data_type;
            [pipeline, collection, dependant_name, emg_space] = createPipeline(db_name, data_type); % returns full day
            data = aggregate(db_name, collection, pipeline);
            t = mongoquery2table(data);
            if data_type == "skill" % rename columns of skill table to match all other data
                t.Properties.VariableNames = {'identifier', 'day', 'block', 'skillp'};
            end
            session_1 = t(t{:,'block'}==1,:); % get subtable for session 1
            session_4 = t(t{:,'block'}==4,:); % get subtable for session 4
            % compound to session resolution
            if data_type == "variability" || data_type == "emg_d"
                % session_1 = removevars(session_1, 'space');
                session_1 = varfun(@mean, session_1, 'GroupingVariables', {'identifier', 'day', 'block'}, 'InputVariables', dependant_name);
                session_1 = removevars(session_1, 'GroupCount');
                % session_4 = removevars(session_4, 'space');
                session_4 = varfun(@mean, session_4, 'GroupingVariables', {'identifier', 'day', 'block'}, 'InputVariables', dependant_name);
                session_4 = removevars(session_4, 'GroupCount');
                dependant_name = "mean_"+dependant_name;
            end
            t2 = intersect(session_1(:,{'identifier'}), session_4(:,{'identifier'}), 'rows');
            t2 = addvars(t2, zeros(height(t2),1),'NewVariableNames','delta_4_1');

            for i = 1:height(t2)
                id = t2{i,'identifier'};
                t2{i,'delta_4_1'} = session_4{session_4.identifier==id,dependant_name}-session_1{session_1.identifier==id,dependant_name};
            end

            % find common row of var 1 & 2
            t3 = intersect(t1(:,{'identifier'}), t2(:,{'identifier'}), 'rows');
            t3 = addvars(t3, zeros(height(t3),1), zeros(height(t3),1),'NewVariableNames',[string(var1), string(var2)]);
            for i = 1:height(t3)
                id = t3{i,'identifier'};
                t3{i,var1} = t1{t1.identifier==id, "delta_4_1"}; % add var1 to common table
                t3{i,var2} = t2{t2.identifier==id, "delta_4_1"}; % add var2 to common table
            end
            disp(' ')
            % correlate
            [r, p] = corr(t3{:,var1}, t3{:,var2}, 'Type', 'Pearson')

        case action == 12 % violin charts
            % get data
            data_type = 'variability';
            [pipeline, collection, dependant_name, emg_space] = createPipeline('fatigue', data_type);
            data = aggregate(db_name, collection, pipeline);
            t = mongoquery2table(data);
            
            data = {};
            data{1} = t{t.block==1,"distance"};
            data{2} = t{t.block==2,"distance"};
            data{3} = t{t.block==3,"distance"};
            data{4} = t{t.block==4,"distance"};
            
            % Imagine how your plot will look!
            style = {};
            style{1}  = 0.7; % How wide should the boxes be? (between 0.5 and 1)
            style{2}  = 1.5; % How thick will the lines be on the box and the violin?
            style{3}  = 'k'; % What color should the outlines be?
            style{4}  = repelem([0.5,0.5,0.5],4,1);
            
            % plot
            violin_chart(data, style)

        case action == 0 % reset cml view
            clc
            fprintf(operations_list);
        case action == 666 % Case 666: Terminate Script   
            run_script = 0;
            
        case action == 911 % Case 911: Clear Workspace
            clearvars -except action

    end % end of master switch
end % end of master while loop

%% Functions
function emg_space = emgSpaceSelector(db_name)

        pyModule = py.importlib.import_module('mongodb');
        pyModule = py.importlib.reload(pyModule);
        aggregate = pyModule.aggregate;

        % get all spaces present in the variability collection
        unwind_stage = py.dict(pyargs('$unwind', py.str('$space')));
        group_stage_1 = py.dict(pyargs('$group', py.dict(pyargs('_id', py.str('$_id'),'space', py.dict(pyargs('$addToSet', py.str('$space')))))));
        group_stage_2 = py.dict(pyargs('$group', py.dict(pyargs('_id', py.str('$space'),'count', py.dict(pyargs('$sum', py.int(1)))))));
        sort_stage = py.dict(pyargs('$sort', py.dict(pyargs('_id', py.int(1)))));
        pipeline = py.list({unwind_stage, group_stage_1, group_stage_2, sort_stage});
        data = aggregate(db_name,'variability',pipeline);
        spaces = {};
        for i = 1:length(data)
            space = {string(data{i}{'_id'})};
            spaces = [spaces; space];
        end

        disp("  available emg spaces")
        fprintf(' ')
        for i = 1:length(spaces)
            fprintf("  "+string(i)+" "+strjoin(spaces{i},' ')+" |")
        end
        fprintf('\n')

        disp(' ')
        emg_space = input('emg space:  ');
        emg_space = spaces{emg_space};
        
end

function feedback = measure_space(db_name, space)
        pyModule = py.importlib.import_module('mongodb');
        pyModule = py.importlib.reload(pyModule);
        get_data = pyModule.get_data;
        find_unique = pyModule.find_unique;
        put_data = pyModule.put_data;
        aggregate = pyModule.aggregate;

        % get all unique trials in the processed collection
        disp('getting ids…')
        pipeline = py.list({py.dict(pyargs("$group",py.dict(pyargs('_id', py.dict(pyargs(...
                                                                   'identifier', '$identifier', ...
                                                                   'day', '$day', ...
                                                                   'block', '$block', ...
                                                                   'trial', '$trial')) ...
                       )))),py.dict(pyargs("$project",py.dict(pyargs(...
                                                                   '_id', int32(1)...
                                                                    )))), ...
                          });
        object_ids = aggregate(db_name, "processed", pipeline);
        disp('ids done')

        % itterate object_ids
        measured = [];
        missing_leads = [];
        h = waitbar(0, 'Measuring euclidean distances...');  % initialize progress bar
        start = datetime;
        for i = 1:length(object_ids)
            % check if requiered leads exist
            parameters = object_ids{i}{'_id'};
            query = py.dict(pyargs( "identifier", parameters{"identifier"}, "day", parameters{"day"}, "block", parameters{"block"}, "trial", parameters{"trial"}));
            projection = py.dict(pyargs("lead",1));
            leads = get_data(db_name,"processed",query,projection);
            leads = cellfun(@(d) strip(string(d{"lead"})), cell(leads), 'UniformOutput', true);

            if isempty(setdiff(space, leads))
                % get trial array
                query = py.dict(pyargs( "identifier", parameters{"identifier"}, "day", parameters{"day"}, "block", parameters{"block"}, "trial", parameters{"trial"}, "lead", py.dict(pyargs('$in',py.list(cellstr(space))))));
                data = get_data(db_name,"processed",query);
                data = cellfun(@(d) double(d{"data"}), cell(data), 'UniformOutput', false);
                data = cell2mat(transpose(data));

                % get mean trial array
                query = py.dict(pyargs( "identifier", parameters{"identifier"}, "day", parameters{"day"}, "block", parameters{"block"}, "lead", py.dict(pyargs('$in',py.list(cellstr(space))))));
                mean_trial = get_data(db_name,"mean",query);
                mean_trial = cellfun(@(d) double(d{"mean trial"}), cell(mean_trial), 'UniformOutput', false);
                mean_trial = cell2mat(transpose(mean_trial));

                % measure distance with Lpq norm
                result = Lpq_norm(2,1,transpose(data-mean_trial));

                % save result to db
                output = parameters;
                measured = [measured struct(output)];
                output{'space'} = strjoin(space, " ");
                output{'distance'} = result;
                put_data(db_name,'variability',output);
            else
                % save missing leads to db
                output = parameters;
                missing_leads = [missing_leads struct(output)];
                output{'space'} = strjoin(space, " ");
                output{'distance'} = "missing leads";
                output{'missing leads'} = py.list(cellstr(setdiff(space, leads)));
                put_data(db_name,'variability',output);
            end
            waitbar(i/length(object_ids), h, sprintf('Measuring euclidean distances... %d%%', round(100*i/length(object_ids))));  % update progress bar
        end

        stop = datetime;
        close(h)
        % return list of measured and unmeasured trials
        feedback = struct('measured', measured, 'missing_leads', missing_leads, 'duration', stop-start);
end

function feedback = mongoquery2table(query_in)
        % Convert PyMongo query result to MATLAB table
        data = cell(query_in);
        for i = 1:numel(data)
            data{i}.pop('_id');
        end
        s = py.list(data);
        s = cellfun(@struct, cell(s), 'UniformOutput', false);
        s = [s{:}];
        t = struct2table(s);
        
        % Convert string columns to MATLAB string type, and double columns to double type
        for col = 1:size(t, 2)
            try
                if strcmp(class(t{1, col}{1}), 'py.str')
                    t.(col) = string(t{:, col});
                elseif strcmp(class(t{1, col}{1}), 'py.int')
                    t.(col) = cellfun(@(x) double(int64(x)), t.(col));
                elseif strcmp(class(t{1, col}{1}), 'py.list')
                    t.(col) = cellfun(@(x) strjoin(string(x), " "), t{:, col}); % string(t{:, col});
                end
            catch ME
                % Catch indexing error and do nothing
                if strcmp(ME.identifier, 'MATLAB:cellRefFromNonCell')
                % Leave column as is
                else
                % Re-throw any other errors
                rethrow(ME)
                end
            end
        end
        
        % Convert all remaining columns to cell type
        t = table2cell(t);
        feedback = cell2table(t, 'VariableNames', fieldnames(s));

end

function [pipeline, collection, dependant_name, emg_space] = createPipeline(db_name, data_type)
    
    pyModule = py.importlib.import_module('mongodb');
    pyModule = py.importlib.reload(pyModule);
    aggregate = pyModule.aggregate;

    % ask for group
    group       = input(' group: ','s');
    group = strip(group);
    if length(group) == 1 % convert group input to int or list of ints
        group = int32(str2num(group));
    elseif length(group) > 1
        group = strip(split(group, ","));
        group = cellfun(@(x) str2num(x), group);
        group = int32(group);
        group = py.list(group);
        group = py.dict(pyargs('$in',group));
    else
        disp('invalid group input')
        return
    end
    % ask for day
    day         = int32(input(' day:   '));
    % ask for descriptive
    if data_type == "v_d" || data_type == "emg_d" 
        descriptive2plot = input('descriptive: ','s');
    end
    % ask for emg space
    if data_type ~= "skill" % do not ask for emg space when modeling skill
        emg_space   = emgSpaceSelector(db_name);
    end

    % get members of group from parameters collection
    pipeline = py.list({...
        py.dict(pyargs('$match',py.dict(pyargs('label', group)))),...
        py.dict(pyargs('$group',py.dict(pyargs('_id', '$label', 'ID', py.dict(pyargs('$addToSet', '$ID'))))))...
        });
    feedback = cell(aggregate('fatigue','parameters',pipeline));
    members = py.list();
    for i = 1:length(feedback)
        members.extend(feedback{i}{'ID'});
    end


    % set return values
    switch true
        case data_type == "variability"
            pipeline = py.list({
                py.dict(pyargs('$match', py.dict(pyargs(...
                    'identifier', py.dict(pyargs('$in', members)),...
                    'day', day,...
                    'space', emg_space,...
                    'distance', py.dict(pyargs("$ne", "missing leads"))...
                    ))))
                });
            collection     = 'variability';
            dependant_name = 'distance';

        case data_type == "skill"
            pipeline = py.list({
                py.dict(pyargs('$match', py.dict(pyargs(...
                    'ID', py.dict(pyargs('$in', members)),...
                    'day', day...
                    )))), ...
                py.dict(pyargs('$project', py.dict(pyargs(...
                    '_id', int32(1), ...
                    'ID', int32(1), ...
                    'day', int32(1), ...
                    'BN', int32(1), ...
                    'skillp', int32(1) ...
                    ))))
                });
            collection     = 'parameters';
            dependant_name = 'skillp';
            emg_space = '';

        case data_type == "v_d" % descriptive of variability or emg
            match_stage = py.dict(pyargs('$match', py.dict(pyargs(...
                    'identifier', py.dict(pyargs('$in', members)), ...
                    'day', day, ...
                    'space', emg_space, ...
                    descriptive2plot, py.dict(pyargs('$ne', NaN))...
                ))));
            project_stage = py.dict(pyargs('$project', py.dict(pyargs('_id', int32(1), 'identifier', int32(1), 'day', int32(1), 'block', int32(1), descriptive2plot, int32(1)))));
            pipeline = py.list({match_stage, project_stage});
            collection = "describe_variability";
            dependant_name = descriptive2plot;

        case data_type == "emg_d" % descriptive of variability or emg
            match_stage = py.dict(pyargs('$match', py.dict(pyargs(...
                    'identifier', py.dict(pyargs('$in', members)), ...
                    'day', day, ...
                    'lead', emg_space, ...
                    descriptive2plot, py.dict(pyargs('$ne', NaN))...
                ))));
            project_stage = py.dict(pyargs('$project', py.dict(pyargs('_id', int32(1), 'identifier', int32(1), 'day', int32(1), 'block', int32(1), 'trial', int32(1), descriptive2plot, int32(1)))));
            pipeline = py.list({match_stage, project_stage});
            collection = "describe_emg";
            dependant_name = descriptive2plot;
    end
end

function data_type = setDataType(data_type_in)
    data_type = input('data type: ','s');
    if data_type == ""
        data_type = data_type_in;
    end
end