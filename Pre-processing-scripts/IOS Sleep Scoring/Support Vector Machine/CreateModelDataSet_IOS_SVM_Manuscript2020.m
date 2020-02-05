function [] = CreateModelDataSet_IOS_SVM_Manuscript2020(procDataFileIDs)
%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%
%   Purpose: Arrange data into a table of most-relevant parameters for SVM model training/classification
%________________________________________________________________________________________________________________________

for a = 1:size(procDataFileIDs,1)
    procDataFileID = procDataFileIDs(a,:);
    modelDataSetID = [procDataFileID(1:end-12) 'ModelData.mat'];
        load(procDataFileID)
        disp(['Creating model data set for ' procDataFileID '... (' num2str(a) '/' num2str(size(procDataFileIDs,1)) ')' ]); disp(' ')
        %% Create table to send into SVM model
        variableNames = {'maxCortDelta','maxCortBeta','maxCortGamma','maxHippTheta','numWhiskEvents','avgEMG','avgHeartRate'};
        % pre-allocation
        maxCortDelta_column = zeros(180,1);
        maxCortBeta_column = zeros(180,1);
        maxCortGamma_column = zeros(180,1);
        maxHippTheta_column = zeros(180,1);
        numWhiskEvents_column = zeros(180,1);
        numForceEvents_column = zeros(180,1);
        avgEMG_column = zeros(180,1);
        avgHeartRate_column = zeros(180,1);
        % extract relevant parameters from each epoch
        for b = 1:length(minRefl_column)    
            % Cortical delta
            maxLHcortDelta = mean(ProcData.sleep.parameters.cortical_LH.specDeltaBandPower{b,1});
            maxRHcortDelta = mean(ProcData.sleep.parameters.cortical_RH.specDeltaBandPower{b,1});
            if maxLHcortDelta >= maxRHcortDelta
                maxCortDelta_column(b,1) = maxLHcortDelta;
            else
                maxCortDelta_column(b,1) = maxRHcortDelta;
            end       
            % Cortical beta
            maxLHcortBeta = mean(ProcData.sleep.parameters.cortical_LH.specBetaBandPower{b,1});
            maxRHcortBeta = mean(ProcData.sleep.parameters.cortical_RH.specBetaBandPower{b,1});
            if maxLHcortBeta >= maxRHcortBeta
                maxCortBeta_column(b,1) = maxLHcortBeta;
            else
                maxCortBeta_column(b,1) = maxRHcortBeta;
            end
            % Cortical gamma
            maxLHcortGamma = mean(ProcData.sleep.parameters.cortical_LH.specGammaBandPower{b,1});
            maxRHcortGamma = mean(ProcData.sleep.parameters.cortical_RH.specGammaBandPower{b,1});
            if maxLHcortGamma >= maxRHcortGamma
                maxCortGamma_column(b,1) = maxLHcortGamma;
            else
                maxCortGamma_column(b,1) = maxRHcortGamma;
            end
            % Hippocampal theta
            maxHippTheta_column(b,1) = mean(ProcData.sleep.parameters.hippocampus.specThetaBandPower{b,1});
            % number of binarized whisking events
            numWhiskEvents_column(b,1) = sum(ProcData.sleep.parameters.binWhiskerAngle{b,1});
            % number of binarized force sensor events
            numForceEvents_column(b,1) = sum(ProcData.sleep.parameters.binForceSensor{b,1});
            % average of the log of the EMG profile
            EMG = ProcData.sleep.parameters.EMG{b,1};
            avgEMG_column(b,1) = mean(EMG);
            % average heart rate
            avgHeartRate_column(b,1) = round(mean(ProcData.sleep.parameters.heartRate{b,1}),1);
        end
        % create table
        paramsTable = table(maxCortDelta_column,maxCortBeta_column,maxCortGamma_column,maxHippTheta_column,numWhiskEvents_column,avgEMG_column,avgHeartRate_column,'VariableNames',variableNames);
        save(modelDataSetID,'paramsTable')
end

end
