% -------------------------------------------------------------------------
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Authors:      Cirelli Renato, Ventre Francesco, Salvatore Bella,
%               Alvaro Romero Calvo, Aloisia Russo.
% Team:         ARACNE
% Date:         03/10/2019
% Revision:     9.5
% ---------------------------- ChangeLog ----------------------------------
%
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
%            - Iterative method implemented. It generates a number of
%              simulation that can be set through the parameter N.
% 01/08/2019 - Added a gui interface for the selection of .mph file, type
%              of data to be saved.
%            - Updated file creation to maintain a clear view of when and
%              how a simulation is created.
% 15/08/2019 - Evaluation points are now saved under mesh field of
%              myCollector, fixed s bug in the code related to data
%              collection.
% 16/08/2019 - The nodal point selection is now giving all the nodal point
%              using mpheval function
% 17/08/2019 - Added a pause after a simulation.
% 21/09/2019 - Integration with Alvaro's code, saved data from second study
% 23/09/2019 - Corrected a bug that was affecting the impact location
%              setting in COMSOL.
% 03/10/2019 - Modified in order to use a plate element, the code is now
%              paramentrized according to FEM model, implemented random
%              Temperature variation between hot, cold and mean.
% 05/10/2019 - The nama of the .mat file is now starting with the user name
%              to make it more identificable, each file now contains the
%              counter value at the instant of generation
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------
clear
close all
clc

%All the figure are docked in one window
set(0,'DefaultTextInterpreter','latex');
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultTextFontSize',12);
set(0,'DefaultAxesFontSize',12);

% Load Library
addpath(genpath('myFunctions'));
addpath(genpath('MASTER'));

%% COMSOL LiveLink
% Load a model
[file,path] = uigetfile('*.mph');
if isequal(file,0)
    close all
    clc
    return
else
   selModel = fullfile(path,file);
   disp(['Selected model: ', selModel]);
   model = mphload(selModel);
end

fprintf('\n');

% Set the dimension of the dataset to be produced
title = 'Dataset Generator';
dims = [1 45];
prompt = {'User Name',...
          'Enter the dimension of the dataset (Integer):'};
definput = {'Insert here your name','20'};
userAnswer = inputdlg(prompt,title,dims,definput);

% End the script if no choice is made
if isempty(userAnswer)
    close all
    clc
    return
end

% Point to save selection
dataToSave = questdlg('Which points do you want to save?', ...
                      'Data Selection',...
                      'Nodal points', ...
                      'Defined Selection',...
                      'Nodal points');
% Handle response
switch dataToSave
    case 'Nodal points'
        fprintf('Nodal points will be saved \n');
        dessert = 1;
    case 'Defined Selection'
        
        % Extract the selection defined in mph file and covert it into a
        % cell
        availableSels = cell(model.selection.tags());
        
        % Selection gui
        [selIndex,tf] = listdlg('ListString',availableSels);

        if ~tf
            error('Please select something to save.\n')
        else
            fprintf([availableSels{selIndex},' selection will be saved \n\n']);
        end
    otherwise
        if ~tf
            error('Please select something to save.\n')
        end
end

% Answer Map
userName = userAnswer{1};
setDim = str2double(userAnswer{2});

% Simulation info
mySetUp.userName = userName;
mySetUp.setDim = setDim;
mySetUp.setCounter = 0;

% Create a folder where to store results with the name equal to date
resFolder = date;
[tStatus,tWarn]=mkdir(resFolder);

if tStatus && isempty(tWarn)
    fprintf([resFolder,' has been created. \n\n']);
else
    fprintf(['Warning: ',tWarn,'\n\n']);
end

% Simulation unique name (NOTE: _ instead of .)
simName = num2str(now);
simName(simName == '.') = '_'; 

