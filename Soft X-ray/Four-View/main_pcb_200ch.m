addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment';

%%%%%%%%%%%%%%%%%%%%%%%%
%200ch用新規pcbプローブのみでの磁気面（Bz）
%dtacqのshot番号を直接指定する場合
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
% pathname.github=getenv('GITHUB_dir');%dtacqのrawdataの保管場所

%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:'};
dlgtitle = 'Input';
dims = [1 35];
definput = {'',''};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2)));

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
% date=230714;
T=searchlog(T,node,date);
% IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
n_data=numel(IDXlist);%計測データ数
shotlist=T.a039(IDXlist);
tfshotlist=T.a039_TF(IDXlist);
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1);

trange=400:600;%【input】計算時間範囲
n=50; %【input】rz方向のメッシュ数

doCheck = false;
% doCheck = true;

for i=1:n_data
    dtacq_num=dtacqlist;
    shot=shotlist(i);
    tfshot=tfshotlist;
    if shot == tfshot
        tfshot = 0;
    end
    i_EF=EFlist;
    TF=TFlist;
    if doCheck
        check_signal(date, dtacq_num, shot, tfshot, pathname);
    else
        plot_psi200ch(date, dtacq_num, shot, tfshot, pathname,n,i_EF,trange,TF);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
%以下、local関数
%%%%%%%%%%%%%%%%%%%%%%%%

function plot_psi200ch(date, dtacq_num, shot, tfshot, pathname, n,i_EF,trange,TF)
filename=strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat');
if exist(filename,"file")==0
    disp('No rawdata file -- Start generating!')
    rawdataPath = pathname.rawdata;
    save_dtacq_data(dtacq_num, shot, tfshot,rawdataPath)
    % return
end
disp('loading data');
load(filename,'rawdata');%1000×192

%正しくデータ取得できていない場合はreturn
if numel(rawdata)< 500
    return
end

%較正係数のバージョンを日付で判別
sheets = sheetnames('coeff200ch.xlsx');
sheets = str2double(sheets);
sheet_date=max(sheets(sheets<=date));

C = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
% ok = logical(C(:,14));
% P=C(:,13);
% coeff=C(:,12);
% zpos=C(:,9);
% rpos=C(:,10);
% probe_num=C(:,5);
% probe_ch=C(:,6);
% ch=C(:,7);
% d2p=C(:,15);
% d2bz=C(:,16);
% d2bt=C(:,17);

% coeffからの一部切り出しversion
C = C(1:192,:);
ok = logical(C(:,14));
P=C(:,13);
coeff=C(:,12);
zpos=C(:,9);
rpos=C(:,10);
probe_num=C(:,5);
probe_ch=C(:,6);
ch=C(:,7);
d2p=C(:,15);
d2bz=C(:,16);
d2bt=C(:,17);

b=rawdata.*coeff';%較正係数RC/NS
b=b.*P';%極性揃え
b=smoothdata(b,1);

%デジタイザchからプローブ通し番号順への変換
bz=zeros(1000,100);
bt=bz;
ok_bz=false(100,1);
ok_bt=ok_bz;
zpos_bz=zeros(100,1);
rpos_bz=zpos_bz;
zpos_bt=zpos_bz;
rpos_bt=zpos_bz;

for i=1:192
    if rem(ch(i),2)==1
        bz(:,ceil(ch(i)/2))=b(:,i);
        ok_bz(ceil(ch(i)/2))=ok(i);
        zpos_bz(ceil(ch(i)/2))=zpos(i);
        rpos_bz(ceil(ch(i)/2))=rpos(i);
    elseif rem(ch(i),2)==0
        bt(:,ch(i)/2)=b(:,i);
        ok_bt(ceil(ch(i)/2))=ok(i);
        zpos_bt(ceil(ch(i)/2))=zpos(i);
        rpos_bt(ceil(ch(i)/2))=rpos(i);
    end
end
[bz, ok_bz, ok_bz_plot] = ng_replace(bz, ok_bz, sheet_date);

ok_bt([4 5 6 7 8 9 10 15 21 27 30 42 43 49 53 69 84 87 92 94 95 96 97 98 99 100]) = false;

[zq,rq]=meshgrid(linspace(min(zpos_bz),max(zpos_bz),n),linspace(min(rpos_bz),max(rpos_bz),n));
grid2D=struct('zq',zq,'rq',rq);

clear zq rq

%data2Dcalc.m
r_EF   = 0.5 ;
n_EF   = 234. ;

if date<221119
    z1_EF   = 0.875;%0.68;
    z2_EF   = -0.830;%-0.68;
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
    'Br',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Jt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
    'Et',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),'trange',trange);

