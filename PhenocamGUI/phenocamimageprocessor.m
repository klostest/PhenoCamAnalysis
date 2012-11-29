function varargout = phenocamimageprocessor(varargin)

% Written by Koen Hufkens at Boston University, Sept. 2011
% This code is published under a GPLv2 license and is free
% to redistribute.

% please reference the necessary publications when using the
% the 90th percentile method:
% Sonnentag et al. 2011 (Agricultural and Forest Management)


% PHENOCAMIMAGEPROCESSOR M-file for phenocamimageprocessor.fig
%      PHENOCAMIMAGEPROCESSOR, by itself, creates a new PHENOCAMIMAGEPROCESSOR or raises the existing
%      singleton*.
%
%      H = PHENOCAMIMAGEPROCESSOR returns the handle to a new PHENOCAMIMAGEPROCESSOR or the handle to
%      the existing singleton*.
%
%      PHENOCAMIMAGEPROCESSOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHENOCAMIMAGEPROCESSOR.M with the given input arguments.
%
%      PHENOCAMIMAGEPROCESSOR('Property','Value',...) creates a new PHENOCAMIMAGEPROCESSOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before phenocamimageprocessor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to phenocamimageprocessor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help phenocamimageprocessor

% Last Modified by GUIDE v2.5 28-Sep-2011 18:21:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @phenocamimageprocessor_OpeningFcn, ...
                   'gui_OutputFcn',  @phenocamimageprocessor_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before phenocamimageprocessor is made visible.
function phenocamimageprocessor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to phenocamimageprocessor (see VARARGIN)

% determine system running and set the path / file separator to / or \
handles.OS = mexext;

if strcmp(handles.OS,'mexw32') || strcmp(handles.OS,'mexw64')
    handles.file_split = '\'; % windows systems
    handles.OS = 'windows';
    handles.basedir = 'C:\';
else
    handles.file_split = '/'; % unix systems
    handles.OS = 'unix';
    handles.basedir = '/';
end

% get overall figure name, this will be used to set axes
% and other plotting parameters etc...
handles.main_figure = gcf;

% default number of regions of interest ROI
% and colour map
handles.nroi = 1;
handles.cmap = ['b' 'r' 'y'];
handles.results=[];
handles.linetype=['- ';'--';': '];

% set directory name to empty
handles.dir_name = [];

% set dark threshold value default
% this is the % below which pictures will be considered
% to dark e.g. nighttime pictures and are excluded
% from the analysis
handles.threshold = 15; 
set(handles.darkthreshold, 'Value',4); % update popout list

% set window size default
set(handles.popupmenuwindowsize,'Value',2); % set the moving window size default to 3 (pos. 2)

% initialize empty center value
%handles.center(1).X = []; % used to check for existence of ROI selections
handles.xcenter =[];
handles.ycenter = [];

% disable all buttons and stuff
% this prevents use of buttons in a
% disorderly fashion == errors
set(handles.setroibutton,'Enable','off');
set(handles.clearroibutton,'Enable','off');
set(handles.calculatebutton,'Enable','off');
set(handles.gcccheckbox,'Enable','off');
set(handles.gccsmoothcheckbox,'Enable','off');
set(handles.redcheckbox,'Enable','off');
set(handles.greencheckbox,'Enable','off');
set(handles.bluecheckbox,'Enable','off');
set(handles.frompopup,'Enable','off');
set(handles.topopup,'Enable','off');
set(handles.popuproi,'Enable','off');    
set(handles.checkboxROI1,'Enable','Off');
set(handles.checkboxROI2,'Enable','Off');
set(handles.checkboxROI3,'Enable','Off');
set(handles.checkbox90th,'Enable','Off');
set(handles.checkboxmean,'Enable','Off');
set(handles.checkboxmedian,'Enable','Off');
set(handles.popupmenuwindowsize,'Enable','Off');
set(handles.pushbuttonupdateplot,'Enable','Off');
set(handles.darkthreshold,'Enable','off');

% set load/save ROI menu item to off
set(handles.menuloadroi,'Enable','off');
set(handles.menusaveroi,'Enable','off');

% set load/save time series data to off
set(handles.menusavetsdata,'Enable','off');

% set logo in first axes
handles.current_image = imread('logo.jpg');
set(handles.main_figure,'CurrentAxes',handles.axes1);
image(handles.current_image);
axis off;

% set fake time series in second axes / empty time series
set(handles.main_figure,'CurrentAxes',handles.axes2);
plot([]);
xlabel('Day of Year (DOY)');
ylabel('Index');

