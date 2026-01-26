%% 設定
target_time = 460; % プロットしたい時間 [us]
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% shotList = [20 30];
% shotList = [20 21 30];
Bt_r = zeros(numel(shotList),40);
j=1;
figure;hold on;
for i = shotList
    % PCB = get_PCB_data(240111,i,0,0);
    % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    [Bt_profile,r_vec] = get_Bt_r(grid2D,data2D,target_time);
    plot(r_vec, Bt_profile, 'LineWidth', 2);
    % if max(Bt_profile) > 0
    %     disp(i);
    % end
    Bt_r(j,:) = Bt_profile.';
    j=j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

% 処理しやすいように構造体またはセル配列にまとめる
groups = {idxTF40, idxTF35, idxTF30, idxTF25};
groupNames = {'TF40', 'TF35', 'TF30', 'TF25'};
groupColors = lines(4); % 4色のカラーマップを作成

% =========================================================================
% 3. 統計計算とエラーバープロット
% =========================================================================
figure('Name', 'Bt Radial Profile by Group', 'Color', 'w');
hold on;

for k = 1:length(groups)
    % 現在のグループのインデックスを取得
    currentIdx = groups{k};
    
    % --- データ抽出 ---
    % 0が含まれている場合（ismemberで見つからなかった場合）を除く処理
    currentIdx = currentIdx(currentIdx > 0); 
    groupData = Bt_r(currentIdx, :);
    
    % --- 統計量の計算 ---
    N = size(groupData, 1);            % データ数 (ショット数)
    mu = mean(groupData, 1, 'omitnan');           % 平均値
    sigma = std(groupData, 0, 1, 'omitnan');      % 標準偏差
    se = sigma ./ sqrt(N);             % 標準誤差 (Standard Error)
    
    % --- プロット ---
    errorbar(r_vec, mu, se, ...
        '-o', ...
        'LineWidth', 2, ...
        'MarkerSize', 6, ...
        'CapSize', 8, ...
        'Color', groupColors(k, :), ...
        'MarkerFaceColor', groupColors(k, :), ...
        'DisplayName', groupNames{k});
end

% =========================================================================
% 4. 装飾
% =========================================================================
xlabel('r [m]', 'FontSize', 14);
ylabel('B_t [T]', 'FontSize', 14);
title(['B_t Radial Distribution (Mean \pm SE) at t = ' num2str(target_time) ' \mu s'], 'FontSize', 16);
grid on;
legend('Location', 'best', 'FontSize', 12);
ax = gca;
ax.FontSize = 14;
xlim([min(r_vec), max(r_vec)]);
hold off;


function [Bt_profile,r_vec] = get_Bt_r(grid2D,data2D,target_time)
    target_z = 0;      % プロットしたいZ座標 [m] (0付近)

    %% 1. 時間インデックスの特定
    % data2D.trange の中から target_time に最も近いインデックスを探す
    [~, t_idx] = min(abs(data2D.trange - target_time));
    % actual_time = data2D.trange(t_idx);

    % fprintf('指定時間: %.1f us -> 実際のデータ時間: %.1f us (Index: %d)\n', ...
        % target_time, actual_time, t_idx);

    %% 2. 空間グリッドの特定
    % grid2D.zq, grid2D.rq の構造を確認して軸ベクトルを取得
    % ※通常、(R方向のサイズ) x (Z方向のサイズ) になっていると仮定します

    % Z方向のベクトル取得 (Zが列方向に変化していると仮定)
    if size(grid2D.zq, 1) > 1 && size(grid2D.zq, 2) > 1
        % メッシュグリッドの場合
        % 行によって値が変わらない方向を探す、あるいは1行目を取得
        z_vec = grid2D.zq(1, :); 
        r_vec = grid2D.rq(:, 1);
    else
        % 1次元ベクトルの場合
        z_vec = grid2D.zq;
        r_vec = grid2D.rq;
    end

    %% 3. Z位置のインデックス特定
    [~, z_idx] = min(abs(z_vec - target_z));
    % actual_z = z_vec(z_idx);

    % fprintf('指定Z位置: %.3f m -> 実際のデータZ位置: %.3f m (Index: %d)\n', ...
    %     target_z, actual_z, z_idx);

    %% 4. データの抽出とプロット
    % Btデータの構造は通常 (R, Z, Time) または (Z, R, Time) です。
    % 前回の get_Epara の interp2 の使い方 (zq, rq, ...) から、
    % data2D.Bt は (R行, Z列, Time) である可能性が高いです。

    if ndims(data2D.Bz) == 3
        if isfield(data2D,'Bt_th')
            Bt_slice_2D = data2D.Bt_th(:, :, t_idx); % 指定時間の2Dデータを取得
        else
            Bt_slice_2D = data2D.Bt(:, :, t_idx); % 指定時間の2Dデータを取得
            Bt_slice_2D = nan(size(Bt_slice_2D));
        end
        
        % Zを固定してR方向のデータを抽出 (すべての行, 指定のZ列)
        Bt_profile = Bt_slice_2D(:, z_idx);
    else
        error('data2D.Bt の次元が想定(3次元)と異なります。');
    end

end

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    % PCB.doOverwrite = true;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    % date = 230828;shotIDX=41;
    % date = 230830;shotIDX=37;
    % date = 240111;shotIDX=29;
    % date = 240828;shotIDX=5;
    % date = 250314;shotIDX=55;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    % date=230714;
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    % IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
    % n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);
    PCB.idx = shotIDX;
    PCB.shot=shotlist;
    PCB.tfshot=tfshotlist;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist;
    PCB.TF=TFlist;
    PCB.date = date;
end