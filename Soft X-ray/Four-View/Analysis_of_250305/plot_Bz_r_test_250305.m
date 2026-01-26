%% 設定
% target_time = 468; % プロットしたい時間 [us]
target_time = 470; % プロットしたい時間 [us]
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

pcbDataDir = getenv('pre_processed_directory_path');
date = '250305';
shotList_2kV = [49:51, 56, 58, 60:65, 67:69];%2kV
shotList_3kV = [23:31, 36:38,40:46];%3kV
shotList_4kV = 18:21;%4kV
% shotList_4kV = [8,9,18:21];%4kV
% shotList_4kV = [8,9];%4kV
shotList = {shotList_2kV,shotList_3kV,shotList_4kV};
% shotList = {shotList_4kV,shotList_3kV,shotList_2kV};

t = 451:480;
[Bz_mean,Bz_std] = deal(zeros(numel(shotList),40));
% trange = t-399;
% j = 1;
figure;hold on;
for i = 1:numel(shotList)
    shotList_tmp = cell2mat(shotList(i));
    Bz_r = zeros(numel(shotList_tmp),40);
    dirPath = fullfile(pcbDataDir,date);
    j=1;
    for k = shotList_tmp
        % disp(k);
        % PCB = get_PCB_data(str2double(date),k,0,0);
        % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
        load([dirPath,num2str(k,'%03i'),'.mat'],'data2D','grid2D');
        % Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
        [Bz_r(j,:),r_vec] = get_Bz_r(grid2D,data2D,target_time);
        plot(r_vec, Bz_r(j,:), 'LineWidth', 2);
        % Br_t(j,:) = get_Br_time(grid2D,data2D,trange) .* 0.75;
        % plot(t,Br_t(j,:));
        if max(Bz_r(j,:)) < 0
            disp(k);
        end
        j = j+1;
    end
    Bz_mean(i,:) = mean(Bz_r,'omitmissing');
    Bz_std(i,:) = std(Bz_r,'omitmissing');
end

figure; hold on;
for i = 1:numel(shotList)
    errorbar(r_vec,Bz_mean(i,:),Bz_std(i,:));
end
grid on;
legend({'TF=2kV','TF=3kV','TF=4kV'});
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Guide magnetic field [T]');


function [Bz_profile,r_vec] = get_Bz_r(grid2D,data2D,target_time)
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
    % Bzデータの構造は通常 (R, Z, Time) または (Z, R, Time) です。
    % 前回の get_Epara の interp2 の使い方 (zq, rq, ...) から、
    % data2D.Bz は (R行, Z列, Time) である可能性が高いです。

    if ndims(data2D.Bz) == 3
        Bz_slice_2D = data2D.Bz(:, :, t_idx); % 指定時間の2Dデータを取得
        
        % Zを固定してR方向のデータを抽出 (すべての行, 指定のZ列)
        Bz_profile = Bz_slice_2D(:, z_idx);
    else
        error('data2D.Bz の次元が想定(3次元)と異なります。');
    end
    Bz_profile = Bz_profile.';
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