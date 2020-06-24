function [] = FigS19_Manuscript2020_fin(rootFolder,AnalysisResults)
%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%
% Purpose:
%________________________________________________________________________________________________________________________

IOS_animalIDs = {'T99','T101','T102','T103','T105','T108','T109','T110','T111','T119','T120','T121','T122','T123'};
behavFields = {'Rest','NREM','REM','Awake','Sleep','All'};
dataTypes = {'deltaBandPower','thetaBandPower','alphaBandPower','betaBandPower'};
colorA = [(51/256),(160/256),(44/256)];   % Rest color
colorB = [(192/256),(0/256),(256/256)];   % NREM color
colorC = [(255/256),(140/256),(0/256)];   % REM color
% colorD = [(31/256),(120/256),(180/256)];  % Whisk color
% colorE = [(0/256),(256/256),(256/256)];  % Isoflurane color
colorF = [(256/256),(192/256),(0/256)];   % Awake color
colorG = [(0/256),(128/256),(256/256)];   % Sleep color
colorH = [(184/256),(115/256),(51/256)];  % All color
%% Average coherence during different behaviors
% cd through each animal's directory and extract the appropriate analysis results
data.Coherr = [];
for a = 1:length(IOS_animalIDs)
    animalID = IOS_animalIDs{1,a};
    for b = 1:length(behavFields)
        behavField = behavFields{1,b};
        % create the behavior folder for the first iteration of the loop
        if isfield(data.Coherr,behavField) == false
            data.Coherr.(behavField) = [];
        end
        for c = 1:length(dataTypes)
            dataType = dataTypes{1,c};
            % don't concatenate empty arrays where there was no data for this behavior
            if isempty(AnalysisResults.(animalID).Coherence.(behavField).(dataType).C) == false
                % create the data type folder for the first iteration of the loop
                if isfield(data.Coherr.(behavField),dataType) == false
                    data.Coherr.(behavField).(dataType).C = [];
                    data.Coherr.(behavField).(dataType).f = [];
                    data.Coherr.(behavField).(dataType).confC = [];
                    data.Coherr.(behavField).(dataType).animalID = {};
                    data.Coherr.(behavField).(dataType).behavior = {};
                end
                % concatenate C/f for existing data - exclude any empty sets
                data.Coherr.(behavField).(dataType).C = cat(2,data.Coherr.(behavField).(dataType).C,AnalysisResults.(animalID).Coherence.(behavField).(dataType).C);
                data.Coherr.(behavField).(dataType).f = cat(1,data.Coherr.(behavField).(dataType).f,AnalysisResults.(animalID).Coherence.(behavField).(dataType).f);
                data.Coherr.(behavField).(dataType).confC = cat(1,data.Coherr.(behavField).(dataType).confC,AnalysisResults.(animalID).Coherence.(behavField).(dataType).confC);
                if isempty(AnalysisResults.(animalID).Coherence.(behavField).(dataType).C) == false
                    data.Coherr.(behavField).(dataType).animalID = cat(1,data.Coherr.(behavField).(dataType).animalID,animalID);
                    data.Coherr.(behavField).(dataType).behavior = cat(1,data.Coherr.(behavField).(dataType).behavior,behavField);
                end
            end
        end
    end
end
% find 0.1/0.01 Hz peaks in coherence
for e = 1:length(behavFields)
    behavField = behavFields{1,e};
    for f = 1:length(dataTypes)
        dataType = dataTypes{1,f};
        for g = 1:size(data.Coherr.(behavField).(dataType).C,2)
            if strcmp(behavField,'Rest') == true
                f_short = data.Coherr.(behavField).(dataType).f(g,:);
                C = data.Coherr.(behavField).(dataType).C(:,g);
                f_long = 0:0.01:0.5;
                C_long = interp1(f_short,C,f_long);
                index01 = find(f_long == 0.1);
                data.Coherr.(behavField).(dataType).C01(g,1) = C_long(index01).^2; %#ok<FNDSB>
            elseif strcmp(behavField,'NREM') == true || strcmp(behavField,'REM') == true
                F = round(data.Coherr.(behavField).(dataType).f(g,:),2);
                C = data.Coherr.(behavField).(dataType).C(:,g);
                index01 = find(F == 0.1);
                data.Coherr.(behavField).(dataType).C01(g,1) = C(index01(1)).^2;
            else
                F = round(data.Coherr.(behavField).(dataType).f(g,:),3);
                C = data.Coherr.(behavField).(dataType).C(:,g);
                index01 = find(F == 0.1);
                index001 = find(F == 0.01);
                data.Coherr.(behavField).(dataType).C01(g,1) = C(index01(1)).^2;
                data.Coherr.(behavField).(dataType).C001(g,1) = C(index001(1)).^2;
            end
        end
    end
end
% take mean/StD of peak C
for e = 1:length(behavFields)
    behavField = behavFields{1,e};
    for f = 1:length(dataTypes)
        dataType = dataTypes{1,f};
        if strcmp(behavField,'Rest') == true || strcmp(behavField,'NREM') == true || strcmp(behavField,'REM') == true
            data.Coherr.(behavField).(dataType).meanC01 = mean(data.Coherr.(behavField).(dataType).C01,1);
            data.Coherr.(behavField).(dataType).stdC01 = std(data.Coherr.(behavField).(dataType).C01,0,1);
        else
            data.Coherr.(behavField).(dataType).meanC01 = mean(data.Coherr.(behavField).(dataType).C01,1);
            data.Coherr.(behavField).(dataType).stdC01 = std(data.Coherr.(behavField).(dataType).C01,0,1);
            data.Coherr.(behavField).(dataType).meanC001 = mean(data.Coherr.(behavField).(dataType).C001,1);
            data.Coherr.(behavField).(dataType).stdC001 = std(data.Coherr.(behavField).(dataType).C001,0,1);
        end
    end
end
%% statistics - generalized linear mixed effects model
% Delta PSD @ 0.1 Hz
Delta_Coh01_tableSize = cat(1,data.Coherr.Rest.deltaBandPower.C01,data.Coherr.NREM.deltaBandPower.C01,data.Coherr.REM.deltaBandPower.C01,...
    data.Coherr.Awake.deltaBandPower.C01,data.Coherr.Sleep.deltaBandPower.C01,data.Coherr.All.deltaBandPower.C01);
