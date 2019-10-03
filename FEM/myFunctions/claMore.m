% function [] = claMore(myHandlers)
%
% This function clears all the data plotted on the given axes handler array
%
% -------------------------------------------------------------------------
% Author: Cirelli Renato
% Team: ARACNE
% Date: 06/06/2019
% Revision: 1
%
% ChangeLog
% 31/05/2019 - First Version 
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

function [] = claMore(myHandlers)

    for j = 1:length(myHandlers)
       cla(myHandlers(j))
    end

end