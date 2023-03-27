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

%import python functions for mongodb interaction
if count(py.sys.path, '/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/z functions/Functions Joshua') == 0
    insert(py.sys.path, int32(0), '/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/z functions/Functions Joshua');
end
pyModule = py.importlib.import_module('mongodb');
pyModule = py.importlib.reload(pyModule);
get_data = pyModule.get_data;
find_unique = pyModule.find_unique;
put_data = pyModule.put_data;
aggregate = pyModule.aggregate;


% supress warnings
warning('off','MATLAB:table:RowsAddedNewVars')

% print legend to cml
operations_list = ...
    " \n"+...
    "1 mark outliers\n"+...
    "2 filter, rectify & stnd4time\n"+...
    "3 mean trials\n"+...
    "4 measure euclidean distances\n"+...
    "5 describe variability\n"+...
    " \n"+...
    "6 view model\n" + ...
    "7 comparative model\n"+...
    "8 create graphs\n"+...
    "\n";
fprintf(operations_list);

%% master while loop
while run_script == 1

    % Select Operation
    disp(' ')
    action = input('What would you like me to do? ');
    disp(' ')

    what_to_process = 0;

    switch true

        case what_to_process == 1 || what_to_process == 2 % db content table
    
            % get unique participant identifiers
            collection = input('collection: ','s');
            participants = find_unique('fatigue_sample',collection,'identifier');
            participants = string(participants);
            db_tableOfContents = array2table(zeros(240,length(participants)));
            db_tableOfContents.Properties.VariableNames = participants;
            db_tableOfContents.Properties.RowNames = string(1:240);
    
            % get data
            if what_to_process == 1
                query = py.dict(pyargs('data type','EMG'));
            else
                lead = input('lead: ','s');
                query = py.dict(pyargs('data type','EMG','lead',lead));
            end
            projection = py.dict(pyargs('identifier',1,'day',1,'block',1,'trial',1));
            data = get_data('fatigue_sample',collection,query, projection, batch_size = int8(10));
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
        
        
        case action == 1 % update inclusion status

        case action == 2 % process included raw data
            disp('started processing')
            % processing parameters
            SRATE = 5000;
            freq_h = 10;
            freq_l = 6;
            ORDER = 4;
            LENGTH = 100000;

            % get unique object ids
            query = py.dict(pyargs('data type','EMG'));
            object_ids = find_unique('fatigue_sample','raw','_id',query);
            disp('ids done')

            % progress bar
            counter = 0;
            h = waitbar(0,['Processing Raw Data ', num2str(counter*100),'%']);
            total = length(object_ids);

            % itterate & process objects
            start_time = now;
            for i = 1:length(object_ids)

                % get, process & put trial data
                query = py.dict(pyargs('_id',object_ids{i}));
                data_in = get_data('fatigue_sample','raw',query);
                data = double(string(data_in{1}{'data'}));
                data = proc_std(data, SRATE, freq_h, freq_l, ORDER);
                data = stnd4time(data, LENGTH);
                data_in{1}{'data'} = py.list(data);
                data_in{1}.pop('_id');
                put_data('fatigue_sample','processed',data_in{1});

                %Update Progress bar
                counter = counter+1;
                waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
            end

            % timer output
            disp("  -> Raw Data processed")
            disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
            close(h)

        case action == 3 % calculate mean trials
            pipeline = py.list({py.dict(pyargs("$group", py.dict(pyargs("_id", py.dict(pyargs("identifier", "$identifier", "day", "$day", "block", "$block","lead","$lead"))))))});
            sessions = aggregate('fatigue_sample','processed',pipeline);

            h = waitbar(0, 'Calculating mean trials...');  % initialize progress bar
            
            for i = 1:length(sessions)
                session = sessions{i}{'_id'};
