clear;

f = 2.45e9; % マイクロ波の周波数 Hz
w = 2 * pi * f; % マイクロ波の角周波数 rad/s
T_e = 2; %電子温度 eV
mu_en = 3.75e8; % 電子-中世アルゴン粒子間の衝突周波数 /s
V_ioni = 15.75; % アルゴンの電離エネルギー eV
lambda_perp = 15e-2; %特性長 m
e = 1.602e-19; % 電子の電荷 C
m_e = 9.109e-31; % 電子の質量 kg

B = linspace(0, 0.2, 1000); %外部磁場

w_ce = e .*B ./ m_e; % 電子のサイクロトロン角波数

rho_ce2 = 2* m_e * T_e / e ./ B.^2; % 電子のサイクロトロン半径 m
D_eperp = rho_ce2 .* mu_en; % 電子の拡散係数 m^2/s

shu = mu_en ./((w+w_ce).^2+mu_en^2) + mu_en ./((w-w_ce).^2+mu_en^2);

E = sqrt(4 * m_e * V_ioni .* D_eperp ./ lambda_perp.^2 / e ./ shu);

[E_min, idx_min] = min(E);
B_min = B(idx_min);
fprintf('最小電場 E = %.2f V/m at B = %.4f T\n', E_min, B_min);

D = e * T_e / (m_e * mu_en);
E_nob = sqrt(2 * m_e * V_ioni * D * (w^2 + mu_en^2) /lambda_perp^2 / e / mu_en);
fprintf('外部磁場がない電場 E = %.2f V/m\n', E);


figure;
plot(B, E, 'r-', 'LineWidth', 2);
hold on;
plot(0,E_nob, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold off;
set(gca, 'YScale', 'log')
xlabel('B [T]');
ylabel('E [V/m]');