Delta_Coh01_Table = table('Size',[size(Delta_Coh01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh01'});
Delta_Coh01_Table.Mouse = cat(1,data.Coherr.Rest.deltaBandPower.animalID,data.Coherr.NREM.deltaBandPower.animalID,data.Coherr.REM.deltaBandPower.animalID,...
    data.Coherr.Awake.deltaBandPower.animalID,data.Coherr.Sleep.deltaBandPower.animalID,data.Coherr.All.deltaBandPower.animalID);
Delta_Coh01_Table.Behavior = cat(1,data.Coherr.Rest.deltaBandPower.behavior,data.Coherr.NREM.deltaBandPower.behavior,data.Coherr.REM.deltaBandPower.behavior,...
    data.Coherr.Awake.deltaBandPower.behavior,data.Coherr.Sleep.deltaBandPower.behavior,data.Coherr.All.deltaBandPower.behavior);
Delta_Coh01_Table.Coh01 = cat(1,data.Coherr.Rest.deltaBandPower.C01,data.Coherr.NREM.deltaBandPower.C01,data.Coherr.REM.deltaBandPower.C01,...
    data.Coherr.Awake.deltaBandPower.C01,data.Coherr.Sleep.deltaBandPower.C01,data.Coherr.All.deltaBandPower.C01);
Delta_Coh01_FitFormula = 'Coh01 ~ 1 + Behavior + (1|Mouse)';
Delta_Coh01_Stats = fitglme(Delta_Coh01_Table,Delta_Coh01_FitFormula);
% Delta PSD @ 0.01 Hz
Delta_Coh001_tableSize = cat(1,data.Coherr.Awake.deltaBandPower.C001,data.Coherr.Sleep.deltaBandPower.C001,data.Coherr.All.deltaBandPower.C001);
Delta_Coh001_Table = table('Size',[size(Delta_Coh001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh001'});
Delta_Coh001_Table.Mouse = cat(1,data.Coherr.Awake.deltaBandPower.animalID,data.Coherr.Sleep.deltaBandPower.animalID,data.Coherr.All.deltaBandPower.animalID);
Delta_Coh001_Table.Behavior = cat(1,data.Coherr.Awake.deltaBandPower.behavior,data.Coherr.Sleep.deltaBandPower.behavior,data.Coherr.All.deltaBandPower.behavior);
Delta_Coh001_Table.Coh001 = cat(1,data.Coherr.Awake.deltaBandPower.C001,data.Coherr.Sleep.deltaBandPower.C001,data.Coherr.All.deltaBandPower.C001);
Delta_Coh001_FitFormula = 'Coh001 ~ 1 + Behavior + (1|Mouse)';
Delta_Coh001_Stats = fitglme(Delta_Coh001_Table,Delta_Coh001_FitFormula);
% Theta PSD @ 0.1 Hz
Theta_Coh01_tableSize = cat(1,data.Coherr.Rest.thetaBandPower.C01,data.Coherr.NREM.thetaBandPower.C01,data.Coherr.REM.thetaBandPower.C01,...
    data.Coherr.Awake.thetaBandPower.C01,data.Coherr.Sleep.thetaBandPower.C01,data.Coherr.All.thetaBandPower.C01);
Theta_Coh01_Table = table('Size',[size(Theta_Coh01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh01'});
Theta_Coh01_Table.Mouse = cat(1,data.Coherr.Rest.thetaBandPower.animalID,data.Coherr.NREM.thetaBandPower.animalID,data.Coherr.REM.thetaBandPower.animalID,...
    data.Coherr.Awake.thetaBandPower.animalID,data.Coherr.Sleep.thetaBandPower.animalID,data.Coherr.All.thetaBandPower.animalID);
Theta_Coh01_Table.Behavior = cat(1,data.Coherr.Rest.thetaBandPower.behavior,data.Coherr.NREM.thetaBandPower.behavior,data.Coherr.REM.thetaBandPower.behavior,...
    data.Coherr.Awake.thetaBandPower.behavior,data.Coherr.Sleep.thetaBandPower.behavior,data.Coherr.All.thetaBandPower.behavior);
Theta_Coh01_Table.Coh01 = cat(1,data.Coherr.Rest.thetaBandPower.C01,data.Coherr.NREM.thetaBandPower.C01,data.Coherr.REM.thetaBandPower.C01,...
    data.Coherr.Awake.thetaBandPower.C01,data.Coherr.Sleep.thetaBandPower.C01,data.Coherr.All.thetaBandPower.C01);
Theta_Coh01_FitFormula = 'Coh01 ~ 1 + Behavior + (1|Mouse)';
Theta_Coh01_Stats = fitglme(Theta_Coh01_Table,Theta_Coh01_FitFormula);
% Theta PSD @ 0.01 Hz
Theta_Coh001_tableSize = cat(1,data.Coherr.Awake.thetaBandPower.C001,data.Coherr.Sleep.thetaBandPower.C001,data.Coherr.All.thetaBandPower.C001);
Theta_Coh001_Table = table('Size',[size(Theta_Coh001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh001'});
Theta_Coh001_Table.Mouse = cat(1,data.Coherr.Awake.thetaBandPower.animalID,data.Coherr.Sleep.thetaBandPower.animalID,data.Coherr.All.thetaBandPower.animalID);
Theta_Coh001_Table.Behavior = cat(1,data.Coherr.Awake.thetaBandPower.behavior,data.Coherr.Sleep.thetaBandPower.behavior,data.Coherr.All.thetaBandPower.behavior);
Theta_Coh001_Table.Coh001 = cat(1,data.Coherr.Awake.thetaBandPower.C001,data.Coherr.Sleep.thetaBandPower.C001,data.Coherr.All.thetaBandPower.C001);
Theta_Coh001_FitFormula = 'Coh001 ~ 1 + Behavior + (1|Mouse)';
Theta_Coh001_Stats = fitglme(Theta_Coh001_Table,Theta_Coh001_FitFormula);
% Alpha PSD @ 0.1 Hz
Alpha_Coh01_tableSize = cat(1,data.Coherr.Rest.alphaBandPower.C01,data.Coherr.NREM.alphaBandPower.C01,data.Coherr.REM.alphaBandPower.C01,...
    data.Coherr.Awake.alphaBandPower.C01,data.Coherr.Sleep.alphaBandPower.C01,data.Coherr.All.alphaBandPower.C01);
Alpha_Coh01_Table = table('Size',[size(Alpha_Coh01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh01'});
Alpha_Coh01_Table.Mouse = cat(1,data.Coherr.Rest.alphaBandPower.animalID,data.Coherr.NREM.alphaBandPower.animalID,data.Coherr.REM.alphaBandPower.animalID,...
    data.Coherr.Awake.alphaBandPower.animalID,data.Coherr.Sleep.alphaBandPower.animalID,data.Coherr.All.alphaBandPower.animalID);
Alpha_Coh01_Table.Behavior = cat(1,data.Coherr.Rest.alphaBandPower.behavior,data.Coherr.NREM.alphaBandPower.behavior,data.Coherr.REM.alphaBandPower.behavior,...
    data.Coherr.Awake.alphaBandPower.behavior,data.Coherr.Sleep.alphaBandPower.behavior,data.Coherr.All.alphaBandPower.behavior);
Alpha_Coh01_Table.Coh01 = cat(1,data.Coherr.Rest.alphaBandPower.C01,data.Coherr.NREM.alphaBandPower.C01,data.Coherr.REM.alphaBandPower.C01,...
    data.Coherr.Awake.alphaBandPower.C01,data.Coherr.Sleep.alphaBandPower.C01,data.Coherr.All.alphaBandPower.C01);
Alpha_Coh01_FitFormula = 'Coh01 ~ 1 + Behavior + (1|Mouse)';
Alpha_Coh01_Stats = fitglme(Alpha_Coh01_Table,Alpha_Coh01_FitFormula);
% Alpha PSD @ 0.01 Hz
Alpha_Coh001_tableSize = cat(1,data.Coherr.Awake.alphaBandPower.C001,data.Coherr.Sleep.alphaBandPower.C001,data.Coherr.All.alphaBandPower.C001);
Alpha_Coh001_Table = table('Size',[size(Alpha_Coh001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh001'});
Alpha_Coh001_Table.Mouse = cat(1,data.Coherr.Awake.alphaBandPower.animalID,data.Coherr.Sleep.alphaBandPower.animalID,data.Coherr.All.alphaBandPower.animalID);
Alpha_Coh001_Table.Behavior = cat(1,data.Coherr.Awake.alphaBandPower.behavior,data.Coherr.Sleep.alphaBandPower.behavior,data.Coherr.All.alphaBandPower.behavior);
Alpha_Coh001_Table.Coh001 = cat(1,data.Coherr.Awake.alphaBandPower.C001,data.Coherr.Sleep.alphaBandPower.C001,data.Coherr.All.alphaBandPower.C001);
Alpha_Coh001_FitFormula = 'Coh001 ~ 1 + Behavior + (1|Mouse)';
Alpha_Coh001_Stats = fitglme(Alpha_Coh001_Table,Alpha_Coh001_FitFormula);
% Beta PSD @ 0.1 Hz
Beta_Coh01_tableSize = cat(1,data.Coherr.Rest.betaBandPower.C01,data.Coherr.NREM.betaBandPower.C01,data.Coherr.REM.betaBandPower.C01,...
    data.Coherr.Awake.betaBandPower.C01,data.Coherr.Sleep.betaBandPower.C01,data.Coherr.All.betaBandPower.C01);
Beta_Coh01_Table = table('Size',[size(Beta_Coh01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh01'});
Beta_Coh01_Table.Mouse = cat(1,data.Coherr.Rest.betaBandPower.animalID,data.Coherr.NREM.betaBandPower.animalID,data.Coherr.REM.betaBandPower.animalID,...
    data.Coherr.Awake.betaBandPower.animalID,data.Coherr.Sleep.betaBandPower.animalID,data.Coherr.All.betaBandPower.animalID);
Beta_Coh01_Table.Behavior = cat(1,data.Coherr.Rest.betaBandPower.behavior,data.Coherr.NREM.betaBandPower.behavior,data.Coherr.REM.betaBandPower.behavior,...
    data.Coherr.Awake.betaBandPower.behavior,data.Coherr.Sleep.betaBandPower.behavior,data.Coherr.All.betaBandPower.behavior);
Beta_Coh01_Table.Coh01 = cat(1,data.Coherr.Rest.betaBandPower.C01,data.Coherr.NREM.betaBandPower.C01,data.Coherr.REM.betaBandPower.C01,...
    data.Coherr.Awake.betaBandPower.C01,data.Coherr.Sleep.betaBandPower.C01,data.Coherr.All.betaBandPower.C01);
Beta_Coh01_FitFormula = 'Coh01 ~ 1 + Behavior + (1|Mouse)';
Beta_Coh01_Stats = fitglme(Beta_Coh01_Table,Beta_Coh01_FitFormula);
% Beta PSD @ 0.01 Hz
Beta_Coh001_tableSize = cat(1,data.Coherr.Awake.betaBandPower.C001,data.Coherr.Sleep.betaBandPower.C001,data.Coherr.All.betaBandPower.C001);
Beta_Coh001_Table = table('Size',[size(Beta_Coh001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','Coh001'});
Beta_Coh001_Table.Mouse = cat(1,data.Coherr.Awake.betaBandPower.animalID,data.Coherr.Sleep.betaBandPower.animalID,data.Coherr.All.betaBandPower.animalID);
Beta_Coh001_Table.Behavior = cat(1,data.Coherr.Awake.betaBandPower.behavior,data.Coherr.Sleep.betaBandPower.behavior,data.Coherr.All.betaBandPower.behavior);
Beta_Coh001_Table.Coh001 = cat(1,data.Coherr.Awake.betaBandPower.C001,data.Coherr.Sleep.betaBandPower.C001,data.Coherr.All.betaBandPower.C001);
Beta_Coh001_FitFormula = 'Coh001 ~ 1 + Behavior + (1|Mouse)';
Beta_Coh001_Stats = fitglme(Beta_Coh001_Table,Beta_Coh001_FitFormula);
%% Power spectra during different behaviors
% cd through each animal's directory and extract the appropriate analysis results
for a = 1:length(IOS_animalIDs)
    animalID = IOS_animalIDs{1,a};
    for b = 1:length(behavFields)
        behavField = behavFields{1,b};
        for c = 1:length(dataTypes)
            dataType = dataTypes{1,c};
            data.PowerSpec.(behavField).(dataType).adjLH.S{a,1} = AnalysisResults.(animalID).PowerSpectra.(behavField).(dataType).adjLH.S;
            data.PowerSpec.(behavField).(dataType).adjLH.f{a,1} = AnalysisResults.(animalID).PowerSpectra.(behavField).(dataType).adjLH.f;
            data.PowerSpec.(behavField).(dataType).adjRH.S{a,1} = AnalysisResults.(animalID).PowerSpectra.(behavField).(dataType).adjRH.S;
            data.PowerSpec.(behavField).(dataType).adjRH.f{a,1} = AnalysisResults.(animalID).PowerSpectra.(behavField).(dataType).adjRH.f;
        end
    end
end
% find the peak of the resting PSD for each animal/hemisphere
for a = 1:length(IOS_animalIDs)
    for c = 1:length(dataTypes)
        dataType = dataTypes{1,c};
        data.PowerSpec.baseline.(dataType).LH{a,1} = max(data.PowerSpec.Rest.(dataType).adjLH.S{a,1});
        data.PowerSpec.baseline.(dataType).RH{a,1} = max(data.PowerSpec.Rest.(dataType).adjRH.S{a,1});
    end
end
% DC-shift each animal/hemisphere/behavior PSD with respect to the resting peak
for a = 1:length(IOS_animalIDs)
    for dd = 1:length(behavFields)
        behavField = behavFields{1,dd};
        for j = 1:length(dataTypes)
            dataType = dataTypes{1,j};
            for ee = 1:size(data.PowerSpec.(behavField).(dataType).adjLH.S,2)
                data.PowerSpec.(behavField).(dataType).normLH{a,1} = (data.PowerSpec.(behavField).(dataType).adjLH.S{a,1})*(1/(data.PowerSpec.baseline.(dataType).LH{a,1}));
                data.PowerSpec.(behavField).(dataType).normRH{a,1} = (data.PowerSpec.(behavField).(dataType).adjRH.S{a,1})*(1/(data.PowerSpec.baseline.(dataType).RH{a,1}));
            end
        end
    end
end
% concatenate the data from the left and right hemispheres - removes any empty data
for e = 1:length(behavFields)
    behavField = behavFields{1,e};
    for f = 1:length(dataTypes)
        dataType = dataTypes{1,f};
        data.PowerSpec.(behavField).(dataType).cat_S = [];
        data.PowerSpec.(behavField).(dataType).cat_f = [];
        data.PowerSpec.(behavField).(dataType).animalID = {};
        data.PowerSpec.(behavField).(dataType).behavior = {};
        data.PowerSpec.(behavField).(dataType).hemisphere = {};
        for z = 1:length(data.PowerSpec.(behavField).(dataType).normLH)
            data.PowerSpec.(behavField).(dataType).cat_S = cat(2,data.PowerSpec.(behavField).(dataType).cat_S,data.PowerSpec.(behavField).(dataType).normLH{z,1},data.PowerSpec.(behavField).(dataType).normRH{z,1});
            data.PowerSpec.(behavField).(dataType).cat_f = cat(1,data.PowerSpec.(behavField).(dataType).cat_f,data.PowerSpec.(behavField).(dataType).adjLH.f{z,1},data.PowerSpec.(behavField).(dataType).adjRH.f{z,1});
            if isempty(data.PowerSpec.(behavField).(dataType).normLH{z,1}) == false
                data.PowerSpec.(behavField).(dataType).animalID = cat(1,data.PowerSpec.(behavField).(dataType).animalID,animalID,animalID);
                data.PowerSpec.(behavField).(dataType).behavior = cat(1,data.PowerSpec.(behavField).(dataType).behavior,behavField,behavField);
                data.PowerSpec.(behavField).(dataType).hemisphere = cat(1,data.PowerSpec.(behavField).(dataType).hemisphere,'LH','RH');
            end
        end
    end
end
% find 0.1/0.01 Hz peaks in PSD
for e = 1:length(behavFields)
    behavField = behavFields{1,e};
    for f = 1:length(dataTypes)
        dataType = dataTypes{1,f};
        for g = 1:size(data.PowerSpec.(behavField).(dataType).cat_S,2)
            if strcmp(behavField,'Rest') == true
                f_short = data.PowerSpec.(behavField).(dataType).cat_f(g,:);
                S = data.PowerSpec.(behavField).(dataType).cat_S(:,g);
                f_long = 0:0.01:0.5;
                S_long = interp1(f_short,S,f_long);
                index01 = find(f_long == 0.1);
                data.PowerSpec.(behavField).(dataType).S01(g,1) = S_long(index01); %#ok<FNDSB>
            elseif strcmp(behavField,'NREM') == true || strcmp(behavField,'REM') == true
                F = round(data.PowerSpec.(behavField).(dataType).cat_f(g,:),2);
                S = data.PowerSpec.(behavField).(dataType).cat_S(:,g);
                index01 = find(F == 0.1);
                data.PowerSpec.(behavField).(dataType).S01(g,1) = S(index01(1));
            else
                F = round(data.PowerSpec.(behavField).(dataType).cat_f(g,:),3);
                S = data.PowerSpec.(behavField).(dataType).cat_S(:,g);
                index01 = find(F == 0.1);
                index001 = find(F == 0.01);
                data.PowerSpec.(behavField).(dataType).S01(g,1) = S(index01(1));
                data.PowerSpec.(behavField).(dataType).S001(g,1) = S(index001(1));
            end
        end
    end
end
% take mean/StD of peak S
for e = 1:length(behavFields)
    behavField = behavFields{1,e};
    for f = 1:length(dataTypes)
        dataType = dataTypes{1,f};
        if strcmp(behavField,'Rest') == true || strcmp(behavField,'NREM') == true || strcmp(behavField,'REM') == true
            data.PowerSpec.(behavField).(dataType).meanS01 = mean(data.PowerSpec.(behavField).(dataType).S01,1);
            data.PowerSpec.(behavField).(dataType).stdS01 = std(data.PowerSpec.(behavField).(dataType).S01,0,1);
        else
            data.PowerSpec.(behavField).(dataType).meanS01 = mean(data.PowerSpec.(behavField).(dataType).S01,1);
            data.PowerSpec.(behavField).(dataType).stdS01 = std(data.PowerSpec.(behavField).(dataType).S01,0,1);
            data.PowerSpec.(behavField).(dataType).meanS001 = mean(data.PowerSpec.(behavField).(dataType).S001,1);
            data.PowerSpec.(behavField).(dataType).stdS001 = std(data.PowerSpec.(behavField).(dataType).S001,0,1);
        end
    end
end
%% statistics - generalized linear mixed effects model
% Delta PSD @ 0.1 Hz
Delta_PSD01_tableSize = cat(1,data.PowerSpec.Rest.deltaBandPower.S01,data.PowerSpec.NREM.deltaBandPower.S01,data.PowerSpec.REM.deltaBandPower.S01,...
    data.PowerSpec.Awake.deltaBandPower.S01,data.PowerSpec.Sleep.deltaBandPower.S01,data.PowerSpec.All.deltaBandPower.S01);
Delta_PSD01_Table = table('Size',[size(Delta_PSD01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD01'});
Delta_PSD01_Table.Mouse = cat(1,data.PowerSpec.Rest.deltaBandPower.animalID,data.PowerSpec.NREM.deltaBandPower.animalID,data.PowerSpec.REM.deltaBandPower.animalID,...
    data.PowerSpec.Awake.deltaBandPower.animalID,data.PowerSpec.Sleep.deltaBandPower.animalID,data.PowerSpec.All.deltaBandPower.animalID);
Delta_PSD01_Table.Hemisphere = cat(1,data.PowerSpec.Rest.deltaBandPower.hemisphere,data.PowerSpec.NREM.deltaBandPower.hemisphere,data.PowerSpec.REM.deltaBandPower.hemisphere,...
    data.PowerSpec.Awake.deltaBandPower.hemisphere,data.PowerSpec.Sleep.deltaBandPower.hemisphere,data.PowerSpec.All.deltaBandPower.hemisphere);
Delta_PSD01_Table.Behavior = cat(1,data.PowerSpec.Rest.deltaBandPower.behavior,data.PowerSpec.NREM.deltaBandPower.behavior,data.PowerSpec.REM.deltaBandPower.behavior,...
    data.PowerSpec.Awake.deltaBandPower.behavior,data.PowerSpec.Sleep.deltaBandPower.behavior,data.PowerSpec.All.deltaBandPower.behavior);
Delta_PSD01_Table.PSD01 = cat(1,data.PowerSpec.Rest.deltaBandPower.S01,data.PowerSpec.NREM.deltaBandPower.S01,data.PowerSpec.REM.deltaBandPower.S01,...
    data.PowerSpec.Awake.deltaBandPower.S01,data.PowerSpec.Sleep.deltaBandPower.S01,data.PowerSpec.All.deltaBandPower.S01);
Delta_PSD01_FitFormula = 'PSD01 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Delta_PSD01_Stats = fitglme(Delta_PSD01_Table,Delta_PSD01_FitFormula);
% Delta PSD @ 0.01 Hz
Delta_PSD001_tableSize = cat(1,data.PowerSpec.Awake.deltaBandPower.S001,data.PowerSpec.Sleep.deltaBandPower.S001,data.PowerSpec.All.deltaBandPower.S001);
Delta_PSD001_Table = table('Size',[size(Delta_PSD001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD001'});
Delta_PSD001_Table.Mouse = cat(1,data.PowerSpec.Awake.deltaBandPower.animalID,data.PowerSpec.Sleep.deltaBandPower.animalID,data.PowerSpec.All.deltaBandPower.animalID);
Delta_PSD001_Table.Hemisphere = cat(1,data.PowerSpec.Awake.deltaBandPower.hemisphere,data.PowerSpec.Sleep.deltaBandPower.hemisphere,data.PowerSpec.All.deltaBandPower.hemisphere);
Delta_PSD001_Table.Behavior = cat(1,data.PowerSpec.Awake.deltaBandPower.behavior,data.PowerSpec.Sleep.deltaBandPower.behavior,data.PowerSpec.All.deltaBandPower.behavior);
Delta_PSD001_Table.PSD001 = cat(1,data.PowerSpec.Awake.deltaBandPower.S001,data.PowerSpec.Sleep.deltaBandPower.S001,data.PowerSpec.All.deltaBandPower.S001);
Delta_PSD001_FitFormula = 'PSD001 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Delta_PSD001_Stats = fitglme(Delta_PSD001_Table,Delta_PSD001_FitFormula);
% Theta PSD @ 0.1 Hz
Theta_PSD01_tableSize = cat(1,data.PowerSpec.Rest.thetaBandPower.S01,data.PowerSpec.NREM.thetaBandPower.S01,data.PowerSpec.REM.thetaBandPower.S01,...
    data.PowerSpec.Awake.thetaBandPower.S01,data.PowerSpec.Sleep.thetaBandPower.S01,data.PowerSpec.All.thetaBandPower.S01);
Theta_PSD01_Table = table('Size',[size(Theta_PSD01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD01'});
Theta_PSD01_Table.Mouse = cat(1,data.PowerSpec.Rest.thetaBandPower.animalID,data.PowerSpec.NREM.thetaBandPower.animalID,data.PowerSpec.REM.thetaBandPower.animalID,...
    data.PowerSpec.Awake.thetaBandPower.animalID,data.PowerSpec.Sleep.thetaBandPower.animalID,data.PowerSpec.All.thetaBandPower.animalID);
Theta_PSD01_Table.Hemisphere = cat(1,data.PowerSpec.Rest.thetaBandPower.hemisphere,data.PowerSpec.NREM.thetaBandPower.hemisphere,data.PowerSpec.REM.thetaBandPower.hemisphere,...
    data.PowerSpec.Awake.thetaBandPower.hemisphere,data.PowerSpec.Sleep.thetaBandPower.hemisphere,data.PowerSpec.All.thetaBandPower.hemisphere);
Theta_PSD01_Table.Behavior = cat(1,data.PowerSpec.Rest.thetaBandPower.behavior,data.PowerSpec.NREM.thetaBandPower.behavior,data.PowerSpec.REM.thetaBandPower.behavior,...
    data.PowerSpec.Awake.thetaBandPower.behavior,data.PowerSpec.Sleep.thetaBandPower.behavior,data.PowerSpec.All.thetaBandPower.behavior);
Theta_PSD01_Table.PSD01 = cat(1,data.PowerSpec.Rest.thetaBandPower.S01,data.PowerSpec.NREM.thetaBandPower.S01,data.PowerSpec.REM.thetaBandPower.S01,...
    data.PowerSpec.Awake.thetaBandPower.S01,data.PowerSpec.Sleep.thetaBandPower.S01,data.PowerSpec.All.thetaBandPower.S01);
Theta_PSD01_FitFormula = 'PSD01 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Theta_PSD01_Stats = fitglme(Theta_PSD01_Table,Theta_PSD01_FitFormula);
% Theta PSD @ 0.01 Hz
Theta_PSD001_tableSize = cat(1,data.PowerSpec.Awake.thetaBandPower.S001,data.PowerSpec.Sleep.thetaBandPower.S001,data.PowerSpec.All.thetaBandPower.S001);
Theta_PSD001_Table = table('Size',[size(Theta_PSD001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD001'});
Theta_PSD001_Table.Mouse = cat(1,data.PowerSpec.Awake.thetaBandPower.animalID,data.PowerSpec.Sleep.thetaBandPower.animalID,data.PowerSpec.All.thetaBandPower.animalID);
Theta_PSD001_Table.Hemisphere = cat(1,data.PowerSpec.Awake.thetaBandPower.hemisphere,data.PowerSpec.Sleep.thetaBandPower.hemisphere,data.PowerSpec.All.thetaBandPower.hemisphere);
Theta_PSD001_Table.Behavior = cat(1,data.PowerSpec.Awake.thetaBandPower.behavior,data.PowerSpec.Sleep.thetaBandPower.behavior,data.PowerSpec.All.thetaBandPower.behavior);
Theta_PSD001_Table.PSD001 = cat(1,data.PowerSpec.Awake.thetaBandPower.S001,data.PowerSpec.Sleep.thetaBandPower.S001,data.PowerSpec.All.thetaBandPower.S001);
Theta_PSD001_FitFormula = 'PSD001 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Theta_PSD001_Stats = fitglme(Theta_PSD001_Table,Theta_PSD001_FitFormula);
% Alpha PSD @ 0.1 Hz
Alpha_PSD01_tableSize = cat(1,data.PowerSpec.Rest.alphaBandPower.S01,data.PowerSpec.NREM.alphaBandPower.S01,data.PowerSpec.REM.alphaBandPower.S01,...
    data.PowerSpec.Awake.alphaBandPower.S01,data.PowerSpec.Sleep.alphaBandPower.S01,data.PowerSpec.All.alphaBandPower.S01);
Alpha_PSD01_Table = table('Size',[size(Alpha_PSD01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD01'});
Alpha_PSD01_Table.Mouse = cat(1,data.PowerSpec.Rest.alphaBandPower.animalID,data.PowerSpec.NREM.alphaBandPower.animalID,data.PowerSpec.REM.alphaBandPower.animalID,...
    data.PowerSpec.Awake.alphaBandPower.animalID,data.PowerSpec.Sleep.alphaBandPower.animalID,data.PowerSpec.All.alphaBandPower.animalID);
Alpha_PSD01_Table.Hemisphere = cat(1,data.PowerSpec.Rest.alphaBandPower.hemisphere,data.PowerSpec.NREM.alphaBandPower.hemisphere,data.PowerSpec.REM.alphaBandPower.hemisphere,...
    data.PowerSpec.Awake.alphaBandPower.hemisphere,data.PowerSpec.Sleep.alphaBandPower.hemisphere,data.PowerSpec.All.alphaBandPower.hemisphere);
Alpha_PSD01_Table.Behavior = cat(1,data.PowerSpec.Rest.alphaBandPower.behavior,data.PowerSpec.NREM.alphaBandPower.behavior,data.PowerSpec.REM.alphaBandPower.behavior,...
    data.PowerSpec.Awake.alphaBandPower.behavior,data.PowerSpec.Sleep.alphaBandPower.behavior,data.PowerSpec.All.alphaBandPower.behavior);
Alpha_PSD01_Table.PSD01 = cat(1,data.PowerSpec.Rest.alphaBandPower.S01,data.PowerSpec.NREM.alphaBandPower.S01,data.PowerSpec.REM.alphaBandPower.S01,...
    data.PowerSpec.Awake.alphaBandPower.S01,data.PowerSpec.Sleep.alphaBandPower.S01,data.PowerSpec.All.alphaBandPower.S01);
Alpha_PSD01_FitFormula = 'PSD01 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Alpha_PSD01_Stats = fitglme(Alpha_PSD01_Table,Alpha_PSD01_FitFormula);
% Alpha PSD @ 0.01 Hz
Alpha_PSD001_tableSize = cat(1,data.PowerSpec.Awake.alphaBandPower.S001,data.PowerSpec.Sleep.alphaBandPower.S001,data.PowerSpec.All.alphaBandPower.S001);
Alpha_PSD001_Table = table('Size',[size(Alpha_PSD001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD001'});
Alpha_PSD001_Table.Mouse = cat(1,data.PowerSpec.Awake.alphaBandPower.animalID,data.PowerSpec.Sleep.alphaBandPower.animalID,data.PowerSpec.All.alphaBandPower.animalID);
Alpha_PSD001_Table.Hemisphere = cat(1,data.PowerSpec.Awake.alphaBandPower.hemisphere,data.PowerSpec.Sleep.alphaBandPower.hemisphere,data.PowerSpec.All.alphaBandPower.hemisphere);
Alpha_PSD001_Table.Behavior = cat(1,data.PowerSpec.Awake.alphaBandPower.behavior,data.PowerSpec.Sleep.alphaBandPower.behavior,data.PowerSpec.All.alphaBandPower.behavior);
Alpha_PSD001_Table.PSD001 = cat(1,data.PowerSpec.Awake.alphaBandPower.S001,data.PowerSpec.Sleep.alphaBandPower.S001,data.PowerSpec.All.alphaBandPower.S001);
Alpha_PSD001_FitFormula = 'PSD001 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Alpha_PSD001_Stats = fitglme(Alpha_PSD001_Table,Alpha_PSD001_FitFormula);
% Beta PSD @ 0.1 Hz
Beta_PSD01_tableSize = cat(1,data.PowerSpec.Rest.betaBandPower.S01,data.PowerSpec.NREM.betaBandPower.S01,data.PowerSpec.REM.betaBandPower.S01,...
    data.PowerSpec.Awake.betaBandPower.S01,data.PowerSpec.Sleep.betaBandPower.S01,data.PowerSpec.All.betaBandPower.S01);
Beta_PSD01_Table = table('Size',[size(Beta_PSD01_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD01'});
Beta_PSD01_Table.Mouse = cat(1,data.PowerSpec.Rest.betaBandPower.animalID,data.PowerSpec.NREM.betaBandPower.animalID,data.PowerSpec.REM.betaBandPower.animalID,...
    data.PowerSpec.Awake.betaBandPower.animalID,data.PowerSpec.Sleep.betaBandPower.animalID,data.PowerSpec.All.betaBandPower.animalID);
Beta_PSD01_Table.Hemisphere = cat(1,data.PowerSpec.Rest.betaBandPower.hemisphere,data.PowerSpec.NREM.betaBandPower.hemisphere,data.PowerSpec.REM.betaBandPower.hemisphere,...
    data.PowerSpec.Awake.betaBandPower.hemisphere,data.PowerSpec.Sleep.betaBandPower.hemisphere,data.PowerSpec.All.betaBandPower.hemisphere);
Beta_PSD01_Table.Behavior = cat(1,data.PowerSpec.Rest.betaBandPower.behavior,data.PowerSpec.NREM.betaBandPower.behavior,data.PowerSpec.REM.betaBandPower.behavior,...
    data.PowerSpec.Awake.betaBandPower.behavior,data.PowerSpec.Sleep.betaBandPower.behavior,data.PowerSpec.All.betaBandPower.behavior);
Beta_PSD01_Table.PSD01 = cat(1,data.PowerSpec.Rest.betaBandPower.S01,data.PowerSpec.NREM.betaBandPower.S01,data.PowerSpec.REM.betaBandPower.S01,...
    data.PowerSpec.Awake.betaBandPower.S01,data.PowerSpec.Sleep.betaBandPower.S01,data.PowerSpec.All.betaBandPower.S01);
Beta_PSD01_FitFormula = 'PSD01 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Beta_PSD01_Stats = fitglme(Beta_PSD01_Table,Beta_PSD01_FitFormula);
% Beta PSD @ 0.01 Hz
Beta_PSD001_tableSize = cat(1,data.PowerSpec.Awake.betaBandPower.S001,data.PowerSpec.Sleep.betaBandPower.S001,data.PowerSpec.All.betaBandPower.S001);
Beta_PSD001_Table = table('Size',[size(Beta_PSD001_tableSize,1),4],'VariableTypes',{'string','string','string','double'},'VariableNames',{'Mouse','Vessel','Behavior','PSD001'});
Beta_PSD001_Table.Mouse = cat(1,data.PowerSpec.Awake.betaBandPower.animalID,data.PowerSpec.Sleep.betaBandPower.animalID,data.PowerSpec.All.betaBandPower.animalID);
Beta_PSD001_Table.Hemisphere = cat(1,data.PowerSpec.Awake.betaBandPower.hemisphere,data.PowerSpec.Sleep.betaBandPower.hemisphere,data.PowerSpec.All.betaBandPower.hemisphere);
Beta_PSD001_Table.Behavior = cat(1,data.PowerSpec.Awake.betaBandPower.behavior,data.PowerSpec.Sleep.betaBandPower.behavior,data.PowerSpec.All.betaBandPower.behavior);
Beta_PSD001_Table.PSD001 = cat(1,data.PowerSpec.Awake.betaBandPower.S001,data.PowerSpec.Sleep.betaBandPower.S001,data.PowerSpec.All.betaBandPower.S001);
Beta_PSD001_FitFormula = 'PSD001 ~ 1 + Behavior + (1|Mouse) + (1|Mouse:Hemisphere)';
Beta_PSD001_Stats = fitglme(Beta_PSD001_Table,Beta_PSD001_FitFormula);
%% Figure Panel S19
summaryFigure = figure('Name','FigS19 (a-p');
sgtitle('Figure Panel S19 (a-p) Turner Manuscript 2020')
%% [S19a] delta PSD
ax1 = subplot(4,4,1);
s1 = scatter(ones(1,length(data.PowerSpec.Rest.deltaBandPower.S01))*1,data.PowerSpec.Rest.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Rest.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
s2 = scatter(ones(1,length(data.PowerSpec.NREM.deltaBandPower.S01))*2,data.PowerSpec.NREM.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.NREM.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
s3 = scatter(ones(1,length(data.PowerSpec.REM.deltaBandPower.S01))*3,data.PowerSpec.REM.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.REM.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
s4 = scatter(ones(1,length(data.PowerSpec.Awake.deltaBandPower.S01))*4,data.PowerSpec.Awake.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.PowerSpec.Awake.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
s5 = scatter(ones(1,length(data.PowerSpec.Sleep.deltaBandPower.S01))*5,data.PowerSpec.Sleep.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.PowerSpec.Sleep.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
s6 = scatter(ones(1,length(data.PowerSpec.All.deltaBandPower.S01))*6,data.PowerSpec.All.deltaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.PowerSpec.All.deltaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19a] PSD @ 0.1 Hz','Delta-band [1-4 Hz]',''})
ylabel('Power (a.u.) @ 0.1 Hz')
legend([s1,s2,s3,s4,s5,s6],'Rest','NREM','REM','Awake','Sleep','All')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,7])
set(gca,'box','off')
ax1.TickLength = [0.03,0.03];
%% [S19b] ultra low delta PSD
ax2 = subplot(4,4,2);
scatter(ones(1,length(data.PowerSpec.Awake.deltaBandPower.S001))*1,data.PowerSpec.Awake.deltaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Awake.deltaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.deltaBandPower.S001))*2,data.PowerSpec.Sleep.deltaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.Sleep.deltaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.deltaBandPower.S001))*3,data.PowerSpec.All.deltaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.All.deltaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19b] PSD @ 0.01 Hz','Delta-band [1-4 Hz]',''})
ylabel('Power (a.u.) 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,4])
set(gca,'box','off')
ax2.TickLength = [0.03,0.03];
%% [S19c] delta Coherence^2
ax3 = subplot(4,4,3);
scatter(ones(1,length(data.Coherr.Rest.deltaBandPower.C01))*1,data.Coherr.Rest.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Rest.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.NREM.deltaBandPower.C01))*2,data.Coherr.NREM.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.NREM.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.REM.deltaBandPower.C01))*3,data.Coherr.REM.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.REM.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.Coherr.Awake.deltaBandPower.C01))*4,data.Coherr.Awake.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.Coherr.Awake.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.deltaBandPower.C01))*5,data.Coherr.Sleep.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.Coherr.Sleep.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.deltaBandPower.C01))*6,data.Coherr.All.deltaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.Coherr.All.deltaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19c] Coherence^2 @ 0.1 Hz','Delta-band [1-4 Hz]',''})
ylabel('Coherence^2 @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,7])
ylim([0,1])
set(gca,'box','off')
ax3.TickLength = [0.03,0.03];
%% [S19d] ultra low gamma Coherence^2
ax4 = subplot(4,4,4);
scatter(ones(1,length(data.Coherr.Awake.deltaBandPower.C001))*1,data.Coherr.Awake.deltaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Awake.deltaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.deltaBandPower.C001))*2,data.Coherr.Sleep.deltaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.Sleep.deltaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.deltaBandPower.C001))*3,data.Coherr.All.deltaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.All.deltaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19d] Coherence^2 @ 0.01 Hz','Delta-band [1-4 Hz]',''})
ylabel('Coherence^2 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,4])
ylim([0,1])
set(gca,'box','off')
ax4.TickLength = [0.03,0.03];
%% [S19e] theta PSD
ax5 = subplot(4,4,5);
scatter(ones(1,length(data.PowerSpec.Rest.thetaBandPower.S01))*1,data.PowerSpec.Rest.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Rest.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.NREM.thetaBandPower.S01))*2,data.PowerSpec.NREM.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.NREM.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.REM.thetaBandPower.S01))*3,data.PowerSpec.REM.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.REM.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Awake.thetaBandPower.S01))*4,data.PowerSpec.Awake.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.PowerSpec.Awake.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.thetaBandPower.S01))*5,data.PowerSpec.Sleep.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.PowerSpec.Sleep.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.thetaBandPower.S01))*6,data.PowerSpec.All.thetaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.PowerSpec.All.thetaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19e] PSD @ 0.1 Hz','Theta-band [4-10 Hz]',''})
ylabel('Power (a.u.) @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,7])
set(gca,'box','off')
ax5.TickLength = [0.03,0.03];
%% [S17f] ultra low theta PSD
ax6 = subplot(4,4,6);
scatter(ones(1,length(data.PowerSpec.Awake.thetaBandPower.S001))*1,data.PowerSpec.Awake.thetaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Awake.thetaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.thetaBandPower.S001))*2,data.PowerSpec.Sleep.thetaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.Sleep.thetaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.thetaBandPower.S001))*3,data.PowerSpec.All.thetaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.All.thetaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19f] PSD @ 0.01 Hz','Theta-band [4-10 Hz]',''})
ylabel('Power (a.u.) 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,4])
set(gca,'box','off')
ax6.TickLength = [0.03,0.03];
%% [S17g] theta Coherence^2
ax7 = subplot(4,4,7);
scatter(ones(1,length(data.Coherr.Rest.thetaBandPower.C01))*1,data.Coherr.Rest.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Rest.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.NREM.thetaBandPower.C01))*2,data.Coherr.NREM.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.NREM.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.REM.thetaBandPower.C01))*3,data.Coherr.REM.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.REM.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.Coherr.Awake.thetaBandPower.C01))*4,data.Coherr.Awake.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.Coherr.Awake.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.thetaBandPower.C01))*5,data.Coherr.Sleep.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.Coherr.Sleep.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.thetaBandPower.C01))*6,data.Coherr.All.thetaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.Coherr.All.thetaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19g] Coherence^2 @ 0.1 Hz','Theta-band [4-10 Hz]',''})
ylabel('Coherence^2 @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,7])
ylim([0,1])
set(gca,'box','off')
ax7.TickLength = [0.03,0.03];
%% [S19h] ultra low theta Coherence^2
ax8 = subplot(4,4,8);
scatter(ones(1,length(data.Coherr.Awake.thetaBandPower.C001))*1,data.Coherr.Awake.thetaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Awake.thetaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.thetaBandPower.C001))*2,data.Coherr.Sleep.thetaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.Sleep.thetaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.thetaBandPower.C001))*3,data.Coherr.All.thetaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.All.thetaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19h] Coherence^2 @ 0.01 Hz','Theta-band [4-10 Hz]',''})
ylabel('Coherence^2 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,4])
ylim([0,1])
set(gca,'box','off')
ax8.TickLength = [0.03,0.03];
%% [S19i] alpha PSD
ax9 = subplot(4,4,9);
scatter(ones(1,length(data.PowerSpec.Rest.alphaBandPower.S01))*1,data.PowerSpec.Rest.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Rest.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.NREM.alphaBandPower.S01))*2,data.PowerSpec.NREM.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.NREM.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.REM.alphaBandPower.S01))*3,data.PowerSpec.REM.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.REM.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Awake.alphaBandPower.S01))*4,data.PowerSpec.Awake.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.PowerSpec.Awake.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.alphaBandPower.S01))*5,data.PowerSpec.Sleep.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.PowerSpec.Sleep.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.alphaBandPower.S01))*6,data.PowerSpec.All.alphaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.PowerSpec.All.alphaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19i] PSD @ 0.1 Hz','Alpha-band [10-13 Hz]',''})
ylabel('Power (a.u.) @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,7])
set(gca,'box','off')
ax9.TickLength = [0.03,0.03];
%% [S19j] ultra low alpha PSD
ax10 = subplot(4,4,10);
scatter(ones(1,length(data.PowerSpec.Awake.alphaBandPower.S001))*1,data.PowerSpec.Awake.alphaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Awake.alphaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.alphaBandPower.S001))*2,data.PowerSpec.Sleep.alphaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.Sleep.alphaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.alphaBandPower.S001))*3,data.PowerSpec.All.alphaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.All.alphaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19j] PSD @ 0.01 Hz','Alpha-band [10-13 Hz]',''})
ylabel('Power (a.u.) 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,4])
set(gca,'box','off')
ax10.TickLength = [0.03,0.03];
%% [S19k] alpha Coherence^2
ax11 = subplot(4,4,11);
scatter(ones(1,length(data.Coherr.Rest.alphaBandPower.C01))*1,data.Coherr.Rest.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Rest.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.NREM.alphaBandPower.C01))*2,data.Coherr.NREM.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.NREM.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.REM.alphaBandPower.C01))*3,data.Coherr.REM.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.REM.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.Coherr.Awake.alphaBandPower.C01))*4,data.Coherr.Awake.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.Coherr.Awake.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.alphaBandPower.C01))*5,data.Coherr.Sleep.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.Coherr.Sleep.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.alphaBandPower.C01))*6,data.Coherr.All.alphaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.Coherr.All.alphaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19k] Coherence^2 @ 0.1 Hz','Alpha-band [10-13 Hz]',''})
ylabel('Coherence^2 @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,7])
ylim([0,1])
set(gca,'box','off')
ax11.TickLength = [0.03,0.03];
%% [S19l] ultra low alpha Coherence^2
ax12 = subplot(4,4,12);
scatter(ones(1,length(data.Coherr.Awake.alphaBandPower.C001))*1,data.Coherr.Awake.alphaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Awake.alphaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.alphaBandPower.C001))*2,data.Coherr.Sleep.alphaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.Sleep.alphaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.alphaBandPower.C001))*3,data.Coherr.All.alphaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.All.alphaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19l] Coherence^2 @ 0.01 Hz','Alpha-band [10-13 Hz]',''})
ylabel('Coherence^2 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,4])
ylim([0,1])
set(gca,'box','off')
ax12.TickLength = [0.03,0.03];
%% [S19m] beta PSD
ax13 = subplot(4,4,13);
scatter(ones(1,length(data.PowerSpec.Rest.betaBandPower.S01))*1,data.PowerSpec.Rest.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Rest.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.NREM.betaBandPower.S01))*2,data.PowerSpec.NREM.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.NREM.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.REM.betaBandPower.S01))*3,data.PowerSpec.REM.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.REM.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Awake.betaBandPower.S01))*4,data.PowerSpec.Awake.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.PowerSpec.Awake.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.betaBandPower.S01))*5,data.PowerSpec.Sleep.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.PowerSpec.Sleep.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.betaBandPower.S01))*6,data.PowerSpec.All.betaBandPower.S01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.PowerSpec.All.betaBandPower.meanS01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19m] PSD @ 0.1 Hz','Beta-band [13-30 Hz]',''})
ylabel('Power (a.u.) @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,7])
set(gca,'box','off')
ax13.TickLength = [0.03,0.03];
%% [S19n] ultra low beta PSD
ax14 = subplot(4,4,14);
scatter(ones(1,length(data.PowerSpec.Awake.betaBandPower.S001))*1,data.PowerSpec.Awake.betaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.PowerSpec.Awake.betaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.Sleep.betaBandPower.S001))*2,data.PowerSpec.Sleep.betaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.PowerSpec.Sleep.betaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.PowerSpec.All.betaBandPower.S001))*3,data.PowerSpec.All.betaBandPower.S001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.PowerSpec.All.betaBandPower.meanS001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19n] PSD @ 0.01 Hz','Beta-band [13-30 Hz]',''})
ylabel('Power (a.u.) 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'yscale','log')
axis square
xlim([0,4])
set(gca,'box','off')
ax14.TickLength = [0.03,0.03];
%% [S19o] beta Coherence^2
ax15 = subplot(4,4,15);
scatter(ones(1,length(data.Coherr.Rest.betaBandPower.C01))*1,data.Coherr.Rest.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorA,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Rest.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.NREM.betaBandPower.C01))*2,data.Coherr.NREM.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorB,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.NREM.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.REM.betaBandPower.C01))*3,data.Coherr.REM.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorC,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.REM.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
scatter(ones(1,length(data.Coherr.Awake.betaBandPower.C01))*4,data.Coherr.Awake.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
e4 = errorbar(4,data.Coherr.Awake.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e4.Color = 'black';
e4.MarkerSize = 10;
e4.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.betaBandPower.C01))*5,data.Coherr.Sleep.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e5 = errorbar(5,data.Coherr.Sleep.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e5.Color = 'black';
e5.MarkerSize = 10;
e5.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.betaBandPower.C01))*6,data.Coherr.All.betaBandPower.C01,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e6 = errorbar(6,data.Coherr.All.betaBandPower.meanC01,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e6.Color = 'black';
e6.MarkerSize = 10;
e6.CapSize = 10;
title({'[S19o] Coherence^2 @ 0.1 Hz','Beta-band [13-30 Hz]',''})
ylabel('Coherence^2 @ 0.1 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,7])
ylim([0,1])
set(gca,'box','off')
ax15.TickLength = [0.03,0.03];
%% [S19p] ultra low beta Coherence^2
ax16 = subplot(4,4,16);
scatter(ones(1,length(data.Coherr.Awake.betaBandPower.C001))*1,data.Coherr.Awake.betaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorF,'jitter','on', 'jitterAmount',0.25);
hold on
e1 = errorbar(1,data.Coherr.Awake.betaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e1.Color = 'black';
e1.MarkerSize = 10;
e1.CapSize = 10;
scatter(ones(1,length(data.Coherr.Sleep.betaBandPower.C001))*2,data.Coherr.Sleep.betaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorG,'jitter','on', 'jitterAmount',0.25);
e2 = errorbar(2,data.Coherr.Sleep.betaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e2.Color = 'black';
e2.MarkerSize = 10;
e2.CapSize = 10;
scatter(ones(1,length(data.Coherr.All.betaBandPower.C001))*3,data.Coherr.All.betaBandPower.C001,75,'MarkerEdgeColor','k','MarkerFaceColor',colorH,'jitter','on', 'jitterAmount',0.25);
e3 = errorbar(3,data.Coherr.All.betaBandPower.meanC001,0,'d','MarkerEdgeColor','k','MarkerFaceColor','k');
e3.Color = 'black';
e3.MarkerSize = 10;
e3.CapSize = 10;
title({'[S19p] Coherence^2 @ 0.01 Hz','Beta-band [13-30 Hz]',''})
ylabel('Coherence^2 0.01 Hz')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis square
xlim([0,4])
ylim([0,1])
set(gca,'box','off')
ax16.TickLength = [0.03,0.03];
%% save figure(s)
dirpath = [rootFolder '\Summary Figures and Structures\'];
if ~exist(dirpath,'dir')
    mkdir(dirpath);
end
savefig(summaryFigure,[dirpath 'FigS19']);
set(summaryFigure,'PaperPositionMode','auto');
print('-painters','-dpdf','-fillpage',[dirpath 'FigS19'])
%% statistical diary
diaryFile = [dirpath 'FigS19_Statistics.txt'];
if exist(diaryFile,'file') == 2
    delete(diaryFile)
end
diary(diaryFile)
diary on
% delta-band 0.1 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19a] Generalized linear mixed-effects model statistics for delta-band PSD @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Delta_PSD01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Rest.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Rest.deltaBandPower.stdS01,1))]); disp(' ')
disp(['NREM  Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.NREM.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.NREM.deltaBandPower.stdS01,1))]); disp(' ')
disp(['REM   Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.REM.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.REM.deltaBandPower.stdS01,1))]); disp(' ')
disp(['Awake Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Awake.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.deltaBandPower.stdS01,1))]); disp(' ')
disp(['Sleep Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.deltaBandPower.stdS01,1))]); disp(' ')
disp(['All   Delta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.All.deltaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.All.deltaBandPower.stdS01,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% delta-band 0.01 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19b] Generalized linear mixed-effects model statistics for delta-band PSD @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Delta_PSD001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Delta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Awake.deltaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.deltaBandPower.stdS001,1))]); disp(' ')
disp(['Sleep Delta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.deltaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.deltaBandPower.stdS001,1))]); disp(' ')
disp(['All   Delta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.All.deltaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.All.deltaBandPower.stdS001,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% delta-band 0.1 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19c] Generalized linear mixed-effects model statistics for delta-band coherence^2 @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Delta_Coh01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Rest.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Rest.deltaBandPower.stdC01,2))]); disp(' ')
disp(['NREM  Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.NREM.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.NREM.deltaBandPower.stdC01,2))]); disp(' ')
disp(['REM   Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.REM.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.REM.deltaBandPower.stdC01,2))]); disp(' ')
disp(['Awake Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Awake.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Awake.deltaBandPower.stdC01,2))]); disp(' ')
disp(['Sleep Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Sleep.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Sleep.deltaBandPower.stdC01,2))]); disp(' ')
disp(['All   Delta 0.1 Hz Coh2: ' num2str(round(data.Coherr.All.deltaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.All.deltaBandPower.stdC01,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% delta-band 0.01 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19d] Generalized linear mixed-effects model statistics for delta-band coherence^2 @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Delta_Coh001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Delta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Awake.deltaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Awake.deltaBandPower.stdC001,2))]); disp(' ')
disp(['Sleep Delta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Sleep.deltaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Sleep.deltaBandPower.stdC001,2))]); disp(' ')
disp(['All   Delta 0.01 Hz Coh2: ' num2str(round(data.Coherr.All.deltaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.All.deltaBandPower.stdC001,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% theta-band 0.1 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19e] Generalized linear mixed-effects model statistics for theta-band PSD @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Theta_PSD01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Rest.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Rest.thetaBandPower.stdS01,1))]); disp(' ')
disp(['NREM  Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.NREM.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.NREM.thetaBandPower.stdS01,1))]); disp(' ')
disp(['REM   Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.REM.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.REM.thetaBandPower.stdS01,1))]); disp(' ')
disp(['Awake Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Awake.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.thetaBandPower.stdS01,1))]); disp(' ')
disp(['Sleep Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.thetaBandPower.stdS01,1))]); disp(' ')
disp(['All   Theta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.All.thetaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.All.thetaBandPower.stdS01,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% theta-band 0.01 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19f] Generalized linear mixed-effects model statistics for theta-band PSD @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Theta_PSD001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Theta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Awake.thetaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.thetaBandPower.stdS001,1))]); disp(' ')
disp(['Sleep Theta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.thetaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.thetaBandPower.stdS001,1))]); disp(' ')
disp(['All   Theta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.All.thetaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.All.thetaBandPower.stdS001,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% theta-band 0.1 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19g] Generalized linear mixed-effects model statistics for theta-band coherence^2 @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Theta_Coh01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Rest.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Rest.thetaBandPower.stdC01,2))]); disp(' ')
disp(['NREM  Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.NREM.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.NREM.thetaBandPower.stdC01,2))]); disp(' ')
disp(['REM   Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.REM.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.REM.thetaBandPower.stdC01,2))]); disp(' ')
disp(['Awake Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Awake.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Awake.thetaBandPower.stdC01,2))]); disp(' ')
disp(['Sleep Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Sleep.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Sleep.thetaBandPower.stdC01,2))]); disp(' ')
disp(['All   Theta 0.1 Hz Coh2: ' num2str(round(data.Coherr.All.thetaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.All.thetaBandPower.stdC01,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% theta-band 0.01 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19h] Generalized linear mixed-effects model statistics for theta-band coherence^2 @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Theta_Coh001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Theta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Awake.thetaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Awake.thetaBandPower.stdC001,2))]); disp(' ')
disp(['Sleep Theta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Sleep.thetaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Sleep.thetaBandPower.stdC001,2))]); disp(' ')
disp(['All   Theta 0.01 Hz Coh2: ' num2str(round(data.Coherr.All.thetaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.All.thetaBandPower.stdC001,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% alpha-band 0.1 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19i] Generalized linear mixed-effects model statistics for alpha-band PSD @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Alpha_PSD01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Rest.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Rest.alphaBandPower.stdS01,1))]); disp(' ')
disp(['NREM  Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.NREM.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.NREM.alphaBandPower.stdS01,1))]); disp(' ')
disp(['REM   Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.REM.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.REM.alphaBandPower.stdS01,1))]); disp(' ')
disp(['Awake Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Awake.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.alphaBandPower.stdS01,1))]); disp(' ')
disp(['Sleep Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.alphaBandPower.stdS01,1))]); disp(' ')
disp(['All   Alpha 0.1 Hz PSD: ' num2str(round(data.PowerSpec.All.alphaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.All.alphaBandPower.stdS01,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% alpha-band 0.01 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19j] Generalized linear mixed-effects model statistics for alpha-band PSD @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Alpha_PSD001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Alpha 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Awake.alphaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.alphaBandPower.stdS001,1))]); disp(' ')
disp(['Sleep Alpha 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.alphaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.alphaBandPower.stdS001,1))]); disp(' ')
disp(['All   Alpha 0.01 Hz PSD: ' num2str(round(data.PowerSpec.All.alphaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.All.alphaBandPower.stdS001,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% alpha-band 0.1 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19k] Generalized linear mixed-effects model statistics for alpha-band coherence^2 @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Alpha_Coh01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.Rest.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Rest.alphaBandPower.stdC01,2))]); disp(' ')
disp(['NREM  Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.NREM.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.NREM.alphaBandPower.stdC01,2))]); disp(' ')
disp(['REM   Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.REM.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.REM.alphaBandPower.stdC01,2))]); disp(' ')
disp(['Awake Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.Awake.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Awake.alphaBandPower.stdC01,2))]); disp(' ')
disp(['Sleep Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.Sleep.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Sleep.alphaBandPower.stdC01,2))]); disp(' ')
disp(['All   Alpha 0.1 Hz Coh2: ' num2str(round(data.Coherr.All.alphaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.All.alphaBandPower.stdC01,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% alpha-band 0.01 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19l] Generalized linear mixed-effects model statistics for alpha-band coherence^2 @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Alpha_Coh001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Alpha 0.01 Hz Coh2: ' num2str(round(data.Coherr.Awake.alphaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Awake.alphaBandPower.stdC001,2))]); disp(' ')
disp(['Sleep Alpha 0.01 Hz Coh2: ' num2str(round(data.Coherr.Sleep.alphaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Sleep.alphaBandPower.stdC001,2))]); disp(' ')
disp(['All   Alpha 0.01 Hz Coh2: ' num2str(round(data.Coherr.All.alphaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.All.alphaBandPower.stdC001,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% beta-band 0.1 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19m] Generalized linear mixed-effects model statistics for beta-band PSD @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Beta_PSD01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Rest.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Rest.betaBandPower.stdS01,1))]); disp(' ')
disp(['NREM  Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.NREM.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.NREM.betaBandPower.stdS01,1))]); disp(' ')
disp(['REM   Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.REM.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.REM.betaBandPower.stdS01,1))]); disp(' ')
disp(['Awake Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Awake.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.betaBandPower.stdS01,1))]); disp(' ')
disp(['Sleep Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.betaBandPower.stdS01,1))]); disp(' ')
disp(['All   Beta 0.1 Hz PSD: ' num2str(round(data.PowerSpec.All.betaBandPower.meanS01,1)) ' +/- ' num2str(round(data.PowerSpec.All.betaBandPower.stdS01,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% beta-band 0.01 Hz PSD statistical diary
disp('======================================================================================================================')
disp('[S19n] Generalized linear mixed-effects model statistics for beta-band PSD @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Beta_PSD001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Beta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Awake.betaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Awake.betaBandPower.stdS001,1))]); disp(' ')
disp(['Sleep Beta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.Sleep.betaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.Sleep.betaBandPower.stdS001,1))]); disp(' ')
disp(['All   Beta 0.01 Hz PSD: ' num2str(round(data.PowerSpec.All.betaBandPower.meanS001,1)) ' +/- ' num2str(round(data.PowerSpec.All.betaBandPower.stdS001,1))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% beta-band 0.1 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19o] Generalized linear mixed-effects model statistics for beta-band coherence^2 @ 0.1 Hz for Rest, NREM, REM, Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Beta_Coh01_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Rest  Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Rest.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Rest.betaBandPower.stdC01,2))]); disp(' ')
disp(['NREM  Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.NREM.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.NREM.betaBandPower.stdC01,2))]); disp(' ')
disp(['REM   Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.REM.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.REM.betaBandPower.stdC01,2))]); disp(' ')
disp(['Awake Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Awake.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Awake.betaBandPower.stdC01,2))]); disp(' ')
disp(['Sleep Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.Sleep.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.Sleep.betaBandPower.stdC01,2))]); disp(' ')
disp(['All   Beta 0.1 Hz Coh2: ' num2str(round(data.Coherr.All.betaBandPower.meanC01,2)) ' +/- ' num2str(round(data.Coherr.All.betaBandPower.stdC01,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
% beta-band 0.01 Hz coherence^2 statistical diary
disp('======================================================================================================================')
disp('[S19p] Generalized linear mixed-effects model statistics for beta-band coherence^2 @ 0.01 Hz for Awake, Sleep, and All')
disp('======================================================================================================================')
disp(Beta_Coh001_Stats)
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['Awake Beta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Awake.betaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Awake.betaBandPower.stdC001,2))]); disp(' ')
disp(['Sleep Beta 0.01 Hz Coh2: ' num2str(round(data.Coherr.Sleep.betaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.Sleep.betaBandPower.stdC001,2))]); disp(' ')
disp(['All   Beta 0.01 Hz Coh2: ' num2str(round(data.Coherr.All.betaBandPower.meanC001,2)) ' +/- ' num2str(round(data.Coherr.All.betaBandPower.stdC001,2))]); disp(' ')
disp('----------------------------------------------------------------------------------------------------------------------')
diary off

end