for i=1:size(trange,2)
    t=trange(i);
    %%Bzの二次元補間(線形fit)
    vq = bz_rbfinterp(rpos_bz, zpos_bz, grid2D, bz, ok_bz, t);
    B_z = -Bz_EF+vq;
    B_t = bz_rbfinterp(rpos_bt, zpos_bt, grid2D, bt, ok_bt, t);
%     B_t = pcb_nan_interp(rpos_bt, zpos_bt, grid2D, bt, ok_bt, t);
    
    for j = 1:100
        ir_bt = find(grid2D.rq(:,1) == rpos_bt(j));
        iz_bt = find(grid2D.zq(1,:) == zpos_bt(j));
        if (ok_bt(j))
            B_t(ir_bt,iz_bt) = bt(i,j);
        else
            B_t(ir_bt,iz_bt) = NaN;
        end
    end
    % B_t = inpaint_nans(B_t,0);

    %%PSI計算
    data2D.psi(:,:,i) = cumtrapz(grid2D.rq(:,1),2*pi*B_z.*grid2D.rq(:,1),1);
    %このままだと1/2πrが計算されてないので
    [data2D.Br(:,:,i),data2D.Bz(:,:,i)]=gradient(data2D.psi(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1)) ;
    data2D.Br(:,:,i)=-data2D.Br(:,:,i)./(2.*pi.*grid2D.rq);
    data2D.Bz(:,:,i)=data2D.Bz(:,:,i)./(2.*pi.*grid2D.rq);
    data2D.Bt(:,:,i)=B_t;
    data2D.Jt(:,:,i)= curl(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),data2D.Br(:,:,i))./(4*pi*1e-7);
end
data2D.Et=diff(data2D.psi,1,3).*1e+6;
%diffは単なる差分なので時間方向のsizeが1小さくなる %ステップサイズは1us
data2D.Et=data2D.Et./(2.*pi.*grid2D.rq);

ok_z = zpos_bz(ok_bz_plot); %z方向の生きているチャンネル
ok_r = rpos_bz(ok_bz_plot); %r方向の生きているチャンネル

if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
    return
end

figure('Position', [0 0 1500 1500],'visible','on');
start=60;
dt = 1;
%  t_start=470+start;
 for m=1:16 %図示する時間
     i=start+m.*dt; %end
     t=trange(i);
     subplot(4,4,m)
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Br(:,:,i),30,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),20,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none')
    contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Jt(:,:,i),30,'LineStyle','none')
%     contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Et(:,:,i),20,'LineStyle','none')
    colormap(jet)
    axis image
    axis tight manual
%     caxis([-0.8*1e+6,0.8*1e+6]) %jt%カラーバーの軸の範囲
%     caxis([-0.01,0.01])%Bz
     % clim([-0.1,0.1])%Bt
    % clim([-5e-3,5e-3])%psi
%     caxis([-500,400])%Et
%     colorbar('Location','eastoutside')
    %カラーバーのラベル付け
%     c = colorbar;
%     c.Label.String = 'Jt [A/m^{2}]';
    hold on
%     plot(grid2D.zq(1,squeeze(mid(:,:,i))),grid2D.rq(:,1))
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),[-20e-3:2e-3:40e-3],'black','LineWidth',1)
%     plot(grid2D.zq(1,squeeze(mid(opoint(:,:,i),:,i))),grid2D.rq(opoint(:,:,i),1),"bo")
%     plot(grid2D.zq(1,squeeze(mid(xpoint(:,:,i),:,i))),grid2D.rq(xpoint(:,:,i),1),"bx")
     % plot(ok_z,ok_r,"k.",'MarkerSize', 6)%測定位置
    hold off
    title(string(t)+' us')
%     xlabel('z [m]')
%     ylabel('r [m]')
 end

clearvars -except data2D grid2D shot;
filename = strcat('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/probedata/processed/a039_',num2str(shot),'.mat');
save(filename)
end

function save_dtacq_data(dtacq_num,shot,tfshot,rawdataPath)

% rawdataPath=getenv('rawdata_path'); %保存先

% %%%%実験オペレーションの取得
% DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
% T=getTS6log(DOCID);
% node='date';
% % pat=230707;
% pat=date;
% T=searchlog(T,node,pat);
% IDXlist=6;%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
% IDXlist = shot;
% n_data=numel(IDXlist);%計測データ数
% shotlist=T.a039(IDXlist);
% tfshotlist=T.a039_TF(IDXlist);
% EFlist=T.EF_A_(IDXlist);
% TFlist=T.TF_kV_(IDXlist);
% dtacqlist=39.*ones(n_data,1);

