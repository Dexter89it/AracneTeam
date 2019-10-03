% -------------------------------------------------------------------------
% This scritp shows the data of the loaded simulation files. Two possible
% case are covered
%
%   Single Simulation File
%   It is possible to choose between data type and multiple sensor reponse
%
%   Multiple Simulation File
%   It is possible to choose between data type and a single sensor response
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Authors:      Cirelli Renato, Ventre Francesco, Salvatore Bella,
%               Alvaro Romero Calvo, Aloisia Russo.
% Team:         ARACNE
% Date:         03/10/2019
% Revision:     10.1
% ---------------------------- ChangeLog ----------------------------------
% 31/05/2019 - First Version
% 15/08/2019 - Fixed a bug where the first element of the collected data
%              was omitted from the selection list, fixed the timeEval
%              error due to an update in the structure of myCollector
% 16/08/2019 - Time vector is now an array (not a matrix anymore), the node
%              of evaluation and the impact location is shown in a
%              separated window
% 23/09/2019 - The code has been rewritten to accept more than one
%              simulation file and to allow the selection of which data to
%              visualize and about which sensor
% 03/10/2019 - Sensorial Network plot adapted for each simulation according
%              to L
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------
clear
%close all
clc
    
%All the figure are docked in one window
set(0,'DefaultTextInterpreter','latex');
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultTextFontSize',12);
set(0,'DefaultAxesFontSize',12);

% Load Library
addpath(genpath('myFunctions'))
%%

% Select and load the file
[filename1s,filepath1]=uigetfile({'*.mat'},'Select Data File','MultiSelect','on');

% Check if the loaded files are more than one
try
    temp = filename1s{1};
    nFiles = size(filename1s,2);
catch
    nFiles = 1;
end

% Generate an unique color for each data file
plotColor =  rand(nFiles,3);

% Iterate over all the loaded simulations
for ldF = 1:nFiles
    
    % Load the data
    try
        filename1 = filename1s{ldF};
    catch
        filename1 = filename1s;
    end
    
    % Load one file in the workspace
    load([filepath1,filename1]);
    
    % Get plate length for current simulation
    L = myCollector.Parameters.L;
    
    if ldF == 1
        figure()
        myAxesHdl_grid = axes();
        axis(myAxesHdl_grid,[0,L,0,L]);
        xlabel(myAxesHdl_grid,'$x \; [m]$');
        ylabel(myAxesHdl_grid,'$y \; [m]$');
        zlabel(myAxesHdl_grid,'$z \; [m]$');
        hold on
    end
        
    % Show the sensor position and ID
    if ldF == 1
        for k = 1:size(myCollector.mesh.x,1)
            
            sensPos = [myCollector.mesh.x(k,1),myCollector.mesh.y(k,1),];
            plot(myAxesHdl_grid,sensPos(1),sensPos(2),'bO');
            
            sensPos = sensPos + L/100;
            myLabel = sprintf('S:%d',k);
            text(myAxesHdl_grid,sensPos(1),sensPos(2),myLabel);
        end
    end    
    
    % Show the impact location, the simulation ID and the pressure P
    impLoc = myCollector.Parameters.impact;
    plot(myAxesHdl_grid,impLoc(1),impLoc(2),'rx');
    
    impLoc = impLoc + L/100;
    myLabel = sprintf('ID: %d   \nP: %.3e Pa\n dt: %.3e\n d: %.3e',...
                      ldF,myCollector.Parameters.P,...
                      myCollector.Parameters.dt,...
                      myCollector.Parameters.d);
    text(myAxesHdl_grid,impLoc(1),impLoc(2),myLabel);
    
    
    if ldF == 1
        myListFields = fieldnames(myCollector.data);
        [chosenFields,tf] = listdlg('ListString',myListFields);

        if ~tf
            error('Please select a field to plot.\n')
        end

        % Field selection dialog
        myListIdx = split(num2str(1:size(myCollector.data.acc.x,1),'%.2d,'),',');
        myListIdx(end) = [];

        % If only one loaded file the selection can be multiple otherwise
        % single only
        if nFiles == 1
            selMode = 'multiple';
        else
            selMode = 'single';
        end
        
        % Sensor selection dialog
        [chosenNodes,~] = listdlg('ListString',myListIdx,'SelectionMode',selMode);

        if ~tf
            error('Please select a node to plot.\n')
        end
    end

    % Nuber of chosen fields
    nFieldChosen = length(chosenFields);
    % Create the axes only at the first call
    if ldF == 1
        % Create an axes for every selected field
        for k= 1:nFieldChosen
           figure()
           myAxesHdl(k) = axes(); 
           hold on
           legend('Location','Best')
        end
    end
    
    % For each selected field
    for k = 1:nFieldChosen
    
    % Select an axes to use
    selAxes = myAxesHdl(k);
    
    % Dynamic field selection for myCollector structure
    tempField = myCollector.data.(myListFields{chosenFields(k)});
    
    % Check what type of data it is 
     if isnumeric(tempField)
        % The data is a numeric one --> Direct plot
        
        title(selAxes,myListFields{chosenFields(k)})
        xlabel(selAxes,'$time \; [s]$')
        ylabel(selAxes,myListFields{chosenFields(k)})
        
        % For each chosen nodes
        for j = chosenNodes
            
            % If only one loaded file, show the sensor ID
            if nFiles == 1
                dispNameStr = sprintf('S: %d',j);
            else
                dispNameStr = sprintf('File ID: %d',ldF);
            end
            
            % Data Normalization upon the maximum of the response
            tempField(j,:) = tempField(j,:)./max(abs(tempField(j,:)));
            plot(selAxes,myCollector.timeEval',tempField(j,:)','MarkerFaceColor',plotColor(ldF,:),'DisplayName',dispNameStr);
        end
        
    else
        % The data is a structure --> Data extraction --> Data Plot
       
        % Store the resulting structure
        nameFileds = fieldnames(tempField);
        % Count how many fields are present
        countFields = length(nameFileds);
        
        % Select only the out of plane component (PARTICULAR CASE)
        for h = 3

            % Extrac the data
            tempData = tempField.(nameFileds{h});
            
            % Find the minimum of the maximum of the overall respons
            minOfTheMax = min(max(abs(tempData),[],2));
            
            for j = chosenNodes
                % Data Normalization upon the maximum of the response
                tempData(j,:) = tempData(j,:)./max(abs(tempData(j,:)));
%                 % Data normalization upon the minimum of the maximum of all
%                 % the responses
%                 tempData(j,:) = tempData(j,:)./minOfTheMax;
                
                if nFiles == 1
                    dispNameStr = sprintf('S %d',j);
                else
                    dispNameStr = sprintf('File ID: %d',ldF);
                end
                
                % Plot the data
                plot(selAxes,myCollector.timeEval',tempData(j,:)','MarkerFaceColor',plotColor(ldF,:),'DisplayName',dispNameStr);
                ylabel(selAxes,nameFileds{h});
                xlabel(selAxes,'$time \; [s]$')
            end
        
        end
        
        if nFiles == 1
            dispNameStr = '';
        else
            dispNameStr = sprintf('S %d',chosenNodes);
        end
        title(selAxes,[myListFields{chosenFields(k)},' ',dispNameStr]);
        
     end
    
    end
    
    
end