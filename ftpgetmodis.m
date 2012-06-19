function [f] = ftpgetmodis(tiles,subdir,ftpsite,dest,styr,endyr,interval,start)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% ftpgetmodis.m %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matlab code to do automated downloading of large MODIS files from the
% MODIS/ASTER FTP data pool, found at:
% https://lpdaac.usgs.gov/lpdaac/get_data/data_pool
% This is designed to download all composites from a given year for a
% certain MODIS tile. Code is currently able to download data from
% 2000 to 2020, by which point, a new system will surely have made this
% code obsolete.
%
% SYNTAX: 
% [f] = ftpgetmodis(tiles,subdir,ftpsite,dest,styr,endyr,interval,start)
%   where: 
% tiles   = MODIS tile text
% subdir  = subdirectory of FTP site - there's one folder for each product
% ftpsite = FTP site address of FTP site
% dest    = local directory to receive downloaded files
% styr    = start year 
% endyr   = end year
% interval= compositing interval, can be 1, 8 or 16
% start   = starting composite for year, should be 1
%
% EXAMPLE: To download MODIS 8-day (interval) Land surface reflectance data 
% - MOD09A1 (subdir) - from the Terra site, starting with 2000 (styr) and 
% going until 2010 (endyr) and if I want all composites from the year
% (start). To download tile h12v11 (tiles), to the N drive (dest), 
% use the following:
%
% ftpgetmodis('h12v11','MOLT/MOD09A1.005/','e4ftl01.cr.usgs.gov','N:\',...
%              2000, 2010, 8, 1)
% Essentially, this is opening the ftp site,
% ftp://e4ftl01.cr.usgs.gov/MOLT/MOD09A1.005 and getting all of the files
% that satisfy the other conditions.
%
%
% by Michael Toomey, mtoomey@geog.ucsb.edu
% last modified April 26, 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% K FOR loop should be from beginning to end year
for k=styr:endyr
    disp(k) 
    % assign increment to "yearrange"
    yearrange = k;
    % calculate the serial dates for each year
    % these must be done separately because of the leap years
    % and the uneven splitting of the year into intervals
    tmp=find(yearrange==2000);
    if numel(tmp)==1 
        yr2000=730566:interval:730851;
    end
    tmp=find(yearrange==2001);
    if numel(tmp)==1
        yr2001=730852:interval:731216;
    end
    tmp=find(yearrange==2002);
    if numel(tmp)==1
        yr2002=731217:interval:731581;
    end
    tmp=find(yearrange==2003);
    if numel(tmp)==1
        yr2003=731582:interval:731946;
    end
    tmp=find(yearrange==2004);
    if numel(tmp)==1
        yr2004=731947:interval:732311;
    end
    tmp=find(yearrange==2005);
    if numel(tmp)==1
        yr2005=732313:interval:732677;
    end
    tmp=find(yearrange==2006);
    if numel(tmp)==1
        yr2006=732678:interval:733042;
    end
    tmp=find(yearrange==2007);
    if numel(tmp)==1
        yr2007=733043:interval:733407;
    end
    tmp=find(yearrange==2008);
    if numel(tmp)==1
        yr2008=733408:interval:733772;
    end
    tmp=find(yearrange==2009);
    if numel(tmp)==1
        yr2009=733774:interval:734138;
    end
    tmp=find(yearrange==2010);
    if numel(tmp)==1
        yr2010=734139:interval:734503;
    end
    tmp=find(yearrange==2011);
    if numel(tmp)==1
        yr2011=734504:interval:734868;
    end
    tmp=find(yearrange==2012);
    if numel(tmp)==1
        yr2012=734869:interval:735234;
    end
    tmp=find(yearrange==2013);
    if numel(tmp)==1
        yr2013=735235:interval:735599;
    end
    tmp=find(yearrange==2014);
    if numel(tmp)==1
        yr2014=735600:interval:735964;
    end
    tmp=find(yearrange==2015);
    if numel(tmp)==1
        yr2015=735965:interval:736329;
    end
    tmp=find(yearrange==2016);
    if numel(tmp)==1
        yr2016=736330:interval:736695;
    end
    tmp=find(yearrange==2017);
    if numel(tmp)==1
        yr2017=736696:interval:737060;
    end
    tmp=find(yearrange==2018);
    if numel(tmp)==1
        yr2018=737061:interval:737425;
    end
    tmp=find(yearrange==2019);
    if numel(tmp)==1
        yr2019=737426:interval:737790;
    end
    tmp=find(yearrange==2020);
    if numel(tmp)==1
        yr2020=737791:interval:738156;
    end
    
    % populate list of all years
    years = whos('yr*');

    % concatenate all dates together
    dates = eval(years(1).name); clear('years(1).name')

    % convert all of these serial numbers into MODIS folder names
    for j=1:numel(dates)
        % convert serial number to date vector
        tmp=datevec(dates(j));
        % make folder names by concatenating year, month and date. the sprintf
        % function places a zero before the ones digit if it is < 10
        yrstr = num2str(tmp(1));    
        datestr{j} = cat(2,yrstr,'.',sprintf('%02d',tmp(2)),'.',...
            sprintf('%02d',tmp(3)));
    end

    % now, start doing that FTP jive, opening up each folder in "datestr" and
    % getting its contents according to the search tiles
    % first, open the anonymous FTP and change to any subdirectory
    f = ftp(ftpsite);
    
    cd(f,subdir);
    % now, going through all folders in datestr, open each folder up, get the
    % files matching the tiles and then go back up to the above directory
    for i=start:numel(dates)
        try
            cd(f,datestr{i});
            tmpstr=cat(2,'Opening folder ',datestr{i});
            disp(tmpstr)
            % concatenate asterisks to make the appropriate search filter
            tile = cat(2,'*',tiles,'*');
            % use try/catch statement to try the file acquisition with the
            % error message of 'can't overwrite file' if there is some kind of
            % problem.
            try
                mget(f,tile,dest);
            catch
                disp('Can''t overwrite or access file')
            end
            % switch back to upper folder
            cd(f,'..');
        catch
            disp('Cannot find specified folder. Moving on.')
        end
    end

    % clear any year variables
    clear yr*
    clear datestr
    clear dates
end