% Choose default command line output for phenocamimageprocessor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes phenocamimageprocessor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = phenocamimageprocessor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in setdirbutton.
function setdirbutton_Callback(hObject, eventdata, handles)
% hObject    handle to setdirbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dir_name = uigetdir(handles.basedir,'Select Image Directory');

if handles.dir_name == 0 % if no valid dir is set do nothing, else do...
else                     % akward construction... change
    
    % list all jpeg files in valid directory
    % and get the number of jpegs in the directory
    % all files located in monthly subdirectories, so have to fish each month's
    % photos out
    for i=1:12    
        tmp_files = dir(strcat(handles.dir_name,handles.file_split,sprintf('%02d',i),handles.file_split,'*.jpg'));        
        if i == 1
            handles.jpeg_files = tmp_files;
        elseif i > 1
            handles.jpeg_files = [handles.jpeg_files; tmp_files];
        end
    end
    
    % calculate number of JPEGs
    handles.nrjpegs = size(handles.jpeg_files,1);
    
    
    % check if there are pictures in the folder if not display error
    % else  continue
    if isempty(handles.jpeg_files)
        errordlg('Contains no valid images, please select another directory')
    else
        
        % define containing matrices for year/month/day/hour/min variables
        handles.year = zeros(handles.nrjpegs,1);
        handles.month = zeros(handles.nrjpegs,1);
        handles.day = zeros(handles.nrjpegs,1);
        handles.hour = zeros(handles.nrjpegs,1);
        handles.minutes = zeros(handles.nrjpegs,1);
        
        % extract date/time values from filename using string manipulation
        for i=1:handles.nrjpegs
           parts = regexp(handles.jpeg_files(i,1).name,'_','split');
           handles.year(i) =  str2double(char(parts(2)));
           handles.month(i) =  str2double(char(parts(3)));
           handles.day(i) =  str2double(char(parts(4)));
           time = char(parts(5));
           handles.hour(i) = str2double(time(1:2));
           handles.minutes(i) = str2double(time(3:4));            
        end
        
        % calculate the range of hours of the images (min / max)
        min_hour = min(handles.hour);
        max_hour = max(handles.hour);
        mean_hour = round((min_hour + max_hour) / 2);

        AM = min_hour : (mean_hour-1);
        PM = mean_hour : max_hour;
        
        % set popup hour menu items using min max ranges as calculated above
        set(handles.frompopup, 'String',AM);
        set(handles.topopup, 'String',PM);
        
        % unlock ROI button and nr ROI popup menu (you are now allowed to use these items)
        set(handles.setroibutton,'Enable','on');
        set(handles.popuproi,'Enable','on');
                
        % calculate midday images, broadly interpreted as between 4am and
        % 8pm
        handles.midday_images = char(handles.jpeg_files.name);
        handles.midday_images = handles.midday_images(handles.hour > 4 & handles.hour < 20,:);
        handles.midday_months = handles.month(handles.hour > 4 & handles.hour < 20,:);
        
        % read random image and plot to axes 1
        handles.current_image = imread(strcat(handles.dir_name,handles.file_split,sprintf('%02d',handles.midday_months(1)),handles.file_split,handles.midday_images(1,:)));
        set(handles.main_figure,'CurrentAxes',handles.axes1);
        image(handles.current_image);
        axis off;
        
        % activate load roi menu item in the menu list
        set(handles.menuloadroi,'Enable','on');
        
        % update the listbox listing all files
        set(handles.imagelistbox,'String',handles.midday_images);
       
    end
end

% pass all handles objects to the root / figure
% if you don't do this the handles won't update
guidata(hObject, handles);
    
  
% --- Executes on button press in setroibutton.
function setroibutton_Callback(hObject, eventdata, handles)
% hObject    handle to setroibutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set focus to axes 1
set(handles.main_figure,'CurrentAxes',handles.axes1);

% hold is on for overplotting
% getline grabbed coordinates and polygons
hold on;
    
% get image size
[nrows, ncols, ncolors] = size(handles.current_image);

% define mask output size
% based upon image size and nroi
handles.mask = zeros(nrows,ncols,handles.nroi);


% for the number of nroi do
for i=1:handles.nroi;
        
    % grab polygon coordinates and dump in structure
    [handles.xcoordinates(:,i).poly,handles.ycoordinates(:,i).poly] = getline('closed');
    
    % define binary mask using poly2mask
    handles.mask(:,:,i) = poly2mask(handles.xcoordinates(:,i).poly,handles.ycoordinates(:,i).poly,nrows,ncols);

    % get polygon center for plotting labels
    handles.xcenter(:,i) = mean(handles.xcoordinates(:,i).poly);
    handles.ycenter(:,i) = mean(handles.ycoordinates(:,i).poly);
      
    % overplot the polygon (see hold on above)
    % and text label
    plot(handles.xcoordinates(:,i).poly,handles.ycoordinates(:,i).poly,char(handles.linetype(i,:)),'Color',handles.cmap(i),'LineWidth',2);
    text(handles.xcenter(:,i), handles.ycenter(:,i), num2str(i),'Color',handles.cmap(i), 'FontWeight','Bold');
