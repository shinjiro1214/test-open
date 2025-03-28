addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

date = 240607;
filename = [pathname.IDSP,'/',num2str(date),'/Xe green dial 482.6nm.asc'];

A = importdata(filename);