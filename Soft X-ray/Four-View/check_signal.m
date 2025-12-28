% function check_signal(date, shot, tfshot, pathname,n)
function check_signal(PCB,pathname)

date = PCB.date;
shot = PCB.shot;
tfshot = PCB.tfshot;
n = PCB.n;

sheets = sheetnames('coeff200ch.xlsx');
sheets = str2double(sheets);
sheet_date=max(sheets(sheets<=date));
C = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
r_shift = 0.00;
ok = logical(C(:,14));
dtacq_num_list = C(:,1);
dtaq_ch = C(:,2);
polarity=C(:,13);
coeff=C(:,12);
zpos=C(:,9);
rpos=C(:,10)+r_shift;
ch=C(:,7);

% if ismember(39,dtacq_num_list)
%     filename1 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(39),'_shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
%     if exist(filename1,"file")==0
%         disp('No rawdata file of a039 -- Start generating!')
%         rawdataPath = pathname.rawdata;
%         save_dtacq_data(39, shot(1), tfshot(1),rawdataPath)
%         % disp(['File:',filename1,' does not exit']);
%         % return
%     end
%     a039_raw = importdata(filename1);
% end
% if ismember(40,dtacq_num_list)
%     filename2 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(40),'_shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
%     if exist(filename2,"file")==0
%         disp('No rawdata file of a040 -- Start generating!')
%         rawdataPath = pathname.rawdata;
%         save_dtacq_data(40, shot(2), tfshot(2),rawdataPath)
%         % disp(['File:',filename2,' does not exit']);
%         % return
%     end
%     a040_raw = importdata(filename2);
% end

if ismember(39,dtacq_num_list)
    filename1 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(39),'/shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
    if exist(filename1,"file")==0
        disp('No rawdata file of a039 -- Start generating!')
        save_dtacq_data(39, shot(1), tfshot(1),filename1)
    end
    load(filename1,"rawdata_woTF");
    a039_raw = rawdata_woTF;
end
if ismember(40,dtacq_num_list)
    filename2 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(40),'/shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
    if exist(filename2,"file")==0
        disp('No rawdata file of a040 -- Start generating!')
        save_dtacq_data(40, shot(2), tfshot(2),filename2)
    end
    load(filename2,"rawdata_woTF");
    a040_raw = rawdata_woTF;
end

raw = zeros(1000,length(dtaq_ch));
for i = 1:length(dtaq_ch)
    if dtacq_num_list(i) == 39
        raw(:,i) = a039_raw(:,dtaq_ch(i));
    elseif dtacq_num_list(i) == 40
        raw(:,i) = a040_raw(:,dtaq_ch(i));
    end
end

b=raw.*coeff';%較正係数RC/NS
b=b.*polarity';%極性揃え
% b = smoothdata(b,1);

%デジタイザchからプローブ通し番号順への変換
bz=zeros(1000,100);
bt=bz;
ok_bz=false(100,1);
ok_bt=ok_bz;
zpos_bz=zeros(100,1);
rpos_bz=zpos_bz;
zpos_bt=zpos_bz;
rpos_bt=zpos_bz;

%digital filter
windowSize = 8;
bb = (1/windowSize)*ones(1,windowSize);
aa = 1;

for i=1:length(ch)
    b(:,i) = filter(bb,aa,b(:,i));
    b(:,i) = b(:,i) - mean(b(1:40,i));
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

zprobepcb    = [-0.2975,-0.255,-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17,0.255,0.2975];
rprobepcb    = [0.06,0.09,0.12,0.15,0.18,0.21,0.24,0.27,0.30,0.33]+r_shift;
rprobepcb_t  = [0.07,0.10,0.13,0.16,0.19,0.22,0.25,0.28,0.31,0.34]+r_shift;
[zq,rq]      = meshgrid(linspace(min(zpos_bz),max(zpos_bz),n),linspace(min(rpos_bz),max(rpos_bz),n));
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
    'rprobepcb_t',rprobepcb_t,...1
    'ok_bz_matrix',ok_bz_matrix,...
    'ok_bt_matrix',ok_bt_matrix);

figure_switch = ["on","on","on","on","off","off"];%bz1,bz2,bt1,bt2,bz_vs_z,bt_vs_z

r = 7;%プローブ本数＝グラフ出力時の縦に並べる個数
col = 10;%グラフ出力時の横に並べる個数
y_upper_lim = 0.05;%縦軸プロット領域（b_z上限）
y_lower_lim = -0.05;%縦軸プロット領域（b_z下限）
% t_start=1;%横軸プロット領域（開始時間）
% t_end=1000;%横軸プロット領域（終了時間）
t_start=1;%横軸プロット領域（開始時間）
t_end=1000;%横軸プロット領域（終了時間）
t = 470;
% z_probe_pcb = [-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17];
z_probe_pcb = [-0.2975 -0.255 -0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17 0.255 0.2975];
n_z = length(z_probe_pcb);
% r_ch=col1+col2;%r方向から挿入した各プローブのチャンネル数

f1=figure(Visible=figure_switch(1));
f1.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bz(col*(i-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i-1)+j));
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i-1)+j),'r:')
        end   
        yline(0,'--k');
        title(num2str(2.*(col*(i-1)+j)-1));
        ylim([y_lower_lim y_upper_lim]);
        xticks([t_start t_end]);
        % xticks([]);
        % yticks([]);
    end
end
sgtitle('Bz signal probe1-5') 