end

% activate clear ROI button
set(handles.clearroibutton,'Enable','on');

% activate from popup dialogues
set(handles.frompopup,'Enable','on');

% disable Set ROI button until reset
set(handles.setroibutton,'Enable','off');

% disable Set ROI button until reset
set(handles.setdirbutton,'Enable','off');

% disable Set ROI button until reset
set(handles.popuproi,'Enable','off');

% hold is off, will overplot with next plot command
hold off;

% set load/save ROI menu item
set(handles.menuloadroi,'Enable','off');
set(handles.menusaveroi,'Enable','on');

% update handles
guidata(hObject, handles);


% --- Executes on button press in clearroibutton.
function clearroibutton_Callback(hObject, eventdata, handles)
% hObject    handle to clearroibutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear every previously set variable to reassign a new
% region of interest etc.

% delete content of mask
handles.mask = [];

% reset the handles.nroi to 1 / default
handles.nroi = 1;
set(handles.popuproi,'Value',1);

% delete content polygon coordinates
%clear handles.coordinates.X

handles.xcoordinates = rmfield(handles.xcoordinates,'poly');
handles.ycoordinates = rmfield(handles.ycoordinates,'poly');

handles.xcenter = [];
handles.ycenter = [];

% set current axes to axes 1 (top plot)
% and reprint current image without polygons
set(handles.main_figure,'CurrentAxes',handles.axes1);
image(handles.current_image);
axis off;

% deactivate popup / clear ROI / calculate buttons / etc
set(handles.clearroibutton,'Enable','off');
set(handles.frompopup,'Enable','off');
set(handles.topopup,'Enable','off');
set(handles.calculatebutton,'Enable','off');
set(handles.gcccheckbox,'Enable','off');
set(handles.gccsmoothcheckbox,'Enable','off');
set(handles.redcheckbox,'Enable','off');
set(handles.greencheckbox,'Enable','off');
set(handles.bluecheckbox,'Enable','off');
set(handles.gcccheckbox,'Value',0);
set(handles.gccsmoothcheckbox,'Value',0);
set(handles.redcheckbox,'Value',0);
set(handles.greencheckbox,'Value',0);
set(handles.bluecheckbox,'Value',0);
set(handles.checkboxROI1,'Value',0);
set(handles.checkboxROI2,'Value',0);
set(handles.checkboxROI3,'Value',0);
set(handles.checkboxROI1,'Enable','off');
set(handles.checkboxROI2,'Enable','off');
set(handles.checkboxROI3,'Enable','off');
set(handles.pushbuttonupdateplot,'Enable','Off');
set(handles.menusavetsdata,'Enable','off');
set(handles.menusaveroi,'Enable','off');
set(handles.setroibutton,'Enable','on');
set(handles.setdirbutton,'Enable','on');
set(handles.popuproi,'Enable','on');
set(handles.checkbox90th,'Enable','Off');
set(handles.checkboxmean,'Enable','Off');
set(handles.checkboxmedian,'Enable','Off');
set(handles.popupmenuwindowsize,'Enable','Off');
set(handles.darkthreshold,'Enable','off');

% clear results
handles.results = [];

% clear axes 2
set(handles.main_figure,'CurrentAxes',handles.axes2);
ylabel('');
cla(handles.axes2);

% return focus to axes 1
set(handles.main_figure,'CurrentAxes',handles.axes1);

% update handles
guidata(hObject, handles);



% --- Executes on selection change in imagelistbox.
function imagelistbox_Callback(hObject, eventdata, handles)
% hObject    handle to imagelistbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns imagelistbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from imagelistbox

% update preview image when selecting a new image in the listbox

% get selected image
selected_image = get(handles.imagelistbox,'Value');

% plot selected image
%handles.current_image = imread(strcat(handles.dir_name,handles.file_split,handles.midday_images(selected_image,:)));
handles.current_image = imread(strcat(handles.dir_name,handles.file_split,sprintf('%02d',handles.midday_months(selected_image)),handles.file_split,handles.midday_images(selected_image,:)));
set(handles.main_figure,'CurrentAxes',handles.axes1);
hold on;
image(handles.current_image);
axis off;

% overplot the image with a polygon
% and text label
if isempty(handles.xcenter)

