% -------------------------------------------------------------------------
% This script compacts the collected data into one file
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Authors:      Cirelli Renato, Ventre Francesco, Salvatore Bella,
%               Alvaro Romero Calvo, Aloisia Russo.
% Team:         ARACNE
% Date:         16/08/2019
% Revision:     1
% ---------------------------- ChangeLog ----------------------------------
% 16/08/2019 - First Version
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

clear
close all
clc

% Exit condition
addMore = 1;
% Compactor file counter
k = 0;
% Preallocation
filesColl = [];

while addMore
    
    % Select and load the file
    [filename1,filepath1]=uigetfile({'*.mat'},'Select Data File','MultiSelect','on');

    % Count the file to load
    if iscell(filename1)
        nLoaded = length(filename1);
        
        for j = 1:nLoaded
            filesColl = [filesColl,load([filepath1,filename1{j}])];
        end
        
    else
        filesColl = [filesColl,load([filepath1,filename1])];
    end

    
    % Next loop initial file counter set
    k = length(filesColl);
    
    answ = questdlg('Add some other files?', ...
                      'Compactor',...
                      'Yes', ...
                      'No',...
                      'Yes');
                  
    switch answ
        case "No"
            %Exit the loop
            addMore = 0;
            fprintf('A total of %d has been added. \n',length(filesColl));
            
            uisave('filesColl','myCollection.mat')
            
        otherwise
    end
    
end