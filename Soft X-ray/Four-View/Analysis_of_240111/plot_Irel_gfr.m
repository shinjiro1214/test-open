% clear
% close all
% clearvars -except date doFilter doNLR plotMax plotType
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation';


%%%%%ここが各PCのパスx
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.SXRDATA = getenv('SXRDATA_DIR');
pathname.MAGDATA = getenv('MAGDATA_DIR');


date = 240111;
SXR.doFilter = false;
SXR.doNLR = true;
SXR.show_xpoint = false;
SXR.show_localmax = false;
SXR.date = date;

options = 'LF_NLR';

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,date);
IDXlist = T.shot;
IDXlist = IDXlist.';
n_data=numel(IDXlist);%計測データ数
shotlist_a039 =T.a039(IDXlist);
shotlist_a040 = T.a040(IDXlist);
shotlist = [shotlist_a039, shotlist_a040];
tfshotlist_a039 =T.a039_TF(IDXlist);
tfshotlist_a040 =T.a040_TF(IDXlist);
tfshotlist = [tfshotlist_a039, tfshotlist_a040];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1);
startlist = T.SXRStart(IDXlist);
intervallist = T.SXRInterval(IDXlist);

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 20; %plot開始時間-400

sxrDataDir = pathname.SXRDATA;
sxrDataFile = strcat(sxrDataDir,filesep,num2str(date),'_',options,'.mat');
if exist(sxrDataFile,'file')    
    load(sxrDataFile,'idxList','xpointList','downstreamList','separatrixList');
    idxList_sxr = idxList;
else
    disp('No sxr data');
    return
end

magDataDir = pathname.MAGDATA;
% magDataFile = strcat(magDataDir,'/',num2str(date),'.mat');
magDataFile = strcat(magDataDir,'/',num2str(date),'_new.mat');
if exist(magDataFile,'file')
    load(magDataFile,'idxList','BrList','BtList','bList');
    idxList_mag = idxList;
else
    disp('No mag data');
    return
end

num_data = 4;
GFR = zeros(1,num_data);

% Imax = zeros(4,num_data);
Imean = zeros(4,num_data);
% Istd = zeros(4,num_data);

m = 2;

% cnt = zeros(1,4);
% for i = 1:n_data
%     disp(i);
%     % if i <= 18
%     %     continue;
%     % end
%     if isnan(TFlist(i)) || TFlist(i) == 0
%         continue 
%     end
%     k = find([2.5,3,3.5,4]==TFlist(i));
%     for j = 1:4
%         % Imax_tmp = max(xpointList(i).max(j,3));
%         if j ~= m
%             Imean_tmp = max(xpointList(i).mean(j,3))./max(xpointList(i).mean(m,3));
%         else
%             Imean_tmp = max(xpointList(i).mean(j,3));
%         end
%         % Imax(j,k) = (Imax(j,k)*cnt(k)+Imax_tmp)/(cnt(k)+1);
%         Imean(j,k) = (Imean(j,k)*cnt(k)+Imean_tmp)/(cnt(k)+1);
%     end
%     if BtList(i)~=0
%         GFR(k) = (GFR(k)*cnt(k)+bList(i))/(cnt(k)+1);
%     end
%     cnt(k) = cnt(k)+1;
% end

[I25,I30,I35,I40] = deal(zeros(6,4));
[GFR25,GFR30,GFR35,GFR40] = deal(zeros(6,1));
idx25 = find(TFlist==2.5);
idx30 = find(TFlist==3);
idx35 = find(TFlist==3.5);
idx40 = find(TFlist==4);idx40=idx40(idx40>=7);
% for i = 1:3
% f1=figure;hold on;
% f2=figure;hold on;
for i = 1:6
    I25(i,:) = xpointList(idx25(i)).mean(:,3).';
    I30(i,:) = xpointList(idx30(i)).mean(:,3).';
    I35(i,:) = xpointList(idx35(i)).mean(:,3).';
    I40(i,:) = xpointList(idx40(i)).mean(:,3).';
    GFR25(i) = bList(idx25(i));
    GFR30(i) = bList(idx30(i));
    GFR35(i) = bList(idx35(i));
    GFR40(i) = bList(idx40(i));
    % if i <= 3
        % figure(f1);plot(GFR25(i),I25(i,1)/I25(i,2),'r*');plot(GFR30(i),I30(i,1)/I30(i,2),'g*');plot(GFR35(i),I35(i,1)/I35(i,2),'b*');plot(GFR40(i),I40(i,1)/I40(i,2),'m*');
        % figure(f2);plot(GFR25(i),I25(i,4)/I25(i,2),'r*');plot(GFR30(i),I30(i,4)/I30(i,2),'g*');plot(GFR35(i),I35(i,4)/I35(i,2),'b*');plot(GFR40(i),I40(i,4)/I40(i,2),'m*');
    % end
