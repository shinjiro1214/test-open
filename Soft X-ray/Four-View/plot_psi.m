function plot_psi(PCB, pathname)
shot = PCB.shot;
date = PCB.date;
IDXlist = PCB.idx;
trange = PCB.trange;
start = PCB.start;

if PCB.chtype == 2
    [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
else
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
end

if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
    return
end

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D, PCB); %時間ごとの磁気軸、X点を検索

% プロット部分
figure('Position', [0 0 1500 1500],'visible','off');

dt = 3;

for m=1:16 %図示する時間
    i=start+m.*dt; %end
    t=trange(i);
    subplot(4,4,m)
    switch PCB.dataType
        case 'psi'
            a = zeros(size(data2D.psi(:,:,i)));
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),a,100,'LineStyle','none');
            clim([-0.5e-2,0.5e-2]);
            dataTypeName = 'psi';
            colorLabel = 'Zpsi (Wb)';
        case 'Bz'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none');
            clim([-0.1,0.1]);
            dataTypeName = 'Bz';
            colorLabel = 'B_z (T)';
        case 'Bt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none');
            clim([0.05,0.3]);%ST
            % clim([-0.05,0.05]);%Spheromak
            dataTypeName = 'Bt';
            colorLabel = 'B_t (T)';
            % disp(max(max(data2D.Bt(:,:,i))))
        case 'Jt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Jt(:,:,i),30,'LineStyle','none');
            clim([-1e6,1e6]);
            dataTypeName = 'Jt';
            colorLabel = 'J_t (A/m^2)';
        case 'Jz'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Jz(:,:,i),30,'LineStyle','none');
            clim([-1e6,1e6]);
            dataTypeName = 'Jz';
            colorLabel = 'J_z (A/m^2)';
        case 'Jr'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Jr(:,:,i),30,'LineStyle','none');
            clim([-1e6,1e6]);
            dataTypeName = 'Jr';
            colorLabel = 'J_r (A/m^2)';
        case 'Et'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Et(:,:,i),100,'LineStyle','none');
            % clim([-8e-4,8e-4]);
            clim([-8e2 8e2]);
            dataTypeName = 'Et';
            colorLabel = 'E_t (V/m)';
        case  'Br'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Br(:,:,i),30,'LineStyle','none');
            clim([-0.07,0.07]);
            dataTypeName = 'Br';
            colorLabel = 'B_r (T)';
        case  'lBl'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bl(:,:,i),20,'LineStyle','none'); 
            clim([0,0.1]);
            dataTypeName = 'lBl';
            % disp(min(min(data2D.Bl(:,:,i))))
            colorLabel = 'B_l (T)';
        case  'dBzdt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dBzdt(:,:,i),20,'LineStyle','none'); 
            clim([0,0.01]);
            dataTypeName = 'dBzdt';
            colorLabel = 'dBzdt (T/s)';
        case  'dBtdt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dBtdt(:,:,i),20,'LineStyle','none'); 
            clim([0,0.01]);
            dataTypeName = 'dBtdt';
            colorLabel = 'dBtdt (T/s)';
        case  'dBrdt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dBrdt(:,:,i),20,'LineStyle','none'); 
            clim([0,0.01]);
            dataTypeName = 'dBrdt';
            colorLabel = 'dBrdt (T/s)';
        case  'dBdt_magnitude'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dBdt_magnitude(:,:,i),20,'LineStyle','none'); 
            clim([0,1e4]);
            dataTypeName = 'dBdt magnitude';
            colorLabel = 'dBdt magnitude (T/s)';
            disp(max(max(data2D.dBdt_magnitude(:,:,i))))
        case  'B parallel'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.B_parallel(:,:,i),20,'LineStyle','none'); 
            clim([0,0.01]);
            dataTypeName = 'B parallel';
            colorLabel = 'B parallel(T)';
        case   'dB parallel dt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dB_parallel_dt(:,:,i),20,'LineStyle','none'); 
            clim([0,0.01]);
            dataTypeName = 'dB parallel dt';
            colorLabel = 'dB parallel dt(T/s)';
        case  'curvature'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.curvature(:,:,i),20,'LineStyle','none'); 
            clim([0,50]);
            dataTypeName = 'curvature';
            colorLabel = 'curvature　(1/m)';
        case  'Bt_th'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,i),20,'LineStyle','none'); 
            clim([-0.2,0.2]);
            dataTypeName = 'Bt_th';
            colorLabel = 'Bt_th　(T)';
        case 'Lamor'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Lamor(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.Lamor(:,:,i))))
            dataTypeName = 'Lamor radius';
            colorLabel = 'Lamor Radius(m)';
        case'JxBr'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.JxBr(:,:,i),20,'LineStyle','none'); 
            clim([-2e5,2e5]);
            disp(max(max(data2D.JxBr(:,:,i))))
            dataTypeName = 'JxBr';
            colorLabel = 'JxBr(N/m^3)';
        case'JxBt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.JxBt(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.JxBt(:,:,i))))
            dataTypeName = 'JxBt';
            colorLabel = 'JxBt(N/m^3)';
        case'JxBz'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.JxBz(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.JxBz(:,:,i))))
            dataTypeName = 'JxBz';
            colorLabel = 'JxBz(N/m^3)';
        case'absJxB'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.absJxB(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.absJxB(:,:,i))))
            dataTypeName = 'absJxB';
            colorLabel = 'absJxB(N/m^3)';
        case'Vcurvature'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Vcurvature(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.Vcurvature(:,:,i))))
            dataTypeName = 'Vcurvature';
            colorLabel = 'Vcurvature(m/s*C/W)';
        case'VdeltaB'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.VdeltaB(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(data2D.VdeltaB(:,:,i))))
            dataTypeName = 'VdeltaB';
            colorLabel = 'VdeltaB(m/s*C/W)';
            
        
    end
    colormap('whitejet')
    axis image
    axis tight manual
    hold on
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
    plot(magAxisList.z(:,i),magAxisList.r(:,i),'ko');
    plot(xPointList.z(i),xPointList.r(i),'kx');
    hold on
    
    switch PCB.dataType
    case 'lBl'
        % ベクトルばをプロットするけど、まず間引きする
        step = 3;  % 例えば 2 とか 3 にすれば間隔が広くなる
        % 各点に対して色を決定
        color = zeros(size(data2D.Bt(:,:,i))); % 色の初期化

        % Btが負のときは緑、それ以外は赤
        color(data2D.Bt(:,:,i) < 0) = 1; % Bt < 0 の部分を 1 (緑)
        color(data2D.Bt(:,:,i) >= 0) = 2; % Bt >= 0 の部分を 2 (赤)

        % 矢印の始点
        zq_sub = grid2D.zq(1:step:end, 1:step:end);
        rq_sub = grid2D.rq(1:step:end, 1:step:end);

        % 各色で矢印を描画
        for idx = 1:numel(zq_sub)
            % 2D の座標 (zq_sub, rq_sub) をインデックスに変換
            [~, z_idx] = min(abs(grid2D.zq(1,:) - zq_sub(idx)));
            [~, r_idx] = min(abs(grid2D.rq(:,1) - rq_sub(idx)));
            
            if color(r_idx, z_idx) == 1
                % Bt < 0 の場合、緑色で矢印
                quiver(zq_sub(idx), rq_sub(idx), data2D.Bz(r_idx, z_idx, i), ...
                       data2D.Br(r_idx, z_idx, i), 4, 'Color', 'r');
            else
                % Bt >= 0 の場合、赤色で矢印
                quiver(zq_sub(idx), rq_sub(idx), data2D.Bz(r_idx, z_idx, i), ...
                       data2D.Br(r_idx, z_idx, i), 4, 'Color', 'g');
            end
        end
    end
    hold off
    title(string(t)+' us')

    c = colorbar;
    ylabel(c, colorLabel);
