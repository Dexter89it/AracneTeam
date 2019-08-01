
% This script shows the collected data
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 01/08/2019
% Revision: 1
%
% ChangeLog
% 31/05/2019 - First Version
%
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
%%

% Select and load the file
[filename1,filepath1]=uigetfile({'*.mat'},'Select Data File','MultiSelect','off');
load([filepath1,filename1]);

%%

myList = fieldnames(myCollector.data);
myList(1) = [];
[indx,tf] = listdlg('ListString',myList);

if ~tf
    error('Please select something to plot.\n')
end

for k = 1:length(indx)
    
    % Dynamic field selection for myCollector structure
    tempFiled = myCollector.data.(myList{indx(k)});
    
    if isnumeric(tempFiled)
        % The data is a numeric one --> Direct plot
        
        figure()
        handler_ax = axes;
        title(myList{indx(k)})
        xlabel('$time \; [s]$')
        ylabel(myList{indx(k)})
        hold on
        
        plot(handler_ax,myCollector.data.timeEval',tempFiled')
        
    else
        % The data is a structure --> Data extraction --> Data Plot
       
        nameFileds = fieldnames(tempFiled);
        countFields = length(nameFileds);
        
        figure()
        
        for h = 1:countFields
            
            % Create a subplot
            subplot(countFields,1,h)
            % Extrac the data
            tempData = tempFiled.(nameFileds{h});
            % Plot the data
            plot(myCollector.data.timeEval',tempData')
            ylabel(nameFileds{h});
            xlabel('$time \; [s]$')
        
        end
        
        suptitle(myList{indx(k)});
        
    end
    
end