%                                 filter = py.dict(pyargs('identifier',session{'ID'},'day',session{'day'},'block',session{'BN'},'data type','EMG'));
%                                 query = py.dict(pyargs('_id','$lead'));
%                                 pipeline = py.list({py.dict(pyargs("$match",filter,"$group",query))});

                data = get_data('fatigue_sample','processed',session,batch_size=int8(10));
                mean_trial = zeros(1,100000);
                for j = 1:length(data)
                    mean_trial = mean_trial + double(data{j}{'data'});
                end
                mean_trial = mean_trial/length(data);
                
                output = py.dict(pyargs('identifier',session{'identifier'},'day',session{'day'},'block',session{'block'},'lead',session{'lead'},'mean trial',py.list(mean_trial)));
                put_data('fatigue_sample','mean',output);

                waitbar(i/length(sessions), h, sprintf('Calculating mean trials... %d%%', round(100*i/length(sessions))));  % update progress bar

            end
            
            close(h);  % close progress bar

        case action == 4 % measure euclidean distances
            spaces = {["ADM" "APB" "FDI"] ["BIC" "FCR"] ["ADM"] ["APB"] ["FDI"] ["BIC"] ["FCR"]};
            for i = 1:length(spaces)
                space = spaces{i};
                disp(string(datetime) + " " + strjoin(space,' '))
                measure_space(space);
            end

        case action == 5 % describe variability
            % get variability by subject & block
            pipeline = py.list({ ...
                                py.dict(pyargs('$group', py.dict(pyargs( ...
                                    '_id', py.dict(pyargs( ...
                                        'identifier', '$identifier', ...
                                        'day', '$day', ...
                                        'block', '$block' ...
                                    )) ...
                                )))) ...
                            });
            data = aggregate('fatigue_sample', 'variability', pipeline);

            % measure descriptives [ skew, kurtosis ]
            h = waitbar(0, 'Analyzing variability...');  % initialize progress bar
            for i = 1:length(data)
                % Define the subject, day, and block inputs
                data_in = data{i}{'_id'};
                identifier_input = data_in{'identifier'};
                day_input = data_in{'day'};
                block_input = data_in{'block'};
                
                % Define the pipeline
                pipeline = py.list({ ...
                    py.dict(pyargs('$match', py.dict(pyargs( ...
                        'identifier', identifier_input, ...
                        'day', day_input, ...
                        'block', block_input ...
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
                variability = aggregate('fatigue_sample', 'variability', pipeline);

                % determine skew & kurtosis
                variability = double(string(variability{1}{'distance'}));
                skew = skewness(variability);
                kurt = kurtosis(variability);
                n = length(variability);
                se_skew = sqrt(6*n*(n-1)/((n-2)*(n+1)*(n+3)));
                se_kurt = sqrt(24*n*(n-1)/((n-2)*(n-3)*(n+3)*(n+5)));
                
                % put data
                output = data_in;
                output{'skew'} = skew;
                output{'se_skew'} = se_skew;
                output{'kurtosis'} = kurt;
                output{'se_kurtosis'} = se_kurt;
                put_data('fatigue_sample', 'describe_variability', output);
                waitbar(i/length(data), h, sprintf('Analyzing variability... %d%%', round(100*i/length(data))));  % update progress bar
            end
            close(h) % close progress bar

%        case 2 % invetigate processed data
%             case 30 % view model
%             case 302 % compare spaces
%             case 31 % compare 1-day models
%             case 39 % compare 1-day models simple
%             case 32 % compare 2-day models
%             case 34 % plot regression models
%             case 35 % reapply model
%             case 36 % view model for skill
%             case 36.2 % comparative skill model
%             case 37 % plot skill model
%             case 38 % plot var & learning within group
%             case 41 % styling options
%             case 42 % empty legend
%             case 43 % plot skill measure
%             case 432 % plot skill measure
%             case 44 % ttest
%             case 45 % correlation
%             case 46 % correlate reapplied models
%             case 47 % correlation coefficient from intercept
%             case 48 % correlation coefficient from intercept

        case action == 6 % view model
            % input
%             emg_space   = emgSpaceSelector();
%             group       = input('group: ');
%             day         = input('day:   ');
% 
%             emg_space   = py.list(cellstr(emg_space));
%             group       = int32(group);
%             day         = int32(day);
            
            % input
            disp('view model')
            data_type        = input('data type: ','s');
            if data_type == "variability" % only ask for emg space when modeling variability
                emg_space   = py.list(cellstr(emgSpaceSelector()));
            end
            group       = int32(input(' group: '));
            day         = int32(input(' day:   '));
            if data_type == "v_d"
                disp(' ');
                descriptive2plot = input('descriptive: ','s');
            end

            % get members of group from parameters collection
            pipeline = py.list({...
                py.dict(pyargs('$match',py.dict(pyargs('label',group)))),...
                py.dict(pyargs('$group',py.dict(pyargs('_id', '$label', 'ID', py.dict(pyargs('$addToSet', '$ID'))))))...
                });
            members = cell(aggregate('fatigue','parameters',pipeline));
            members = members{1}{'ID'};


            % get data for all group members
            switch data_type
                case "variability"
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

                case "skill"
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

                case "v_d"
                    match_stage = py.dict(pyargs('$match', py.dict(pyargs('identifier', py.dict(pyargs('$in', members)), 'day', day, descriptive2analyse, py.dict(pyargs('$ne', NaN))))));
                    project_stage = py.dict(pyargs('$project', py.dict(pyargs('_id', 1, 'identifier', 1, 'day', 1, 'block', 1, descriptive2analyse, 1))));
                    pipeline = py.list({match_stage, project_stage});
                    collection = "describe_variability";
                    dependant_name = descriptive2analyse;

                case "s_d"
            end

            data = aggregate('fatigue_sample', collection, pipeline);
            
            % convert mongodb result to matlab table
            t = mongoquery2table(data);

            % get dependant
            dependant = t{:, dependant_name};
            
            % get regressors
            % calculate regressors
            switch data_type
                case 'variability'
                    regressors = ((t.block-1)*30)+t.trial;

                case 'skill'
                    regressors = t.BN;
                    
                case 'v_d'
                    regressors = t.block;

                case 'emg_d'
            end

            mdlr = fitlm(regressors,dependant,'RobustOpts','on');
            
            % output
            if data_type == "variability"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(emg_space), " ");
                regressor_info = "regressor: ((t.block-1)*30)+t.trial";
            elseif data_type == "skill" || data_type == "v_d"
                dependant_info = "dependant:  " + dependant_name;
                regressor_info = "regressor: block";
            end
            disp(' ')
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––");
            fprintf("<strong>Robust Multiple Linear Regression Model | Group "+string(group)+" Day "+string(day)+"</strong>");
            disp(' ');
            disp(dependant_info);
            disp(regressor_info);
            disp(' ')
            disp(mdlr)
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")

        case action == 7 % comparative variability model
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
            data_type        = input('data type: ','s');
            disp(' ')
            disp('choose test group')
            if data_type == "variability" % only ask for emg space when modeling variability
                test_emg_space   = py.list(cellstr(emgSpaceSelector()));
            end
            test_group       = int32(input(' group: '));
            test_day         = int32(input(' day:   '));
            disp(' ')
            disp('choose base group')
            if data_type == "variability" % only ask for emg space when modeling variability
                base_emg_space   = py.list(cellstr(emgSpaceSelector()));
            end
            base_group       = int32(input(' group: '));
            base_day         = int32(input(' day:   '));
            if data_type == "v_d"
                disp(' ');
                descriptive2analyse = input('descriptive: ','s');
            end
            
            % get members of group from parameters collection
            % …for test group
            pipeline = py.list({...
                py.dict(pyargs('$match',py.dict(pyargs('label',test_group)))),...
                py.dict(pyargs('$group',py.dict(pyargs('_id', '$label', 'ID', py.dict(pyargs('$addToSet', '$ID'))))))...
                });
            test_members = cell(aggregate('fatigue','parameters',pipeline));
            test_members = test_members{1}{'ID'};
            % …for base group
            pipeline = py.list({...
                py.dict(pyargs('$match',py.dict(pyargs('label',base_group)))),...
                py.dict(pyargs('$group',py.dict(pyargs('_id', '$label', 'ID', py.dict(pyargs('$addToSet', '$ID'))))))...
                });
            base_members = cell(aggregate('fatigue','parameters',pipeline));
            base_members = base_members{1}{'ID'};

            % set pipeline & collection for data type
            switch data_type
                case 'variability'
                    pipeline_test = py.list({
                        py.dict(pyargs('$match', py.dict(pyargs(...
                            'identifier', py.dict(pyargs('$in', test_members)),...
                            'day', test_day,...
                            'space', test_emg_space,...
                            'distance', py.dict(pyargs("$ne", "missing leads"))...
                            ))))
                        });
                    pipeline_base = py.list({
                        py.dict(pyargs('$match', py.dict(pyargs(...
                            'identifier', py.dict(pyargs('$in', base_members)),...
                            'day', base_day,...
                            'space', base_emg_space,...
                            'distance', py.dict(pyargs("$ne", "missing leads"))...
                            ))))
                        });
                    collection     = 'variability';
                    dependant_name = 'distance';

                case 'skill'
                    pipeline_test = py.list({
                        py.dict(pyargs('$match', py.dict(pyargs(...
                            'ID', py.dict(pyargs('$in', test_members)),...
                            'day', test_day...
                            )))), ...
                        py.dict(pyargs('$project', py.dict(pyargs(...
                            '_id', int32(1), ...
                            'ID', int32(1), ...
                            'day', int32(1), ...
                            'BN', int32(1), ...
                            'skillp', int32(1) ...
                            ))))
                        });
                    pipeline_base = py.list({
                        py.dict(pyargs('$match', py.dict(pyargs(...
                            'ID', py.dict(pyargs('$in', base_members)),...
                            'day', base_day...
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
                case 'v_d'                   
                    match_stage = py.dict(pyargs('$match', py.dict(pyargs('identifier', py.dict(pyargs('$in', test_members)), 'day', test_day, descriptive2analyse, py.dict(pyargs('$ne', NaN))))));
                    project_stage = py.dict(pyargs('$project', py.dict(pyargs('_id', 1, 'identifier', 1, 'day', 1, 'block', 1, descriptive2analyse, 1))));
                    pipeline_test = py.list({match_stage, project_stage});
                    match_stage = py.dict(pyargs('$match', py.dict(pyargs('identifier', py.dict(pyargs('$in', base_members)), 'day', base_day, descriptive2analyse, py.dict(pyargs('$ne', NaN))))));
                    pipeline_base = py.list({match_stage, project_stage});

                    collection = "describe_variability";
                    dependant_name = descriptive2analyse;
                case 'emg_d'
            end


            % get data for all group members
            test_data = aggregate('fatigue_sample', collection, pipeline_test);
            base_data = aggregate('fatigue_sample', collection, pipeline_base);
            
            % convert mongodb result to matlab table
            test_table = mongoquery2table(test_data);
            base_table = mongoquery2table(base_data);

            % get dependant
            test_dependant = test_table{:, dependant_name};
            base_dependant = base_table{:, dependant_name};
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
            coefficient_interpretation.Properties.VariableNames = ["G"+base_group+"d"+base_day "G"+test_group+"d"+test_day+" vs G"+base_group+"d"+base_day "G"+test_group+"d"+test_day];
            if data_type == "variability"
                dependant_info = "dependant:  " + dependant_name + " " + strjoin(string(test_emg_space), " ")+" / "+strjoin(string(test_emg_space), " ");
                regressor_info = "regressors: ((t.block-1)*30)+t.trial ,  binary,  time*binary";
            elseif data_type == "skill" || data_type == "v_d"
                dependant_info = "dependant:  " + dependant_name;
                regressor_info = "regressors: block,  binary,  block*binary";
            end
            disp(' ')
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
            fprintf("<strong>RMLR - Group "+string(test_group)+" day "+string(test_day)+" vs Group "+string(base_group)+" day "+string(base_day)+"</strong>")
            disp(' ');
            disp(dependant_info);
            disp(regressor_info);
            disp(' ')
            disp(coefficient_interpretation)
            disp(mdlr)
            disp("–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––")
          
        case action == 9
%           NEW CASE statistical analysis of variability description
%               -> build comparative models by group
%                  		• time a/o variability as independant?

        case action == 22 % create graphs
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
                emg_space   = emgSpaceSelector();
                group       = input('group: ');
                day         = input('day:   ');
    
                emg_space   = py.list(cellstr(emg_space));
                group       = int32(group);
                day         = int32(day);
                
                % get members of group from parameters collection
                pipeline = py.list({...
                    py.dict(pyargs('$match',py.dict(pyargs('label',group)))),... {"$match": {"label": 2}},
                    py.dict(pyargs('$group',py.dict(pyargs('_id', '$label', 'ID', py.dict(pyargs('$addToSet', '$ID'))))))...
                    });
                members = cell(aggregate('fatigue','parameters',pipeline));
                members = members{1}{'ID'};
    
    
                % get variability values for all group members
                pipeline = py.list({
                    py.dict(pyargs('$match', py.dict(pyargs(...
                        'identifier', py.dict(pyargs('$in', members)),...
                        'day', day,...
                        'space', emg_space,...
                        'distance', py.dict(pyargs("$ne", "missing leads"))...
                        ))))
                    });
                data = aggregate('fatigue_sample','variability',pipeline);
                
                % convert mongodb result to matlab table
                data = cell(data);
                for i = 1:numel(data)
                    data{i}.pop('_id');
                end
                s = py.list(data);
                s = cellfun(@struct, cell(s), 'UniformOutput', false);
                s = [s{:}];
                t = struct2table(s);
                t.identifier = string(t{:,'identifier'});
                t.day = cellfun(@double, t.day);
                t.block = cellfun(@double, t.block);
                t.trial = cellfun(@double, t.trial);
                t.space = string(t{:,'space'});
                t.distance = double(t{:,'distance'});
    
                % get dependant
                dependant = t{:, 'distance'};
                
                % get regressors
                regressors = ((t.block-1)*30)+t.trial;
    
                % fit robust model
                mdlr = fitlm(regressors,dependant,'RobustOpts','on');

                % reapply model
                intercept   = mdlr.Coefficients{1,1};
                effect      = mdlr.Coefficients{2,1};
                time_scaffold = transpose(1:120);
                reapplied_model = intercept + effect*time_scaffold(:,1);

                %plot model
                linewidth = input("linewidth: ");
                linecolor = input("linecolor: ","s");
                plotlabel = input("legend label: ","s");

                legendcontent = [legendcontent string(plotlabel)];

                plot(reapplied_model, 'LineWidth', linewidth, 'Color', linecolor);
                legend(legendcontent);

                set(gca,'box','off');
                set(gca,'XLim',[1 120],'XTick',15:30:105);
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

            % post creation editing loop
            while true
                listofedits = ...
                        " \n"+...
                        "1 first edit\n"+...
                        "2 second edit\n"+...
                        "9 save\n"+...
                        "0 end\n"+...
                        "\n";
                fprintf(listofedits);
                editing = input("edit: ");
    
                switch editing
    
                    case 1
                        disp('edit 1')
    
                    case 2
                        disp('edit 2')
    
                    case 9
                        
    
                    case 0
                        break
                end
            end

        case action == 0 % reset cml view
            clc

        case action == 666 % Case 666: Terminate Script   
            run_script = 0;
            
        case action == 911 % Case 911: Clear Workspace
            clearvars -except action fatigue_alldat mean_trials Missing_Trials Parameters rootDir run_script status_update calc_variables  distances_to_calc

    end % end of master switch
end % end of master while loop

%% Functions
function emg_space = emgSpaceSelector()

        pyModule = py.importlib.import_module('mongodb');
        pyModule = py.importlib.reload(pyModule);
        aggregate = pyModule.aggregate;

        % get all spaces present in the variability collection
        unwind_stage = py.dict(pyargs('$unwind', py.str('$space')));
        group_stage_1 = py.dict(pyargs('$group', py.dict(pyargs('_id', py.str('$_id'),'space', py.dict(pyargs('$addToSet', py.str('$space')))))));
        group_stage_2 = py.dict(pyargs('$group', py.dict(pyargs('_id', py.str('$space'),'count', py.dict(pyargs('$sum', py.int(1)))))));
        sort_stage = py.dict(pyargs('$sort', py.dict(pyargs('_id', py.int(1)))));
        pipeline = py.list({unwind_stage, group_stage_1, group_stage_2, sort_stage});
        data = aggregate('fatigue_sample','variability',pipeline);
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

function feedback = measure_space(space)
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
        object_ids = aggregate('fatigue_sample', "processed", pipeline);
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
            leads = get_data('fatigue_sample',"processed",query,projection);
            leads = cellfun(@(d) strip(string(d{"lead"})), cell(leads), 'UniformOutput', true);

            if isempty(setdiff(space, leads))
                % get trial array
                query = py.dict(pyargs( "identifier", parameters{"identifier"}, "day", parameters{"day"}, "block", parameters{"block"}, "trial", parameters{"trial"}, "lead", py.dict(pyargs('$in',py.list(cellstr(space))))));
                data = get_data('fatigue_sample',"processed",query);
                data = cellfun(@(d) double(d{"data"}), cell(data), 'UniformOutput', false);
                data = cell2mat(transpose(data));

                % get mean trial array
                query = py.dict(pyargs( "identifier", parameters{"identifier"}, "day", parameters{"day"}, "block", parameters{"block"}, "lead", py.dict(pyargs('$in',py.list(cellstr(space))))));
                mean_trial = get_data('fatigue_sample',"mean",query);
                mean_trial = cellfun(@(d) double(d{"mean trial"}), cell(mean_trial), 'UniformOutput', false);
                mean_trial = cell2mat(transpose(mean_trial));

                % measure distance with Lpq norm
                result = Lpq_norm(2,1,transpose(data-mean_trial));

                % save result to db
                output = parameters;
                measured = [measured struct(output)];
                output{'space'} = py.list(cellstr(space));
                output{'distance'} = result;
                put_data('fatigue_sample','variability',output);
            else
                % save missing leads to db
                output = parameters;
                missing_leads = [missing_leads struct(output)];
                output{'space'} = py.list(cellstr(space));
                output{'distance'} = "missing leads";
                output{'missing leads'} = py.list(cellstr(setdiff(space, leads)));
                put_data('fatigue_sample','variability',output);
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