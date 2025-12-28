function fit()
% 全ての再構成手法(Tik, MFI, MEM)との比較機能を追加した最終版

% --- 主要な設定項目 ---
true_params = [ ...
    -0.3,  0.3, 0.1, 0.2, 1.5, ...
     0.3, -0.3, 0.2, 0.1, 1.2];
initial_params = [ ...
    -0.2,  0.2, 0.15, 0.15, 1.3, ...
     0.2, -0.2, 0.15, 0.15, 1.0];
noise_level_percent = 10;
plot_interval = 10;

% --- 準備 ---
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-view';
newProjectionNumber = 30;
newGridNumber = 50;
[gm2d1, ~, ~, ~, U1, ~, ~, ~, s1, ~, ~, ~, v1, ~, ~, ~, M, K, ~, ~, ~] = parametercheck(newProjectionNumber, newGridNumber);

%% 1. 真のファントムと観測データの生成
[EE_true, I_true] = create_phantom_and_projection(true_params, gm2d1);
noise_power_db = 10 * log10(100 / noise_level_percent);
Iwgn_target = awgn(I_true, noise_power_db, 'measured');
Iwgn_target(Iwgn_target < 0) = 0;
fprintf('複数光源のファントムと観測データを生成しました。\n');


%% 2. 【比較手法】Tikhonov, MFI, MEMによる再構成
recon_method_names = {'Tikhonov', 'MFI', 'MEM'};
num_recon_methods = length(recon_method_names);
EE_reconst_cell = cell(num_recon_methods, 1);
I_reconst_cell = cell(num_recon_methods, 1);

