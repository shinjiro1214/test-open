%%%%%%%%%%%%%%%%%%%%%%%%
% 200ch用新規pcbプローブのみでの磁気面（Bz）
% dtacqのshot番号を直接指定する場合
% 補間手順（scatteredInterpolant)
% 測定データ→死んだチャンネルを補間→プロット用meshgridに補間
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
clear all
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所



% 直接入力の場合
shot=[2477;956];%【input】dtacqの保存番号: shot_39 or [shot_39;shot_40]
%tfshot= [2417;896];
tfshot=zeros(size(shot));%【input】dtacqのTFのみ番号: tfshot_39 or [tfshot_39;tfshot_40]
date = 230831;%【input】計測日
i_EF = 0;%【input】EF電流
probecheck_mode = 0; % 【input】TF only の時は必ずtrue(1)にして生信号をcheck
interp_method = 1;
% 0: 'scatteredInterpolant', 1: 'bz_rbfinterp', 2: 'spline'


trange=400:800;%【input】計算時間範囲
n=40; %【input】rz方向のメッシュ数
r_shift = 0.00; % 【input】プローブの差し込み具合を変更した場合は記入

process_psi200ch(date,shot,tfshot,pathname,n,i_EF,trange,r_shift,probecheck_mode,interp_method);
disp('pcb:1/1')



%%%%%%%%%%%%%%%%%%%%%%%%
%以下、local関数
%%%%%%%%%%%%%%%%%%%%%%%%

function process_psi200ch(date, shot, tfshot, pathname, n,i_EF,trange, r_shift,probecheck_mode,interp_method)

%較正係数のバージョンを日付で判別
sheets = sheetnames('coeff200ch.xlsx');
sheets = str2double(sheets);
sheet_date = max(sheets(sheets <= date)); % 計測日以前で最新バージョンの較正係数を使用
C = readmatrix('coeff200ch.xlsx', 'Sheet', num2str(sheet_date)); % 較正係数の読み込み
ok = logical(C(:,14)); % chが生きていれば1，死んでいれば0
dtacq_num_list = C(:,1);
dtaq_ch = C(:,2);
polarity=C(:,13); % 極性
coeff=C(:,12); % 較正係数 RC/NS
zpos=C(:,9); % z位置[m]
rpos=C(:,10)+r_shift; % r位置[m]
ch=C(:,7); % デジタイザch番号

if ismember(39,dtacq_num_list)
    filename39 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(39),'_shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
    filename39_extf = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(39),'_shot',num2str(tfshot(1)),'_tfshot0.mat');
    if exist(filename39,"file")==0
        % disp(['File:',filename39,' does not exit']);
        % return
        disp(['File: shot',num2str(shot(1)),' does not exist: start save_dtacqdata'])
        res = save_dtacqdata_func(shot,tfshot);
    end
    if tfshot(1) ~= 0 && exist(filename39_extf,"file")==0
        disp(['File:',filename39_extf,' does not exit']);
        return
    end
    a039_raw = importdata(filename39);
    if tfshot(1) == 0
        a039_raw_extf = zeros(size(a039_raw));
    else
        a039_raw_extf = importdata(filename39_extf);
    end
end
if ismember(40,dtacq_num_list)
    filename40 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(40),'_shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
    filename40_extf = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(40),'_shot',num2str(tfshot(2)),'_tfshot0.mat');
    if exist(filename40,"file")==0
        disp(['File:',filename40,' does not exist']);
        return
    end
    if tfshot(2)~= 0 && exist(filename40_extf,"file")==0
        disp(['File:',filename40_extf,' does not exist']);
        return
    end
    a040_raw = importdata(filename40);
    if tfshot(2) == 0
        a040_raw_extf = zeros(size(a040_raw));
    else
        a040_raw_extf = importdata(filename40_extf);
    end
end

raw = zeros(1000,length(dtaq_ch));
raw_extf = zeros(1000,length(dtaq_ch));
for i = 1:length(dtaq_ch)
    if dtacq_num_list(i) == 39
        raw(:,i) = a039_raw(:,dtaq_ch(i));
        raw_extf(:,i) = a039_raw_extf(:,dtaq_ch(i));
    elseif dtacq_num_list(i) == 40
        raw(:,i) = a040_raw(:,dtaq_ch(i));
        raw_extf(:,i) = a040_raw_extf(:,dtaq_ch(i));
    end
end

b=raw.*coeff';%較正係数RC/NS
b=b.*polarity';%極性揃え
b_extf = raw_extf.*coeff';
b_extf = b_extf.*polarity';

