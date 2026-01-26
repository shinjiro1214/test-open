%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 指定範囲 (r=0.1~0.15m) における電子温度の空間平均・時間発展プロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except triple_data2D R_values time_values; % 既存のワークスペースを維持しつつ変数を整理

% --- 1. 設定 ---
target_date = 251218;
% r_range = [0.10, 0.15]; % プロット対象のR範囲 [m]
r_range = [0.15, 0.18]; % プロット対象のR範囲 [m]
% save_plot = false;       % 図を保存するかどうか

% パスの設定 (保存時と同じロジック)
filepath_mat = fullfile(getenv('PROBE_DATA_DIR'), 'tripleProbe', [num2str(target_date), '.mat']);

% --- 2. データの読み込み ---
% ワークスペースにデータがない場合のみロード
if ~exist('triple_data2D', 'var') || ~exist('R_values', 'var') || ~exist('time_values', 'var')
    if exist(filepath_mat, 'file')
        load(filepath_mat);
        fprintf('Loaded: %s\n', filepath_mat);
    else
        error('データファイルが見つかりません: %s', filepath_mat);
    end
end

% --- 3. データ抽出と計算 ---
% 3次元配列から2次元へ (R x Time)
Te_data_all = squeeze(triple_data2D.Te(:, 1, :)); % [eV] (保存時に変換済みと仮定)

% 指定範囲のインデックスを取得
idx_target_r = find(R_values >= r_range(1) & R_values <= r_range(2));

if isempty(idx_target_r)
    error('指定された範囲 (R=%.2f-%.2f m) にデータが存在しません。', r_range(1), r_range(2));
end

fprintf('使用するR座標: %s [m]\n', num2str(R_values(idx_target_r), '%.3f '));

% 指定範囲のデータを抽出
Te_subset = Te_data_all(idx_target_r, :);

% 空間平均と空間標準偏差(ばらつき)を計算
% dim=1 (行方向=R方向) について平均
Te_spatial_mean = mean(Te_subset, 1, 'omitnan');
Te_spatial_std  = std(Te_subset, 0, 1, 'omitnan');

% --- 4. プロット ---
figure('Name', 'Spatially Averaged Te Evolution', 'Color', 'w');

% エラーバー付きでプロット (空間的なばらつきを表示)
% 塗りつぶし(shaded error bar)で見やすくする場合
hold on;
curve1 = Te_spatial_mean + Te_spatial_std;
curve2 = Te_spatial_mean - Te_spatial_std;
x2 = [time_values, fliplr(time_values)];
inBetween = [curve1, fliplr(curve2)];

% ばらつき（標準偏差）を薄い色で塗りつぶし
fill(x2, inBetween, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Spatial Std Dev');

% 平均値を太線でプロット
plot(time_values, Te_spatial_mean, 'r', 'LineWidth', 2, 'DisplayName', 'Spatial Mean');

hold off;

% --- 5. グラフの装飾 ---
grid on;
xlim([450, 600]); % 元のコードの時間軸に合わせる
xlabel('Time [\mus]', 'FontSize', 12);
ylabel('Electron temperature [eV]', 'FontSize', 12);
% title(sprintf('Spatially Averaged T_e (R = %.2f - %.2f m)', r_range(1), r_range(2)), 'FontSize', 14);
% legend('Location', 'best');
xlim([460 480]);
% xlim([460 490]);
% 軸の文字サイズ調整
ax = gca;
ax.FontSize = 16;

% % --- 6. 保存 (任意) ---
% if save_plot
%     saveDir = fullfile(getenv('PROBE_DATA_DIR'), 'tripleProbe', 'figures');
%     if ~exist(saveDir, 'dir'), mkdir(saveDir); end
%     filename = sprintf('Te_avg_time_evolution_%d', target_date);
%     saveas(gcf, fullfile(saveDir, [filename, '.png']));
%     disp(['Saved figure to: ', fullfile(saveDir, [filename, '.png'])]);
% end