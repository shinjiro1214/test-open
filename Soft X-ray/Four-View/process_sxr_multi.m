function SXRdata = process_sxr_multi(SXR)
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
ReconMethod = SXR.ReconMethod;
SXRfilename = SXR.SXRfilename;

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス


if doFilter == 1
    if ReconMethod == 0
        options = 'NLF_TP';
    elseif ReconMethod == 1
        options = 'NLF_MFI';
    elseif ReconMethod == 2
        options = 'NLF_MEM';
    elseif ReconMethod == 3
        options  = 'NLF_cGAN';
    elseif ReconMethod == 4
        options = 'NLF_GPT';
    end
else
    if ReconMethod == 0
        options = 'LF_TP';
    elseif ReconMethod == 1
        options = 'LF_MFI';
    elseif ReconMethod == 2
        options = 'LF_MEM';
    elseif ReconMethod == 3
        options  = 'LF_cGAN';
    elseif ReconMethod == 4
        options = 'LF_GPT';
    end
end

dirPath = getenv('SXR_MATRIX_DIR');
matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));
if exist(matrixFolder,'dir') == 0
    doCalculation = true;
    mkdir(matrixFolder);
elseif length(dir(matrixFolder))-2 ~= 8 %フォルダが存在しても全結果がない場合は計算する
    doCalculation = true;
elseif SXR.Reset == 1
    doCalculation = true;
else
    doCalculation = false; 
end

newProjectionNumber = 30;
newGridNumber = 50;
% 再構成計算に必要なパラメータを計算するなら読み込む
parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);
if doCalculation
    disp('No matrix data -- Start calculation');
    
    
    if evalin('base', 'exist(''N_projection'', ''var'')')
        NP = evalin('base', 'N_projection');
        if NP ~= newProjectionNumber
            [gm2d1, gm2d2, gm2d3, gm2d4, U1, U2, U3, U4, ...
                      s1, s2, s3, s4, v1, v2, v3, v4, M, K, range, N_projection, N_grid] = parametercheck(newProjectionNumber, newGridNumber);
        end
    else
        [gm2d1, gm2d2, gm2d3, gm2d4, U1, U2, U3, U4, ...
                  s1, s2, s3, s4, v1, v2, v3, v4, M, K, range, N_projection, N_grid] = parametercheck(newProjectionNumber, newGridNumber);
    end

    % 生画像の取得
    info = imfinfo(SXRfilename);
    % disp(info.StripOffsets); % これがヘッダーサイズ(バイト)の可能性大
    % disp([info.Width, info.Height]); % 画素数
    % disp(info.BitDepth); % ビット深度 (16ならuint16, 8ならuint8)
    rawImage = imread(SXRfilename);
    disp('raw image loaded')

    % % 非線形フィルターをかける（必要があれば）
    % if doFilter
    %     % figure;imagesc(rawImage);
    %     disp(size(rawImage));
    %     [rawImage,~] = imnlmfilt(rawImage,'SearchWindowSize',91,'ComparisonWindowSize',15);
    %     % figure;imagesc(rawImage);
    % end

    % 非線形フィルターをかける（必要があれば）
    if doFilter
        % キャッシュファイル名の作成（パラメータをファイル名に含める）
        [filepath, name, ~] = fileparts(SXRfilename);
        cacheFilename = fullfile(filepath, strcat(name, '_filtered_sw91_cw15.mat'));

        if exist(cacheFilename, 'file')
            disp('Loading filtered image from cache...');
            tic;
            load(cacheFilename, 'rawImage');
            disp('Cache load time:');
            toc;
        else
            disp('Applying non-local means filter...');
            disp(size(rawImage));
            tic;
            [rawImage,~] = imnlmfilt(rawImage,'SearchWindowSize',91,'ComparisonWindowSize',15);
            disp('Filter calculation time:');
            toc;
            
            % フィルタ結果を保存
            save(cacheFilename, 'rawImage'); 
            disp('Filtered image saved to cache.');
        end
    end
else
    disp(strcat('Loading matrix from :',matrixFolder))
    load(parameterFile,'range');
end

doPlot = false;

