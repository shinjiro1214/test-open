%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1次元のプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% データの読み込み
date = 251220;
prompt = 'Enter the shot number: ';
dlgtitle = 'Shot Number';
dims = [1 30];
definput = {''};
% definput = {shotnum};
shotnum = inputdlg(prompt, dlgtitle, dims, definput);
shotnum = str2double(shotnum{1});

if shotnum < 10
    shotnum = ['00', num2str(shotnum)];
elseif shotnum < 100 
    shotnum = ['0', num2str(shotnum)];
else
    shotnum = [num2str(shotnum)];
end

% save_filepath = "G:\My Drive\lab\lab_data\mach_probe_rawdata";

% 研究室内にいる場合のファイルパス
% filepath = "\\NIFS\experiment\results\MachProbe\";
% 研究室外のファイルパス
% filepath = "G:\My Drive\lab\lab_data\mach_probe_rawdata";

filepath = getenv('NIFS_TRIPLE');
% filename = strcat(filepath, '\', num2str(date), '\ES_', num2str(date), shotnum, '.csv');
filename = fullfile(filepath,num2str(date), ['ES_', num2str(date), shotnum, '.csv']);

% ファイルの読み込み
test = readmatrix(filename);
index_start = 4500;
index_end = 7500;
% V2 = 20;
% V3 = 10;
V2 = 40;
V3 = 20;
% V2 = 20;
% V3 = 40;
% V2 = 30;
% V3 = 15;
% V2 = 10;
% V3 = 10;

% % if you use H gas. The A is 1.00.
% A = 1.00; % atomic weight
% if you use Ar gas. The A is 39.95.
A = 39.95;
% S_probe = 2.89*10^-5; % probe surface area [m2] Φ0.45mm electrode
S_probe = 1.4e-5;
I2_values = test(index_start:index_end, 36);
I3_values = test(index_start:index_end, 37);

% % 強化したスムージング
% I2_values = smoothdata(I2_values, 'movmean', 50);
% I3_values = smoothdata(I3_values, 'movmean', 50);

% % 強化したスムージング
% I2_values = smoothdata(I2_values, 'movmean', 10);
% I3_values = smoothdata(I3_values, 'movmean', 10);

% I1_values = I2_values + I3_values;
time = test(index_start:index_end, 1);

% q = 1.60217663 * 10^(-19); % electron charge
% kb = 1.380649 * 10^(-23); % boltzmann const
% K2ev = 11604.5250061657; % kelvin to eV
% mi = A * 1.66054 * 10^(-27); % ion mass

% % =================================================
% % 数値解法（Look-up Table法）への変更
% % =================================================

% % 1. 左辺（電流の比率）を実験データから計算
% % User equation: Ratio = (I1+I2)/(I1+I3)
% Ratio_measured = (I1_values + I2_values) ./ (I1_values + I3_values);

% % 2. Teの探索範囲を設定（例: 0.1 eV から 100 eV まで）
% Te_table = logspace(log10(0.1), log10(1000), 10000); % 細かく刻む

% % 3. そのTeに対応する右辺（理論値）の比率を計算しておく
% RHS_table = (1 - exp(-V2 ./ Te_table)) ./ (1 - exp(-V3 ./ Te_table));

% % =========================================================
% % 【追加修正】重複するデータ点（一意でない点）を削除する処理
% % =========================================================
% % unique関数で、値が重複している部分を取り除き、ソートします
% [RHS_unique, unique_idx] = unique(RHS_table);
% Te_unique = Te_table(unique_idx);

% % 4. 実測したRatioが、理論曲線のどこに当てはまるか逆引き（補間）する
% % ※ ここでは修正した RHS_unique と Te_unique を使います
% Te_calculated = interp1(RHS_unique, Te_unique, Ratio_measured, 'pchip', NaN);

% % % 結果の確認（最初の10点）
% % disp('Calculated Te (first 10 points):');
% % disp(Te_calculated(1:10));

% % プロットして確認
% figure;
% plot(time, Te_calculated);
% xlabel('Time');
% ylabel('Te [eV]');
% title('Electron Temperature Time Evolution');
% xlim([450 480]);
% grid on;

% % solve for Te
% syms I1 I2 I3 Te
% eqn = (I1+I2)/(I1+I3) == (1 - exp(-q*V2/(kb*Te)))/(1 - exp(-q*V3/(kb*Te)));
% Te_symbolic = solve(eqn,Te);
% % Calculate Te_values and check for division by zero
% try
%     Te_values = real(double(subs(Te_symbolic, {I1 I2 I3}, {I1_values I2_values I3_values})));
% catch
%     % Handle division by zero error
%     warning('Division by zero occurred while solving for Te. Applying previous valid value as fallback.');
%     Te_values = zeros(size(I1_values));
%     for i = 2:length(I1_values)
%         try
%             Te_values(i) = real(double(subs(Te_symbolic, {I1 I2 I3}, {I1_values(i) I2_values(i) I3_values(i)})));
%         catch
%             if i > 1
%                 Te_values(i) = Te_values(i - 1);
%             end
%         end
%     end
% end


% % solve for ne
% syms ne Te I2 I3
% eqn = exp(-0.5) * S_probe * ne * q * (kb * Te / mi)^0.5 == (I3 - I2*exp(-q*(V3-V2)/(kb*Te)))/(1-exp(-q*(V3-V2)/(kb*Te)));
% ne_symbolic = solve(eqn,ne);
% % Calculate ne_values and check for division by zero
% try
%     ne_values = real(double(subs(ne_symbolic, {Te I2 I3}, {Te_values I2_values I3_values})));
% catch
%     % Handle division by zero error
%     warning('Division by zero occurred while solving for ne. Applying previous valid value as fallback.');
%     ne_values = zeros(size(I2_values));
%     for i = 2:length(I2_values)
%         try
%             ne_values(i) = real(double(subs(ne_symbolic, {Te I2 I3}, {Te_values(i) I2_values(i) I3_values(i)})));
%         catch
%             if i > 1
%                 ne_values(i) = ne_values(i - 1);
%             end
%         end
%     end
% end


% plot
figure;
sgtitle(['shot',shotnum])

% subplot(3,1,1)
hold on;
plot(time, I2_values);
plot(time, I3_values);
legend({['I2 (V_p=', num2str(V2), 'V)'], ['I3 (V_p=', num2str(V3), 'V)']})
ylabel('Probe current [A]')
xlim([450, 500])
% ylim([0 10]);
ylim([-5 10]);
hold off
grid on