% dont try to plot polygons just refresh axes
else
    for i=1:handles.nroi
    plot(handles.xcoordinates(:,i).poly,handles.ycoordinates(:,i).poly,'Color',handles.cmap(i));
    text(handles.xcenter(:,i), handles.ycenter(:,i), num2str(i), 'Color',handles.cmap(i), 'FontWeight','Bold');
    end
end

hold off;
% update handles
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function imagelistbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imagelistbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in frompopup.
function frompopup_Callback(hObject, eventdata, handles)
% hObject    handle to frompopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns frompopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from frompopup

val = get(handles.frompopup,'Value'); % get value / location
str = get(handles.frompopup,'String'); % get all strings in popup
handles.start_time = str2double(strcat(str(val,1),str(val,2))); % concat strings and convert to double

% if set enable topopup
set(handles.topopup,'Enable','on');

% update handles
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function frompopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frompopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in topopup.
function topopup_Callback(hObject, eventdata, handles)
% hObject    handle to topopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns topopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from topopup

val = get(handles.topopup,'Value'); % get value / location
str = get(handles.topopup,'String'); % get all strings in popup
handles.end_time = str2double(strcat(str(val,1),str(val,2))); % concat strings and convert to double

% activate calculation options
set(handles.checkbox90th,'Enable','On');
set(handles.checkbox90th,'Value',1);
set(handles.checkboxmean,'Enable','Off');
set(handles.checkboxmedian,'Enable','Off');
set(handles.popupmenuwindowsize,'Enable','On');
set(handles.calculatebutton,'Enable','On');
set(handles.darkthreshold,'Enable','on');

% update handles
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function topopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to topopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calculatebutton.
function calculatebutton_Callback(hObject, eventdata, handles)
% hObject    handle to calculatebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.results);

% make a list of subsetted jpegs to be processed
handles.subset_images = char(handles.jpeg_files.name);
handles.subset_images = handles.subset_images(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);
handles.subset_months = handles.month(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);

% get the length of this list
size_subset_images = size(handles.subset_images,1);

% subset year / month / day / hour / min
subset_year = handles.year(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);
subset_month = handles.month(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);
subset_day = handles.day(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);
subset_hour = handles.hour(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);
subset_min = handles.minutes(handles.hour >= handles.start_time & handles.hour <= handles.end_time,:);