%デジタイザchからプローブ通し番号順への変換
bz=zeros(1000,140);
bt=bz;
bz_ex = bz;
bt_ex = bz;
ok_bz=false(140,1);
ok_bt=ok_bz;
zpos_bz=zeros(140,1);
rpos_bz=zpos_bz;
zpos_bt=zpos_bz;
rpos_bt=zpos_bz;

%digital filter 移動平均フィルター（ノイズを含む信号の平滑化）
windowSize = 3;
bb = (1/windowSize)*ones(1,windowSize);
aa = 1;

for i=1:length(ch)
    b(:,i) = filter(bb,aa,b(:,i));
    b(:,i) = b(:,i) - mean(b(1:40,i));
    b_extf(:,i) = filter(bb,aa,b_extf(:,i));
    b_extf(:,i) = b_extf(:,i) - mean(b_extf(1:40,i));
    if rem(ch(i),2)==1
        bz(:,ceil(ch(i)/2))=b(:,i);
        bz_ex(:,ceil(ch(i)/2)) = b_extf(:,i);
        ok_bz(ceil(ch(i)/2))=ok(i);
        zpos_bz(ceil(ch(i)/2))=zpos(i);
        rpos_bz(ceil(ch(i)/2))=rpos(i);
    elseif rem(ch(i),2)==0
        bt(:,ch(i)/2)=b(:,i);
        bt_ex(:,ch(i)/2) = b_extf(:,i);
        ok_bt(ceil(ch(i)/2))=ok(i);
        zpos_bt(ceil(ch(i)/2))=zpos(i);
        rpos_bt(ceil(ch(i)/2))=rpos(i);
    end
end

% zprobepcb    = [-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17];
zprobepcb    = [-0.2975,-0.255,-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17,0.255,0.2975];
rprobepcb    = [0.06,0.09,0.12,0.15,0.18,0.21,0.24,0.27,0.30,0.33]+r_shift;
rprobepcb_t  = [0.07,0.10,0.13,0.16,0.19,0.22,0.25,0.28,0.31,0.34]+r_shift;
[zq,rq]      = meshgrid(linspace(min(zpos_bz),max(zpos_bz),n),linspace(min(rpos_bz),max(rpos_bz),n));
% [zq,rq]      = meshgrid(zprobepcb,rprobepcb);
% [zq_t,rq_t]  = meshgrid(zprobepcb,rprobepcb_t);
[zq_probepcb,rq_probepcb]=meshgrid(zprobepcb,rprobepcb);
ok_bt_matrix = false(length(rprobepcb),length(zprobepcb));
ok_bz_matrix = false(length(rprobepcb),length(zprobepcb));
for i = 1:length(ok_bt)
    if rpos_bt(i) > (r_shift)
        index_r = (abs(rpos_bt(i)-rprobepcb_t)<0.001);index_z = (zpos_bt(i)==zprobepcb);
        ok_bt_matrix = ok_bt_matrix + rot90(index_r,-1)*index_z*ok_bt(i);
    end
    index_r = (abs(rpos_bz(i)-rprobepcb)<0.001);index_z = (zpos_bz(i)==zprobepcb);
    ok_bz_matrix = ok_bz_matrix + rot90(index_r,-1)*index_z*ok_bz(i);
end

grid2D=struct(...
    'zq',zq,...
    'rq',rq,...
    'zprobepcb',zprobepcb,...
    'rprobepcb',rprobepcb,...
    'rprobepcb_t',rprobepcb_t,...
    'ok_bz_matrix',ok_bz_matrix,...
    'ok_bt_matrix',ok_bt_matrix);
grid2D_probe = struct('zq',zq_probepcb,'rq',rq_probepcb,'rq_t',rprobepcb_t);

clear zq rq rq_t zprobepcb rprobepcb zq_probepcb rq_probepcb rprobepcb_t ok_bz_matrix ok_bt_matrix

%% probecheck_script

if probecheck_mode
 probecheck_script;
end

%% calculate data

%data2Dcalc.m
r_EF   = 0.5 ;
n_EF   = 234. ;

if date<221119
    z1_EF   = 0.68;
    z2_EF   = -0.68;
else
    z1_EF   = 0.78;
    z2_EF   = -0.78;
end
[Bz_EF,~] = B_EF(z1_EF,z2_EF,r_EF,i_EF,n_EF,grid2D.rq,grid2D.zq,false);
clear EF r_EF n_EF i_EF z_EF

data2D=struct(...
    'psi',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Bz',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Bt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Bt_ex',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Br',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Babs',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Jt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Et',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Lambda',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'trange',trange);