for i = 1:num_recon_methods
    ReconMethod = i - 1; % 0:Tik, 1:MFI, 2:MEM
    fprintf('\n比較手法 (%s) による再構成を実行します...\n', recon_method_names{i});
    
    % get_distributionを呼び出し
    EE_reconst_cell{i} = get_distribution(M, K, gm2d1, U1, s1, v1, Iwgn_target.', false, ReconMethod);
    
    EE_reconst_cell{i} = flipud(EE_reconst_cell{i});
    
    % 再構成した2D分布から、1Dの視線積分値を順計算
    I_reconst_cell{i} = gm2d1 * EE_reconst_cell{i}(:);
end


%% 3. 【本手法】非線形フィットによる最適化
obj_fun = @(params) cost_function(params, Iwgn_target, gm2d1);

% --- プロット機能のための準備 ---
history_x = []; history_fval = []; num_params = length(initial_params);
figure('Name', 'Optimization Progress', 'Position', [1150, 100, 800, 600]);
ax1 = subplot(2, 1, 1); h_error_plot = plot(ax1, NaN, NaN, '-o', 'LineWidth', 1.5, 'Color', '#0072BD');
title('Convergence Plot'); xlabel('Iteration'); ylabel('Error'); grid on;
ax2 = subplot(2, 1, 2); param_names_short = {'z_c', 'r_c', 'a', 'b', 'I'};
colors = lines(5); h_param_plots = gobjects(num_params, 1);
hold on;
for k = 1:num_params
    param_type_idx = mod(k-1, 5) + 1;
    h_param_plots(k) = plot(ax2, NaN, NaN, 'o-', 'Color', colors(param_type_idx,:), 'DisplayName', sprintf('P%d(%s)', k, param_names_short{param_type_idx}));
end
hold off; title('Parameter Evolution'); xlabel('Iteration'); ylabel('Parameter Value');
legend(ax2, 'show', 'Location', 'northeast', 'FontSize', 8); grid on;

options = optimset('Display', 'iter', 'OutputFcn', @plot_optimization_progress, 'MaxFunEvals', 5000, 'TolFun', 1e-8);
fprintf('\n本手法 (fminsearch) によるパラメータ最適化を開始します...\n');
[optimal_params, fval] = fminsearch(obj_fun, initial_params, options);


%% 4. 結果の表示と可視化
fprintf('\n==================================================\n');
fprintf('          最適化結果のサマリー\n');
fprintf('==================================================\n');
fprintf('最終的な誤差 (Sum of Squared Errors): %e\n\n', fval);
num_gaussians = length(true_params) / 5;
param_names_long = {'中心位置 Z (z_center)', '中心位置 R (r_center)', '広がり a (width a)', '広がり b (width b)', '強度 I (Intensity)'};
for i = 1:num_gaussians
    fprintf('--- ガウス関数 %d のパラメータ ---\n', i);
    fprintf('%-25s | %10s | %10s\n', 'パラメータ名', '真の値', '推定値');
    fprintf(repmat('-', 1, 52)); fprintf('\n');
    true_p = true_params((i-1)*5 + 1 : i*5); optimal_p = optimal_params((i-1)*5 + 1 : i*5);
    for j = 1:5, fprintf('%-25s | %10.4f | %10.4f\n', param_names_long{j}, true_p(j), optimal_p(j)); end
    fprintf('\n');
end

% --- 最適化結果から最終的なファントムを計算 ---
[EE_optimal_fit, I_optimal_fit] = create_phantom_and_projection(optimal_params, gm2d1);

% --- 結果のプロット ---
% ★★★ 図1: 2Dファントムの比較★★★
figure('Name', '2D Phantom Comparison', 'Position', [50, 400, 1500, 800]);
subplot(2, 3, 1); imagesc(EE_true); title('1. 真のファントム'); axis image; colorbar;
subplot(2, 3, 2); imagesc(EE_optimal_fit); title('2. 本手法 (非線形フィット)'); axis image; colorbar;
for i = 1:num_recon_methods
    subplot(2, 3, 2 + i);
    imagesc(EE_reconst_cell{i});
    title(sprintf('%d. %s法', 2+i, recon_method_names{i}));
    axis image; colorbar;
end
sgtitle('2Dファントムの比較', 'FontSize', 16, 'FontWeight', 'bold');

% ★★★ 図2: 視線積分値の比較プロット ★★★
figure('Name', 'Line-of-Sight Integral Values', 'Position', [50, 50, 1200, 600]);
plot(I_true, 'k-', 'LineWidth', 2.5, 'DisplayName', '真の積分値');
hold on;
plot(Iwgn_target, '.', 'Color', [0.7 0.7 0.7], 'MarkerSize', 8, 'DisplayName', '観測データ');
plot(I_optimal_fit, 'r--', 'LineWidth', 2.5, 'DisplayName', '本手法 (非線形フィット)');
plot(I_reconst_cell{1}, 'g:', 'LineWidth', 2, 'DisplayName', 'Tikhonov法');
plot(I_reconst_cell{2}, 'b-.', 'LineWidth', 2, 'DisplayName', 'MFI法');
plot(I_reconst_cell{3}, 'm--', 'LineWidth', 2, 'DisplayName', 'MEM法');
hold off;
grid on; legend('show', 'Location', 'northeast', 'FontSize', 10);
title('視線積分値の比較 (全手法)'); xlabel('視線チャンネル番号'); ylabel('強度 [a.u.]');
set(gca, 'FontSize', 12);

%% --- ネスト関数  ---
    function stop = plot_optimization_progress(x, optimValues, state)
        stop = false;
        if strcmp(state, 'iter') && (mod(optimValues.iteration, plot_interval) == 0 || optimValues.iteration == 1)
            history_fval(end+1) = optimValues.fval; history_x(:, end+1) = x;
            plot_iteration_count = [1, plot_interval * (1:(length(history_fval)-1))];
            set(h_error_plot, 'XData', plot_iteration_count, 'YData', history_fval);
            for p_idx = 1:num_params, set(h_param_plots(p_idx), 'XData', plot_iteration_count, 'YData', history_x(p_idx, :)); end
            drawnow;
        end
    end
end

%% --- 中心関数 & 目的関数 ---
function [EE, I] = create_phantom_and_projection(params, gm2d)
    [~, num_grid_points] = size(gm2d); N_grid = round(sqrt(num_grid_points));
    if N_grid^2 ~= num_grid_points, error('ジオメトリ行列の列数が完全な平方数ではありません。'); end
    [r_space, z_space] = meshgrid(linspace(-1, 1, N_grid), linspace(-1, 1, N_grid));
    EE_phantom = zeros(N_grid, N_grid); num_gaussians = length(params) / 5;
    if mod(length(params), 5) ~= 0, error('パラメータの数が5の倍数ではありません。'); end
    for i = 1:num_gaussians
        p = params((i-1)*5 + 1 : i*5);
        z_center = p(1); r_center = p(2); a = abs(p(3)); b = abs(p(4)); intensity = p(5);
        EE_phantom = EE_phantom + intensity * exp(-((z_space - z_center).^2 / (2 * a^2) + (r_space - r_center).^2 / (2 * b^2)));
    end
    EE_phantom = EE_phantom + 0.001;
    if max(EE_phantom(:)) > 0, EE_phantom = EE_phantom ./ max(EE_phantom(:)); end
    EE = fliplr(rot90(EE_phantom)); E_vec = reshape(EE, 1, []);
    I = gm2d * E_vec';
end
function error = cost_function(params, Iwgn_target, gm2d)
    [~, I_calculated] = create_phantom_and_projection(params, gm2d);
    error = sum((I_calculated - Iwgn_target).^2);
end