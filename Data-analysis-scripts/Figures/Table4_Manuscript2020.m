function [AnalysisResults] = Table4_Manuscript2020(rootFolder,saveFigs,AnalysisResults)
%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%________________________________________________________________________________________________________________________
%
% Purpose: Generate Table 4 for Turner_Kederasetti_Gheres_Proctor_Costanzo_Drew_Manuscript2020
%________________________________________________________________________________________________________________________

%% set-up and process data
columnNames = AnalysisResults.Coherr.columnNames;
rowNames = {'Gamma_C001_meanStD','Gamma_C001_pVal','HbT_C001_meanStD','HbT_C001_pVal'};
T(1,:) = cell2table(AnalysisResults.Coherr.gammaBandPower.meanStD001);
T(2,:) = cell2table(AnalysisResults.Coherr.gammaBandPower.p001);
T(3,:) = cell2table(AnalysisResults.Coherr.CBV_HbT.meanStD001);
T(4,:) = cell2table(AnalysisResults.Coherr.CBV_HbT.p001);
T.Properties.RowNames = rowNames;
T.Properties.VariableNames = columnNames;
%% Table 4
summaryTable = figure('Name','Table4'); %#ok<*NASGU>
sgtitle('Table 4 Turner Manuscript 2020')
uitable('Data',T{:,:},'ColumnName',T.Properties.VariableNames,'RowName',T.Properties.RowNames,'Units','Normalized','Position',[0,0,1,1]);
%% save figure(s)
if strcmp(saveFigs,'y') == true
    dirpath = [rootFolder '\Summary Figures and Structures\MATLAB Analysis Figures\'];
    if ~exist(dirpath,'dir')
        mkdir(dirpath);
    end
    savefig(summaryTable,[dirpath 'Table4']);
end

end