%% **************** angle correction **************** 
% 死んだchの内挿 → プローブ1本ごとに角度補正 → プロット用gridへの内挿
% 内挿は Delaunay 三角形分割による
sheets_angle = sheetnames('angle.xlsx');sheets_angle = str2double(sheets_angle);
sheet_angle_date=max(sheets_angle(sheets_angle<=date));
angle_file = readmatrix('angle.xlsx','Sheet',num2str(sheet_angle_date));
angle_zpos = angle_file(1,2:end);
angle = angle_file(2,2:end);
sin_lis = sin(angle);
cos_lis = cos(angle);
sin_matrix = repmat(sin(angle),10,1);%sin_matrix(1:10,:) = zeros(10,10);
cos_matrix = repmat(cos(angle),10,1);%cos_matrix(1:10,:) = ones(10,10);

% B_z_calibrated = zeros(length(grid2D.rprobepcb),length(grid2D.zprobepcb),length(trange));
% B_t_calibrated = zeros(length(grid2D.rprobepcb_t),length(grid2D.zprobepcb),length(trange));
% B_t_ex_calibrated = zeros(length(grid2D.rprobepcb_t),length(grid2D.zprobepcb),length(trange));

bz_ok = bz(:,ok_bz);
zpos_bz_ok = zpos_bz(ok_bz);
rpos_bz_ok = rpos_bz(ok_bz);
bz_ex_ok = bz_ex(:,ok_bz);
bt_ok = bt(:,ok_bt);
zpos_bt_ok = zpos_bt(ok_bt);
rpos_bt_ok = rpos_bt(ok_bt);
bt_ex_ok = bt_ex(:,ok_bt);

B_z_noncalib = zeros(length(trange),size(bz,2));
B_t_noncalib = B_z_noncalib;
B_z_ex_noncalib = B_z_noncalib;
B_t_ex_noncalib = B_z_noncalib;

B_z_calibrated_restored = bz;
B_t_calibrated_restored = bt;
B_t_ex_calibrated_restored = bt_ex;