f2=figure(Visible=figure_switch(2));
f2.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bz(col*(i+r-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i+r-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bz(t_start:t_end,col*(i+r-1)+j),'r:')
        end   
        yline(0,'--k');
        title(num2str(2.*(col*(i+r-1)+j)-1));
        ylim([y_lower_lim y_upper_lim]);
        xticks([t_start t_end]);
        % xticks([]);
        % yticks([]);
    end
end
sgtitle('Bz signal probe6-10')

f3=figure(Visible=figure_switch(3));
f3.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bt(col*(i-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i-1)+j),'r:')
        end   
        yline(0,'--k');
        title(num2str(2.*(col*(i-1)+j)));
        ylim([-0.2 0.2]);
        % ylim([y_lower_lim y_upper_lim]);
        xticks([t_start t_end]);
        % xticks([]);
        % yticks([]);
    end
end
sgtitle('Bt signal probe1-5')

f4=figure(Visible=figure_switch(4));
f4.WindowState = 'maximized';
for i=1:r
    for j=1:col
        subplot(r,col,(i-1)*col+j)
        if ok_bt(col*(i+r-1)+j)==1 %okなチャンネルはそのままプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i+r-1)+j))
        else %NGなチャンネルは赤色点線でプロット
            plot(t_start:t_end,bt(t_start:t_end,col*(i+r-1)+j),'r:')
        end
        yline(0,'--k');
        title(num2str(2.*(col*(i+r-1)+j)));
        ylim([-0.2 0.2]);
        % ylim([y_lower_lim y_upper_lim]);
        xticks([t_start t_end]);
        % xticks([]);
        % yticks([]);
    end
end
sgtitle('Bt signal probe6-10')

% saveas(gcf,strcat(pathname.save,'\date',num2str(date),'_dtacq',num2str(d_tacq),'_02','.png'))
% close

% 横軸z, 縦軸Bzのプロット
f5=figure(Visible=figure_switch(5));
f5.WindowState = 'maximized';
styles = ["-*","-^","-v","-<","->","-o","-square","-diamond","-pentagram","-hexagram"];
tiles = tiledlayout(2,1);
sgtitle(strcat('t=',num2str(t),' us'))
nexttile
hold on
for i=1:10
    zline=(1:10:n_z*10-9)+(i-1);
    bz_zline=bz(t,zline);
    bz_zline(ok_bz(zline)==false)=NaN;
    plot(z_probe_pcb,bz_zline,styles(i),'Color','k','MarkerSize',12)
    clear bz_zline
end
hold off
yline(0,'k--')
xline(z_probe_pcb,':','LineWidth',1.5)
legend('r1','r2','r3','r4','r5','r6','r7','r8','r9','r10',Location='eastoutside')
title('Before interpolation')

Bz_interped = bz_rbfinterp(rpos_bz, zpos_bz, grid2D, bz, ok_bz, t);
nexttile
hold on
for i=1:10
    zline=(1:10:n_z*10-9)+(i-1);
    bz_zline=Bz_interped(zline);
    plot(linspace(min(zpos_bz),max(zpos_bz),n_z),bz_zline,styles(i),'Color','k','MarkerSize',12)
    clear bz_zline
end
hold off
xlabel('z [m]')
ylabel('Bz')
yline(0,'k--')
xline(z_probe_pcb,':','LineWidth',1.5)
legend('r1','r2','r3','r4','r5','r6','r7','r8','r9','r10',Location='eastoutside')
title('After interpolation')
tiles.TileSpacing = 'compact';
tiles.Padding = 'compact';

% 横軸z, 縦軸Btのプロット
f6=figure(Visible=figure_switch(6));
f6.WindowState = 'maximized';
styles = ["-*","-^","-v","-<","->","-o","-square","-diamond","-pentagram","-hexagram"];
tiles = tiledlayout(2,1);
sgtitle(strcat('t=',num2str(t),' us'))
nexttile
hold on
for i=1:10
    zline=(1:10:n_z*10-9)+(i-1);
    bt_zline=bt(t,zline);
    bt_zline(ok_bt(zline)==false)=NaN;
    plot(z_probe_pcb,bt_zline,styles(i),'Color','k','MarkerSize',12)
    clear bz_zline
end
hold off
yline(0,'k--')
xline(z_probe_pcb,':','LineWidth',1.5)
legend('r1','r2','r3','r4','r5','r6','r7','r8','r9','r10',Location='eastoutside')
title('Before interpolation')

Bt_interped = bz_rbfinterp(rpos_bt, zpos_bt, grid2D, bt, ok_bt, t);
nexttile
hold on
for i=1:10
    zline=(1:10:n_z*10-9)+(i-1);
    bt_zline=Bt_interped(zline);
    plot(linspace(min(zpos_bz),max(zpos_bz),n_z),bt_zline,styles(i),'Color','k','MarkerSize',12)
    clear bz_zline
end
hold off
xlabel('z [m]')
ylabel('Bz')
yline(0,'k--')
xline(z_probe_pcb,':','LineWidth',1.5)
legend('r1','r2','r3','r4','r5','r6','r7','r8','r9','r10',Location='eastoutside')
title('After interpolation')
tiles.TileSpacing = 'compact';
tiles.Padding = 'compact';

hidden = find(figure_switch == 'off');
figures = [f1,f2,f3,f4,f5,f6];
for i = hidden
    close(figures(i));
end

end