if doSave
    f = figure;
    f.Units = 'normalized';
    f.Position = [0.1,0.2,0.8,0.8];
end

SXR.times = start:interval:(start+interval*7);

for t_idx_loop = 1:length(SXR.times) % インデックス管理のためにループ変数を変更
    t = SXR.times(t_idx_loop);
    number = (t-start)/interval+1;
    matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
    if any(~exist(matrixPath,'file')) || any(SXR.Reset == 1)%doCalculation
%         ベクトル形式の画像データの読み込み
        disp('getting vector image')
        [VectorImage1,VectorImage2, VectorImage3, VectorImage4] = get_sxr_image(date,number,newProjectionNumber,rawImage);
        
        datadirPath = getenv('SXR_DATA_DIR');
        dataFolder = strcat(datadirPath,'/',num2str(date),'/shot',num2str(shot));
        if ~exist(dataFolder, 'dir')
            mkdir(dataFolder);
        end

        dataPath = strcat(dataFolder,'/',num2str(number),'.mat');
        n_p = N_projection;
        sxr1 = zeros(n_p);
        sxr2 = zeros(n_p);
        sxr3 = zeros(n_p);
        sxr4 = zeros(n_p);
        k=FindCircle(n_p/2);
        sxr1(k) = VectorImage1;
        sxr2(k) = VectorImage2;
        sxr3(k) = VectorImage3;
        sxr4(k) = VectorImage4;
        save(dataPath, 'sxr1', 'sxr2','sxr3','sxr4')
        

        


%         再構成計算
        disp('getting distribution')
        if SXR.date == 260325
            EE1 = get_distribution(M,K,gm2d4,U4,s4,v4,VectorImage1,doPlot,ReconMethod, N_projection);
        else
            EE1 = get_distribution(M,K,gm2d1,U1,s1,v1,VectorImage1,doPlot,ReconMethod, N_projection);
        end
        if 241110 <= SXR.date && SXR.date <= 250206
            EE2 = get_distribution(M,K,gm2d3,U3,s3,v3,VectorImage2,doPlot,ReconMethod, N_projection);
        else
            EE2 = get_distribution(M,K,gm2d2,U2,s2,v2,VectorImage2,doPlot,ReconMethod, N_projection);
        end
        EE3 = get_distribution(M,K,gm2d3,U3,s3,v3,VectorImage3,doPlot,ReconMethod, N_projection);
        EE4 = get_distribution(M,K,gm2d4,U4,s4,v4,VectorImage4,doPlot,ReconMethod, N_projection);
        
%         再構成結果を保存するファイルを作成、保存
        
        % matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
        save(matrixPath,'EE1','EE2','EE3','EE4');
        
    else
        % matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
        % disp(strcat('Loading result matrix from ',which(matrixPath)));
        load(matrixPath,'EE1','EE2','EE3','EE4');
    end
    
    EE = cat(3,EE1,EE2,EE3,EE4);

    if ~doSave
        f = figure;
        f.Units = 'normalized';
        f.Position = [0.1,0.2,0.8,0.8];
    end

    SXRdata.range = range;
    SXRdata.time(t_idx_loop) = t;

    % plot_save_sxr(grid2D,data2D,range,date,shot,t,EE,show_localmax,show_xpoint,doSave,doFilter,ReconMethod);
    
    if ReconMethod ~= 3
        SXRdata.EE(:,:,:,t_idx_loop) = EE;
        % plot_save_sxr(PCBdata,SXR,SXRdata,PCB);
    else    
        cGANPath = strcat(dirPath,'/cGAN_large/',num2str(date),'/shot',num2str(shot),'/',num2str(number),'.mat');
        load(cGANPath,'EE1','EE2','EE3','EE4');
        EE = cat(3,EE1,EE2,EE3,EE4);
        SXRdata.EE = EE;
        % plot_save_sxr(PCBdata,SXR,SXRdata,PCB);
    end

end
if doSave
    close(f);
end

% threed = false;
% newProjectionNumber3d = 30;
% newGridNumber3d = 20;
% pathname_fig = getenv('SXR_RECONSTRUCTED_FIG_DIR');

% if threed
    
