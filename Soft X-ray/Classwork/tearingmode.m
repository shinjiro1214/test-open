% kaの範囲を定義 (0に近い値は発散を避けるため除外)
ka = linspace(0, 5, 500);

% 1. 導体壁がない場合のΔ'a (問題で与えられた式)
% Δ'a = 2ka(exp(-2ka) - 2ka + 1) / (exp(-2ka) + 2ka - 1)
delta_prime_no_wall = (2*ka .* (exp(-2*ka) - 2*ka + 1)) ./ (exp(-2*ka) + 2*ka - 1);

% 2. 導体壁がある場合のΔ'a (導出された式)
% Δ'a = -2ka * coth(2ka)
delta_prime_wall = -2*ka .* coth(2*ka);

% グラフの描画
figure; % 新しい図ウィンドウを作成

% 導体壁なしのデータをプロット (赤実線)
plot(ka, delta_prime_no_wall, 'r-', 'LineWidth', 2);
hold on; % 現在のグラフに重ねて描画する設定

% 導体壁ありのデータをプロット (青破線)
plot(ka, delta_prime_wall, 'b--', 'LineWidth', 2);
hold off; % 重ねて描画する設定を解除

% グラフの装飾
title('テアリングモード安定性パラメータ \Delta''a の比較');
xlabel('ka');
ylabel('\Delta''a');
legend('導体壁なし', '導体壁あり (x=2a)');
grid on; % グリッド線を表示

% 軸の原点を交差させる
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';

% y軸の表示範囲を調整
ylim([-10 5]);