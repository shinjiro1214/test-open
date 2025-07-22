clearvars -except date doFilter doNLR
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation';

%%%%実験オペレーションの取得
prompt = {'Date:','doFilter:','doNLR:'};
definput = {'','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('doFilter','var')
    definput{2} = num2str(doFilter);
end
if exist('doNLR','var')
    definput{3} = num2str(doNLR);
end
dlgtitle = 'Input';
dims = [1 35];
answer = inputdlg(prompt,dlgtitle,dims,definput);
if isempty(answer)
    return
end

date = str2double(cell2mat(answer(1)));
doFilter = logical(str2num(cell2mat(answer(2))));
doNLR = logical(str2num(cell2mat(answer(3))));

SXR.doFilter = doFilter;
SXR.doNLR = doNLR;
SXR.show_xpoint = false;
SXR.show_localmax = false;
SXR.date = date;

if doFilter & doNLR
    options = 'NLF_NLR';
elseif ~doFilter & doNLR
    options = 'LF_NLR';
elseif doFilter & ~doNLR
    options = 'NLF_LR';
else
    options = 'LF_LR';
end

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

sxrDataDir = getenv('SXRDATA_DIR');
sxrDataFile = strcat(sxrDataDir,filesep,num2str(date),'_',options,'.mat');
if exist(sxrDataFile,'file')
    load(sxrDataFile,'idxList','xpointList','downstreamList');
    idxList_sxr = idxList;
else
    disp('No sxr data');
    return
end

magDataDir = getenv('MAGDATA_DIR');
magDataFile = strcat(magDataDir,'/',num2str(date),'.mat');
if exist(magDataFile,'file')
    load(magDataFile,'idxList','BrList','BtList','bList');
    idxList_mag = idxList;
else
    disp('No mag data');
    return
end

tablePath = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/新規論文_2023/240111_xpoint_timing.xlsx';
T2 = readtable(tablePath);

number = zeros(1,4);
I = zeros(30,4);
for i = 1:numel(T2.shot)
    number(1) = (T2.Al10(i)-startlist(T2.shot(i)))/intervallist(T2.shot(i));
    number(2) = (T2.Al25(i)-startlist(T2.shot(i)))/intervallist(T2.shot(i));
    number(4) = (T2.Mylar10(i)-startlist(T2.shot(i)))/intervallist(T2.shot(i));
    number(3) = (T2.Mylar20(i)-startlist(T2.shot(i)))/intervallist(T2.shot(i));
    for j = 1:4
        if isnan(number(j))
            continue
        end
        % I(i,j) = xpointList(T2.shot(i)).max(j,number(j)+1);
        I(i,j) = xpointList(T2.shot(i)).mean(j,number(j)+1);
    end
end

I(I==0) = NaN;

% disp(I);
I40 = mean(I(T2.TF==4,:),'omitnan');
I35 = mean(I(T2.TF==3.5,:),'omitnan');
I30 = mean(I(T2.TF==3,:),'omitnan');
I25 = mean(I(T2.TF==2.5,:),'omitnan');

TF = zeros(1,4);
TF(1) = mean(T2.GFR(T2.TF==2.5),'omitnan');
TF(2) = mean(T2.GFR(T2.TF==3),'omitnan');
TF(3) = mean(T2.GFR(T2.TF==3.5),'omitnan');
TF(4) = mean(T2.GFR(T2.TF==4),'omitnan');

I_mean = cat(1,I25,I30,I35,I40);
I_mean = I_mean(:,[1,2,4,3]);
I_std = I_mean.*0.2;

f = figure;
f.Position = [440 278 560 600];
% hold on
titleList = {'~50eV','50~80eV','100eV~','200eV~'};
% TF = [2.5 3 3.5 4];
for i = 1:4
    subplot(4,1,i);
    % plot(TF,I_mean(:,i).','-*','LineWidth',3);
    errorbar(TF,I_mean(:,i).',I_std(:,i).','-*');
    title(titleList(i));
    ylim([0 inf]);
    % xlim([2.4 4.1]);
    ax = gca;
    ax.FontSize = 14;
end
% xlabel('Guide magnetic field [T]');
xlabel('Guide field ratio');
% sgtitle('Max intensity at x-point');
sgtitle('Mean intensity at x-point');
%ylabel('Soft X-ray intensity [a.u.]');
% legend({'~50eV','50~80eV','100eV~','200eV~'},'Location','north');

% figure;plot(TF,I_mean(:,3));
