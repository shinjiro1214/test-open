function v_end = get_electron_acceleration2(num_particle,Te,ne,Et,GFR,plotFlag)

%% 1. 定数の定義

% 物理定数
m_e = 9.1093837015e-31; % 電子の質量 (kg)
q_e = 1.602176634e-19; % 電子の電荷 (C)
k_B = 1.380649e-23;    % ボルツマン定数 (J/K)
epsilon0 = 8.8541878128e-12; % 真空の誘電率 (F/m)

% シミュレーションパラメータ
% N_particles = 1e5; % テスト粒子数
N_particles = num_particle; % テスト粒子数
% E0 = 400;           % 均一な電場の強さ (V/m)
E0 = Et;           % 均一な電場の強さ (V/m)
% dt = 1.0e-9;       % タイムステップ (s) - 例として1 ps
% t_end = 1.0e-6;     % シミュレーション終了時間 (s) - 例として5 ns (少し長くしてみる)

% 初期条件
% Te_eV = 10; % 電子温度 (eV)
Te_eV = Te;
Te_K = Te_eV * (q_e / k_B); % 電子温度 (K)
Bp = 1;
Bt = GFR;
% R = 0.02; %加速領域サイズ[m]
R = 0.05; %加速領域サイズ[m]

% l = R*sqrt(1+GFR^2);
timeLimit = 1e-7; %時間制限


% t_ra = sqrt(2*R*(1+GFR^2)*m_e/(q_e*E0*GFR));
% disp('escape time is: ');disp(t_ra);

% 初期位置 (全て原点から開始)
initial_x = zeros(N_particles, 1);

% 初期速度のサンプリング (1次元マクスウェル-ボルツマン分布)
% 標準偏差 sigma_v = sqrt(k_B * Te_K / m_e)
sigma_v = sqrt(3 * k_B * Te_K / m_e);
initial_v = sigma_v * randn(N_particles, 1); % 平均0、標準偏差 sigma_v のガウス分布
% initial_v = 5e6 + sigma_v * randn(N_particles, 1); % 平均u、標準偏差 sigma_v のガウス分布
initial_v = abs(initial_v); % 正の方向のみにリセット

% クーロン衝突モデルのパラメータ (例示。実際の値はプラズマ条件による)
% プラズマのパラメータを設定して、実際の衝突周波数を計算すると良い
% n_e = 1.0e20; % 電子密度 (m^-3) - 例として
n_e = ne;
% n_i = n_e;   % イオン密度 (m^-3) - プラズマは中性とする
Z = 1;       % イオンの電荷数
lambda_D = sqrt(epsilon0 * k_B * Te_K / (n_e * q_e^2)); % デバイ長
ln_Lambda = log(12 * pi * n_e * lambda_D^3); % クーロン対数 (近似式)

%% 2. 時間ベクトルの作成

% t = 0:dt:t_end; % 時間ベクトル
% num_steps_max = length(t); % ステップ数

%% 3. 結果を保存するための配列の初期化

num_steps_max = 1e3;

x = zeros(N_particles, num_steps_max); % 位置を保存する配列
v = zeros(N_particles, num_steps_max); % 速度を保存する配列
t = zeros(N_particles, num_steps_max); % 時間を保存する配列
l = nan(N_particles, num_steps_max); % 平均自由行程？を保存する配列
n_step = zeros(N_particles,1); % ステップ？衝突？回数を保存する配列
n_update = zeros(N_particles,1); % 粒子が更新された回数を保存する配列
Work_done = zeros(N_particles, 1);

% 【追加】損失エネルギー積算用 (Joule)
Loss_Collision_Total_J = 0;
Loss_Escape_Total_J = 0;

% 初期値を設定
x(:, 1) = initial_x;
v(:, 1) = initial_v;

%% 4. ループによる計算 (メインシミュレーション)

% 電子の加速度 (電場による) は一定
E_para = E0*Bt/sqrt((Bp^2+Bt^2));
% a_field = q_e * E0 / m_e;
a_field = q_e * E_para / m_e;

