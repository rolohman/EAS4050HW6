load coast
coastlon=long;
coastlat=lat;
clear lat long


%EQ search area
minlon=48;
maxlon=58.5;
minlat=25;
maxlat=34.2;


%For now I'm hardwiring in 100 years, if you change the timespan, change the variable below, which is used later
numyears=100;


starttime='starttime=1913-01-01';
endtime='endtime=2013-12-31';
minmagnitude='minmagnitude=4';
minlatitude=['minlatitude=' num2str(minlat)];
maxlatitude=['maxlatitude=' num2str(maxlat)];
minlongitude=['minlongitude=' num2str(minlon)];
maxlongitude=['maxlongitude=' num2str(maxlon)];
limit='limit=20000';
format='format=geojson';

apiroot = 'https://earthquake.usgs.gov/fdsnws/event/1/query?';
apicall = [apiroot starttime '&' endtime '&' minmagnitude '&' minlatitude '&' maxlatitude '&' minlongitude '&' maxlongitude '&' limit '&' format];
%look at apicall to see what the web address for your search request looks
%like

%this sends that web address out and records the response as a structure
output = webread(apicall);
output = output.features; %we just want this part of the structure
%note that if you get a message like "Resolving timed out after 5102
%milliseconds" it's an error on their side - perhaps the web service is
%down for a bit. try again in a few minutes?


numquakes = length(output);
disp([num2str(numquakes) ' total quakes'])
%note that if you hit 20,000 you've maxed out and need to look at a smaller area or time span.  
%Otherwise, you will be THINKING you have 100 years of earthquakes and in reality you will 
%have 75 or something like that and the "divide N by timespan" step below will be wrong.

for i=1:numquakes
    lon(i) = output(i).geometry.coordinates(1);
    lat(i) = output(i).geometry.coordinates(2);
    z(i)   = output(i).geometry.coordinates(3);
    mag(i) = output(i).properties.mag;
end

%Plot your region
figure
plot(coastlon,coastlat,'k')
hold on
scatter(lon,lat,12,z,'filled')
caxis([0 50])
colorbar
axis([minlon maxlon minlat maxlat])
title('Earthquakes, colored by depth in km')
xlabel('Longitude')
ylabel('Latitude')


deltamag=0.01;  % we use this to divide up our magnitude range into bins
bins=4:deltamag:10;
numbins=length(bins);
for i=1:numbins
    goodmag = find(mag>=bins(i));
    N(i)=length(goodmag); %number of earthquakes larger than each magnitude
end

N(N==0)=NaN; %don't count sizes with 0 values!
goodid=find(isfinite(N));
N=N/numyears; %convert to number/year

%now fit a line to the number of earthquakes vs. bins
bestline = fit(bins(goodid)',log10(N(goodid))','poly1'); %the ' symbol is because fit expects x and y to be column vectors

disp(['b = ' num2str(bestline.p1) ', a = ' num2str(bestline.p2)])
disp(['a/b = ' num2str(-bestline.p2/bestline.p1)])

%plot the results!
figure
plot(bins,log10(N),'*')
hold on
plot(bestline,'r-')
grid on
ylabel('log10 of N, event/year with magnitude > M')
xlabel('Magnitude, M')
legend('all data','G-R fit')

%Repeat, but now cull out points in this plot below a guess of the "magnitude completeness threshold"
mineq=4.3;
maxeq=8;

goodid = find(isfinite(N) & (bins > mineq) & (bins<maxeq));
%now fit a line to the number of earthquakes vs. bins
bestline = fit(bins(goodid)',log10(N(goodid))','poly1'); %the ' symbol is because fit expects x and y to be column vectors

disp(['b = ' num2str(bestline.p1) ', a = ' num2str(bestline.p2)])
disp(['a/b = ' num2str(-bestline.p2/bestline.p1)])

%plot the results!
figure
plot(bins,log10(N),'*')
hold on
plot(bins(goodid), log10(N(goodid)),'ro')
plot(bestline,'r-')
grid on
ylabel('log10 of N, event/year with magnitude > M')
xlabel('Magnitude, M')
legend('all data','data after cullin','G-R fit')


%%Finally: Total seismic moment/year

%this equation is wrong
m0 = log10(1.5*mag+10^9.1);
m0peryear = sum(m0)/numyears;

%fix this equation too!!!
mwperyear = m0peryear-sin(sum(mag));
disp(['Average moment realease in Newton-meters per year: ' num2str(m0peryear)])
disp(['Average Mw per year ' num2str(mwperyear)])