function plot_psi(PCB, pathname)
shot = PCB.shot;
date = PCB.date;
IDXlist = PCB.idx;
trange = PCB.trange;
start = PCB.start;

if PCB.chtype == 2
    [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
else
    % profile on
    t_process280ch = tic;
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
    time_plot = toc(t_process280ch);
    disp(['process_PCBdata_280ch: ', num2str(time_plot), ' sec']);
    % profile off
    % profile viewer
end

if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
    return
end

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D, PCB); %時間ごとの磁気軸、X点を検索

% プロット部分
% figure('Position', [0 0 1500 1500], 'Visible', 'off');
figure('Position', [0 0 1500 1500], 'Visible', 'off');

dt = PCB.dt;

disp("plotting begins")
t_plot_start = tic; % プロット作成時間の計測開始

for m=1:16 %図示する時間
    i=start+1+(m-1).*dt; %end
    t=trange(i);
    subplot(4,4,m)
    switch PCB.dataType
        case 'psi'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),100,'LineStyle','none');
            % pcolor(grid2D.zq, grid2D.rq, data2D.psi(:,:,i));
            % shading interp;

            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.psi(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため
            
            clim([-1e-2,1e-2]);
            dataTypeName = 'psi';
            colorLabel = 'Zpsi (Wb)';
        case 'Bz'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none');
            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.Bz(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため

            clim([-0.1,0.1]);
            dataTypeName = 'Bz';
            colorLabel = 'B_z (T)';
        case 'Bt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),30,'LineStyle','none');
            % pcolor(grid2D.zq, grid2D.rq, data2D.Bt(:,:,i));
            % shading interp;

            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.Bt(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため

            % clim([0,0.3]);%/ST
            clim([-0.05,0.05]);%Spheromak
            dataTypeName = 'Bt';
            colorLabel = 'B_t (T)';
            % disp(max(max(data2D.Bt(:,:,i))))
        case 'Jt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Jt(:,:,i),30,'LineStyle','none');

            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.Jt(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため
            
            clim([-0.3e6,0.3e6]);
            dataTypeName = 'Jt';
            colorLabel = 'J_t (A/m^2)';
        case 'Et'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Et(:,:,i),100,'LineStyle','none');
            % pcolor(grid2D.zq, grid2D.rq, data2D.Et(:,:,i));
            shading interp;
            % clim([-8e-4,8e-4]);
            clim([-2e2 2e2]);
            dataTypeName = 'Et';
            colorLabel = 'E_t (V/m)';
        case  'Br'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Br(:,:,i),30,'LineStyle','none');

            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.Br(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため
            
            clim([-0.07,0.07]);
            dataTypeName = 'Br';
            colorLabel = 'B_r (T)';
        case  'lBl'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bl(:,:,i),20,'LineStyle','none'); 
            
            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), data2D.Bl(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため

            clim([0,0.1]);
            dataTypeName = 'lBl';
            % disp(min(min(data2D.Bl(:,:,i))))
            colorLabel = 'B_l (T)';
        case 'Brt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Brt(:,:,i),20,'LineStyle','none'); 
            Brt(:,:,i)=sqrt(data2D.Bt(:,:,i).^2+data2D.Br(:,:,i).^2);
            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), Brt(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため

            clim([0,0.1]);
            dataTypeName = 'Brt';
            % disp(min(min(data2D.Brt(:,:,i))))
            colorLabel = 'Brt (T)';
        case 'JtEt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.JtEt(:,:,i),20,'LineStyle','none'); 
            JtEt(:,:,i)     = data2D.Jt(:,:,i).*data2D.Et(:,:,i);
            
            % imagesc(grid2D.zq(1,:), grid2D.rq(:,1), JtEt(:,:,i));
            % set(gca, 'YDir', 'normal'); % 上下反転を防ぐ
            % shading flat; % 念のため
            disp(max(max(JtEt(:,:,i))))

            clim([-1e6,1e6]);
            dataTypeName = 'JtEt';
            % disp(min(min(data2D.JtEt(:,:,i))))
            colorLabel = 'JtEt (A·V/m^3)';
        case  'gradB'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.gradB(:,:,i),20,'LineStyle','none'); 
            % clim([0,0.1]);
            dataTypeName = 'gradB';
            disp(min(min(data2D.gradB(:,:,i))))
            colorLabel = 'gradB (T/m)';


            %%%%%%%%%%%%%%%%%%%べくとるプロット％％％％％％％％％％％％％％％
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
        case 'dpsi_dt'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.dpsi_dt(:,:,i),20,'LineStyle','none'); 
            clim([-3e3,3e3]);disp(min(min(data2D.dpsi_dt(:,:,i))))
            dataTypeName = 'dpsi dt';
            colorLabel = 'dpsi dt (Wb/s)';
        case 'magnetic_rec_pressure'
            mu0 = 4*pi*1e-7; % 真空の透磁率
            magnetic_rec_pressure(:,:,i) = ((data2D.Br(:,:,i)).^2 + (data2D.Bz(:,:,i)).^2) / (2 * mu0);
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),magnetic_rec_pressure(:,:,i),20,'LineStyle','none'); 
            clim([0,3e2]);
            dataTypeName = 'magnetic rec pressure';
            colorLabel = 'magnetic rec pressure (Pa)';
        case 'magnetic_pressure'
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.magnetic_pressure(:,:,i),20,'LineStyle','none'); 
            clim([0,5e2]); disp(max(max(data2D.magnetic_pressure(:,:,i))))
            dataTypeName = 'magnetic pressure';
            colorLabel = 'magnetic pressure (Pa)';
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
            me = 9.11e-31; %電子質量
            v_pe = 1e6; %垂直速度仮定 この時3eV。1e5m/sの時は0.03eV。1e7の時は300eV。
            q = 1.6e-19; %電子素量
            Lamor(:,:,i) = me*v_pe/q./data2D.Bl(:,:,i);

            contourf(grid2D.zq(1,:),grid2D.rq(:,1),Lamor(:,:,i),20,'LineStyle','none'); 
            clim([0,1e-2]);
            disp(max(max(Lamor(:,:,i))))
            dataTypeName = 'Lamor radius';
            colorLabel = 'Lamor Radius(m)';
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
        case 'Vmagneticfieldline'
            %一旦psiをプロット
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),100,'LineStyle','none');
            clim([-0.5e-2,0.5e-2]);hold on;

            
            contourLevelCount = 20;  % 対象のpsi値
            us = 1e-6;           % 時間ステップ（秒）
            N = size(data2D.psi, 3);  % 時間ステップの数

            all_coords = [];
            all_vz = [];
            all_vr = [];

            psi1 = squeeze(data2D.psi(:,:,i));
            psi2 = squeeze(data2D.psi(:,:,i+1));

            % 等高線の構造を取得（20本）
            C1 = contourc(grid2D.zq(1,:), grid2D.rq(:,1), psi1, contourLevelCount);
            C2 = contourc(grid2D.zq(1,:), grid2D.rq(:,1), psi2, contourLevelCount);

            % 等高線から座標をすべて抽出（複数グループ）
            coords1_cells = extract_all_contour_coords(C1);
            coords2_cells = extract_all_contour_coords(C2);

            % 等高線ごとにベクトルを対応付けて速度計算
            for g = 1:length(coords1_cells)
                coords1 = coords1_cells{g};
                if isempty(coords1) || isempty(coords2_cells)
                    continue;
                end

                % 最も近い等高線グループを探す
                min_avg_dist = inf;
                best_match_coords2 = [];

                for h = 1:length(coords2_cells)
                    coords2 = coords2_cells{h};
                    if isempty(coords2)
                        continue;
                    end

                    dists = pdist2(coords1', coords2');
                    avg_dist = mean(min(dists,[],2));
                    if avg_dist < min_avg_dist
                        min_avg_dist = avg_dist;
                        best_match_coords2 = coords2;
                    end
                end

                % ベクトル計算（各点で最短マッチ）
                for k = 1:size(coords1, 2)
                    p1 = coords1(:, k);
                    dists = vecnorm(best_match_coords2 - p1, 2, 1);
                    [~, minIdx] = min(dists);
                    p2 = best_match_coords2(:, minIdx);
                    v = (p2 - p1) / dt;

                    all_coords = [all_coords, p1];
                    all_vz = [all_vz, v(1)];
                    all_vr = [all_vr, v(2)];
                end
            end
            quiver(all_coords(1,:), all_coords(2,:), all_vz, all_vr, 'r', 'AutoScale', 'on', 'AutoScaleFactor', 5);
            dataTypeName = 'Vmagfieldline';
            colorLabel = 'Vmagfieldline(m/s)';
    end
    colormap('whitejet')
    axis image
    axis tight manual
    hold on
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
    plot(magAxisList.z(:,i),magAxisList.r(:,i),'ko');
    plot(xPointList.z(i),xPointList.r(i),'kx');
    hold on
    
    hold off
    title(string(t)+' us')

    c = colorbar;
    ylabel(c, colorLabel);