% convert year / month / day / hour / min ... sec to matlab date
subset_year = unique(subset_year');
subset_month = subset_month';
subset_day = subset_day';
subset_hour = subset_hour';
subset_min = subset_min';

% calculate doy from year / month / ...
handles.subset_doy = date2jd(subset_year,subset_month,subset_day,subset_hour,subset_min);
handles.max_doy = max(unique(handles.subset_doy));
handles.min_doy = min(unique(handles.subset_doy));

% make a martrix to contain the results (length list, indices - 5)
handles.results = zeros(size_subset_images,6,handles.nroi);

% fill year column
handles.results(:,1,:) = subset_year;

% waitbar settings
h = waitbar(0,'Please wait...','Name','Processing Images...',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');        
        
for i=1:size_subset_images;
    
    % this part needs vectorization as it slows down the whole
    % calculation to much
    % calculate gcc ./ mask and for every layer grab the mean
    
    % Check for Cancel button press
    if getappdata(h,'canceling') % grab cancel button hit
        %delete(h); % delete wait bar handle
        break % interupt the processing
    end
    % Report current estimate in the waitbar's message field
    waitbar(i/size_subset_images);
    
    % calculate DOY 
    handles.results(i,2,:) = date2jd(subset_year, subset_month(i), subset_day(i), subset_hour(i), subset_min(i));  
    
    % read in image
    img =   imread(strcat(handles.dir_name,handles.file_split,sprintf('%02d',handles.subset_months(i)),handles.file_split,handles.subset_images(i,:)));
    % split image in its components
    red = img(:,:,1);
    green = img(:,:,2);
    blue = img(:,:,3);
    
    % calculate green chromatic coordinates    
    for j=1:handles.nroi
        mask = handles.mask(:,:,j);
        
        handles.results(i,3,j) = mean(mean(red(mask == 1)));
        handles.results(i,4,j) = mean(mean(green(mask == 1)));
        handles.results(i,5,j) = mean(mean(blue(mask == 1)));
        
         % calculate green chromatic coordinates
        gcc = handles.results(i,4,j) ./ (handles.results(i,3,j) + handles.results(i,4,j) + handles.results(i,5,j));
        
        % put gcc values in results
        handles.results(i,6,j) =  gcc;
    end    
end

% delete waitbar handle when done
delete(h);

end

% set window size
val = get(handles.popupmenuwindowsize,'Value'); % get value / location
str = get(handles.popupmenuwindowsize,'String'); % get all strings in popup
windowsize = floor(str2double(str(val,1)));
windowsize = floor(windowsize/2);

% smooth the data using the moving quantile method
l = round(handles.max_doy - windowsize);

% make matrix to dump smoothed results in
handles.gccsmooth = zeros(round(handles.max_doy),1,handles.nroi);

% set threshold (dark images)
threshold = 255*(handles.threshold/100);

% smooth time series
for i=1:handles.nroi;
     
    DOY = round(handles.results(:,2,i));
     
    for n=windowsize+1:l;
        
        handles.gccsmooth(n,1,i) = n;
        
        if windowsize == 0;
        subset = handles.results(DOY == n & handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,6,i);
        else
        subset = handles.results(DOY >= n-windowsize & DOY <= n+windowsize & handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,6,i);
        end
        
        % 90th percentile
        if get(handles.checkbox90th,'Value') == 1
        handles.gccsmooth(n,2,i)=myquantile(subset,0.9);
        end    
        % mean
        if get(handles.checkboxmean,'Value') == 1
        handles.gccsmooth(n,2,i)=nanmean(subset);
        end
        % median
        if get(handles.checkboxmedian,'Value') == 1
        handles.gccsmooth(n,2,i)=nanmedian(subset);
        end
        
    end
 end

 
% make plotting options available
set(handles.gcccheckbox,'Enable','on');
set(handles.gccsmoothcheckbox,'Enable','on');
set(handles.redcheckbox,'Enable','off');
set(handles.greencheckbox,'Enable','off');
set(handles.bluecheckbox,'Enable','off');

% check the gcc box
set(handles.gcccheckbox,'Value',1);
set(handles.gccsmoothcheckbox,'Value',1);
set(handles.redcheckbox,'Value',0);
set(handles.greencheckbox,'Value',0);
set(handles.bluecheckbox,'Value',0);

% set ROI checkboxes
if handles.nroi == 1;
    set(handles.checkboxROI1,'Value',1);
end

if handles.nroi == 2;
    set(handles.checkboxROI1,'Enable','On');
    set(handles.checkboxROI1,'Value',1);
    set(handles.checkboxROI2,'Enable','On');
    set(handles.checkboxROI2,'Value',1);
end

if handles.nroi == 3;
    set(handles.checkboxROI1,'Enable','On');
    set(handles.checkboxROI1,'Value',1);
    set(handles.checkboxROI2,'Enable','On');
    set(handles.checkboxROI2,'Value',1);
    set(handles.checkboxROI3,'Enable','On');
    set(handles.checkboxROI3,'Value',1);
end


% clear axes 2
set(handles.main_figure,'CurrentAxes',handles.axes2);
ylabel('');
xlabel('Day of Year (DOY)');
cla(handles.axes2);

hold on;

% set axes parameters
set(handles.main_figure,'CurrentAxes',handles.axes2);

% remove 0's
handles.gccsmooth = handles.gccsmooth(handles.gccsmooth(:,1,1) ~= 0,:,:);

% trim data (every 3 samples)
handles.gccsmooth = handles.gccsmooth(1:(windowsize*2)+1:end,:,:);

%handles.gccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,6,i);
%handles.doygccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,2,i);

% plot gccsmooth graphs for ROI 1
for i=1:handles.nroi;
    
    handles.gccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,6,i);
    handles.doygccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,2,i);
    
    ylabel('GCC');
    plot(handles.gccsmooth(:,1,i),handles.gccsmooth(:,2,i),'-','Color',handles.cmap(i),'LineWidth',2);
    plot(handles.doygccsubset,handles.gccsubset,'.','Color',handles.cmap(i));
end
hold off;

% enable save menu items
set(handles.menusavetsdata,'Enable','On');

% set update button
set(handles.pushbuttonupdateplot,'Enable','On');

% update handles
guidata(hObject, handles);


% --- Executes on button press in gcccheckbox.
function gcccheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to gcccheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gcccheckbox

