clearvars -except date IDXlist doSave doFilter doNLR times
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shohgookazaki/Documents/GitHub/test-open'/'Soft X-ray'/Four-View; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
% ~/Documents/MATLAB にてstartup.mを作って、その中でsetenv('パス名','アドレス')していくと自動になる。
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory_path=getenv('pre_processed_directory_path');


%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:','times:'};
definput = {'','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('IDXlist','var')
    definput{2} = num2str(IDXlist);
end
if exist('times','var')
    definput{3} = num2str(times);
end
dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDX','var') && exist('times','var')
%     definput = {num2str(date),num2str(IDX),num2str(times)};
% else
%     definput = {'','',''};
% end
% definput = {'','',''};
% definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2))); 
times = str2num(cell2mat(answer(3))); 


%-----------スプレッドシートからデータ抜き取り--------------------%
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);

T=searchlog(T,'date',date);
if isnan(T.shot(1))
    T(1, :) = [];
end
n_data=numel(IDXlist);%計測データ
shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1); % 39が計測データ数だけ縦に並ぶ。
startlist = T.SXRStart(IDXlist);
intervallist = T.SXRInterval(IDXlist);


PCB.trange=400:600;%【input】計算時間範囲
PCB.n=50; %【input】rz方向のメッシュ数
PCB.restart = 0;

figure;hold on
xlabel('time [us]');ylabel('Merging ratio [%]');
legendList = cell(1,n_data);
ax=gca;ax.FontSize=18;

% % エクセルファイルの保存先とファイル名を指定
% outputFile = 'merging_rate.xlsx';
% 
% % 書き込み対象のデータを初期化
% all_merging_ratios = [];
% % 最長のmerging_ratioの長さを記録する変数
% max_length = 0;

disp('Getting coeff')
file_id = '1izM2mY1kjGAxIqMIXwhyzw1iuuMF3k5VXFJqi9Sy2U4';
url = sprintf('https://docs.google.com/spreadsheets/d/%s/export?format=xlsx', file_id);
    
% 一時ファイルとしてダウンロード (計算資源節約のため websave を使用)
temp_file = 'temp_coeff.xlsx';
options = weboptions('Timeout', 30);
websave(temp_file, url, options);
% --- 既存のロジック (ファイル名を temp_file に変更) ---
sheets = sheetnames(temp_file);
sheets = str2double(sheets);
    
% 外部情報の参照と乖離の指摘（日付形式の確認）
% 一般的な形式(YYMMDD)を想定していますが、桁数が異なるとロジックが破綻するため確認推奨

sheet_date = max(sheets(sheets <= date));
    
% 指定シートを読み込み
PCB.C = readmatrix(temp_file, 'Sheet', num2str(sheet_date));
delete(temp_file); % ダウンロードした一時ファイルを削除



for i = 1:n_data
    shot = IDXlist(i);
    start = startlist(i);
    interval = intervallist(i);

    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.date = date;
    TF=TFlist(i);
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname); %process_PCBdata_200ch.mに行く
    if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
        return
    end
    
    merging_ratio = get_merging_ratio(data2D,grid2D,times);
    legendList(i) = cellstr(strcat('shot',num2str(IDXlist(i))));
    
    % % 最長のmerging_ratioの長さを更新
    % max_length = max(max_length, length(merging_ratio));
    % % merging_ratioのデータを保存用の配列に追加
    % all_merging_ratios = [all_merging_ratios; merging_ratio];

    % figure;
    plot(times,merging_ratio,'LineWidth',2);
    % xlabel('time [us]');ylabel('Merging ratio [%]');
    % title('Merging ratio');
    % ax=gca;ax.FontSize=18;

end
ylim([0 100]);
legend(legendList,'Location','northwest');
sgtitle(date);

% % Initialize padded array with NaN and set proper dimensions
% padded_merging_ratios = NaN(n_data, max_length);
% 
% for i = 1:n_data
%     % Pad each row of all_merging_ratios to match max_length
%     padded_merging_ratios(i, 1:length(all_merging_ratios(i, :))) = all_merging_ratios(i, :);
% end
% 
% % Verify sizes of IDXlist and padded_merging_ratios for concatenation
% if length(IDXlist) ~= size(padded_merging_ratios, 1)
%     error('Length of IDXlist (%d) does not match the number of rows in padded_merging_ratios (%d).', length(IDXlist), size(padded_merging_ratios, 1));
% end
% 
% % Concatenate IDXlist with padded_merging_ratios
% outputData = [IDXlist, padded_merging_ratios];
% 
% % Create header
% header = [{'Shot Number'}, arrayfun(@(t) sprintf('Time_%dus', t), times(1:max_length), 'UniformOutput', false)];
% 
% % Write to output file
% outputData = [header; num2cell(outputData)];
% writecell(outputData, outputFile);