%     if evalin('base', 'exist(''N_projection'', ''var'')')
%         NP = evalin('base', 'N_projection');
%         if NP ~= newProjectionNumber3d
%             [N_projection, N_grid3d, gm3d,U3d,s3d, v3d, M3d, K3d, nolines] = parametercheck_3d(newProjectionNumber3d, newGridNumber3d);
%         end
%     else
%         [N_projection, N_grid3d, gm3d,U3d,s3d, v3d, M3d, K3d, nolines] = parametercheck_3d(newProjectionNumber3d, newGridNumber3d);
%     end
%     rawImage = imread(SXRfilename);

%     % Define the number of time points and create a figure
%     numTimes = numel(times);
%     figure('Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Full-screen figure

%     for tIdx = 1:numTimes
%         t = SXR.time(tIdx);
%         number = (t-start)/interval+1;
        
    
        
%         [VectorImage1,VectorImage2, VectorImage3, VectorImage4] = get_sxr_image(date,number,newProjectionNumber3d,rawImage);
    
%         l = cat(2,VectorImage1,VectorImage2,VectorImage4); %20240721ではVectorImage3はなし
        
%         EE = get_distribution_3d(M3d, K3d, U3d, s3d, v3d, l, N_grid3d, nolines);
%         EE = permute(EE, [3,2,1]);


%         rmin3d = 0; 
%         rmax3d = 375; 
%         dmin3d = -375; 
%         dmax3d = 375; 
%         zmin3d = -300; 
%         zmax3d = 300;
%         r = linspace(rmin3d, rmax3d, newGridNumber3d+1);
%         z = linspace(zmin3d, zmax3d, newGridNumber3d+1);
%         d = linspace(dmin3d, dmax3d, newGridNumber3d+1);
    
%         % Create a grid for the data
%         [Z, D, R] = meshgrid(z, d, r);
        
%         subplot(2, ceil(numTimes/2), tIdx); % Adjust the grid size as needed


%         h = slice(Z, D, R, EE, z, d, r); % Example slice positions along Z

        
%         % 0以上の部分に対してカラーマップを設定
%         set(h, 'FaceColor', 'interp', 'EdgeColor', 'none', 'FaceAlpha', 0.075); % 透明度を設定

%         % カラーマップの調整
%         colormap(jet); % jetカラーマップを使用
%         cb = colorbar; % カラーバーを追加
%         %cb.Limits = [0, max(EE(:))]; % カラーバーの範囲を0から最大値に設定
%         %clim([0, max(EE(:))]); % カラーバーに表示する範囲を設定
%         cb.Limits = [0, 0.3];
%         clim([0,0.3]);


%         % Z, D, Rの範囲を取得
%         zRange = [min(z), max(z)];
%         dRange = [min(d), max(d)];
%         rRange = [min(r), max(r)];
        
%         % 各軸の中心と長さを計算
%         centerZ = mean(zRange);
%         centerD = mean(dRange);
%         centerR = mean(rRange);
        
%         % 最小の長さを取得して、それに基づいて軸の制限を設定
%         lengthZ = zRange(2) - zRange(1);
%         lengthD = dRange(2) - dRange(1);
%         lengthR = rRange(2) - rRange(1);
%         maxLength = max([lengthZ, lengthD, lengthR]);
        
%         % 各軸の制限を設定
%         xlim([centerZ - maxLength/2, centerZ + maxLength/2]);
%         ylim([centerD - maxLength/2, centerD + maxLength/2]);
%         zlim([centerR - maxLength/2, centerR + maxLength/2]);
        

%         xlabel('z軸');
%         ylabel('depth');
%         zlabel('r軸');
%         title(strcat('shot',num2str(shot),' at ',num2str(t),'us'));
    
        
%         view(3);       % Set to 3D view
%         grid on;

        
%     end
%     % Save the figure to a file without displaying it
%     savepath = fullfile(pathname_fig,'/3D/LF_TP/',num2str(date), strcat('shot',num2str(shot),'.fig'));
%     saveas(gcf,savepath);

% end
end


function k = FindCircle(L)
    R = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
        end
    end
    % figure;imagesc(R)
    k = find(R<L);
end