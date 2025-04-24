clearvars -except date IDXlist times

addpath '/Users/shohgookazaki/Documents/matlab/common';
clearvars -except date IDXlist Area
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shohgookazaki/Documents/GitHub/test-open'/'Soft X-ray'/Four-View; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス

run define_path.m

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
% ~/Documents/MATLAB にてstartup.mを作って、その中でsetenv('パス名','アドレス')していくと自動になる。
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory_path=getenv('pre_processed_directory_path');


%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:'};
definput = {'',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('IDXlist','var')
    definput{2} = num2str(IDXlist);
end

dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDX','var') && exist('times','var')
%     definput = {num2str(date),num2str(IDX),num2str(times)};
% else
%     definput = {'','',''};
% end
% definput = {'','',''};
% definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2))); 
Area = [1 2 3]; % ,'Area(1:X点近傍、2:下流内側、3:下流外側):'
times = 460:510;
SXR.doFilter = 0;
SXR.ReconMethod = 2;
ESP.date = date;
ESP.shotlist = [41:42, 54:57, 60:64];
ESP.probe = 1; % 1: Someyasan, 2: Uebosan
FIG.start = 460;%【input】プロット開始時刻[us]
FIG.dt = 1;%【input】プロット時間間隔[us]
FIG.tate = 10;%【input】プロット枚数(縦)
FIG.yoko = 5;%【input】プロット枚数(横)
PCB.idx = IDXlist(1);

%-----------スプレッドシートからデータ抜き取り--------------------%
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);

T=searchlog(T,'date',date);
if isnan(T.shot(1))
    T(1, :) = [];
end
n_data=numel(IDXlist);%計測データ
shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1); % 39が計測データ数だけ縦に並ぶ。
startlist = T.SXRStart(IDXlist);
intervallist = T.SXRInterval(IDXlist);

shot_a039 =T.a039(PCB.idx);
shot_a040 = T.a040(PCB.idx);
ESP.PCBshot = [shot_a039, shot_a040];

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=50; %【input】rz方向のメッシュ数
PCB.restart = 0;

% figure;hold on
% xlabel('time [us]');ylabel('Merging ratio [%]');
% legendList = cell(1,n_data);
% ax=gca;ax.FontSize=18;

% % エクセルファイルの保存先とファイル名を指定
% outputFile = 'merging_rate.xlsx';
% 
% % 書き込み対象のデータを初期化
% all_merging_ratios = [];
% % 最長のmerging_ratioの長さを記録する変数
% max_length = 0;

% 全ショットのmerging_ratioを格納するための配列