end

sgtitle(strcat(dataTypeName, ' diagram of shot', num2str(shot), ', on', num2str(date), ':', num2str(IDXlist(1))));

pathname_fig = getenv('savedata_path');
foldername_fig = strcat(pathname_fig,'/',num2str(date),'/',dataTypeName);
if exist(foldername_fig,'dir') == 0
    mkdir(foldername_fig);
end
savepath = fullfile(foldername_fig, strcat(dataTypeName, '(','shot',num2str(IDXlist(1)),')','.png'));
saveas(gcf,savepath);

end

%{
filename=strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat');
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
% sheets = sheetnames('coeff200ch.xlsx');
% sheets = str2double(sheets);
sheets = str2double(sheetnames('coeff200ch.xlsx'));
sheet_date=max(sheets(sheets<=date));

C_raw = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
C = C_raw(1:192,:); 
ok = logical(C(:,14));
P=C(:,13);
coeff=C(:,12);
zpos=C(:,9);
rpos=C(:,10);
% probe_num=C(:,5);
% probe_ch=C(:,6);
ch=C(:,7);
% d2p=C(:,15);
% d2bz=C(:,16);
% d2bt=C(:,17);

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
start=50;
dt = 4;
%  t_start=470+start;
 for m=1:16 %図示する時間
     i=start+m.*dt; %end
     t=trange(i);
     subplot(4,4,m)
%     contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none')
    contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),40,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Jt(:,:,i),30,'LineStyle','none')
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
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
%     plot(grid2D.zq(1,squeeze(mid(opoint(:,:,i),:,i))),grid2D.rq(opoint(:,:,i),1),"bo")
%     plot(grid2D.zq(1,squeeze(mid(xpoint(:,:,i),:,i))),grid2D.rq(xpoint(:,:,i),1),"bx")
     % plot(ok_z,ok_r,"k.",'MarkerSize', 6)%測定位置
    hold off
    title(string(t)+' us')
%     xlabel('z [m]')
%     ylabel('r [m]')
 end
filename = strcat(pathname.pre_processed_directory_path, '/a039_',num2str(shot),'.mat');
save(filename)
clearvars -except data2D grid2D shot;
%}

