clearvars -except date IDXlist times xaxis

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


% %%%%実験オペレーションの取得

dlgtitle = 'Input';
dims = [1 35];

% % 異極性Case-I
% datelist = [250205; 250205; 250205; 250205; 250205];
% IDXlistlist = [9 15 16 NaN NaN NaN;
%     40 41 42 43 44 45;
%     33 34 35 36 37 38;
%     26 27 28 29 30 31;
%     5 6 7 23 24 25];
% chargelist = [20; 24; 26; 28; 30];

%異極鉎Case-O
% datelist = [250206; 250206; 250206; 250206];
% IDXlistlist = [20:23 NaN NaN;
%     14:19;
%     8:13;
%     2:7];
% chargelist = [24; 26; 28; 30];


% %　フラクスコア　水素
% datelist = [250125; 250125; 250125; 250125; 250125; 250125];
% IDXlistlist = [8 9 10 11 12 13;
%     14 15 16 17 18 19;
%     20 21 22 23 24 25;
%     26 27 29 30 31 32;
%     33 34 35 36 37 38;
%     39 40 41 42 43 44];
% chargelist = [0; 1; 2; 3; 4; 5];


% フラックスコア　アルゴン
datelist = [250206; 240621; 240621; 240621; 240621; 240622; 240622];
IDXlistlist = [21 22 23 NaN NaN NaN NaN NaN;
    2 4 5 6 7 9 11 12;
    18 19 20 24 25 26 NaN NaN;
    36 37 38 39 40 41 NaN NaN;
    49 50 52 53 54 55 NaN NaN;
    20 21 22 NaN NaN NaN NaN NaN;
    26 27 29 30 NaN NaN NaN NaN];
chargelist = [0; 0; 1; 2; 3; 4; 6];


% % セパレーションコイル　アルゴン 
% datelist = [240111;  240111; 240111; 240111];
% IDXlistlist = [16 17 18 19 20 21;
%     13 14 15 22 23 24;
%     10 11 12 25 26 27;
%     7 8 9 28 29 30];
% chargelist = [2.5; 3; 3.5; 4];


% フラックスコア　アルゴン
% datelist = [240828;240828];
% IDXlistlist = [30 31 32 33 34 36 37 38 39 40 41 43 44 45 48 49 50 51 52 53 54 ;
%     3 4 5 6 7 8 16 17 18 19 20 21 22 23 24 25 26 27 29 NaN NaN];
% chargelist = [5; 6];

% %%%%%%%%%%%%%%%%%%%
doxpointplot = 0; %Etのx点プロット。0はしない。1はする。
PCB.xpointdata = 2; %1はEt、2はEt/Jt
%%%%%%%%%%%%%%%%%%%
FIG.start = 450;
FIG.end = 500;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xaxis = 2; %1はTF、2はガイド磁場比、3はリコネクション磁場のトロイダル成分B_rt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mtcount = 7; % 1:all, 2:~0, 3:0~25, 4:25~50, 5:50~75, 6:75~100, 7:100~

guideratio = zeros(size(IDXlistlist));
B_rec_all = zeros(size(IDXlistlist));

tate = 5;
yoko = 5;
start = 40;
dt = 1;

times = 400:550;
SXR.doFilter = 0;
SXR.ReconMethod = 2;
ESP.date = datelist(1);

if ESP.date == 241230
            available_filters = [1 3 4];% only 1um Mylar 光ってた
        elseif ESP.date == 241110
            available_filters = [1 4];
        elseif ESP.date == 250125 || ESP.date == 240828 || ESP.date == 250205 || ESP.date == 250206
            available_filters = [1 2 4];
        else
            available_filters = 1:4;
end

guidedata = zeros(numel(datelist), numel(times), 4, 3,mtcount);
PCB.trange=400:600;%【input】計算時間範囲
all_data = nan(numel(IDXlistlist(1,:)),numel(datelist),numel(PCB.trange));

