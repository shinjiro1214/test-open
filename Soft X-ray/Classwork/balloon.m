% ワークスペースと図をクリア
clear;
clc;
close all;

% δW の数式を定義 (元の s, alpha の順で定義)
deltaW = @(s, alpha) (pi^2/6 - 1/4)*s.^2 - (13/6)*s.*alpha + alpha.^2 - alpha + 1/2;

% プロットの準備
figure;
hold on; % 複数のプロットを重ね書きする設定

% 1. 不安定領域を塗りつぶす
%    前回と同様に s から α の上下限を計算
s_range = linspace(0.243, 2, 200);
discriminant = (-(13/6)*s_range - 1).^2 - 4*1*((pi^2/6 - 1/4)*s_range.^2 + 1/2);
alpha_upper = ( (13/6)*s_range + 1 + sqrt(discriminant) ) / 2;
alpha_lower = ( (13/6)*s_range + 1 - sqrt(discriminant) ) / 2;

% fill関数で塗りつぶす。x座標にalpha, y座標にsを指定する
fill([alpha_lower, fliplr(alpha_upper)], [s_range, fliplr(s_range)], ...
     [1 0.8 0.8], 'EdgeColor', 'none', 'DisplayName', '不安定領域 (δW < 0)');

% 2. 安定限界の線をプロット
%    fimplicitの変数を (alpha, s) の順で扱うように無名関数 @(alpha,s) を作成
fimplicit(@(alpha,s) deltaW(s,alpha), [0 4 0 2], 'r', 'LineWidth', 2, 'DisplayName', '安定限界 (δW = 0)');

% グラフの体裁を整える
hold off;
grid on;
box on;
xlim([0 4]);
ylim([0 2]);
xlabel('\alpha', 'FontSize', 12); % x軸ラベルをalphaに変更
ylabel('s', 'FontSize', 12);       % y軸ラベルをsに変更
title('バルーニング安定限界', 'FontSize', 14);
legend('Location', 'northwest');

% 見やすくするために軸のフォントサイズなどを調整
ax = gca;
ax.FontSize = 11;