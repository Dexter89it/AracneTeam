
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 01/08/2019
% Revision: 5
%
% ChangeLog
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
%            - Iterative method implemented. It generates a number of
%              simulation that can be set through the parameter N.
% 01/08/2019 - Added a gui interface for the selection of .mph file, type
%              of data to be saved.
%            - Updated file creation to maintain a clear view of when and
%              how a simulation is created
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
addpath(genpath('myFunctions'))

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
   mphopen(selModel);
end

fprintf('\n');

% Set the dimension of the dataset to be produced
title = 'Dataset Generator';
dims = [1 45];
prompt = {'Enter the dimension of the dataset (Integer):',...
          'Enter the magnitude interval [N]:',...
          'Enter the impact location limits on x [m]:',...
          'Enter the impact location limits on y [m]:'};
definput = {'20','[0.7,774]','[0.01,0.49]','[0.01,0.49]'};
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
setDim = str2double(userAnswer{1});
fLimits = str2num(userAnswer{2});
posLimits.x = str2num(userAnswer{3});
posLimits.y = str2num(userAnswer{4});

mySetUp.setDim = setDim;
mySetUp.fLimits = fLimits;
mySetUp.posLimits = posLimits;


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

% Start to dance ;)
for k = 1 : setDim

    % Preallocation
    myCollector = struct();
    
    % Mesh Setup
    myCollecoter.mesh.hauto = model.mesh('mesh1').feature('size').getDouble('hauto');
    % Study Setup
    myCollecoter.study.t0 = str2double(model.study('std1').feature('time').getString('tlist_vector_start'));
    myCollecoter.study.step = str2double(model.study('std1').feature('time').getString('tlist_vector_step'));
    myCollecoter.study.tf = str2double(model.study('std1').feature('time').getString('tlist_vector_stop'));
    
    % Generate a random load within the given internval
    % NOTE: Set a maximum and/or a minimum here...
    fVal = fLimits(1) + (fLimits(2)-fLimits(1)).*rand();

    % Generate a random position within the given intervals
    posVal = [posLimits.x(1);posLimits.y(1)] + ...
             [posLimits.x(2)-posLimits.x(1),0;...
              0,posLimits.y(2)-posLimits.y(1)]*rand(2,1);

    % Update the model with the current parameters
    % Peak of the force
    model.param.set('L_peak',[num2str(fVal),'[N]']);
    % Location of the applied force
    model.param.set('impact_x',[num2str(posVal(1)),'[m]']);
    model.param.set('impact_y',[num2str(posVal(2)),'[m]']);
    
    % Save the parameters
    myCollector.Parameters.L_peak.value = fVal;
    myCollector.Parameters.L_peak.unit = '[N]';
    myCollector.Parameters.impact.value = posVal;
    myCollector.Parameters.impact.unit = '[m]';

    % Run the model
    % Note: If the model has been already solved in COMSOL, a solution is
    % present in the .mph file and the re-run is not necessary (unless
    % parameters are changed ;) )
    
    % Update Geometry
    model.geom('geom1').runAll();
    fprintf('Geometry has been updated\n');
    % Update the mesh
    model.mesh('mesh1').run();
    fprintf('Mesh has been updated\n\n');
    
    fprintf('Simulation has started\n');
    tic
    model.study('std1').run
    myCollector.runTime = toc;
    fprintf('Simulation has ended in %.1f s \n\n',myCollector.runTime);

    
     % Data Extraction
    switch dataToSave
        
        case 'Nodal points'
            
            tic
            % Time series for each node (node_id,value)
            myCollector.data.timeEval = mphevalpoint(model,'t');

            % Acceleration of each node (node_id,value)
            fprintf(' -- Saving acceleration data \n'); 
            myCollector.data.acc.x = mphevalpoint(model,'shell.u_ttX');
            myCollector.data.acc.y = mphevalpoint(model,'shell.u_ttY');
            myCollector.data.acc.z = mphevalpoint(model,'shell.u_ttZ');

            % Velocity of each node (node_id,value)
            fprintf(' -- Saving velocity data \n'); 
            myCollector.data.vel.x = mphevalpoint(model,'shell.u_tX');
            myCollector.data.vel.y = mphevalpoint(model,'shell.u_tY');
            myCollector.data.vel.z = mphevalpoint(model,'shell.u_tZ');

            % Displacement of each node (node_id,value)
            fprintf(' -- Saving displacement data \n');
            myCollector.data.disp.x = mphevalpoint(model,'shell.umx');
            myCollector.data.disp.y = mphevalpoint(model,'shell.umy');
            myCollector.data.disp.z = mphevalpoint(model,'shell.umz');

            % Energy Densities of each node (node_id,value) [J/m^3]
            fprintf(' -- Saving energy densities data \n');
            myCollector.data.Wk = mphevalpoint(model,'shell.Wk');
            myCollector.data.Ws = mphevalpoint(model,'shell.Ws');

