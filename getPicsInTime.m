function [picName, picTimesPruned] = getPicsInTime(site)
% Instructions:  place this file in the directory containing Phenocam site
% directories.  It takes one argument:  the string 'site'.  It will create
% directories for each year in the site directory and fill them with near
% noon images, one per day.
%
% example arguments
% site = 'upperbuffalo';
% year = 2008;
% site = 'uillinoisenergyfarm';
% year = 'all';
% picDir = [site filesep num2str(year)];
% outDir = [site filesep num2str(year) 'NearNoon'];
% mkdir(outDir);

listing = dir(site);

for i = 1:length({listing.name})
    if strmatch(listing(i).name(1), '.'), continue; end
    if listing(i).isdir
        if ~isempty(str2num(listing(i).name)) &&...
            (str2num(listing(i).name) > 1980) &&...
            (str2num(listing(i).name) < 2020) ;
%         outDir = ['NearNoon' site filesep listing(i).name];
%         mkdir(outDir);
        
        yearListing = dir([site filesep listing(i).name]);
        
        counter = 1;
        for j = 1:length({yearListing.name})
            if strmatch(yearListing(j).name(1), '.'), continue; end
            
            if ( yearListing(j).isdir &&...
                (str2num(yearListing(j).name) >= 01) &&...
                (str2num(yearListing(j).name) <= 12) );
            
                jpegListing = dir([site filesep listing(i).name...
                    filesep yearListing(j).name filesep '*.jpg']);
                
                %get rid of IR photos
                isIR = strfind({jpegListing.name}, 'IR');
                count2 = 1;
                irCount = 0;
                for k = 1:length(isIR)
                    if isempty(isIR{k})
                        nonIRListing{count2} = jpegListing(k).name;
                        count2 = count2 + 1;
                        irCount = irCount + 1;
                    end
                end
                
                %only do if there were IR photos
                if irCount==0, nonIRListing = cell(0,0); end
                
                for k = 1:length(nonIRListing)
                    jpeg_files{counter} = [site filesep listing(i).name...
                    filesep yearListing(j).name filesep...
                    nonIRListing{k}];
                counter = counter + 1;
                end
            end
        end
        
        outDir = [site filesep 'NearNoon' listing(i).name];
        mkdir(outDir);
        
        %parse the jpeg file names
        for j=1:length(jpeg_files)
            % split strings by the underscore
            parts = regexp(jpeg_files{j},'_','split');
            year(j) =  str2double(char(parts(2)));
            month(j) =  str2double(char(parts(3)));
            day(j) =  str2double(char(parts(4)));
            time = char(parts(5));
            if length(time) < 10
                time;
            end
                
            hour(j) = str2double(time(1:2));
            minutes(j) = str2double(time(3:4));
    
            DOY(j) = date2jd(year(j), month(j), day(j),...
            hour(j), minutes(j));
        end
        
        %get unique DOYs
        roundedDOY = floor(DOY);
        unDOY = unique(roundedDOY);

        %find closest pics to noon
        counter = 1;
        for j = 1:length(unDOY)
            distanceFromNoon = abs( DOY - (unDOY(j) + 0.5) );
            [C,I] = min(distanceFromNoon);
            copyfile(jpeg_files{I}, outDir);
            counter = counter + 1;
        end
    end
    end
    clear yearListing jpegListing jpeg_files parts year month day time...
        hour minutes DOY roundedDOY unDOY distanceFromNoon nonIRListing...
        isIR
end