% Create a unique folder based on the time of execution
mkdir([resFolder,'\',simName]);

mySetUp.simDate = resFolder;
mySetUp.simName = simName;

% Consider a study temperature
T_mean = (173.15 + 373.15)/2;                % K
T_shadow = 173.15;                           % K
T_sun = 373.15;                              % K

T = [T_mean; T_shadow; T_sun];               % K
T = T(round(2*rand(setDim,1))+1);            % K
AL = AL_data(T);                             % m/s^2; Kg/m^3

% Exclude the penetration check TRUE case
count = 0;
% Preallocation
impColl = zeros(setDim,7);

fprintf('Particle generator activated!\n')
while count < setDim
    
    % incremente counter
    count = count + 1;

    % Data Generation
    temp = impact_generator('./MASTER/total_flux.txt',1,AL(:,count));
    
    try
        % Check penetration
        if temp(6) == 1
            count = count - 1;
        else
            impColl(count,:) = temp; 
        end
    catch
        count = count - 1;  
    end
    
end
fprintf('We ran out of particles!\n')

dt = impColl(:,1);
P = impColl(:,2);
d = impColl(:,3);
up2 = impColl(:,4);
v = impColl(:,5);
crosspen = impColl(:,6);
G = impColl(:,7);

% Preallocation
shootTime = zeros(1,setDim);

% Start to dance ;)
for k = 1 : setDim
    
    % Preallocation
    myCollector = struct();
    
    % Info to store
    myCollector.ID = k; 
    
    % Parameters to store
    myCollector.Parameters.dt = dt(k);
    myCollector.Parameters.P = P(k);
    myCollector.Parameters.d = d(k);
    myCollector.Parameters.up2 = up2(k);
    myCollector.Parameters.v = v(k);
    myCollector.Parameters.crospen = crosspen(k); 
    myCollector.Parameters.G = G(k);
    myCollector.Parameters.T = T(k);
          
    % Update the model with the current parameters
    % Peak of the force
    model.param.set('P_imp',[num2str(P(k)),'[Pa]']);
    % Square impulse time
    model.param.set('t_imp',[num2str(dt(k)),'[s]']);
    % Impact diameter
    model.param.set('d_imp',[num2str(d(k)),'[m]']);
    % Study Temperature
    model.param.set('T_amb',[num2str(T(k)),'[m]']);
    % Speed of sound in the material
    model.param.set('c_al',[num2str(AL(1,k)),'[m]']);
    
    % Generate a random position within the given intervals 
    % done here since depends on previously assigned parameters (t_imp)
    L_eval = mphevaluate(model, 'L');
    L_eval = L_eval(1);
    posLimits.x = [L_eval/10; L_eval-L_eval/10];
    posLimits.y = [L_eval/10; L_eval-L_eval/10];
    posVal = [posLimits.x(1);posLimits.y(1)] + ...
             [posLimits.x(2)-posLimits.x(1),0;...
              0,posLimits.y(2)-posLimits.y(1)]*rand(2,1);  
    myCollector.Parameters.impact = posVal;
    myCollector.Parameters.L = L_eval;
    
    % Location of the applied force
    model.param.set('x_imp',[num2str(posVal(1)),'[m]']);
    model.param.set('y_imp',[num2str(posVal(2)),'[m]']);
    
    % Update Geometry
    model.geom('geom1').runAll();
    fprintf('Geometry has been updated\n');
    % Update the mesh
    model.mesh('mesh1').run();
    fprintf('Mesh has been updated\n');
    
    % Running simulation
    fprintf('Simulation has started\n');
    tic
    model.study('std1').run
    fprintf('Study is complete\n');
    myCollector.runTime = toc;
    fprintf('Simulation has ended in %.1f s \n\n',myCollector.runTime);
    
    % Select the dataset to be used during the data extraction from COMSOL
    selDataset = 'dset1';
    
    % Data Extraction
    switch dataToSave
        
        case 'Nodal points'
            
            tic
            
            % Time series for each node (node_id,value)
            temp = mpheval(model,'t','edim','boundary','dataset',selDataset);
            myCollector.timeEval = temp.d1';
            myCollector.timeEval = myCollector.timeEval(1,:);
            
            % Evaluation Point Coordinates
            fprintf(' -- Saving evaluation points coordinates \n');
            
            temp = mpheval(model,'x','edim','boundary','dataset',selDataset);
            myCollector.mesh.x = temp.d1';
            
            temp = mpheval(model,'y','edim','boundary','dataset',selDataset);
            myCollector.mesh.y = temp.d1';
                        
            % Acceleration of each node (node_id,value)
            fprintf(' -- Saving acceleration data \n');
            
            temp = mpheval(model,'plate.u_ttX','edim','boundary','dataset',selDataset);
            myCollector.data.acc.x = temp.d1';
            
            temp = mpheval(model,'plate.u_ttY','edim','boundary','dataset',selDataset);
            myCollector.data.acc.y = temp.d1';
            
            temp = mpheval(model,'plate.u_ttZ','edim','boundary','dataset',selDataset);
            myCollector.data.acc.z = temp.d1';
            
            % Velocity of each node (node_id,value)
            fprintf(' -- Saving velocity data \n'); 
            
            temp = mpheval(model,'plate.u_tX','edim','boundary','dataset',selDataset);
            myCollector.data.vel.x = temp.d1';
            
            temp = mpheval(model,'plate.u_tY','edim','boundary','dataset',selDataset);
            myCollector.data.vel.y = temp.d1';
            
            temp = mpheval(model,'plate.u_tZ','edim','boundary','dataset',selDataset);
            myCollector.data.vel.z = temp.d1';

            % Displacement of each node (node_id,value)
            fprintf(' -- Saving displacement data \n');
            
            temp = mpheval(model,'plate.umx','edim','boundary','dataset',selDataset);
            myCollector.data.disp.x = temp.d1';
            
            temp = mpheval(model,'plate.umy','edim','boundary','dataset',selDataset);
            myCollector.data.disp.y = temp.d1';
            
            temp = mpheval(model,'plate.umz','edim','boundary','dataset',selDataset);
            myCollector.data.disp.z = temp.d1';

            % Energy Densities of each node (node_id,value) [J/m^3]
            fprintf(' -- Saving energy densities data \n');
            
            temp = mpheval(model,'plate.Wk','edim','boundary','dataset',selDataset);
            myCollector.data.Wk = temp.d1';

            myCollector.saveTime = toc;
            fprintf('Data has been saved in %.1f s \n',myCollector.saveTime); 
           
        case 'Defined Selection'
            
            tempSel = availableSels{selIndex};
            
            tic
            % Time series for each node (node_id,value)
            myCollector.timeEval = mphevalpoint(model,'t','selection',tempSel,'dataset',selDataset);
            myCollector.timeEval = myCollector.timeEval(1,:);

            % Evaluation Point Coordinates
            fprintf(' -- Saving evaluation points coordinates \n'); 
            myCollector.mesh.x = mphevalpoint(model,'x','selection',tempSel,'dataset',selDataset);
            myCollector.mesh.y = mphevalpoint(model,'y','selection',tempSel,'dataset',selDataset);
            
            % Acceleration of each node (node_id,value)
            fprintf(' -- Saving acceleration data \n'); 
            myCollector.data.acc.x = mphevalpoint(model,'plate.u_ttX','selection',tempSel,'dataset',selDataset);
            myCollector.data.acc.y = mphevalpoint(model,'plate.u_ttY','selection',tempSel,'dataset',selDataset);
            myCollector.data.acc.z = mphevalpoint(model,'plate.u_ttZ','selection',tempSel,'dataset',selDataset);

            % Velocity of each node (node_id,value)
            fprintf(' -- Saving velocity data \n'); 
            myCollector.data.vel.x = mphevalpoint(model,'plate.u_tX','selection',tempSel,'dataset',selDataset);
            myCollector.data.vel.y = mphevalpoint(model,'plate.u_tY','selection',tempSel,'dataset',selDataset);
            myCollector.data.vel.z = mphevalpoint(model,'plate.u_tZ','selection',tempSel,'dataset',selDataset);

            % Displacement of each node (node_id,value)
            fprintf(' -- Saving displacement data \n');
            myCollector.data.disp.x = mphevalpoint(model,'plate.umx','selection',tempSel,'dataset',selDataset);
            myCollector.data.disp.y = mphevalpoint(model,'plate.umy','selection',tempSel,'dataset',selDataset);
            myCollector.data.disp.z = mphevalpoint(model,'plate.umz','selection',tempSel,'dataset',selDataset);

            % Energy Densities of each node (node_id,value) [J/m^3]
            fprintf(' -- Saving energy densities data \n');
            myCollector.data.Wk = mphevalpoint(model,'plate.Wk','selection',tempSel,'dataset',selDataset);

            myCollector.saveTime = toc;
            fprintf('Data has been saved in %.1f s \n',myCollector.saveTime); 
            
    end
    
    fprintf('Simulation %d of %d completed.\n\n\n',k,setDim);
    
    % Save the results
    % Clean all spaces
    userName(userName == ' ') = [];
    % Increment the set counter
    mySetUp.setCounter = mySetUp.setCounter + 1;
    save([resFolder,'\',simName,'\',userName,'_',simName,'_',num2str(k),'.mat'],'myCollector','mySetUp');
    
    % Memorize the total run time
    shootTime(k) = myCollector.runTime + myCollector.saveTime;
    
    % Clean some stuff
    clear('myCollector')

    % Time left
    timeLeft = mean(shootTime(shootTime>0))*(setDim - k);
    fprintf('The dataset will be ready in: %.1f [s] = %.1f [m] = %.1f [h] (KIND OF)\n\n',timeLeft,timeLeft/60,timeLeft/3600);
    
end
