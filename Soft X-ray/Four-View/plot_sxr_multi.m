function [] = plot_sxr_multi(PCBdata,SXR)
% grid2D = PCBdata.grid2D;
% data2D = PCBdata.data2D;
date = SXR.date;
shot = SXR.shot;
% show_xpoint = SXR.show_xpoint;
% show_localmax = SXR.show_localmax;
start = SXR.start;
interval = SXR.interval;
doSave = SXR.doSave;
doFilter = SXR.doFilter;
doNLR = SXR.doNLR;
SXRfilename = SXR.SXRfilename;

if doFilter & doNLR
    options = 'NLF_NLR';
elseif ~doFilter & doNLR
    options = 'LF_NLR';
elseif doFilter & ~doNLR
    options = 'NLF_LR';
else
    options = 'LF_LR';
end

dirPath = getenv('SXR_MATRIX_DIR');
matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));
if exist(matrixFolder,'dir') == 0
    doCalculation = true;
    mkdir(matrixFolder);
elseif length(dir(matrixFolder))-2 ~= 8 %フォルダが存在しても全結果がない場合は計算する
    doCalculation = true;
else
    doCalculation = false; 
end

% 再構成計算に必要なパラメータを計算するなら読み込む
parameterFile = 'parameters.mat';
if doCalculation
    disp('No matrix data -- Start calculation');
    % newProjectionNumber = 50;
    % newGridNumber = 90;
    newProjectionNumber = SXR.projection;
    newGridNumber = SXR.grid;
    if isfile(parameterFile)
        disp(strcat('Loading parameter from ',which(parameterFile)))
        load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
                'U1','U2','U3','U4','s1','s2','s3','s4', ...
                'v1','v2','v3','v4','M','K','range','N_projection','N_grid');
            
        if newProjectionNumber ~= N_projection || newGridNumber ~= N_grid
            % disp('Different parameters - Start calculation!');
            disp('Different parameters!');
            disp(['current projection number: ',num2str(N_projection)]);
            disp(['current grid number: ',num2str(N_grid)]);
            flag = true;
            while flag
                userInput = input('continue? (y/n): ','s');
                if strcmpi(userInput, 'y')
                    flag = false;
                elseif strcmpi(userInput, 'n')
                    disp('stop calculation');
                    return;
                else
                    disp('Invalid input. Please enter y/n');
                end
            end
            disp('Start calculation!');
            % get_parameters(newProjectionNumber,newGridNumber,parameterFile);
            get_parameters_new(newProjectionNumber,newGridNumber,parameterFile);
            load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
                    'U1','U2','U3','U4','s1','s2','s3','s4', ...
                    'v1','v2','v3','v4','M','K','range');
        end
    else
        disp('No parameter!');
        flag = true;
        while flag
            userInput = input('continue? (y/n): ','s');
            if strcmpi(userInput, 'y')
                flag = false;
            elseif strcmpi(userInput, 'n')
                disp('stop calculation');
                return;
            else
                disp('Invalid input. Please enter y/n');
            end
        end
        disp('Start calculation!');
        % get_parameters(newProjectionNumber,newGridNumber,parameterFile);
        get_parameters_new(newProjectionNumber,newGridNumber,parameterFile);
        load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
                'U1','U2','U3','U4','s1','s2','s3','s4', ...
                'v1','v2','v3','v4','M','K','range');
    end

    % 生画像の取得
    rawImage = imread(SXRfilename);
    
    % 非線形フィルターをかける（必要があれば）
    if doFilter
        % figure;imagesc(rawImage);
        [rawImage,~] = imnlmfilt(rawImage,'SearchWindowSize',91,'ComparisonWindowSize',15);
        % figure;imagesc(rawImage);
    end
else
    disp(strcat('Loading matrix from :',matrixFolder))
    % load(parameterFile,'range');
end

if date == 230830
    times = start:interval:(start+interval*3);
else
    times = start:interval:(start+interval*7);
end
doPlot = false;

if doSave
    f = figure;
    f.Units = 'normalized';
    % f.Position = [0.1,0.2,0.8,0.8];
    f.Position = [0.4830 1.1946 0.8000 0.8002];
end

for t = times
    number = (t-start)/interval+1;
    matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
    if ~exist(matrixPath,'file')%doCalculation
%         ベクトル形式の画像データの読み込み
        if date == 230830
            [VectorImage1,VectorImage2, VectorImage3, VectorImage4] = get_sxr_image_230830(date,number,newProjectionNumber,rawImage);
        else
            [VectorImage1,VectorImage2, VectorImage3, VectorImage4] = get_sxr_image(date,number,newProjectionNumber,rawImage);
        end

%         再構成計算
        EE1 = get_distribution(M,K,gm2d1,U1,s1,v1,VectorImage1,doPlot,doNLR);
        EE2 = get_distribution(M,K,gm2d2,U2,s2,v2,VectorImage2,doPlot,doNLR);
        EE3 = get_distribution(M,K,gm2d3,U3,s3,v3,VectorImage3,doPlot,doNLR);
        EE4 = get_distribution(M,K,gm2d4,U4,s4,v4,VectorImage4,doPlot,doNLR);
        
%         再構成結果を保存するファイルを作成、保存
        
        % matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
        save(matrixPath,'EE1','EE2','EE3','EE4','range');
        
    else
        % matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
        % disp(strcat('Loading result matrix from ',which(matrixPath)));
        varName = who('-file',matrixPath);
        if ismember('range',varName)
            load(matrixPath,'EE1','EE2','EE3','EE4','range');
            % disp('1');
        else
            load(matrixPath,'EE1','EE2','EE3','EE4');
            load(parameterFile,'range');
            save(matrixPath,'EE1','EE2','EE3','EE4','range');
            % disp('2');
        end
    end
    
    EE = cat(3,EE1,EE2,EE3,EE4);

    if ~doSave
        f = figure;
        f.Units = 'normalized';
        f.Position = [0.1,0.2,0.8,0.8];
    end

    SXRdata.EE = EE;
    SXRdata.t = t;
    SXRdata.range = range;

    % plot_save_sxr(grid2D,data2D,range,date,shot,t,EE,show_localmax,show_xpoint,doSave,doFilter,doNLR);
    plot_save_sxr(PCBdata,SXR,SXRdata);

end

if doSave
    close(f);
end

end