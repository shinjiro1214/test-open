pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.MAGDATA = getenv('MAGDATA_DIR');
pathname.ESP = getenv('NIFS_ESP');
pathname.github = getenv('GITHUB_DIR');
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));

t_plot = 468;

PCB = get_PCB_data(240111,27,465,2);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
idx_t = data2D.trange == t_plot;
Z_grid = grid2D.zq;
R_grid = grid2D.rq;
Bz_data = data2D.Bz(:,:,idx_t);
Br_data = data2D.Br(:,:,idx_t);
Bt_data = data2D.Bt_th(:,:,idx_t);
Et_data = data2D.Et(:,:,idx_t);
Bp_data = sqrt(Br_data.^2 + Bz_data.^2);
Source_data = (Et_data .* Bt_data) ./ (Bp_data + eps);

% Z_start = min(Z_grid,[],'all');
% R_start = R_grid(5,1);

num_lines = 5;
R_start_list = linspace(0.1, 0.2, num_lines); % 0.6m付近まで
Z_start_list = repmat(min(Z_grid(:)), 1, num_lines);     % Zはすべて左端

% 前提: R_grid, Z_grid, Br_data, Bz_data, Source_data は作成済みとする

% --- 1. 磁力線の一括追跡 (ループ不要) ---
% 始点リストをそのまま渡せます
% 戻り値 lines は {1xN} のセル配列になります
lines = stream2(Z_grid, R_grid, Bz_data, Br_data, Z_start_list, R_start_list);

% --- 2. 各ラインごとの積分とプロット (ここはループが楽) ---
figure; hold on;
colormap jet; % 色分け用

for k = 1:length(lines)
    % k番目の磁力線データを取り出す
    % セル配列の中身には {} でアクセスします
    line_path = lines{k};
    
    % --- エラー回避: 短すぎる線（壁に即衝突など）はスキップ ---
    if size(line_path, 1) < 2
        continue; 
    end
    
    % --- 以下、1本のときと同じ処理 ---
    Z_line = line_path(:, 1);
    R_line = line_path(:, 2);
    
    % ソース項の補間
    Source_on_line = interp2(Z_grid, R_grid, Source_data, Z_line, R_line, 'linear');
    
    % 距離計算と積分
    dZ = diff(Z_line);
    dR = diff(R_line);
    ds = sqrt(dZ.^2 + dR.^2);
    
    % Sourceの要素数を合わせて積分
    Source_mid = (Source_on_line(1:end-1) + Source_on_line(2:end)) / 2;
    dPhi = Source_mid .* ds;
    Phi_line = [0; cumsum(dPhi)];
    
    % --- プロット ---
    % 1本のグラフとして描画 (色は自動で変わるか、明示的に指定)
    plot(Z_line, Phi_line, 'LineWidth', 1.5, 'DisplayName', sprintf('R_{st}=%.2f', R_start_list(k)));
end

hold off;
% title('Potential Profiles for Multiple Flux Surfaces');
xlabel('Z [m]');
ylabel('Electrostatic Potential \phi [V]');
grid on;
legend show; % 凡例を表示

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

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