if a_field == 0
    v_end = initial_v;
    return;
end

% tau_v_init = (4*pi()*epsilon0^2*m_e^2*initial_v.^3)./(n_e*Z^2*q_e^4*ln_Lambda);
% disp(mean(tau_v_init));

% a_flag = ones(N_particles,1);
% f_v = figure;
% シミュレーションループ
for i = 1:(num_steps_max - 1)
    % if min(n_update) >= 1
    %     break;
    % end
    for p = 1:N_particles % 各粒子についてループ
        % なぜか速度が0になることがあるのでその場合は熱速度で初期化
        while v(p,i) == 0
            % v(p, i) = abs( sigma_v * randn() + 5e6);
            v(p, i) = abs( sigma_v * randn() );
        end
        % 時間過ぎてたら計算しない
        if t(p, i) > timeLimit
            continue;
        end

        % --- 既存の物理計算 ---
        tau_v = (4*pi()*epsilon0^2*m_e^2*abs(v(p, i)).^3)./(n_e*Z^2*q_e^4*ln_Lambda);
        
        % 速度の更新 (加速)
        v_next = v(p, i) + a_field * tau_v;
        
        % 位置の更新
        dx = (v(p, i)*tau_v + 0.5*a_field*tau_v^2) * Bp/sqrt(Bp^2+Bt^2);
        x_next = x(p, i) + dx;
        
        % 時間の更新
        t_next = t(p, i) + tau_v;
        
        % --- 仕事の計算 (Jouleに統一) ---
        % 力 F = qE
        ds = (v(p, i)*tau_v + 0.5*a_field*tau_v^2);
        Force = q_e * E_para; 
        dW_J = Force * ds;
        Work_done(p) = Work_done(p) + dW_J;

        % --- イベント判定と損失計算 ---
        
        is_collision = (rand() < 1-exp(-1)); % 衝突判定
        is_escape = (x_next > R && t_next < 1e-6); % 脱出判定

        if is_collision
            % [衝突損失]
            
            % 1. リセット前のエネルギー (J)
            E_pre = 0.5 * m_e * v_next^2;
            
            % 2. リセット (熱浴からの再サンプリング)
            v_reset = abs( sigma_v * randn() );
            
            % 3. リセット後のエネルギー (J)
            E_post = 0.5 * m_e * v_reset^2;
            
            % 4. 損失の積算 (持っていたE - 新しいE)
            Loss_Collision_Total_J = Loss_Collision_Total_J + (E_pre - E_post);
            
            % 状態の更新
            v(p, i+1) = v_reset;
            x(p, i+1) = 0; % 位置リセット
            n_step(p) = 0;
            n_update(p) = n_update(p) + 1;
            
        elseif is_escape
            % [脱出損失]
            
            % 1. リセット前のエネルギー (J)
            E_pre = 0.5 * m_e * v_next^2;
            
            % 2. リセット
            v_reset = abs( sigma_v * randn() );
            
            % 3. リセット後のエネルギー (J)
            E_post = 0.5 * m_e * v_reset^2;
            
            % 4. 損失の積算
            Loss_Escape_Total_J = Loss_Escape_Total_J + (E_pre - E_post);
            
            % 状態の更新
            v(p, i+1) = v_reset;
            x(p, i+1) = 0; % 位置リセット
            n_step(p) = 0;
            n_update(p) = n_update(p) + 1;
            
        else
            % [何もしない (加速継続)]
            v(p, i+1) = v_next;
            x(p, i+1) = x_next;
        end

        % 共通の更新
        t(p, i+1) = t_next;
        l(p,i) = v(p, i) * tau_v;
        n_step(p) = n_step(p) + 1;
        
        % ゼロ速度回避 (念のため)
        while v(p, i+1) == 0
            v(p, i+1) = abs( sigma_v * randn() );
        end
    end
end

% figure;plot(mean(l,2,'omitnan'),'*');
% disp(mean(l,'all','omitnan'));
% figure;plot(n_step,'*');
% disp(mean(n_step));

