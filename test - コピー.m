clear
%%%%%%%%%%%%%%%%%%%%%%%%
%  １つのショットをまとめて解析したいという目的
%　 test-openで実行する。ログから読み込んで、それぞれのパスを設定するコード
%%　参考　https://jp.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html
%%%%%%%%%%%%%%%%%%%%%%%%

yourname = 'C:\Users\---\';
f = fullfile(yourname,'Documents','GitHub','test-open','magneticprobe');
addpath(f);
f = fullfile(yourname,'Documents','GitHub','test-open','SXR_test');
addpath(f);
%%%適宜変更


DOCID='';
T=getTS6log(DOCID);% ログのテーブルを取得

 node='date';  % 検索する列の名前. T.Properties.VariableNamesで一覧表示できる
 pat=211223;   % 検索パターン（数値なら一致検索、文字なら含む検索）　

searchlog(T,node,pat)% ログのテーブルから当てはまるものを抽出した新しいテーブルを作成

%logからshot,TFshot,などのオペレーション設定を読む
prompt = 'number: ';%表示したいショットのnumberの値（通し番号）を入力
IDX=input(prompt) ;
date=T.date(IDX);
shot=T.shot(IDX);
TF_shot = T.TFoffset(IDX) ;
offset_TF = true;
%disp(['EF=', num2str(T.EF_A_(IDX))])
%%NaNでないことを確認（ログが空白だとNaNになる）

%%ファイルへのパスを作る
%それぞれのPCから共有フォルダまでのパスはそれぞれ異なるので各自で設定
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス
pathname.fourier='I:';%md0までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath

%共有フォルダ以下から目的ショットのファイルを探す
filepath.rgw=strcat(pathname.ts3u, '\', string(date),'\' ...
    ,string(date),num2str(shot,'%03i'),'.rgw');
filepath.D288=dir(strcat(pathname.fourier,'\Doppler\288CH\20',string(date),'\*shot',num2str(shot),'*.asc'));
filepath.Dhighspeed=dir(strcat(pathname.NIFS,'\Doppler\Photron\',string(date),'\**\*shot',num2str(shot),'*.tif'));
filepath.SXR=strcat(pathname.NIFS,'\X-ray\',string(date),'\shots\',string(date),num2str(shot,'%03i'),'.tif');




%[B_z,r_probe,z_probe,ch_dist,B_z_return,data_return,shot_num] 
[B_z,r_probe,z_probe,ch_dist,data,data_raw,shot_num]= get_B_z(date,TF_shot,shot,offset_TF,T.EF_A_(IDX),pathname.ts3u);
B_z = B_z([2,3,4,6,7,8],2:end,:);
data = data([2,3,4,6,7,8],2:end,:);
z_probe = z_probe(2:end);
ch_dist = ch_dist([2,3,4,6,7,8],2:end);
r_probe = r_probe([2,3,4,6,7,8]);



%plot_B_z_in_time(B_z,ch_dist,350,600);
%plot_psi_SXR_multi(B_z,r_probe,z_probe,date,shot,layer,area,start,exposure,SXRfilename)
plot_psi_SXR_multi(B_z,r_probe,z_probe,date,shot,true,true,T.Period_StartTime_(IDX),2,filepath.SXR)