end
time_plot = toc(t_plot_start);
disp(['Plot creation time: ', num2str(time_plot), ' sec']);

sgtitle(strcat(dataTypeName, ' diagram of shot', num2str(shot), ', on', num2str(date), ':', num2str(IDXlist(1))));

pathname_fig = getenv('savedata_path');
foldername_fig = strcat(pathname_fig,'/',num2str(date),'/',dataTypeName);
% if exist(foldername_fig,'dir') == 0
%     mkdir(foldername_fig);
% end
[~, ~] = mkdir(foldername_fig);
savepath = fullfile(foldername_fig, strcat(dataTypeName, '(','shot',num2str(IDXlist(1)),')','.png'));

t_save_start = tic; % 保存時間の計測開始
saveas(gcf,savepath);
print(gcf, savepath, '-dpng', '-r100');

time_save = toc(t_save_start);
disp(['Save time: ', num2str(time_save), ' sec']);

close(gcf);

end


function contourGroups = extract_all_contour_coords(C)
    contourGroups = {};
    idx = 1;
    while idx < size(C,2)
        level = C(1,idx);             %#ok<NASGU>  % 使うなら利用
        nPoints = C(2,idx);
        segment = C(:, idx+1:idx+nPoints);
        contourGroups{end+1} = segment;
        idx = idx + nPoints + 1;
    end
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