% figure;plot(max(t),'*');
% disp(mean(max(t)));

v_end = v(:,end);
for p = 1:N_particles
    while v_end(p) == 0
        v_end(p) = abs( sigma_v * randn() );
        % v_end(p) = abs( sigma_v * randn() + 5e6);
    end
end

%% 最終集計 (W/m^3 に換算)

% 係数: 密度 / 粒子数 / 時間
scale = n_e / N_particles / timeLimit; 

% 1. Input Power (電場からの投入)
P_Input = sum(Work_done) * scale;

% 2. Net Heating (系内に残ったエネルギー増分)
K_initial_J = 0.5 * m_e * initial_v.^2;
K_final_J = 0.5 * m_e * v(:, end).^2; % v_endのゼロ処理などは適宜行ってください
P_Net_Heating = (sum(K_final_J) - sum(K_initial_J)) * scale;

% 3. Collision Loss (衝突損失)
P_Loss_Collision = Loss_Collision_Total_J * scale;

% 4. Escape Loss (脱出損失)
P_Loss_Escape = Loss_Escape_Total_J * scale;

% 5. Ideal Energy Gain (理想的な加速によるエネルギーゲイン)
Ideal_Energy_Gain = q_e*Et*GFR*R * N_particles * scale;

% --- 結果表示 ---
fprintf('=== Energy Balance (Unit: W/m^3) ===\n');
fprintf('Total Input Power     : %e\n', P_Input);
fprintf('------------------------------------\n');
fprintf('  > Net Heating       : %e (%.1f%%)\n', P_Net_Heating, P_Net_Heating/P_Input*100);
fprintf('  > Collision Loss    : %e (%.1f%%)\n', P_Loss_Collision, P_Loss_Collision/P_Input*100);
fprintf('  > Escape Loss       : %e (%.1f%%)\n', P_Loss_Escape, P_Loss_Escape/P_Input*100);
fprintf('------------------------------------\n');
fprintf('Sum of Outputs        : %e\n', P_Net_Heating + P_Loss_Collision + P_Loss_Escape);
fprintf('Error (Input - Out)   : %e (%.1f%%)\n', P_Input - (P_Net_Heating + P_Loss_Collision + P_Loss_Escape), (P_Input - (P_Net_Heating + P_Loss_Collision + P_Loss_Escape))/P_Input*100);
fprintf('------------------------------------\n');
fprintf('Initial Energy        : %e\n', sum(K_initial_J)*scale);
fprintf('Final energy          : %e (%.1f%%)\n', sum(K_final_J)*scale, sum(K_final_J)/sum(K_initial_J)*100);
fprintf('------------------------------------\n');
fprintf('Ideal Energy Gain     : %e\n\n', Ideal_Energy_Gain);

if plotFlag
    v(v>2e7) = 2e7;
    [V_hist0,VEdge0] = histcounts(initial_v,'BinWidth',1e5);
    [V_hist1,VEdge1] = histcounts(v(:, end),'BinWidth',1e5);
    figure;
    semilogy(VEdge0(2:end),V_hist0,VEdge1(2:end),V_hist1,'LineWidth',2);
    legend({'before','after'},'Location','northeast');
    xlabel('Electron velocity [m/s]');
    ylabel('Number of particles');
    ax = gca;
    ax.FontSize = 18;
    title('Electron velocity distribution');

    initial_k = 0.5 * m_e * initial_v.^2 ./ q_e;
    k = 0.5 * m_e * v.^2 ./ q_e;
    [K_hist0, K_edge0] = histcounts(initial_k,'BinWidth',5);
    [K_hist1, K_edge1] = histcounts(k(:, end),'BinWidth',5);
    figure;
    semilogy(K_edge0(2:end),K_hist0,K_edge1(2:end),K_hist1,'LineWidth',2);
    legend({'before','after'},'Location','northeast');
    xlabel('Electron energy [eV]');
    ylabel('Number of particles');
    ax = gca;
    ax.FontSize = 18;
    title('Electron energy distribution');
    xlim([0 500]);
end

end