calib_Ar = ["CH_number" "CH_position" "lambda_position" "nm/pixel" "instrument" "strength"];

%--【Input】----
date = 240607;%校正実験日
w_CH = 3;%チャンネル切り取り幅

for i = 1:96
    if  exist([num2str(date),'/calibation',num2str(i),'_w_CH=',num2str(w_CH),'.mat'],'file') ~= 0
        load([num2str(date),'/calibation',num2str(i),'_w_CH=',num2str(w_CH),'.mat'],'cal_result')
        calib_Ar = cat(1,calib_Ar,cal_result);
    end
end
save([num2str(date),'_Xe_calibation','.mat'],'calib_Ar')