% %             % Strain Energies of each node (node_id,value) [J/m^2]
% %             fprintf(' -- Saving strain energies data \n');
% %             myCollector.data.WsB = mphevalpoint(model,'shell.WsB');
% %             myCollector.data.WsS = mphevalpoint(model,'shell.WsS');
% %             myCollector.data.WsM = mphevalpoint(model,'shell.WsM');

% %             % Shear Stresses Evaluation of each node (node_id,value)
% %             fprintf(' -- Saving shear stresses data \n');
% %             myCollector.data.mises.tot = mphevalpoint(model,'shell.mises');
% %             myCollector.data.mises.b = mphevalpoint(model,'shell.mises_b');
% %             myCollector.data.mises.m = mphevalpoint(model,'shell.mises_m');
% %             myCollector.data.tresca = mphevalpoint(model,'shell.tresca');
% %             myCollector.data.sp.spl = mphevalpoint(model,'shell.sp1');
% %             myCollector.data.sp.sp2 = mphevalpoint(model,'shell.sp2');
% %             myCollector.data.sp.sp3 = mphevalpoint(model,'shell.sp3');

            myCollector.saveTime = toc;
            fprintf('Data has been saved in %.1f s \n',myCollector.saveTime); 
           
        case 'Defined Selection'
            
            tempSel = availableSels{selIndex};
            
            tic
            % Time series for each node (node_id,value)
            myCollector.timeEval = mphevalpoint(model,'t','selection',tempSel);

            % Acceleration of each node (node_id,value)
            fprintf(' -- Saving acceleration data \n'); 
            myCollector.data.acc.x = mphevalpoint(model,'shell.u_ttX','selection',tempSel);
            myCollector.data.acc.y = mphevalpoint(model,'shell.u_ttY','selection',tempSel);
            myCollector.data.acc.z = mphevalpoint(model,'shell.u_ttZ','selection',tempSel);

            % Velocity of each node (node_id,value)
            fprintf(' -- Saving velocity data \n'); 
            myCollector.data.vel.x = mphevalpoint(model,'shell.u_tX','selection',tempSel);
            myCollector.data.vel.y = mphevalpoint(model,'shell.u_tY','selection',tempSel);
            myCollector.data.vel.z = mphevalpoint(model,'shell.u_tZ','selection',tempSel);

            % Displacement of each node (node_id,value)
            fprintf(' -- Saving displacement data \n');
            myCollector.data.disp.x = mphevalpoint(model,'shell.umx','selection',tempSel);
            myCollector.data.disp.y = mphevalpoint(model,'shell.umy','selection',tempSel);
            myCollector.data.disp.z = mphevalpoint(model,'shell.umz','selection',tempSel);

            % Energy Densities of each node (node_id,value) [J/m^3]
            fprintf(' -- Saving energy densities data \n');
            myCollector.data.Wk = mphevalpoint(model,'shell.Wk','selection',tempSel);
            myCollector.data.Ws = mphevalpoint(model,'shell.Ws','selection',tempSel);

% %             % Strain Energies of each node (node_id,value) [J/m^2]
% %             fprintf(' -- Saving strain energies data \n');
% %             myCollector.data.WsB = mphevalpoint(model,'shell.WsB','selection',tempSel);
% %             myCollector.data.WsS = mphevalpoint(model,'shell.WsS','selection',tempSel);
% %             myCollector.data.WsM = mphevalpoint(model,'shell.WsM','selection',tempSel);

% %             % Shear Stresses Evaluation of each node (node_id,value)
% %             fprintf(' -- Saving shear stresses data \n');
% %             myCollector.data.mises.tot = mphevalpoint(model,'shell.mises','selection',tempSel);
% %             myCollector.data.mises.b = mphevalpoint(model,'shell.mises_b','selection',tempSel);
% %             myCollector.data.mises.m = mphevalpoint(model,'shell.mises_m','selection',tempSel);
% %             myCollector.data.tresca = mphevalpoint(model,'shell.tresca','selection',tempSel);
% %             myCollector.data.sp.sp1 = mphevalpoint(model,'shell.sp1','selection',tempSel);
% %             myCollector.data.sp.sp2 = mphevalpoint(model,'shell.sp2','selection',tempSel);
% %             myCollector.data.sp.sp3 = mphevalpoint(model,'shell.sp3','selection',tempSel);

            myCollector.saveTime = toc;
            fprintf('Data has been saved in %.1f s \n',myCollector.saveTime); 
            
    end
    
    fprintf('Simulation %d of %d completed.\n\n\n',k,setDim);
    
    % Save the results
    save([resFolder,'\',simName,'\',simName,'_',num2str(k),'.mat'],'myCollector','mySetUp');
    
    % Clean some stuff
    clear('myCollector')
    
end
