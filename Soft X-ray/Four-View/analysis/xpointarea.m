function [Ep] = xpointarea(EE1, EE2, EE3, EE4, xPointList, t, data2D, Ep_previous)

t_idx = find(data2D.trange==t);
z = xPointList.z(t_idx);
r = xPointList.r(t_idx);

zmin = -0.17;
zmax = 0.17;
rmin = 0.06;
rmax = 0.33;

z_indices = linspace(zmin, zmax, size(EE1, 2)); % x軸のインデックス
r_indices = linspace(rmin, rmax, size(EE1, 1)); % y軸のインデックス

% 対象範囲内のインデックスを取得
dz = 0.05; % 横の長さ
dr = 0.05; % 縦の長さ

% z座標（x座標）に対応するインデックスを検索
z_range = z_indices >= z - dz/2 & z_indices <= z + dz/2;

% r座標（y座標）に対応するインデックスを検索
r_range = r_indices >= r - dr/2 & r_indices <= r + dr/2;

% その範囲の平均を計算
sub_matrix1 = EE1(r_range, z_range); % 範囲内の部分行列を抽出
sub_matrix2 = EE2(r_range, z_range);
sub_matrix3 = EE3(r_range, z_range);
sub_matrix4 = EE4(r_range, z_range);

E1 = mean(sub_matrix1(:)); % 平均値を計算
E2 = mean(sub_matrix2(:));
E3 = mean(sub_matrix3(:));
E4 = mean(sub_matrix4(:));

Ep = cat(1,E1,E2,E3,E4);
% Ep = cat(1,E1,E2,E3);
if isnan(Ep)
    disp('nan')
    Ep = Ep_previous;
end

end