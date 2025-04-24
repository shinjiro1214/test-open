function idx = convert_shot_number(PCB)

date = PCB.date;
shot = PCB.shot;
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,date);

IDX_039 = find(T.a039==shot(1));
IDX_040 = find(T.a040==shot(2));

if IDX_039==IDX_040
    idx = IDX_039;
else
    idx = NaN;
    disp('2 indices do not match');
end

end