% get checkbox status (both gcc's)
gccstatus = get(handles.gcccheckbox,'Value');
gccsmoothstatus = get(handles.gccsmoothcheckbox,'Value');

if gccstatus + gccsmoothstatus >= 1;
    
    % clear rgb checkboxes (should be mutually exclusive)
    set(handles.redcheckbox,'Value',0);
    set(handles.greencheckbox,'Value',0);
    set(handles.bluecheckbox,'Value',0);
    
    set(handles.redcheckbox,'Enable','off');
    set(handles.greencheckbox,'Enable','off');
    set(handles.bluecheckbox,'Enable','off');
    
else
    hold off;
    ylabel('');
    cla(handles.axes2);
    set(handles.redcheckbox,'Enable','on');
    set(handles.greencheckbox,'Enable','on');
    set(handles.bluecheckbox,'Enable','on');
end



% --- Executes on button press in gccsmoothcheckbox.
function gccsmoothcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to gccsmoothcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gccsmoothcheckbox
% get checkbox status (both gcc's)
gccstatus = get(handles.gcccheckbox,'Value');
gccsmoothstatus = get(handles.gccsmoothcheckbox,'Value');

if gccstatus + gccsmoothstatus >= 1;
    
    % clear rgb checkboxes (should be mutually exclusive)
    set(handles.redcheckbox,'Value',0);
    set(handles.greencheckbox,'Value',0);
    set(handles.bluecheckbox,'Value',0);
    
    set(handles.redcheckbox,'Enable','off');
    set(handles.greencheckbox,'Enable','off');
    set(handles.bluecheckbox,'Enable','off');
    
else
    hold off;
    ylabel('');
    cla(handles.axes2);
    set(handles.redcheckbox,'Enable','on');
    set(handles.greencheckbox,'Enable','on');
    set(handles.bluecheckbox,'Enable','on');
end

% --- Executes on button press in redcheckbox.
function redcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to redcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of redcheckbox

% overplot if it is another RGB colour (see below)
%hold on;

% set plotting axes
%set(handles.main_figure,'CurrentAxes',handles.axes2);

% get checkbox status (RGB)
redstatus = get(handles.redcheckbox,'Value');
greenstatus = get(handles.greencheckbox,'Value');
bluestatus = get(handles.bluecheckbox,'Value');

if redstatus + greenstatus + bluestatus >= 1;
    
    % clear axes and plot everything again
    cla(handles.axes2) ;
    
    % clear rgb checkboxes (should be mutually exclusive)
    set(handles.gcccheckbox,'Value',0);
    set(handles.gccsmoothcheckbox,'Value',0);
    
    set(handles.gcccheckbox,'Enable','off');
    set(handles.gccsmoothcheckbox,'Enable','off');
    
else
    hold off;
    ylabel('');
    cla(handles.axes2);
    set(handles.gcccheckbox,'Enable','on');
    set(handles.gccsmoothcheckbox,'Enable','on');
end


% --- Executes on button press in greencheckbox.
function greencheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to greencheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of greencheckbox

% set plotting axes
set(handles.main_figure,'CurrentAxes',handles.axes2);

% get checkbox status (RGB)
redstatus = get(handles.redcheckbox,'Value');
greenstatus = get(handles.greencheckbox,'Value');
bluestatus = get(handles.bluecheckbox,'Value');

if redstatus + greenstatus + bluestatus >= 1

    % clear rgb checkboxes (should be mutually exclusive)
    set(handles.gcccheckbox,'Value',0);
    set(handles.gccsmoothcheckbox,'Value',0);
    
    set(handles.gcccheckbox,'Enable','off');
    set(handles.gccsmoothcheckbox,'Enable','off');
    
else
    hold off;
    ylabel('');
    cla(handles.axes2);
    set(handles.gcccheckbox,'Enable','on');
    set(handles.gccsmoothcheckbox,'Enable','on');
end


% --- Executes on button press in bluecheckbox.
function bluecheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to bluecheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bluecheckbox

% overplot if it is another RGB colour (see below)
%hold on;

% set plotting axes
set(handles.main_figure,'CurrentAxes',handles.axes2);

% get checkbox status (RGB)
redstatus = get(handles.redcheckbox,'Value');
greenstatus = get(handles.greencheckbox,'Value');
bluestatus = get(handles.bluecheckbox,'Value');

if redstatus + greenstatus + bluestatus >= 1;
    
    % clear rgb checkboxes (should be mutually exclusive)
    set(handles.gcccheckbox,'Value',0);
    set(handles.gccsmoothcheckbox,'Value',0);
    
    set(handles.gcccheckbox,'Enable','off');
    set(handles.gccsmoothcheckbox,'Enable','off');
    
else
    hold off;
    ylabel('');
    cla(handles.axes2);
    set(handles.gcccheckbox,'Enable','on');
    set(handles.gccsmoothcheckbox,'Enable','on');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over setroibutton.
function setroibutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to setroibutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menufile_Callback(hObject, eventdata, handles)
% hObject    handle to menufile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuloadroi_Callback(hObject, eventdata, handles)
% hObject    handle to menuloadroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file,path] = uigetfile('*.mat','Load ROI...');
% filename = strcat(path,'/',file);
filename = strcat(path,handles.file_split,file);

% save data
mask = load(filename);
handles.mask = int8(mask.roiimg);

% hold is on for overplotting
% getline grabbed coordinates and polygons
hold on;
    
% get image size / nr ROI
handles.nroi = size(mask.roiimg,3);

% for the number of nroi do
for i=1:handles.nroi;
    
    % get polygon from mask
    loc = bwboundaries(handles.mask(:,:,i));
    loc = cell2mat(loc);
    
    % grab polygon coordinates and dump in structure
    handles.xcoordinates(:,i).poly = loc(:,2);
    handles.ycoordinates(:,i).poly = loc(:,1);

    % get polygon center for plotting labels
    handles.xcenter(:,i) = mean(handles.xcoordinates(:,i).poly);
    handles.ycenter(:,i) = mean(handles.ycoordinates(:,i).poly);

    % overplot the polygon (see hold on above)
    % and text label
    plot(handles.xcoordinates(:,i).poly,handles.ycoordinates(:,i).poly,'Color',handles.cmap(i));
    text(handles.xcenter(:,i), handles.ycenter(:,i), num2str(i), 'Color',handles.cmap(i), 'FontWeight','Bold');

end

% activate clear ROI button
set(handles.clearroibutton,'Enable','on');

% activate from popup dialogues
set(handles.frompopup,'Enable','on');

% disable Set ROI button until reset
set(handles.setroibutton,'Enable','off');

% disable Set ROI button until reset
set(handles.setdirbutton,'Enable','off');

% disable Set ROI button until reset
set(handles.popuproi,'Enable','off');

hold off;

% pass all handles objects to the root / figure
% if you don't do this the handles won't update
guidata(hObject, handles);


% --------------------------------------------------------------------
function menusaveroi_Callback(hObject, eventdata, handles)
% hObject    handle to menusaveroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file,path] = uiputfile('*.mat','Save ROI...');
filename = strcat(path,'/',file);
roiimg = handles.mask;

