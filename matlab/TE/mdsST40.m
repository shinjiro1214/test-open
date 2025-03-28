addpath '/Users/rsomeya/Documents/lab/matlab/common';

%各PCのパスを定義
run define_path.m

%%ST40データ取り込み練習

%mdsplusのパスを通す
setenv('MDSPLUS_DIR','/usr/local/mdsplus');
addpath(fullfile(getenv('MDSPLUS_DIR'), 'matlab'));
%ST40に接続
mdsconnect('87.224.94.202:8000');

shot_start_num = 11909;
%実験ログ読み込み
DOCID = '13vB2pWO_zp3kMjpwVyoWXwHmu4M7HovwN3ic4VrifuQ';%ST40実験ログのID
loginURL = 'https://www.google.com';
csvURL = ['https://docs.google.com/spreadsheet/ccc?key=' DOCID '&output=csv&pref=2'];
cookieManager = java.net.CookieManager([], java.net.CookiePolicy.ACCEPT_ALL);
java.net.CookieHandler.setDefault(cookieManager);
handler = sun.net.www.protocol.https.Handler;
connection = java.net.URL([],loginURL,handler).openConnection();
connection.getInputStream();
ST40table = webread(csvURL);
ST40log = ST40table(:,4);
ST40log = fillmissing(ST40log,'constant',0);%0埋め
shot_start_row = find((ST40log.Var4)==shot_start_num);
if isempty(shot_start_row)
    warning(['Shot ',num2str(shot_start_num),' was not found.'])
    return
end

check = 0;
i_shot = 1;
while check < 5
    shot_num = ST40log.Var4(shot_start_row+i_shot -1);
    if shot_num > shot_start_num -1
        folder_name = [pathname.mat,'/ST40'];
        if not(exist(folder_name,'dir'))
            mkdir(folder_name)
        end
        savename = [folder_name,'/ST40_shot',num2str(shot_num),'.mat'];
        if exist(savename,"file")
            load(savename,'ST40data')
            if i_shot == 1
                figure('Position',[0 0 800 600])
                shotlist = ST40data.shot_num;
                I_MClist = ST40data.I_MC;
                I_TFlist = ST40data.I_TF;
                Iplist = ST40data.Ip;
                plot(ST40data.I_MC,ST40data.Ip,'rx','LineWidth',3)
                drawnow
                hold on
            else
                shotlist = [shotlist;ST40data.shot_num];
                I_MClist = [I_MClist;ST40data.I_MC];
                I_TFlist = [I_TFlist;I_TF];
                Iplist = [Iplist;ST40data.Ip];
                plot(ST40data.I_MC,ST40data.Ip,'rx','LineWidth',3)
                drawnow
                hold on
            end
        else
            % shotにアクセス
            mdsopen('ST40',shot_num);
            %データ取得
            d_MC=mdsvalue("_d_MC="+'.PSU.MC:I');
            d_Ip=mdsvalue("_d_Ip="+'.PFIT.POST_BEST.RESULTS.GLOBAL:IP');
            d_TF=mdsvalue("_d_TF="+'.PSU.TF:I_REF');
            %データに対応する時刻を取得
            t_MC = mdsvalue("dim_of(_d_MC)");
            t_Ip = mdsvalue("dim_of(_d_Ip)");
            t_TF = mdsvalue("dim_of(_d_TF)");
            if isnumeric(t_MC) && isnumeric(t_Ip) && isnumeric(t_TF)
                idx_t_MC_0 = knnsearch(t_MC,0);
                I_MC = d_MC(idx_t_MC_0);
                idx_t_Ip_4ms = knnsearch(t_Ip,0.004);
                idx_t_Ip_6ms = knnsearch(t_Ip,0.006);
                Ip = max(d_Ip(idx_t_Ip_4ms:idx_t_Ip_6ms),[],'all');
                idx_t_TF_0 = knnsearch(t_TF,0);
                I_TF = d_TF(idx_t_TF_0);
                if i_shot == 1
                    figure('Position',[0 0 800 600])
                    shotlist = shot_num;
                    I_MClist = I_MC;
                    I_TFlist = I_TF;
                    Iplist = Ip;
                    plot(I_MC,Ip,'rx','LineWidth',3)
                    drawnow
                    hold on
                else
                    shotlist = [shotlist;shot_num];
                    I_MClist = [I_MClist;I_MC];
                    I_TFlist = [I_TFlist;I_TF];
                    Iplist = [Iplist;Ip];
                    plot(I_MC,Ip,'rx','LineWidth',3)
                    drawnow
                    hold on
                end
                % figure('Position',[0 0 800 600])
                % tiledlayout(1,2)
                % nexttile
                % plot(t_MC,d_MC)
                % xlim([-0.01 0.02])
                % title(['MC current - shot',num2str(shot_num)])
                % xlabel('Time [s]')
                % ylabel('MC current [A]')
                % nexttile
                % plot(t_Ip,d_Ip)
                % xlim([-0.01 0.02])
                % title(['I_p - shot',num2str(shot_num)])
                % xlabel('Time [s]')
                % ylabel('I_p [A]')
                ST40data =struct(...
                    'shot_num',shot_num,...
                    'd_MC',d_MC,...
                    'd_Ip',d_Ip,...
                    'd_TF',d_TF,...
                    't_MC',t_MC,...
                    't_Ip',t_Ip,...
                    't_TF',t_TF,...
                    'I_MC',I_MC,...
                    'Ip',Ip,...
                    'I_TF',I_TF);
                save(savename,'ST40data')
            end
        end
        check = 0;
    else
        check = check+1;
    end
    i_shot = i_shot+1;
end

datalist = cat(2,shotlist,I_MClist,I_TFlist,Iplist);
filename = ['shot',num2str(shotlist(1)),'-',num2str(shotlist(end)),'.mat'];
save(['mat/',filename],'datalist')

mdsclose;
mdsdisconnect;