for a = 1:3% ,'Area(1:X点近傍、2:下流内側、3:下流外側):'

    SXR.area = a;
    all_merging_ratios = zeros(n_data, numel(times));
    all_mean_sxr = zeros(n_data, numel(times),4);

    for i = 1:n_data
        % 各ショットのデータ取得
        shot = IDXlist(i);
        PCB.idx = IDXlist(i);
        PCB.shot = shotlist(i,:);
        PCB.tfshot = tfshotlist(i,:);
        PCB.i_EF = EFlist(i);
        PCB.date = date;

        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);

        if isstruct(grid2D) == 0 % データがない場合
            all_merging_ratios(i, :) = NaN;
            continue;
        end

        % merging_ratioを計算
        merging_ratio = get_merging_ratio(data2D, grid2D, times);

        %軟X線データゲットする
        [PCBdata.grid2D, PCBdata.data2D] = process_PCBdata_200ch(PCB, pathname);
        SXR.start = startlist(i);
        SXR.interval = intervallist(i);
        SXR.date = date;
        SXR.shot = IDXlist(i);
        SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
        SXRdata.mean_sxr = zeros(numel(times),4);

        

        SXRdata = SXR_multi(PCBdata,SXR,times,SXRdata);


        % savename = [pathname.ESPmat,'/',num2str(ESP.date),'_shot',num2str(ESP.shotlist(1)),'-',num2str(ESP.shotlist(end)),'-a039_',num2str(ESP.PCBshot(1)),'_',num2str(FIG.start),'_',num2str(FIG.dt),'_',num2str(FIG.tate*FIG.yoko),'.mat'];
        % load(savename,'ExBdata2D','newPCBdata2D');
        % ExBdata2D.mean_Et = zeros(numel(times),1);
        % ExBdata2D = ESP_data(ExBdata2D,PCBdata,times);



        all_merging_ratios(i, :) = merging_ratio; % 配列に保存
        all_mean_sxr(i,:,:) = SXRdata.mean_sxr;
    end

    % カラーマップを定義（4種類のフィルターの色）
    colors = lines(4);

    % 新しいfigureを作成
    figure;
    hold on;

    if ESP.date == 241230
        available_filters = [1 3 4];% only 1um Mylar 光ってた
    elseif ESP.date == 241110
        available_filters = [1 4];
    else
        available_filters = 1:4;
    end

    for i  = available_filters
        disp('plotting begins');

        % 平均値と標準誤差の計算
        % disp(size(all_merging_ratios))
        qmerge = prctile(all_merging_ratios, [10 90],1);
        iqrmerge = qmerge(2,:)-qmerge(1,:);
        filtered_merge = all_merging_ratios;
        filtered_merge(filtered_merge < qmerge(1,:)-1.5*iqrmerge | filtered_merge > qmerge(2,:)+1.5*iqrmerge) = NaN;
        mean_merging_ratio = mean(filtered_merge, 1, 'omitnan');
        std_merging_ratio = std(filtered_merge, 0, 1, 'omitnan');
        stderr_merging_ratio = std_merging_ratio ./ sqrt(sum(~isnan(filtered_merge), 1));

        %sxr平均値と標準誤差の計算
        all_mean_sxr(all_mean_sxr==0)=NaN;
        qsxr = prctile(all_mean_sxr, [25 75], 1);
        iqrsxr = qsxr(2,:,:)-qsxr(1,:,:);
        filtered_sxr = all_mean_sxr;
        filtered_sxr(filtered_sxr<qsxr(1,:,:)-1.5*iqrsxr | filtered_sxr > qsxr(2,:,:)+1.5*iqrsxr) = NaN;

        mean_sxr = mean(filtered_sxr, 1, 'omitnan');

        std_mean_sxr = std(filtered_sxr, 0, 1, 'omitnan');
        stderr_mean_sxr = std_mean_sxr./sqrt(sum(~isnan(filtered_sxr), 1));

        % 縦横のエラーバー用データ
        x = mean_merging_ratio;           % x軸のデータ
        y = mean_sxr(:,:,i);                     % y軸のデータ
        x_err = stderr_merging_ratio;     % x軸のエラーバー
        y_err = stderr_mean_sxr(:,:,i);             % y軸のエラーバー


        validIdx = ~isnan(y);  % NaN ではない部分のインデックスを取得
        x_clean = x(validIdx);  % NaN に対応する x を削除
        y_clean = y(validIdx);  % NaN を削除

        %名前
        if SXR.area == 1
            area = 'Xpoint';
        elseif SXR.area == 2
            area = 'inward downstream';
        elseif SXR.area == 3
            area = 'outward downstream';
        end
        if i == 1
            filter = '1um Al';
        elseif i == 2
            filter = '2.5um Al';
        elseif i == 3
            filter = '2um Mylar';
        elseif i == 4
            filter = '1um Mylar';
        end

        % 平均値とエラーバー（標準誤差）のプロット

        plot(x_clean, y_clean, '-o', 'Color', colors(i, :), 'LineWidth', 1.5, 'MarkerFaceColor', colors(i, :), ...
            'MarkerEdgeColor', colors(i, :), 'DisplayName', filter);
        % 縦エラーバーのプロット（縦方向）
        errorbar(x, y, y_err, 'vertical', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, ...
            'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');

        % 横エラーバーのプロット（横方向）
        errorbar(x, y, x_err, 'horizontal', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, ...
            'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');

    end

    xlabel('Merging ratio [%]');
    ylabel('SXR intensity[a.u.]');
    titleString = sprintf('Intensity to Merging on %s in the range of %s', date, area);
    title(titleString);
    xlim([0 100])
    if ESP.date == 241110 || ESP.date == 241230
        ylim([0 15]);
    elseif  ESP.date == 240621 || ESP.date == 240622 
        ylim([0 5]);
    elseif ESP.date == 240111|| ESP.date == 231216 || 230921
        ylim([0 3]);
    elseif ESP.date == 230920
        ylim([0 1]) ;
    else 
        ylim([0 10]);
    end
    ax = gca; ax.FontSize = 18;
    grid on;
    legend('show', 'Location', 'best');
    hold off;

    disp('finish!');