% save data
save(filename, 'roiimg');

% --------------------------------------------------------------------
function menusavetsdata_Callback(hObject, eventdata, handles)
% hObject    handle to menusavetsdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file,path] = uiputfile('*.txt','Save time series data...');

for i=1:handles.nroi;

filenameraw = strcat(path,'/','raw-',num2str(i),'-',file);
filenamesmooth = strcat(path,'/','smooth-',num2str(i),'-',file);
rawdata = handles.results(:,:,i);
smoothdata = handles.gccsmooth(:,:,i);

% add year to smoothed data
year = unique(handles.year);
l = size(smoothdata,1);
years = zeros(l,1);
years(:,1) = year;
smoothdata = [years, smoothdata];

dlmwrite(filenameraw,rawdata);
dlmwrite(filenamesmooth,smoothdata);

end


% --- Executes on selection change in popuproi.
function popuproi_Callback(hObject, eventdata, handles)
% hObject    handle to popuproi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popuproi contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popuproi

% set the number of ROI to use in the analysis
handles.nroi = get(handles.popuproi,'Value');

% pass all handles objects to the root / figure
% if you don't do this the handles won't update
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popuproi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popuproi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuabout_Callback(hObject, eventdata, handles)
% hObject    handle to menuabout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuphenocam_Callback(hObject, eventdata, handles)
% hObject    handle to menuphenocam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

about = fileread('ABOUT.txt');
msgbox(about,'About PhenoCam');

% --------------------------------------------------------------------
function menuphenocamtool_Callback(hObject, eventdata, handles)
% hObject    handle to menuphenocamtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disclaimer = fileread('DISCLAIMER.txt');
msgbox(disclaimer,'DISCLAIMER');


% --- Executes on button press in checkboxROI1.
function checkboxROI1_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxROI1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxROI1


% --- Executes on button press in checkboxROI2.
function checkboxROI2_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxROI2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxROI2


% --- Executes on button press in checkboxROI3.
function checkboxROI3_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxROI3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxROI3


% --- Executes on button press in pushbuttonupdateplot.
function pushbuttonupdateplot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonupdateplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% get checkbox status (RGB)
redstatus = get(handles.redcheckbox,'Value');
greenstatus = get(handles.greencheckbox,'Value');
bluestatus = get(handles.bluecheckbox,'Value');

