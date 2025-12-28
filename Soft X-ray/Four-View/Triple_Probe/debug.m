% ==========================================================
% 診断用プロット: 電流比と理論限界の比較
% ==========================================================

% 電流比の計算 (あなたのコードと同じ定義)
Ratio_measured = (I1_values + I2_values) ./ (I1_values + I3_values);

% 理論的限界値 (V2=40, V3=30 の場合)
Ratio_Limit_Upper = V2 / V3; % 約 1.333
Ratio_Limit_Lower = 1.0;     % 1.0

% プロット
figure;
plot(time, Ratio_measured, 'k', 'LineWidth', 1.5); hold on;
yline(Ratio_Limit_Upper, 'r--', 'Limit (1.33)', 'LineWidth', 2);
yline(Ratio_Limit_Lower, 'b--', 'Limit (1.0)', 'LineWidth', 2);
hold off;

title(['Diagnosis: Current Ratio (Target: ' num2str(V2) 'V / ' num2str(V3) 'V)']);
ylabel('Ratio ( (I1+I2)/(I1+I3) )');
xlabel('Time [us]');
ylim([0.5 2.0]);
grid on;

% 判定メッセージ
total_points = length(Ratio_measured);
valid_points = sum(Ratio_measured > Ratio_Limit_Lower & Ratio_measured < Ratio_Limit_Upper);
fprintf('========================================\n');
fprintf('解析可能なデータ点数: %d / %d (%.1f%%)\n', valid_points, total_points, valid_points/total_points*100);
fprintf('※ 赤線より上、青線より下のデータは全て「解なし(NaN)」になります。\n');
fprintf('========================================\n');