end
% % Initialize padded array with NaN and set proper dimensions
% padded_merging_ratios = NaN(n_data, max_length);
% 
% for i = 1:n_data
%     % Pad each row of all_merging_ratios to match max_length
%     padded_merging_ratios(i, 1:length(all_merging_ratios(i, :))) = all_merging_ratios(i, :);
% end
% 
% % Verify sizes of IDXlist and padded_merging_ratios for concatenation
% if length(IDXlist) ~= size(padded_merging_ratios, 1)
%     error('Length of IDXlist (%d) does not match the number of rows in padded_merging_ratios (%d).', length(IDXlist), size(padded_merging_ratios, 1));
% end
% 
% % Concatenate IDXlist with padded_merging_ratios
% outputData = [IDXlist, padded_merging_ratios];
% 
% % Create header
% header = [{'Shot Number'}, arrayfun(@(t) sprintf('Time_%dus', t), times(1:max_length), 'UniformOutput', false)];
% 
% % Write to output file
% outputData = [header; num2cell(outputData)];
% writecell(outputData, outputFile);


function ExBdata2D = ESP_data(ExBdata2D,PCBdata, times)
    
    pcbgrid2D = PCBdata.grid2D;
    pcbdata2D = PCBdata.data2D;

    [magAxisList,xPointList] = get_axis_x_multi(pcbgrid2D,pcbdata2D); %時間ごとの磁気軸、X点を検索
    
    

    for t = times
        merg_idx = times == t;
        pcb_tidx = pcbdata2D.trange == t;
        esp_tidx = ExBdata2D.time == t;

        
        z = xPointList.z(pcb_idx);
        r = xPointList.r(pcb_idx);
        dz = 0.1;
        dr = 0.1;
        
        pcb_zidx = pcbgrid2D.zq >= z-dz & pcbgrid2D.zq <= z+dz;
        pcb_ridx = pcbgrid2D.rq >= r-dr & pcbgrid2D.rq <= r+dr;
        
        esp_zidx = ExBdata2D.zq >= z-dz & ExBdata2D.zq <= z+dz;
        esp_ridx = ExBdata2D.rq >= r-dr & ExBdata2D.rq <= r+dr;
        
        mean_psi = mean(pcbdata2D.psi(pcb_zidx,pcb_ridx,t));

        ExBdata2D.mean_phi(merg_idx) = mean_psi;
    end
    
end