% get checkbox status (both gcc's)
gccstatus = get(handles.gcccheckbox,'Value');
gccsmoothstatus = get(handles.gccsmoothcheckbox,'Value');

% get checkbox status (ROI)
roi1 = get(handles.checkboxROI1,'Value');
roi2 = get(handles.checkboxROI2,'Value');
roi3 = get(handles.checkboxROI3,'Value');

% check if there are pictures in the folder if not display error
% else  continue
if redstatus + greenstatus + bluestatus + gccstatus + gccsmoothstatus == 0;
     errordlg('Please select an index value');
else
    
    if roi1 + roi2 + roi3 == 0;
         errordlg('Please select ROI(s)');
    else

    roi_selected = [roi1 roi2 roi3];
    rois = [1 2 3];
    rois = rois(roi_selected==1);

    % clear axes2
    cla(handles.axes2) ;

    % set axes parameters
    set(handles.main_figure,'CurrentAxes',handles.axes2);
    hold on;
    xlabel('Day of Year (DOY)');
    
    for i=rois;
   
        if redstatus == 1;
                % set the label
                ylabel('DN');
                plot(handles.results(:,2,1),handles.results(:,3,i),char(handles.linetype(i,:)),'Color',[1 0 0],'LineWidth',2);
        end
        if greenstatus == 1;
                % set the label
                ylabel('DN');
                plot(handles.results(:,2,1),handles.results(:,4,i),char(handles.linetype(i,:)),'Color',[0 1 0],'LineWidth',2);
        end
        if bluestatus == 1;
                % set the label
                ylabel('DN');
                plot(handles.results(:,2,1),handles.results(:,5,i),char(handles.linetype(i,:)),'Color',[0 0 1],'LineWidth',2);
        end

        if gccstatus == 1;
                % set the label
                % set threshold (dark images)
                threshold = 255*(handles.threshold/100);
                handles.gccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,6,i);
                handles.doygccsubset = handles.results(handles.results(:,3,i) > threshold & handles.results(:,4,i) > threshold & handles.results(:,5,i) > threshold,2,i);                
                ylabel('GCC');
                plot(handles.doygccsubset,handles.gccsubset,'.','Color',handles.cmap(i),'LineWidth',2);
        end

        if gccsmoothstatus == 1;
                % set the label
                ylabel('GCC');
                plot(handles.gccsmooth(:,1,i),handles.gccsmooth(:,2,i),'-','Color',handles.cmap(i),'LineWidth',2);
        end

    end

    end
end
hold off;


% --- Executes on selection change in popupmenuwindowsize.
function popupmenuwindowsize_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuwindowsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuwindowsize contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuwindowsize


% --- Executes during object creation, after setting all properties.
function popupmenuwindowsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuwindowsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox90th.
function checkbox90th_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox90th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox90th


if get(handles.checkbox90th, 'Value') == 1;
    set(handles.checkboxmean,'Value',0);
    set(handles.checkboxmedian,'Value',0);
    set(handles.checkboxmean,'Enable','Off');
    set(handles.checkboxmedian,'Enable','Off');
    set(handles.calculatebutton,'Enable','On');
else
    set(handles.checkboxmean,'Enable','On');
    set(handles.checkboxmedian,'Enable','On');
    set(handles.calculatebutton,'Enable','Off');
end



% --- Executes on button press in checkboxmean.
function checkboxmean_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxmean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxmean

if get(handles.checkboxmean, 'Value') == 1;
    set(handles.checkbox90th,'Value',0);
    set(handles.checkboxmedian,'Value',0);
    set(handles.checkbox90th,'Enable','Off');
    set(handles.checkboxmedian,'Enable','Off');
    set(handles.calculatebutton,'Enable','On');
else
    set(handles.checkbox90th,'Enable','On');
    set(handles.checkboxmedian,'Enable','On');
    set(handles.calculatebutton,'Enable','Off');
end


% --- Executes on button press in checkboxmedian.
function checkboxmedian_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxmedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxmedian
if get(handles.checkboxmedian, 'Value') == 1;
    set(handles.checkboxmean,'Value',0);
    set(handles.checkbox90th,'Value',0);
    set(handles.checkboxmean,'Enable','Off');
    set(handles.checkbox90th,'Enable','Off');
    set(handles.calculatebutton,'Enable','On');
else
    set(handles.checkboxmean,'Enable','On');
    set(handles.checkbox90th,'Enable','On');
    set(handles.calculatebutton,'Enable','Off');
end


% --- Executes on selection change in darkthreshold.
function darkthreshold_Callback(hObject, eventdata, handles)
% hObject    handle to darkthreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns darkthreshold contents as cell array
%        contents{get(hObject,'Value')} returns selected item from darkthreshold

val = get(handles.darkthreshold,'Value'); % get value / location
str = get(handles.darkthreshold,'String'); % get all strings in popup
handles.threshold = str2double(str(val,1)); % concat strings and convert to double

% pass all handles objects to the root / figure
% if you don't do this the handles won't update
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function darkthreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to darkthreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
