function v_end = get_electron_acceleration(num_particle,Te,ne,Et,GFR,plotFlag)

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
R = 0.02; %加速領域サイズ[m]

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
        if t(p, i) > 1e-7
            continue;
        end
        % 衝突判定 (モンテカルロ法)
        % 速度に基づいて衝突時間を計算
        tau_v = (4*pi()*epsilon0^2*m_e^2*abs(v(p, i)).^3)./(n_e*Z^2*q_e^4*ln_Lambda);
        % tau_v = (4*pi()*epsilon0^2*m_e^2*abs(v(p, i)).^3)./(n_e*(Z+2)*q_e^4*ln_Lambda);
        % if v(p, i) ~= 0
        %     tau_v = (4*pi()*epsilon0^2*m_e^2*abs(v(p, i)).^3)./(n_e*Z^2*q_e^4*ln_Lambda);
        % else
        %     % 速度が0になった粒子は熱速度で再度散乱させる
        %     v(p, i+1) = abs( sigma_v * randn() );
        %     x(p, i+1) = 0;
        %     tau_v = 1e-6/num_steps_max;
        %     t(p, i+1) = t(p, 1) + tau_v;
        %     continue;
        % end

        % 速度の更新 (電場による加速)
        v(p, i+1) = v(p, i) + a_field * tau_v;
        % 位置の更新
        x(p, i+1) = x(p, i) + (v(p, i)*tau_v+0.5*a_field*tau_v^2) * Bp/sqrt(Bp^2+Bt^2);
        % 時間の更新
        % t(p, i+1) = t(p, 1) + tau_v;
        t(p, i+1) = t(p, i) + tau_v;
        % 平均自由行程？の更新
        l(p,i) = v(p, i) * tau_v;
        % ステップ？衝突？回数の更新
        n_step(p) = n_step(p) + 1;

        % P_v = nu_v * dt;
        % P_v = nu_v * dt * (1-exp(-1));
        % 発生した場合は、速度を0にリセット (簡易モデル)
        % もし速度の散乱を考慮するなら、ここで散乱後の速度を計算
        if rand() < 1-exp(-1)
            % 熱平衡速度に戻す:
            v(p, i+1) = abs( sigma_v * randn() );
            % v(p, i+1) = abs( sigma_v * randn() + 5e6);
            % 位置もリセット
            x(p, i+1) = 0;
            n_step(p) = 0;
            n_update(p) = n_update(p) + 1;
        elseif x(p, i+1) > R && t(p, i+1) < 1e-6
        % elseif x(p, i+1) > R
            % 外に出ても初期値でリセット
            v(p, i+1) = abs( sigma_v * randn() );
            % v(p, i+1) = abs( sigma_v * randn() + 5e6);
            x(p, i+1) = 0;
            n_step(p) = 0;
            n_update(p) = n_update(p) + 1;
        end

        % もし速度が0なら熱速度で再拡散（0でなくなるまで？）
        while v(p, i+1) == 0
            v(p, i+1) = abs( sigma_v * randn() );
            % v(p, i+1) = abs( sigma_v * randn() + 5e6);
        end

        % % 速度の更新 (電場による加速)
        % v(p, i+1) = v(p, i) + a_field * dt * a_flag(p);

        % % 位置の更新
        % x(p, i+1) = x(p, i) + (v(p, i)*dt+0.5*a_field*dt^2) * Bp/sqrt(Bp^2+Bt^2) * a_flag(p);
        % if x(p, i+1) > R
        %     v(p, i+1) = sigma_v * randn();
        %     % a_flag(p) = 0;
        % end
    end
    % if mod(i,100) == 99
    %     % 速度分布を更新し、プロット
    %     v_plot = v(:,i);
    %     v_plot(v_plot>2e7) = 2e7;
    %     [N,edge] = histcounts(v_plot,'BinWidth',1e5);
    %     figure(f_v);semilogy(edge(2:end),N,'LineWidth',2);pause(0.5);
    %     disp(numel(find(v_plot==0)))
    % end
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
% disp(numel(find(v_end==0)));

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