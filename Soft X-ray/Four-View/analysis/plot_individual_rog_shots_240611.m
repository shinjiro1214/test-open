function plot_individual_shots_240611()
    % --- ユーザー環境設定 ---
    % ※ご自身の環境に合わせてパスを変更してください
    pathname.fourier = '/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/koala/mnt/fourier';
    directory_rogo = fullfile(pathname.fourier, 'rogowski');

    % --- 解析対象の設定 (240611のみ) ---
    % target_date = 240611;
    % target_date = 250206;
    target_date = 251220;
    % 以前のコードに基づくショットリスト
    % target_shots = [110:111, 113:115, 117:141];
    % target_shots = [2:23];
    target_shots = [5:10, 12:23];

    % --- 校正係数 (Wiki 2024/07/03以降準拠) ---
    % 単位: A/V
    COEFF_FCTF1 = 85.8 * 1e3;  % CH11
    COEFF_FCTF2 = 217.0 * 1e3; % CH12

    % --- プロットの準備 ---
    % 多数のプロットを並べるため、大きなウィンドウを作成
    figure('Position', [50, 50, 1600, 1000], 'Name', ['Individual Shots for Date: ', num2str(target_date)]);
    % タイルレイアウトの設定 (自動で列数を調整)
    t = tiledlayout('flow', 'TileSpacing', 'tight', 'Padding', 'compact');
    title(t, ['FCTF1 (Blue) & FCTF2 (Red) Waveforms - Date: ', num2str(target_date)]);
    xlabel(t, 'Time [\mus]', 'FontSize', 12);
    ylabel(t, 'Normalized Current (I/I_{max})', 'FontSize', 12);

    fprintf('Processing shots for date %d...\n', target_date);

    % --- ループ処理: 各ショットをプロット ---
    for s = 1:length(target_shots)
        shot_num = target_shots(s);

        % データ取得処理 (物理量変換 -> 極性反転まで)
        [time_axis, curr11, curr12] = get_processed_data_single(target_date, shot_num, directory_rogo, COEFF_FCTF1, COEFF_FCTF2);

        if isempty(time_axis)
            fprintf('Skipping shot %d (Data not found or error).\n', shot_num);
            continue;
        end

        % --- 正規化 (Normalization) ---
        % 形状比較のため、それぞれの最大値で規格化します
        % (絶対値を見たい場合はこの部分をコメントアウトしてください)
        norm11 = curr11 / max(abs(curr11));
        norm12 = curr12 / max(abs(curr12));

        % --- サブプロット作成 ---
        nexttile;
        hold on;

        % FCTF1 (CH11) を青でプロット
        p1 = plot(time_axis, norm11, 'b', 'LineWidth', 1.2, 'DisplayName', 'FCTF1');
        % FCTF2 (CH12) を赤でプロット
        p2 = plot(time_axis, norm12, 'r', 'LineWidth', 1.2, 'DisplayName', 'FCTF2');

        % グラフの装飾
        title(sprintf('Shot %d', shot_num), 'FontSize', 10);
        grid on;
        % 関心のある時間領域にズーム (必要に応じて調整してください)
        xlim([350, 650]);
        % Y軸の範囲を固定 (正規化後なので -0.5 ～ 1.2 程度)
        ylim([-0.5, 1.2]);
        
        % 最初のタイルだけに凡例を表示（スペース節約のため）
        if s == 1
            legend([p1, p2], 'Location', 'northeast', 'FontSize', 8);
        end

        hold off;
    end
    
    fprintf('Plotting completed.\n');
end

% --- データ取得・処理関数 (単一ショット用) ---
function [time_axis, ch11, ch12] = get_processed_data_single(date_val, shot_num, dir_path, c1, c2)
    time_axis = []; ch11 = []; ch12 = [];

    % パス生成
    [~, ~, filepath] = directory_generation_Rogowski_single(date_val, shot_num, dir_path);
    
    if ~isfile(filepath)
        return;
    end

    try
        % データ読み込み
        data = readmatrix(filepath, "FileType", "text");

        % 時間軸パラメータ設定 (1000us, 10MHz想定)
        aquisition_rate = 10;
        x_idx = 10 : 10 : 10000; % 1us から 1000us まで

        % カラム定義 (Wiki準拠: CH11, CH12)
        % データ形式が [時間, CH1, CH2, ..., CH16] と仮定
        col11 = 2 + 11;
        col12 = 2 + 12;

        % 指定時間範囲のデータを抽出
        raw11 = data(x_idx, col11);
        raw12 = data(x_idx, col12);

        % 1. 校正係数適用 (電圧 V -> 電流 A)
        val11 = raw11 * c1;
        val12 = raw12 * c2;

        % 2. ベースライン補正 (初期の平均値を引く)
        baseline_window = 1:20; % 最初の20点(2us分)を平均
        val11 = val11 - mean(val11(baseline_window));
        val12 = val12 - mean(val12(baseline_window));

        % 時間軸データの作成 (us単位)
        t_ax = x_idx' ./ aquisition_rate; % 列ベクトルにする

        % 3. 極性反転チェック (450us時点の値で判定)
        target_time = 450;
        % 450usに最も近いインデックスを探す
        [~, idx_450] = min(abs(t_ax - target_time));

        % 指定時刻の値が負であれば、全体を反転させる
        if val11(idx_450) < 0
            val11 = val11 * -1;
        end
        if val12(idx_450) < 0
            val12 = val12 * -1;
        end

        % 結果を返す
        time_axis = t_ax;
        ch11 = val11;
        ch12 = val12;

    catch ME
        fprintf('Error processing Shot %d: %s\n', shot_num, ME.message);
        % エラー時は空の配列が返される
    end
end

% --- パス生成ヘルパー関数 ---
function [date_str, shot_str, full_path] = directory_generation_Rogowski_single(date_val, shot_num, directory_rogo)
    date_str = num2str(date_val);
    % ショット番号を3桁の文字列に変換
    if shot_num < 10
        shot_str = ['00', num2str(shot_num)];
    elseif shot_num < 100
        shot_str = ['0', num2str(shot_num)];
    else
        shot_str = num2str(shot_num);
    end
    
    % ファイルパスを構築 (.rgw を優先し、なければ .txt を探す)
    full_path = fullfile(directory_rogo, date_str, [date_str, shot_str, '.rgw']);
    if ~isfile(full_path)
         full_path = fullfile(directory_rogo, date_str, [date_str, shot_str, '.txt']);
    end
end