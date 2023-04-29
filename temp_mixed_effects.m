%% FATIGUE v9: mixed effects models
% just teaching myself how to use mixed effect models

%% import calc_vars
%[f,p] = uigetfile(fullfile('','*.*'),'Select calc_variables (.csv)');
%calc_variables = readtable(fullfile(p,f));
calc_variables = calc_variables_backup;
% dummy_vars = dummyvar(calc_variables{:,"group"});
% dummy_vars = array2table(dummy_vars,"VariableNames",["g1" "g2" "g3"]);
% calc_variables = removevars(calc_variables,"group");
% calc_variables = [dummy_vars calc_variables
calc_variables.group = categorical(calc_variables.group);
calc_variables.day = categorical(calc_variables.day);
calc_variables.session = categorical(calc_variables.session);
calc_variables.trial = categorical(calc_variables.trial);
calc_variables.subject = categorical(calc_variables.subject);


%% fit & show lmem
lme = fitlme(calc_variables,'fdiApbAdmFcrBic ~ group * day * session + (1|subject)')
F = fitted(lme);
R = response(lme);
figure();
plot(R,F,'rx')
xlabel('Response')
ylabel('Fitted')

%% predict model
% create scafold
% Define the number of rows and columns in the table
numRows = 720; % 3 groups x 2 days x 4 sessions x 30 trials
numCols = 5; % group, day, session, trial, subject, fdiApbAdmFcrBic

% Create a matrix of NaN values with the specified dimensions
dataMatrix = zeros(numRows, numCols);

% Fill in the predictor variables (group, day, session, trial)
dataMatrix(:, 1) = repelem(1:3, 2*4*30);
dataMatrix(:, 2) = repmat([1 2], 1, 3*4*30);
dataMatrix(:, 3) = repmat(kron(1:4, ones(1, 2*30)), 1, 3);
%dataMatrix(:, 4) = repmat(kron(1:30, ones(1, 2*4)), 1, 3);

% Convert the matrix to a table and assign variable names
newdata = array2table(dataMatrix, ...
                      'VariableNames', {'group', 'day', 'session', 'subject', 'fdiApbAdmFcrBic'}); % 'VariableNames', {'group', 'day', 'session', 'trial', 'subject', 'fdiApbAdmFcrBic'});
newdata.group   = categorical(newdata.group);
newdata.day     = categorical(newdata.day);
%newdata.trial   = categorical(newdata.trial);
newdata.session = categorical(newdata.session);
newdata.subject = categorical(newdata.subject);
newdata.fdiApbAdmFcrBic = double(newdata.fdiApbAdmFcrBic);

%% predict model
prediction = predict(lme, newdata);
data = addvars(newdata,prediction,'NewVariableNames','prediction');
gscatter(data.day .* data.session, data.prediction, data.group);

% Set the x-axis label to "Day * Session"
xlabel('Day * Session');

% Set the y-axis label to "fdiApbAdmFcrBic"
ylabel('fdiApbAdmFcrBic');

% Add a legend
legend('Group 1', 'Group 2', 'Group 3');