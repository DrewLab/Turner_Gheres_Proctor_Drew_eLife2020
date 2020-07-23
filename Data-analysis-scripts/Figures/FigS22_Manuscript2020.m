function [AnalysisResults] = FigS22_Manuscript2020(rootFolder,saveFigs,delim,AnalysisResults)
%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%________________________________________________________________________________________________________________________
%
% Purpose: Generate figure panel S22 for Turner_Kederasetti_Gheres_Proctorostanzo_Drew_Manuscript2020
%________________________________________________________________________________________________________________________

%% set-up and process data
% load in all the ConfusionData.mat structure
if isfield(AnalysisResults,'ConfusionMatrix') == true
    holdYlabels = AnalysisResults.ConfusionMatrix.holdYlabels;
    holdXlabels = AnalysisResults.ConfusionMatrix.holdXlabels;
else
    startingDirectory = cd;
    confusionDataDirectory = [startingDirectory '\Summary Figures and Structures\Confusion Matricies\'];
    cd(confusionDataDirectory)
    load('ConfusionData.mat','-mat')
    % pull out confusion matrix values
    modelName = 'RF';
    holdYlabels = [];
    holdXlabels = [];
    for bb = 1:length(ConfusionData.(modelName).testYlabels)
        holdYlabels = vertcat(holdYlabels,ConfusionData.(modelName).testYlabels{bb,1}); %#ok<*AGROW>
        holdXlabels = vertcat(holdXlabels,ConfusionData.(modelName).testXlabels{bb,1});
    end
    % update analysis structure
    AnalysisResults.ConfusionMatrix.holdYlabels = holdYlabels;
    AnalysisResults.ConfusionMatrix.holdXlabels = holdXlabels;
    % save results
    cd(rootFolder)
    save('AnalysisResults.mat','AnalysisResults')
end
% patch names
holdYlabels = strrep(holdYlabels,'Not Sleep','rfc-Awake');
holdYlabels = strrep(holdYlabels,'NREM Sleep','rfc-NREM');
holdYlabels = strrep(holdYlabels,'REM Sleep','rfc-REM');
holdXlabels = strrep(holdXlabels,'Not Sleep','rfc-Awake');
holdXlabels = strrep(holdXlabels,'NREM Sleep','rfc-NREM');
holdXlabels = strrep(holdXlabels,'REM Sleep','rfc-REM');
%% Figure panel S22
confMat = figure('Name','FigS22 (a)'); %#ok<*NASGU>
%% confusion matrix
cm = confusionchart(holdYlabels,holdXlabels);
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
confVals = cm.NormalizedValues;
totalScores = sum(confVals(:));
modelAccuracy = round((sum(confVals([1,5,9])/totalScores))*100,1);
cm.Title = {'Figure S22 - Turner et al. 2020','','[S22a] Random forest unseen data confusion matrix',['total accuracy: ' num2str(modelAccuracy) ' (%)']};
%% save location
if strcmp(saveFigs,'y') == true
    dirpath = [rootFolder delim 'Summary Figures and Structures' delim 'MATLAB Analysis Figures' delim];
    if ~exist(dirpath,'dir')
        mkdir(dirpath);
    end
    savefig(confMat,[dirpath 'FigS22']);
    set(confMat,'PaperPositionMode','auto');
    print('-painters','-dpdf','-bestfit',[dirpath 'FigS22'])
end

end