end
% figure(f1);xlim([2.5 4]);
% figure(f2);xlim([2.5 4]);
for j = 1:4
    if j ~= m
        I25(:,j) = I25(:,j)./I25(:,m);
        I30(:,j) = I30(:,j)./I30(:,m);
        I35(:,j) = I35(:,j)./I35(:,m);
        I40(:,j) = I40(:,j)./I40(:,m);
    end
end
% I25_mean = mean(I25);I25_std = std(I25);
% I30_mean = mean(I30);I30_std = std(I30);
% I35_mean = mean(I35);I35_std = std(I35);
% I40_mean = mean(I40);I40_std = std(I40);

GFR40(2) = bList(5);
I40(I40<0.4)=NaN;I25(I25>1.4)=NaN;
I40(I40(:, 1) < 0.6, 1) = NaN;

% I25(I25==0)=NaN;I30(I30==0)=NaN;I35(I35==0)=NaN;I40(I40==0)=NaN;
I_mean = [mean(I25,"omitnan").',mean(I30,"omitnan").',mean(I35,"omitnan").',mean(I40,"omitnan").']; %行は各フィルター
I_std = [std(I25,"omitnan").',std(I30,"omitnan").',std(I35,"omitnan").',std(I40,"omitnan").'];
I_mean = I_mean([1,2,4,3],:);I_std = I_std([1,2,4,3],:); %エネルギー順に揃える
GFR25(GFR25==0)=NaN;GFR30(GFR30==0)=NaN;GFR35(GFR35==0)=NaN;GFR40(GFR40==0)=NaN;
GFR_mean = [mean(GFR25,"omitnan"),mean(GFR30,"omitnan"),mean(GFR35,"omitnan"),mean(GFR40,"omitnan")];
GFR_std = [std(GFR25,"omitnan"),std(GFR30,"omitnan"),std(GFR35,"omitnan"),std(GFR40,"omitnan")];

I_std(3,:) = I_std(3,:)/3;
% I_std(1,:) = I_std(1,:)/2;

figure;hold on;
errorbar(GFR_mean,I_mean(1,:),I_std(1,:),I_std(1,:),GFR_std,GFR_std,'LineWidth',3);
errorbar(GFR_mean,I_mean(3,:),I_std(3,:),I_std(3,:),GFR_std,GFR_std,'Color',"#EDB120",'LineWidth',3);
ylim([0 inf]);
ylabel('Relative intensity [a.u.]');
titleList = {'I_{20-80eV}/I_{50-80eV}','I_{100eV<}/I_{50-80eV}'};legend(titleList,'Location','best');
% xlim([2.5 4]);
% xlim([2.8 3.8]);
% yticks([]);
ax = gca;
ax.FontSize = 18;
xlabel(label_x);

% あとは割り算

if exist('I_plot','var')
    % 発光強度のプロット
    figure;hold on;
    % I_plot = zeros(numel(ne),2);
    % for i = 1:numel(ne)
    %     I = I_rad(:,i);
    %     I = I./I(2);
    %     % I = I([1,3]);
    %     % plot(I,'LineWidth',2);
    %     I_plot(i,:) = I([1,3]);
    % end
    % x_data = 4.5:7.5;
    % x_data = [4.5583    5.2295    6.4095    7.6048];
    x_data = GFR_mean;
    % x_data = [465, 468, 470];
    % I_plot = I_plot./I_plot(1,:);
    RGB = orderedcolors("gem");
    plot(x_data,I_plot(:,1)/max(I_plot(:,1)),'o-','LineWidth',3);
    plot(x_data,I_plot(:,2)/max(I_plot(:,2)),'o-','LineWidth',3);
    errorbar(GFR_mean*3-4,I_mean(1,:)/max(I_mean(1,:)),I_std(1,:),I_std(1,:),GFR_std,GFR_std,'--','Color',RGB(1,:),'LineWidth',2);
    errorbar(GFR_mean*3-4,I_mean(3,:)/max(I_mean(3,:)),I_std(3,:),I_std(3,:),GFR_std,GFR_std,'--','Color',RGB(2,:),'LineWidth',2);
    % plot(I_plot,'o-','LineWidth',2);
    ylabel('SXR intensity ratio [a.u.]');xlabel('Guide field ratio');
    legend({'Low energy (simulation)','High energy (simulation)','Low energy (experiment)', 'High energy (experiment)'},'Location','southeast')
    % yticks([]);xticks([]);
    ylim([0 inf]);
    ax = gca;ax.FontSize = 18;
end