function SXRdata = SXR_multi(PCBdata, SXR,pcbtimes,SXRdata)
    

    %plot_sxr_multiの一部を抜き出しただけ
    doFilter = SXR.doFilter;
    ReconMethod = SXR.ReconMethod;
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

    date = SXR.date;
    shot = SXR.shot;
    start = SXR.start;
    interval = SXR.interval;
    dirPath = getenv('SXR_MATRIX_DIR');
    matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));
    newProjectionNumber = 30;
    newGridNumber = 50;
    parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);
    disp(strcat('Loading matrix from :',matrixFolder))
    load(parameterFile,'range');
    times = start:interval:(start+interval*7);

    %ここからはplot_sxr_multi関係ない
    %x点付近の平均値を抜き出す
    grid2D = PCBdata.grid2D;
    data2D = PCBdata.data2D;

    range = range./1000;
    zmin1 = range(1);
    zmax1 = range(2);
    zmin2 = range(3);
    zmax2 = range(4);
    rmin = range(5);
    rmax = range(6);
    
    prevz = 0;
    prevr = 0;
    for t = times
        number = (t-start)/interval+1;
        matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
        load(matrixPath,'EE1','EE2','EE3','EE4');
        EE = cat(3,EE1,EE2,EE3,EE4);

        index = pcbtimes == t;

        r_space_SXR = linspace(rmin,rmax,size(EE,1));
        z_space_SXR1 = linspace(zmin1,zmax1,size(EE,2));
        z_space_SXR2 = linspace(zmin2,zmax2,size(EE,2));

        t_idx = find(data2D.trange==t);
        [~,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索
        
        z = xPointList.z(t_idx);
        r = xPointList.r(t_idx);
        if any(isnan(z)) || any(isnan(r))
            if t == times(1)
                z = 0;
                r = 0.2;
            else
                z = prevz;
                r = prevr;
            end
        end
        prevz = z;
        prevr = r;

        for i = 1:4
            % 対象範囲内のインデックスを取得
            % 横の長さ
            if date == 241230
                dz = 0.05;
                dr = 0.025;
            elseif date == 241110
                dz = 0.1;
                dr = 0.005;
            elseif date == 240501
                dz = 0.05;
                dr = 0.05;
            elseif date == 240621 || date == 240622
                dz = 0.075;
                dr = 0.025;
            elseif date == 230920 || date == 231216 || date == 240111 %セパレーション
                dz = 0.05;
                dr = 0.025;
            else
                dz = 0.075;
                dr = 0.025;
            end
            
            
            if SXR.area == 1
                SXRdata.r_xrange = r_space_SXR>=r-dr & r_space_SXR <= r+dr & r_space_SXR>0.1 & r_space_SXR<0.35;
            elseif SXR.area  == 2
                SXRdata.r_xrange = r_space_SXR<=r-dr & r_space_SXR>0.1 & r_space_SXR<0.35;
                dz = 2*dz;
            elseif SXR.area == 3
                SXRdata.r_xrange = r_space_SXR>=r+dr & r_space_SXR>0.1 & r_space_SXR<0.35;
                dz = 2*dz;
            end

            if i<=2
                SXRdata.z_xrange = z_space_SXR2 >= z-dz & z_space_SXR2<= z+dz;
            else
                SXRdata.z_xrange = z_space_SXR1 >= z-dz & z_space_SXR1<= z+dz;
            end

            % 対象範囲内の部分行列を抽出
            sub_matrix = EE(SXRdata.r_xrange, SXRdata.z_xrange,i); % 範囲内の部分行列を抽出
            
            SXR.plot = 0;
            if SXR.plot == 1 && i == 1
                plot_matrix = zeros(size(EE(:,:,i)));
                plot_matrix(SXRdata.r_xrange, SXRdata.z_xrange) = EE(SXRdata.r_xrange, SXRdata.z_xrange,i);
                figure
                contourf(plot_matrix)
                clim([0 1 ]);
                disp(size(sub_matrix));
                % title(strcat(num2str(SXR.shot), num2str(i), num2str(t)))
                colorbar;
                
                hold off
            end

            % regional max を特定
            regional_max_mask = imregionalmax(sub_matrix);
            % regional max の値を取得
            regional_max_values = sub_matrix(regional_max_mask);
            
            % E = mean(regional_max_values);

            qsxr = prctile(sub_matrix, [75 100], 1);
            E = qsxr(2);
            
            E = max(max(sub_matrix));
            if isempty(E)
                SXRdata.mean_sxr(index, i) = 0; % 空の場合に0を代入
            else
                SXRdata.mean_sxr(index, i) = E; % 通常の代入
            end
        end

        

    end
    
end



function merging_ratio = get_merging_ratio(data2D,grid2D,times)

    merging_ratio = zeros(numel(times),1);
    i = 1;
    
    for time = times
        psi_timeseries = data2D.psi;
        psi = psi_timeseries(:,:,data2D.trange==time);
        merging_ratio(i) = clc_merging_ratio(psi,grid2D);
        i = i+1;
    end
    idx_nan=find(isnan(merging_ratio));
    for j = 1:numel(idx_nan)
        i = idx_nan(j);
        if times(i)<470
            merging_ratio(i) = 0;
        elseif times(i)>480
            merging_ratio(i) = 1;
        end
    end
    merging_ratio(merging_ratio<0)=0;
    merging_ratio=merging_ratio*100;
    % figure('Position',[100 100 600 200]);
    % if plot_flag
    %     figure;
    %     plot(times,merging_ratio,'k-','LineWidth',2);
    %     xlabel('time [us]');ylabel('Merging ratio [%]');
    %     title('Merging ratio');
    %     ax=gca;ax.FontSize=18;
    % end
    
    % merging_speed = diff(merging_ratio);
    % figure;
    % plot(times(2:end),merging_speed,'k-','LineWidth',2);
    % xlabel('time [us]');ylabel('Merging speed [a.u.]');
    % title('Merging speed');
    % ax=gca;ax.FontSize=18;

end

function merging_ratio = clc_merging_ratio(psi,grid2D)

    [pos_oz,pos_or,pos_xz,~,psi_o,psi_x] = search_xo(psi,grid2D);

    % if sum(pos_oz<pos_xz)==1 && sum(isnan(pos_oz))==0 % pos_xzがpos_ozの最大値と最小値の間にあることを判別＆O点が2つあることを判別
    % 必要な条件：O点が少なくとも一つある＋X点が（あれば）その二つの間
    if max(sum(pos_oz<pos_xz),sum(pos_oz>pos_xz))==1 % pos_xzがpos_ozの最大値と最小値の間にあることを判別（NaNが入ってもいいように）
        common_flux = psi_x;
        % private_flux = mean(psi_o, 'omitnan');
        private_flux = min(psi_o,[],'omitnan');
    elseif sum(isnan(pos_oz))==0 && sum(pos_oz>0)==1 && isnan(pos_xz)% O点二つ（値が違う）あるけどX点なし
        pos_xz = mean(pos_oz);
        pos_xr = mean(pos_or);
        r_space = grid2D.rq(:,1);
        z_space = grid2D.zq(1,:);
        z_idx = knnsearch(z_space',pos_xz);
        r_idx = knnsearch(r_space,pos_xr);
        common_flux = psi(r_idx,z_idx);
        private_flux = min(psi_o);
    else
        common_flux = NaN;
        private_flux = NaN;
    end
    
    merging_ratio = common_flux/private_flux;

end

function [pos_oz,pos_or,pos_xz,pos_xr,psi_o,psi_x] = search_xo(psi,grid2D)
    
    r_space = grid2D.rq(:,1);
    z_space = grid2D.zq(1,:);
    mesh_r = numel(r_space);
    
    % psi_or=zeros(2,length(time));
    pos_or=zeros(2,1);
    pos_oz=pos_or;
    psi_o = zeros(2,1);
    % psi_xr=zeros(1,length(time));
    % psi_xz=psi_xr;
    % [max_psi,max_psi_r]=max(psi_store,[],1); %各時間、各列(z)ごとのpsiの最大値
    [max_psi,max_psi_r]=max(psi,[],1); %各列(z)ごとのpsiの最大値
    max_psi=squeeze(max_psi);
    
    % for i = time
    %     ind=i-time(1)+1;
    %     max_psi_ind=find(islocalmax(smooth(max_psi(:,i)),'MaxNumExtrema', 2));
    max_psi_ind=find(islocalmax(smooth(max_psi),'MaxNumExtrema', 2));
    %     r_ind=max_psi_r(:,:,i);
    r_ind=max_psi_r;
    %     if numel(max_psi(min(max_psi_ind),i))==0
    if numel(max_psi(min(max_psi_ind)))==0
        %         psi_or(1,ind)=NaN;
        %         psi_oz(1,ind)=NaN;
        pos_or(1)=NaN;
        pos_oz(1)=NaN;
        psi_o(1) = NaN;
    else
        o1r=r_ind(min(max_psi_ind));
        %         psi_or(1,ind)=r_space(o1r);
        %         psi_oz(1,ind)=z_space(min(max_psi_ind));
        pos_or(1)=r_space(o1r);
        pos_oz(1)=z_space(min(max_psi_ind));
        %         psi_o(1) = psi_store(min(max_psi_ind),o1r);
        psi_o(1) = psi(o1r,min(max_psi_ind));
    end
    %     if numel(max_psi(max(max_psi_ind),i))==0
    if numel(max_psi(max(max_psi_ind)))==0
        %         psi_or(2,ind)=NaN;
        %         psi_oz(2,ind)=NaN;
        pos_or(2)=NaN;
        pos_oz(2)=NaN;
        psi_o(2) = NaN;
    else
        o2r=r_ind(max(max_psi_ind));
        %         psi_or(2,ind)=r_space(o2r);
        %         psi_oz(2,ind)=z_space(max(max_psi_ind));
        pos_or(2)=r_space(o2r);
        pos_oz(2)=z_space(max(max_psi_ind));
        %         psi_o(2) = psi_store(min(max_psi_ind),o2r);
        psi_o(2) = psi(o2r,max(max_psi_ind));
    end
    %     if numel(find(islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1)))==0
    if numel(find(islocalmin(smooth(max_psi),'MaxNumExtrema', 1)))==0
        %         psi_xr(1,ind)=NaN;
        %         psi_xz(1,ind)=NaN;
        pos_xr=NaN;
        pos_xz=NaN;
        psi_x = NaN;
    else
        %         min_psi_ind=islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1);
        min_psi_ind=islocalmin(smooth(max_psi),'MaxNumExtrema', 1);
        xr=r_ind(min_psi_ind);
        if xr==1 || xr==mesh_r %r両端の場合は検知しない
            %             psi_xr(1,ind)=NaN;
            %             psi_xz(1,ind)=NaN;
            pos_xr=NaN;
            pos_xz=NaN;
            psi_x = NaN;
        else
            %             psi_xr(1,ind)=r_space(xr);
            %             psi_xz(1,ind)=z_space(min_psi_ind);
            pos_xr=r_space(xr);
            pos_xz=z_space(min_psi_ind);
            %             psi_x = psi_store(min_psi_ind,xr);
            psi_x = psi(xr,min_psi_ind);
        end
    end
    %     if max_psi(1,i)==max(max_psi(1:end/2,i)) %z両端の場合はpsi中心が画面外として検知しない
    mid_idx = round(numel(max_psi)/2);
    if max_psi(1)==max(max_psi(1:mid_idx)) %z両端の場合はpsi中心が画面外として検知しない
        %         psi_or(1,ind)=NaN; %r_space(r_ind(1));
        %         psi_oz(1,ind)=NaN; %z_space(1);
        pos_or(1)=NaN; %r_space(r_ind(1));
        pos_oz(1)=NaN; %z_space(1);
        psi_o(1) = NaN;
    end
    %     if max_psi(end,i)==max(max_psi(end/2:end,i))
    if max_psi(end)==max(max_psi(mid_idx:end))
        %         psi_or(2,ind)=NaN; %r_space(r_ind(1));
        %         psi_oz(2,ind)=NaN; %z_space(end);
        pos_or(2)=NaN; %r_space(r_ind(1));
        pos_oz(2)=NaN; %z_space(end);
        psi_o(2) = NaN;
    end
end