Fz = scatteredInterpolant(zpos_bz_ok, rpos_bz_ok, bz_ok(1,:)');
Ft = scatteredInterpolant(zpos_bt_ok, rpos_bt_ok, bt_ok(1,:)');
Fz_ex = scatteredInterpolant(zpos_bz_ok, rpos_bz_ok, bz_ex_ok(1,:)');
Ft_ex = scatteredInterpolant(zpos_bt_ok, rpos_bt_ok, bt_ex_ok(1,:)');
for i=1:length(trange)
    t=trange(i);
    Fz.Values = bz_ok(t,:)';
    Ft.Values = bt_ok(t,:)';
    Fz_ex.Values = bz_ex_ok(t,:)';
    Ft_ex.Values = bt_ex_ok(t,:)';
    B_z_noncalib(i,:) = Fz(zpos_bz, rpos_bz)';
    B_t_noncalib(i,:) = Ft(zpos_bt, rpos_bt)';
    B_z_ex_noncalib(i,:) = Fz_ex(zpos_bz, rpos_bz)';
    B_t_ex_noncalib(i,:) = Ft_ex(zpos_bt, rpos_bt)';
end



for i=1:length(angle) % プローブ1本(10ch)ごとに角度較正
    idx = 10*(i-1)+1:10*i; % プローブのidxリスト
    cos_val = cos_lis(angle_zpos == zpos_bz(10*i));
    sin_val = sin_lis(angle_zpos == zpos_bz(10*i));
    B_z_calibrated_restored(trange,idx) = B_z_noncalib(:,idx).*cos_val - B_t_noncalib(:,idx).*sin_val;
    B_t_calibrated_restored(trange,idx) = B_z_noncalib(:,idx).*sin_val + B_t_noncalib(:,idx).*cos_val;
    B_t_ex_calibrated_restored(trange,idx) = B_z_ex_noncalib(:,idx).*sin_val + B_t_ex_noncalib(:,idx).*cos_val;
end



B_z_splined = zeros(length(grid2D.rprobepcb),length(grid2D.zprobepcb),length(trange));
B_t_splined = zeros(length(grid2D.rprobepcb_t),length(grid2D.zprobepcb),length(trange));
B_t_ex_splined = zeros(length(grid2D.rprobepcb_t),length(grid2D.zprobepcb),length(trange));

for ch = 1:size(B_z_noncalib,2)
    B_z_splined(grid2D.rprobepcb==rpos_bz(ch),grid2D.zprobepcb==zpos_bz(ch),:) = B_z_calibrated_restored(trange,ch);
    B_t_splined(grid2D.rprobepcb_t==rpos_bt(ch),grid2D.zprobepcb==zpos_bt(ch),:) = B_t_calibrated_restored(trange,ch);
    B_t_ex_splined(grid2D.rprobepcb_t==rpos_bt(ch),grid2D.zprobepcb==zpos_bt(ch),:) = B_t_ex_calibrated_restored(trange,ch);
end

%% **************** interpolation and grid 2D calculation **************** 
% 3 methods:scatterInterpolant or bz_rbfinterp or spline
% bz_rbfinterp: linear, multiquadric...



 Fz_grid = scatteredInterpolant(zpos_bz, rpos_bz, B_z_calibrated_restored(1,:)');
 Ft_grid = scatteredInterpolant(zpos_bt, rpos_bt, B_t_calibrated_restored(1,:)');
 Ft_ex_grid = scatteredInterpolant(zpos_bt, rpos_bt, B_t_ex_calibrated_restored(1,:)');


 for i=1:length(trange)
    t=trange(i);
    
    if interp_method == 0 %'scatteredInterpolant'
            Fz_grid.Values = B_z_calibrated_restored(t,:)';
            Ft_grid.Values = B_t_calibrated_restored(t,:)';
            Ft_ex_grid.Values = B_t_ex_calibrated_restored(t,:)';

            grid_z_lis = reshape(grid2D.zq,[],1);
            grid_r_lis = reshape(grid2D.rq,[],1);
            vq = reshape(Fz_grid(grid_z_lis,grid_r_lis),[n,n]);
            B_z = -Bz_EF + vq;
            B_t = reshape(Ft_grid(grid_z_lis,grid_r_lis),[n,n]);
            B_t_ex = reshape(Ft_ex_grid(grid_z_lis,grid_r_lis),[n,n]);

    elseif interp_method == 1 %'bz_rbfinterp'
            %Bzの二次元補間(線形fit)
            vq = bz_rbfinterp(rpos_bz, zpos_bz, grid2D, bz, ok_bz, t);
            B_z = -Bz_EF+vq;
            B_t = bz_rbfinterp(rpos_bt, zpos_bt, grid2D, bt, ok_bt, t);
            B_t_ex = bz_rbfinterp(rpos_bt-0.01, zpos_bt, grid2D, B_t_ex_calibrated_restored, ok_bt, t);

    elseif interp_method == 2 %'spline'
         vq = interp2(grid2D_probe.zq,grid2D_probe.rq,B_z_splined(:,:,i),grid2D.zq,grid2D.rq, 'spline');
         B_z = -Bz_EF+vq;
         B_t = interp2(grid2D_probe.zq,grid2D_probe.rq_t,B_t_splined(:,:,i),grid2D.zq,grid2D.rq, 'spline');
         B_t_ex = interp2(grid2D_probe.zq,grid2D_probe.rq_t,B_t_ex_splined(:,:,i),grid2D.zq,grid2D.rq, 'spline');   
    end

            

            % PSI計算
            % data2D.psi(:,:,i) = cumtrapz(grid2D.rq(:,1),2*pi*B_z.*grid2D.rq(:,1),1);
            data2D.psi(:,:,i) = flip(get_psi(flip(B_z,1),flip(grid2D.rq(:,1)),1),1);

            %このままだと1/2πrが計算されてないので
            [data2D.Br(:,:,i),data2D.Bz(:,:,i)]=gradient(data2D.psi(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1)) ;
            data2D.Br(:,:,i)=-data2D.Br(:,:,i)./(2.*pi.*grid2D.rq);
            data2D.Bz(:,:,i)=data2D.Bz(:,:,i)./(2.*pi.*grid2D.rq);
            data2D.Bt(:,:,i)=B_t;
            data2D.Bt_ex(:,:,i)=B_t_ex;
            data2D.Jt(:,:,i)= curl(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),data2D.Br(:,:,i))./(4*pi*1e-7);
            data2D.Lambda(:,:,i) = (2*pi*grid2D.rq.*data2D.Bt(:,:,i))./(data2D.psi(:,:,i));
            data2D.Babs(:,:,i) = sqrt(data2D.Br(:,:,i).^2 + data2D.Bz(:,:,i).^2 + (data2D.Bt(:,:,i)+data2D.Bt_ex(:,:,i)).^2);
 
 end
% ***********************************************

if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
    return
end

clearvars -except data2D grid2D shot date;
filename = strcat('C:\Users\uswk0\OneDrive\ドキュメント\data\pre_processed\a039_',num2str(shot(1)),'.mat');%保存ファイル名
save(filename)
end