% dtacqlist=39;
% shotlist= 1819;%【input】dtacqの保存番号
% tfshotlist = 1817;

% dtacqlist=40;
% shotlist= 299;%【input】dtacqの保存番号
% tfshotlist = 297;

% date = 230706;%【input】計測日
% n=numel(shotlist);%計測データ数

%RC係数読み込み

% for i=1:n
%     dtacq_num=dtacqlist(i);
%     shot=shotlist(i);
%     tfshot=tfshotlist(i);
%     [rawdata]=getMDSdata(dtacq_num,shot,tfshot);%測定した生信号
%     save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat'),'rawdata');
%     if tfshot>0
%         [rawdata]=getMDSdata(dtacq_num,shot,0);
%         % save(strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata0');
%         save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata');
%     end
% end

% dtacq_num=dtacqlist(i);
% shot=shotlist(i);
% tfshot=tfshotlist(i);

[rawdata]=getMDSdata(dtacq_num,shot,tfshot);%測定した生信号
save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat'),'rawdata');
if tfshot==0
    [rawdata]=getMDSdata(dtacq_num,shot,0);
    % save(strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata0');
    save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata');
end

end

function check_signal(date, dtacq_num, shot, tfshot, pathname)
filename=strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat');
% filename=strcat(pathname.rawdata,'rawdata_noTF_dtacq',num2str(d_tacq),'.mat');
if exist(filename,"file")==0
    disp('No rawdata file -- Start generating!')
    rawdataPath = pathname.rawdata;
    save_dtacq_data(dtacq_num, shot, tfshot,rawdataPath)
    % return
end
load(filename,'rawdata');%1000×192

%正しくデータ取得できていない場合はreturn
if numel(rawdata)< 500
    return
end

%較正係数のバージョンを日付で判別
sheets = sheetnames('coeff200ch.xlsx');
sheets = str2double(sheets);
sheet_date=max(sheets(sheets<=date));

C = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
C = C(1:192,:);
ok = logical(C(:,14));
P=C(:,13);
coeff=C(:,12);
zpos=C(:,9);
rpos=C(:,10);
probe_num=C(:,5);
probe_ch=C(:,6);
ch=C(:,7);
d2p=C(:,15);
d2bz=C(:,16);
d2bt=C(:,17);

% coeff = coeff(1:192);

b=rawdata.*coeff';%較正係数RC/NS
b=b.*P';%極性揃え
b=smoothdata(b,1);

%デジタイザchからプローブ通し番号順への変換
bz=zeros(1000,100);
bt=bz;
ok_bz=true(1,100);
ok_bt=ok_bz;

for i=1:192
    if rem(ch(i),2)==1
        bz(:,ceil(ch(i)/2))=b(:,i);
        ok_bz(ceil(ch(i)/2))=ok(i);
    elseif rem(ch(i),2)==0
        bt(:,ceil(ch(i)/2))=b(:,i);
        ok_bt(ceil(ch(i)/2))=ok(i);
    end
end
ok_bz_plot=ok_bz;
% ok_bt([4 5 6 7 8 9 10 15 21 27 30 42 43 49 53 69 84 87 92 94 95 96 97 98 99 100]) = false;

% 221219ver
% Pcheck=[1	-1	1	1	-1	-1	-1	1	1	1	1	1	1	-1	-1	0	-1	-1	1	-1	1	0	1	-1	-1	1	-1	-1	1	-1	-1	1	-1	1	-1	1	-1	-1	-1	1	-1	-1	1	1	-1	-1	-1	-1	-1	-1	1	-1	-1	-1	-1	-1	-1	-1	-1	-1	1	1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	1	-1	1	-1	-1	-1	-1	1	-1	-1	1	-1	-1	1	-1	-1	1	1	1	-1	1	-1	-1	1	1	1	-1];
% bz=bz.*Pcheck;
% bz(:,[37 47 57])=-bz(:,[37 47 57]);
% bz(:,70)=-bz(:,70);
% for i=0:9
%     bz(:,[7 8 9 10]+10.*i)=-bz(:,[7 8 9 10]+10.*i);
% end
% ok_bz([5 6 11 16 20 22 31 33 39 49 63 66 71 72 79 80 95 100])=false;
% ok_bz(49)=true;
% bz(:,49)=-bz(:,49);

%生信号描画用パラメータ
r = 5;%プローブ本数＝グラフ出力時の縦に並べる個数
col = 10;%グラフ出力時の横に並べる個数
y_upper_lim = 0.05;%3e-3;%0.1;%縦軸プロット領域（b_z上限）
y_lower_lim = -0.05;%3e-3;%-0.1;%縦軸プロット領域（b_z下限）
t_start=1;%430;%455;%横軸プロット領域（開始時間）
t_end=1000;%550;%横軸プロット領域（終了時間）
% r_ch=col1+col2;%r方向から挿入した各プローブのチャンネル数

f1=figure;
f1.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bz_plot(col*(i-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i-1)+j),'r:')
        end   
        title(num2str(2.*(col*(i-1)+j)-1));
        xticks([t_start t_end]);
        ylim([y_lower_lim y_upper_lim]);
    end
end
sgtitle('Bz signal probe1-5')

f2=figure;
f2.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bz_plot(col*(i+r-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i+r-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i+r-1)+j),'r:')
        end   
        title(num2str(2.*(col*(i+r-1)+j)-1));
        xticks([t_start t_end]);
        ylim([y_lower_lim y_upper_lim]);
    end
