clear all
load('mat/shot11909-12170.mat')

id_NAN = isnan(datalist(:,2));
datalist(id_NAN, :) = [];
id_NAN = isnan(datalist(:,3));
datalist(id_NAN, :) = [];
id_NAN = isnan(datalist(:,4));
datalist(id_NAN, :) = [];
%MCで並べ替え
datalist_MC = sortrows(datalist,2);
datalist_MC(1,:)=[];
% %TFで並べ替え
% datalist_TF = sortrows(datalist,3);
% 
% figure
% plot(datalist(:,3),datalist(:,2),'rx')


% high MC 
% 11966
% 11993
% 12063
% 12015
% 12013
% 12040
% 12012

% low MC
% 12159
% 12160
% 12157
% 12158
% 12156
% 12152
% 12154
% 12155
% 12151
% 12149
% 12150
% 12148
% 12147
% 12146