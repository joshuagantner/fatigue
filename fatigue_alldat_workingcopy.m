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
    "1 process data \n";
fprintf(operations_list);

%% master while loop
while run_script == 1

    % Select Operation
    disp(' ')
    action = input('What would you like me to do? ');
    disp(' ')

    switch action

        case 1 % process data
            disp('1 db content table')
            disp('2 db content table for lead')
            disp('3 proces data')
            disp(' ')
            what_to_process = input('what to process: ');

            switch true
                case what_to_process == 1 || what_to_process == 2 % db content table

                    % get unique participant identifiers
                    collection = input('collection: ','s');
                    participants = find_unique('fatigue',collection,'identifier');
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
                    data = get_data('fatigue',collection,query, projection, batch_size = int8(10));
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
                
                case what_to_process == 3 % process raw data
                    disp(' ')
                    disp('1 mark outliers')
                    disp('2 filter, rectify & stnd4time')
                    disp('3 mean trials')
                    disp('4 euclidean distances')
                    disp(' ')
                    what_to_process_2 = input('what to process: ');
        
                    switch what_to_process_2
                        case 1 % update inclusion status
        
                        case 2 % process included raw data
                            disp('started processing')
                            % processing parameters
                            SRATE = 5000;
                            freq_h = 10;
                            freq_l = 6;
                            ORDER = 4;
                            LENGTH = 100000;
        
                            % get unique object ids
                            query = py.dict(pyargs('data type','EMG'));
                            object_ids = find_unique('fatigue','raw','_id',query);
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
                                data_in = get_data('fatigue','raw',query);
                                data = double(string(data_in{1}{'data'}));
                                data = proc_std(data, SRATE, freq_h, freq_l, ORDER);
                                data = stnd4time(data, LENGTH);
                                data_in{1}{'data'} = py.list(data);
                                data_in{1}.pop('_id');
                                put_data('fatigue','processed',data_in{1});
        
                                %Update Progress bar
                                counter = counter+1;
                                waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
                            end

                            % timer output
                            disp("  -> Raw Data processed")
                            disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
                            close(h)

                        case 3 % calculate mean trials
                            pipeline = py.list({py.dict(pyargs("$group", py.dict(pyargs("_id", py.dict(pyargs("identifier", "$identifier", "day", "$day", "block", "$block","lead","$lead"))))))});
                            sessions = aggregate('fatigue','processed',pipeline);

                            n = 100;  % total number of iterations
                            h = waitbar(0, 'Calculating mean trials...');  % initialize progress bar
                            
                            for i = 1:length(sessions)
                                session = sessions{i}{'_id'};
%                                 filter = py.dict(pyargs('identifier',session{'ID'},'day',session{'day'},'block',session{'BN'},'data type','EMG'));
%                                 query = py.dict(pyargs('_id','$lead'));
%                                 pipeline = py.list({py.dict(pyargs("$match",filter,"$group",query))});

                                data = get_data('fatigue','processed',session,batch_size=int8(10));
                                mean_trial = zeros(1,100000);
                                for j = 1:length(data)
                                    mean_trial = mean_trial + double(data{j}{'data'});
                                end
                                mean_trial = mean_trial/length(data);
                                
                                output = py.dict(pyargs('identifier',session{'identifier'},'day',session{'day'},'block',session{'block'},'lead',session{'lead'},'mean trial',py.list(mean_trial)));
                                put_data('fatigue','mean',output);

                                waitbar(i/length(sessions), h, sprintf('Calculating mean trials... %d%%', round(100*i/length(sessions))));  % update progress bar

                            end
                            
                            close(h);  % close progress bar

                        case 4 % measure euclidean distances
                            % get unique object ids
                            query = py.dict(pyargs('data type','EMG'));
                            object_ids = find_unique('fatigue','raw','_id',query);
                            disp('ids done')

                            % progress bar
                            counter = 0;
                            h = waitbar(0,['measuring euclidean distances ', num2str(counter*100),'%']);
                            total = length(object_ids);
        
                            % itterate & process objects
                            start_time = now;
                            for i = 1:length(object_ids)
        
                                % get data
                                query = py.dict(pyargs('_id',object_ids{i}));
                                data_in = get_data('fatigue','processed',query);
                                data_in = data_in{1};

                                ID = data_in{'ID'};
                                day = data_in{'day'};
                                session = data_in{'SessN'};
                                lead = data_in{'lead'};

                                query = py.dict(pyargs('ID',ID,'day',day,'SessN',session,'lead',lead));
                                projection = py.dict(pyargs('mean trial',1));
                                mean_trial = get_data('fatigue','mean',query,projection);   
                                mean_trial = double(string(mean_trial{1}{'mean trial'}));
                                data = double(string(data_in{'data'}));

                                % calculate the euclidean dsitance
                                result = Lpq_norm(2,1,data-mean_trial);
                                
                                % save the euclidean distance to the database
                                data_in.pop('_id');
                                data_in.pop('data');
                                data_in{'variability'} = result;
                                put_data('fatigue','variability',data_in);
        
                                %Update Progress bar
                                counter = counter+1;
                                waitbar(counter/total,h,['Processing Raw Data ', num2str(round(counter/total*100)),'%']);
                            end

                            % timer output
                            disp("  -> Euclidean Distances calculated")
                            disp(strcat("     runtime: ",datestr(now-start_time,"MM:SS")))
                            close(h)

                    end % end
            end % end
            
        case 2 % invetigate processed data
            case 30 % view model
            case 302 % compare spaces
            case 31 % compare 1-day models
            case 39 % compare 1-day models simple
            case 32 % compare 2-day models
            case 34 % plot regression models
            case 35 % reapply model
            case 36 % view model for skill
            case 36.2 % comparative skill model
            case 37 % plot skill model
            case 38 % plot var & learning within group
            case 41 % styling options
            case 42 % empty legend
            case 43 % plot skill measure
            case 432 % plot skill measure
            case 44 % ttest
            case 45 % correlation
            case 46 % correlate reapplied models
            case 47 % correlation coefficient from intercept
            case 48 % correlation coefficient from intercept
        case 77 % plot var & learning all groups one day
        
        case 01 % settings
            case 011 % set root directory            
            case 0 % reset cml view
                clc

            case 666 % Case 666: Terminate Script   
                run_script = 0;
                
            case 911 % Case 911: Clear Workspace
                clearvars -except action fatigue_alldat mean_trials Missing_Trials Parameters rootDir run_script status_update calc_variables  distances_to_calc

    end % end of master switch
end % end of master while loop

%% Functions
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

function data = loadData(identifier, type, day, block, trial, lead) %"F007C", "EMG", 1, 2, 28, "ADM"

    query_result = get_data(identifier, type, day, block, trial, lead);
    query_result{'id'} = query_result.pop('_id');
    query_result{'data_type'} = query_result.pop('data type');
    query_result = struct(query_result);
    data = double(transpose(string(query_result.data)));

end