end
sgtitle('Bz signal probe6-10')

f3=figure;
f3.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bt(col*(i-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i-1)+j),'r:')
        end   
        title(num2str(2.*(col*(i-1)+j)));
        xticks([t_start t_end]);
        %ylim([-0.2 0.2]);
        ylim([y_lower_lim y_upper_lim]);
    end
end
sgtitle('Bt signal probe1-5')

f4=figure;
f4.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bt(col*(i+r-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i+r-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i+r-1)+j),'r:')
        end   
        title(num2str(2.*(col*(i+r-1)+j)));
        xticks([t_start t_end]);
        %ylim([-0.2 0.2]);
        ylim([y_lower_lim y_upper_lim]);
    end
end
sgtitle('Bt signal probe6-10')

% saveas(gcf,strcat(pathname.save,'\date',num2str(date),'_dtacq',num2str(d_tacq),'_02','.png'))
% close

%横軸z, 縦軸Bzのプロット
% f5=figure;
% f5.WindowState = 'maximized';
% t=465;
% for i=1:10
%     zline=(1:10:91)+(i-1);
%     bz_zline=bz(t,zline);
%     bz_zline(ok_bz(zline)==false)=NaN;
%     plot([-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17],bz_zline,'-*')
%     clear bz_zline
%     hold on
% end
% hold off
% xlabel('z [m]')
% ylabel('Bz')
% yline(0,'k--')
% title(strcat('t=',num2str(t),' us'))
% legend('r1','r2','r3','r4','r5','r6','r7','r8','r9','r10',Location='eastoutside')

% bz1=[bz(t,1) bz(t,11) bz(t,21) bz(t,31) bz(t,41) bz(t,51) bz(t,61) bz(t,71) bz(t,81) bz(t,91)];
% bz2=[bz(t,2) bz(t,12) bz(t,22) bz(t,32) bz(t,42) bz(t,52) bz(t,62) bz(t,72) bz(t,82) bz(t,92)];
% bz3=[bz(t,3) bz(t,13) bz(t,23) bz(t,33) bz(t,43) bz(t,53) bz(t,63) bz(t,73) bz(t,83) bz(t,93)];
% bz4=[bz(t,4) bz(t,14) bz(t,24) bz(t,34) bz(t,44) bz(t,54) bz(t,64) bz(t,74) bz(t,84) bz(t,94)];
% bz5=[bz(t,5) bz(t,15) bz(t,25) bz(t,35) bz(t,45) bz(t,55) bz(t,65) bz(t,75) bz(t,85) bz(t,95)];
% bz6=[bz(t,6) bz(t,16) bz(t,26) bz(t,36) bz(t,46) bz(t,56) bz(t,66) bz(t,76) bz(t,86) bz(t,96)];
% bz7=[bz(t,7) bz(t,17) bz(t,27) bz(t,37) bz(t,47) bz(t,57) bz(t,67) bz(t,77) bz(t,87) bz(t,97)];
% bz8=[bz(t,8) bz(t,18) bz(t,28) bz(t,38) bz(t,48) bz(t,58) bz(t,68) bz(t,78) bz(t,88) bz(t,98)];
% bz9=[bz(t,9) bz(t,19) bz(t,29) bz(t,39) bz(t,49) bz(t,59) bz(t,69) bz(t,79) bz(t,89) bz(t,99)];
% bz10=[bz(t,10) bz(t,20) bz(t,30) bz(t,40) bz(t,50) bz(t,60) bz(t,70) bz(t,80) bz(t,90) bz(t,100)];

end