for j = 1:numel(datelist)
    date = datelist(j);
    IDXlist = IDXlistlist(j,:);
    IDXlist = IDXlist(~isnan(IDXlist));
    % disp(chargelist(j))

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
    % for a = 1:3% ,'Area(2:X点近傍、3:下流内側、1:下流外側):'

    % SXR.area = a;

    all_merging_ratios = zeros(n_data, numel(times));
    all_mean_sxr = zeros(n_data, numel(times),4,3,mtcount);

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
        PCB.merging_ratio = get_merging_ratio(data2D, grid2D, times);
        [B_r,B_t,B_rt,b] = get_guide_field_ratio2(PCB,pathname);
        if b < 0
            guideratio(j,i) = 0;
        else
            guideratio(j,i) = b;
        end
        B_rec_all(j,i) = B_rt;%sqrt(B_r.^2 + B_rt.^2);
        % disp(B_t)

        %軟X線データゲットする
        [PCBdata.grid2D, PCBdata.data2D] = process_PCBdata_280ch(PCB, pathname);
        SXR.start = startlist(i);
        SXR.interval = intervallist(i);
        SXR.date = date;
        SXR.shot = IDXlist(i);
        SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
        SXRdata.mean_sxr = zeros(numel(times),4,3);
        SXRdata.merge_mean_sxr = zeros(numel(times),4,3,mtcount);

        SXRdata = SXR_multi(PCBdata,SXR,times,SXRdata,PCB);
        
        %　平均取る時間帯を限定。
        for mt = 1:mtcount
            PCB.mergetime = mt;
            new_mean_sxr = nan(size(SXRdata.mean_sxr));
            idx = false(length(times),1);
            if PCB.mergetime == 1
                idx = PCB.merging_ratio' < 1000 & PCB.merging_ratio'>-1000;
            elseif PCB.mergetime == 2
                idx = PCB.merging_ratio' <= 0;
            elseif PCB.mergetime == 3
                idx = PCB.merging_ratio' <= 25 & PCB.merging_ratio' > 0;
            elseif PCB.mergetime == 4
                idx = PCB.merging_ratio' <= 50 & PCB.merging_ratio' > 25;
            elseif PCB.mergetime == 5
                idx = PCB.merging_ratio' <= 75 & PCB.merging_ratio' > 50;
            elseif PCB.mergetime == 6
                idx = PCB.merging_ratio' < 100 & PCB.merging_ratio' > 75;
            elseif PCB.mergetime == 7
                idx = PCB.merging_ratio' >= 100;
            end
            new_mean_sxr(idx, :, :) = SXRdata.mean_sxr(idx, :, :);
            SXRdata.merge_mean_sxr(:,:,:,mt) = new_mean_sxr;
        end

        all_merging_ratios(i, :) = PCB.merging_ratio; % 配列に保存
        all_mean_sxr(i,:,:,:,:) = SXRdata.merge_mean_sxr;
        
        if doxpointplot
            [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
            all_data(i,j,:) = xpointplot(grid2D, data2D,PCB);
        end
    end
    for i  = available_filters
        guidedata(j,:,i,:,:) = max(all_mean_sxr(:,:,i,:,:));
    end
end
colors = lines(4);

figure('Position', [0 0 1500 1500],'visible','on');
for mt = 2:6
    if mt == 1
        timing = 'all';
    elseif mt == 2
        timing = '~0%';
    elseif mt == 3
        timing = '0~25%';
    elseif mt == 4
        timing = '25~50%';
    elseif mt == 5
        timing = '50~75%';
    elseif mt ==6
        timing = '75~100%';
    elseif mt ==7
        timing = '100%~';
    end
for a = 1:3
    if a == 2
        ar = 'Xpoint';
    elseif a == 3
        ar = 'downstream in';
    elseif a == 1
        ar = 'downstream out';
    end
    

    %%%%%%%%%%%%%%%%%%%%maxのプロット%%%%%%%%%%%%%%%%%%
    subplot(3,5,(a-1)*5+mt-1);hold on;
    for i = available_filters

        if i == 1
            filter = '1um Al';
        elseif i == 2
            filter = '2.5um Al';
        elseif i == 3
            filter = '2um Mylar';
        elseif i == 4
            filter = '1um Mylar';
        end
        std_guidedata = std(guidedata(:,:,i,a,mt), 0, 2, 'omitnan');
        stderr_guidedata = std_guidedata ./ sqrt(sum(~isnan(guidedata(:,:,i,a,mt)), 2));
        guidedata(guidedata==0) = NaN;

        % disp(size(stderr_guidedata))
        % disp(size(max(guidedata(:,:,i,a))))
        
        guideratio(guideratio==0) = NaN;
        guideratiomean = mean(guideratio, 2, 'omitnan');
        std_guideratio = std(guideratio, 0, 2, 'omitnan');
        stderr_guideratio = std_guideratio ./ sqrt(sum(~isnan(guideratio),2));
        
        

        B_rec_all(B_rec_all==0) = NaN;
        B_rec_allmean = mean(B_rec_all, 2, 'omitnan');
        std_B_rec_all = std(B_rec_all, 0, 2, 'omitnan');
        stderr_B_rec_all = std_B_rec_all ./ sqrt(sum(~isnan(B_rec_all),2));
        B_rec_all(B_rec_all==0) = NaN;
        
        if xaxis == 1
            plot(chargelist, max(guidedata(:,:,i,a,mt),[],2), '-o', 'Color', colors(i,:), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :), 'DisplayName', filter);
            errorbar(chargelist, max(guidedata(:,:,i,a,mt),[],2), stderr_guidedata, 'vertical', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
            xlim([chargelist(1) chargelist(end)])
        elseif xaxis == 2
            guideratiomean(1) = 0;%異極性のため　それ以外の時はコメントアウトする
            stderr_guideratio(1) = 0; %異極性のため
            disp(max(guidedata(:,:,i,a,mt),[],2))
            plot(guideratiomean, max(guidedata(:,:,i,a,mt),[],2), '-o', 'Color', colors(i,:), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :), 'DisplayName', filter);
            errorbar(guideratiomean, max(guidedata(:,:,i,a,mt),[],2), stderr_guidedata, 'vertical', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
            errorbar(guideratiomean, max(guidedata(:,:,i,a,mt),[],2), stderr_guideratio, 'horizontal', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
            subtitlestring = sprintf('%s %s', ar,timing);
            title(subtitlestring);
            % disp(guideratiomean)
            % xlim([floor(guideratiomean(1)) ceil(guideratiomean(end))])
            xlim([0 10]);
        elseif xaxis == 3
            plot(B_rec_allmean, max(guidedata(:,:,i,a,mt),[],2), '-o', 'Color', colors(i,:), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :), 'DisplayName', filter);
            errorbar(B_rec_allmean, max(guidedata(:,:,i,a,mt),[],2), stderr_guidedata, 'vertical', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
            errorbar(B_rec_allmean, max(guidedata(:,:,i,a,mt),[],2), stderr_B_rec_all, 'horizontal', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
            subtitlestring = sprintf('%s %s', ar,timing);
            title(subtitlestring);
            % disp(guideratiomean)
            % xlim([floor(guideratiomean(1)) ceil(guideratiomean(end))])
            xlim([0.02 0.05]);
        
        end
        if ESP.date == 241110 || ESP.date == 241230 
            ylim([0 15]);
        elseif ESP.date == 250206|| ESP.date == 250205 
            ylim([0 25]);
        elseif  ESP.date == 240621 || ESP.date == 240622
            ylim([0 16]);
        elseif ESP.date == 240111
            ylim([0 10]);
        elseif ESP.date == 231216 || ESP.date == 230921
            ylim([0 3]);
        elseif ESP.date == 230920
            ylim([0 1]) ;
        elseif ESP.date == 250125
            ylim([0 30]);
        elseif ESP.date == 240828
            ylim([0 15]);
        else
            ylim([0 10]);
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%時間スキャン%%%%%%%%%%%%%%%%%%%%%%
    % figure('Position', [0 0 1500 1500],'visible','on')
    % for j = 1:tate*yoko
    %     subplot(tate,round(yoko),j);hold on;
    %     tidx = times_clean(j); %start + dt*(j-1)+1;
    %     for i = available_filters
    %         if i == 1
    %             filter = '1um Al';
    %         elseif i == 2
    %             filter = '2.5um Al';
    %         elseif i == 3
    %             filter = '2um Mylar';
    %         elseif i == 4
    %             filter = '1um Mylar';
    %         end
    %         % std_guidedata = std(guidedata(:,:,i,a), 0, 1, 'omitnan');
    %         % stderr_guidedata = std_guidedata ./ sqrt(sum(~isnan(guidedata(:,:,i,a)), 1));
    % 
    %         disp(size(stderr_guidedata))
    %         disp(size(guidedata))
    % 
    %         plot(chargelist, guidedata(:,tidx,i,a), '-o', 'Color', colors(i,:), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :), 'DisplayName', filter);
    %         % errorbar(chargelist, guidedata(:,tidx,i,a), stderr_guidedata, 'vertical', 'o', 'Color', colors(i, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', colors(i, :),'HandleVisibility', 'off');
    %         title([num2str(times(tidx)) 'us'])
    %         xlim([chargelist(1) chargelist(end)])
    %         if ESP.date == 241110 || ESP.date == 241230
    %             ylim([0 15]);
    %         elseif  ESP.date == 240621 || ESP.date == 240622
    %             ylim([0 16]);
    %         elseif ESP.date == 240111
    %             ylim([0 10]);
    %         elseif ESP.date == 231216 || ESP.date == 230921
    %             ylim([0 3]);
    %         elseif ESP.date == 230920
    %             ylim([0 1]) ;
    %         elseif ESP.date == 250125
    %             ylim([0 30]);
    %         elseif ESP.date == 240828
    %             ylim([0 15]);
    %         else
    %             ylim([0 10]);
    %         end
    %     end
    % end
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hold off

    if xaxis == 1
        titleString= sprintf('Intensity to guidefield on %s', datelist(1));
        sgtitle(titleString);
        xlabel('TF[kV]');
    elseif xaxis == 2
        titleString= sprintf('Intensity to guidefieldratio on %s', datelist(1));
        sgtitle(titleString);
        xlabel('Bt/Bp');
    elseif xaxis == 3
        titleString= sprintf('Intensity to B_rec_t on %s', datelist(1));
        sgtitle(titleString);
        xlabel('Brec_t[T]');
    end
    ax = gca; ax.FontSize = 18;
    ylabel('SXR intensity[a.u.]');
    grid on;
    
end

end
legend('show', 'Location', 'best');
legend('show', 'Location', 'best');
disp('finish!');

colors = lines(numel(datelist));
if doxpointplot
    figure;
    hold on;
    for j = 1:numel(datelist)
        all_mean_data = mean(all_data(:,j,:),1,'omitnan');
        std_mean = std(all_data(:,j,:), 0, 1, 'omitnan');
        stderr_mean = std_mean ./ sqrt(sum(~isnan(all_data(:,j,:)),1));
        
        errorbar(PCB.trange, squeeze(all_mean_data)', squeeze(stderr_mean)', '-ko', 'Color', colors(j, :), 'LineWidth', 1.2, 'MarkerFaceColor', colors(j, :), 'DisplayName', num2str(chargelist(j)));
        xlim([FIG.start FIG.end]);
        xlabel('time[s]');
        if PCB.xpointdata == 1
            ylim([-3e2 3e2]);
            ylabel('Et[V/m]');
        elseif PCB.xpointdata == 2
            % ylim([-10 40]);
            ylim([-0.5 1])
            ylabel('Et/Jt[mΩ/m]')
        end
    end
    legend('show', 'Location', 'best');
    hold off;
end

function SXRdata = SXR_multi(PCBdata, SXR,pcbtimes,SXRdata,PCB)
    

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
        [~,xPointList] = get_axis_x_multi(grid2D,data2D,PCB); %時間ごとの磁気軸、X点を検索
        
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
        

        for a = 1:3
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
            elseif date == 250205 || date == 250206
                dz = 0.025;
                dr = 0.025;
            else
                dz = 0.075;
                dr = 0.025;
            end
            
            
            if a == 2
                SXRdata.r_xrange = r_space_SXR>=r-dr & r_space_SXR <= r+dr & r_space_SXR>0.1 & r_space_SXR<0.35;
            elseif a  == 3
                SXRdata.r_xrange = r_space_SXR<=r-dr & r_space_SXR>0.1 & r_space_SXR<0.35;
                dz = 2*dz;
            elseif a == 1
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
                figure;
                contourf(plot_matrix)
                clim([0 1 ]);
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
                SXRdata.mean_sxr(index, i,a) = 0; % 空の場合に0を代入
            else
                SXRdata.mean_sxr(index, i,a) = E; % 通常の代入
            end
            

        end
        end

        

    end
    
end

