clear
% filename = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/probedata/processed/240111020_200ch.mat';
% filename = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/probedata/processed/240621055_200ch.mat';
% filename = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111020_200ch.mat';
filename = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111020.mat';
load(filename,'data2D','grid2D');
% data2D(:,:,68);

% X点周辺の切り出し
% [~,xpoint] = get_axis_x(grid2D,data2D,467);
[~,xpointList] = get_axis_x_multi(grid2D,data2D);
x_r = xpointList.r(data2D.trange==467);
x_z = xpointList.z(data2D.trange==467);
rq = grid2D.rq;
zq = grid2D.zq;
x_r_idx = knnsearch(rq(:,1),x_r);
x_z_idx = knnsearch(zq(1,:).',x_z);

newRangeR = x_r_idx-2:x_r_idx+2;
newRangeZ = x_z_idx-2:x_z_idx+2;

rq_n = rq(newRangeR,newRangeZ);
zq_n = zq(newRangeR,newRangeZ);
% 100×100になるよう内挿
r_new = linspace(min(rq_n(:,1)),max(rq_n(:,1)),100);
z_new = linspace(min(zq_n(1,:)),max(zq_n(1,:)),100);

[zq_new,rq_new] = meshgrid(z_new,r_new);

me = 9.11e-31; %kg
e = 1.6*10^(-19); %C

% t＝467μsのデータを使って電子の運動を追跡
% 1ステップごとに位置と速度を再計算
% 拡散領域の外（ガイド磁場に対する面内磁場の割合が一定値をこえるとき）に出るまでにどれだけの速度になるか見積もり

v_e = zeros(3,1000);
x_e = zeros(2,1000); %インデックスの配列

Et = data2D.Et(newRangeR,newRangeZ,68);
Bt = data2D.Bt(newRangeR,newRangeZ,68);
Bz = data2D.Bz(newRangeR,newRangeZ,68);
Br = data2D.Br(newRangeR,newRangeZ,68);

% 100×100になるよう内挿
Et_new = interp2(zq_n,rq_n,Et,zq_new,rq_new);
Bt_new = interp2(zq_n,rq_n,Bt,zq_new,rq_new);
Bz_new = interp2(zq_n,rq_n,Bz,zq_new,rq_new);
Br_new = interp2(zq_n,rq_n,Br,zq_new,rq_new);

% rq = grid2D.rq;
% zq = grid2D.zq;
dr = abs(rq_new(1,1)-rq_new(2,1));
dz = abs(zq_new(1,1)-zq_new(1,2));

% [~,xpoint] = get_axis_x(grid2D,data2D,467);
% x_e(1,1) = knnsearch(rq(:,1),xpoint.r);
% x_e(2,1) = knnsearch(zq(1,:).',xpoint.z);
% x_e(1,1) = knnsearch(rq_new(:,1),xpoint.r);
% x_e(2,1) = knnsearch(zq_new(1,:).',xpoint.z);

Bp = sqrt(Br_new.^2+Bz_new.^2);
[~,I] = min(Bp,[],'all');
[r_ind, z_ind] = ind2sub(size(Bt_new),I);
% x_e(1,1) = r_ind;
% x_e(2,1) = z_ind;

x_e(1,1) = r_ind+1;
x_e(2,1) = z_ind;

% X点近傍の磁場が0になるように微修正
Br_new = Br_new - Br_new(r_ind,z_ind);
Bz_new = Bz_new - Bz_new(r_ind,z_ind);
disp(Bp(r_ind,z_ind));
disp(Bt_new(r_ind,z_ind));
Bp = sqrt(Br_new.^2+Bz_new.^2);
disp(min(Bp,[],'all'));

% 衝突時間で計算を終わらせるとちょうど良さそう

v_e(3,1) = -1e6; %熱速度くらい

% 1nsごとにステップ
for i = 2:200
    r_idx = x_e(1,i-1);
    z_idx = x_e(2,i-1);
    % 電場によって加速（磁力線に沿って？）
    v_e(:,i) = v_e(:,i-1) + [0;0;1].*e*Et_new(r_idx,z_idx)/me*1e-12;
    % 速度は電場、位置は磁場で変更？
    % 磁場と速度の内積で移動距離を計算、ポロイダル平面に投影して位置を更新
    B = [Br_new(r_idx,z_idx),Bz_new(r_idx,z_idx),Bt_new(r_idx,z_idx)];
    norm_B = B./norm(B); %磁場方向の単位ベクトル
    dx = dot(v_e(:,i),norm_B);
    dx_2 = dx*norm_B(1:2);
    dr_idx = round(dx_2(1)/dr);
    dz_idx = round(dx_2(2)/dz);
    x_e(1,i) = r_idx+dr_idx;
    x_e(2,i) = z_idx+dz_idx;
    r_idx_new = x_e(1,i);
    z_idx_new = x_e(2,i);
    if ~ismember(r_idx_new,1:100) || ~ismember(z_idx_new,1:100)
        maxStep = i;
        break
    else
        gfr_new = Bt_new(r_idx_new,z_idx_new)/Bp(r_idx_new,z_idx_new);
        if gfr_new <= 0.3
            maxStep = i;
            break
        end
    end
end

if i == 200
    maxStep = 200;
end

step = 1:maxStep;
figure;
plot(step,vecnorm(v_e(:,1:maxStep)));
xlabel('step');ylabel('electron velocity [m/s]');

% figure;
% plot(z_new(x_e(2,1:maxStep-1)),r_new(x_e(1,1:maxStep-1)));
% xlabel('z');ylabel('r');

Ee = 0.5*me*v_e.^2./e;
figure;
plot(step,vecnorm(Ee(:,1:maxStep)));
xlabel('step');ylabel('electron energy [eV]');