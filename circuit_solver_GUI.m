function circuit_solver_GUI
%
% Application for creating and solving custom electric circuits
%
% David Richardson
% 2/19/2023
%
% Write Forward later ~~~
%
%

% 10/19/2023 looks like all feature are meeting functionality requirements 
% adequately. Some relativley minor issues remain on circuit resizing,
% there are a few significant items on the list to implement, and we are
% dissallowing node side add-ons to child side.
%
% then it may be onto beautifying

% Things to fix before adding new stuff or showing this :
% - mouse icon is slipping up sometimes (I have no idea why or how to fix)
% - redraw circuit is different from originally using H0 and W0. Thats odd

%% Willa Notes
%
% - get rid of variable name column in options 
%   color: black text on any light color backgorund i.e. gold is BAD
% - drop the gold,                                                          [done]
% - change green for blue bckground                                         [done]
% - for the settings panel, do a lighter version of bcgkround blue          [none]
% - each options group gets ind. panel                                      
% - Rename and associate group 'format'                                     [done]
% - option to print circuit to pdf !                                        [none] ~~~ not easy but very cool idea!
%       - Probably needs seperate optoins group in Settings                 
% - Seperate batteries and resistors by case A vs a (smart)                 [done] 
% - change your fonts (to what???)                                          [none] ~~~
% - uniform desc. length for options
% - borders around axis!                                                    [none] ~~~ no clue
% - Title banner for whole figure                                           [none] ~~~
% - add element 'title'                                            
% - 'show all details' button for element properties                        [not sure]
% - highlight element upon right-click
% - copy and paste element to context menu
% - 'edit' in addition to delete for value AND ID! (nice)                   [done]  
%
%% Data Stored in UserData struct :
%
% ==================================================================
% Revision II 
% ==================================================================
% f.UserData.
%               element_add  
%               NodeAddMode
%               Side_Count
%               HighLight_obj           
%               Selected_obj
%               Lock
%               Changed_opts
%               Settings_w
%               ShowResize
%               ToolBarHeight
%               old
%                               UserData
%                               B_Table
%                               R_Table
%               Temp
%                               Side_ind
%                               Line_ind
%                               Node_ind
%               Nodes(i)      
%                               Position
%                               In
%                               Out
%                               Show
%               Sides(i)       
%                               Tag
%                               Origin
%                               Direction
%                               Length
%                               isOriginal
%                               Group_ind               
%                               Parent_ind
%                               FollowedBy      ~~~ not used yet
%                               branch_height   
%                               NodePos
%                               Nodes      
%                               Elements{i} 
%                                               Type        
%                                               Side_ind    
%                                               Rel_Origin  
%                                               Length
%                                               x_plot
%                                               y_plot  
%                                               ID 
%               Symbols
%
%                               pointers
%                                               Split
%                                               Resistor
%                                               Battery
%                               btn_icons
%                                               Split
%                                               Resistor
%                                               Battery
%                               icon_plots
%                                               Resistor
%                                                           x
%                                                           y
%                                               Battery
%                                                           x
%                                                           y
%
%% To Do List
%
% Node functionality
%   - draw                                (!!!)         [done] 
%   - solve                                             [done] 
%   - resize                                            [done]  
%
% Save and load configuration                           [done]
%
% Error for non-numeric entry for element value         [done]
%
% Initial Layout button ('clear')                       [done]
%
% Display and make editable options struct (!!)         [done]
%
% Fix undo button; add adjustment to  R and B tables    [done]
%
% Options Grouping and non display                      [done] ~~~ beautify
%
% Make element values adjustable (Ohms, Volts)          [done]
%
% DELETE element (from table and plot)                  [done]
%
% Make settings savable  with default                   [done]
%
% Change load/save, insist on "config.mat" as fake ext. [done]
%
% Child Side plus button                                [none] ~~~ hold (reconsidering hold)
%
% Place control buttons in a toolbar                    [done]
%
% make settings a pop-up like every program             [none] ~~~ plot
%
% *** Show scrollover button options (!!)               [done]
%
% (maybe) GND button and functionality                  [maybe]
%
% Update tables upon reapply options call               [done] 
%
% Merger conflict on sides !                            [none] ~~~ hold
%       combined with side extender!                    [none]
%
% Copy side elements across twin branch sides           [none] * associated with child-side plus button*
%
% Undo needs to save UserData (more of a bug)           [done]
% 
% UserData Node Add Mode! (maybe -- I'm not sold yet)   [none] ~~~
%
% Add Sides to Nodes! Draw, solve, resize               [none] ~~~ **
%
% Make Display mode optional for push node w/ speed opt [done]
%
% (maybe) redraw_element (imag. many els, change name)  [none]
%
% Add closing function to main gui to close subfigures  [none] ~~~
%
% Make uitable editing reflect in UserData & edit gui   [done]
%
% Implement warning/err for newnode side on child side  [done] 
%
% Option to show element values instead of IDs !!       [none] ~~~ **
%
% Element labels should have their own fontsize option  [done] 
%
% All options that control circuit plotting get subgui  [none] ~~~
%   ^ Different re-apply function (redraw_square)
%
% Add gui option for nodeaddmode (maybe?)               [none]
%
% Fix and Test drawing on node                          [none] ~~~
%

%% Quick Bugs 

% not as major solves as above, shorter doc

% - add new element name always based on last element name.
%   - fix, test w editing name of only el then adding a second el

%% Main

% include path
folder = fileparts(mfilename("fullpath"));
p = genpath(folder);
addpath(p)

dbstop if error
Create_GUI
end

function Create_GUI(UserData,R_Table,B_Table)
%% Application Startup Call

% Read options either from saved current or default
if exist('CS_UserSettings.mat','file')
    load('CS_UserSettings.mat','opts_set')
else
    opts_set = default_opts;
end

% read option set cell array values
opts = read_opts(opts_set);

% Create and initialize figure
f = create_figure(opts);

% Add axes area
ax_obj = add_axes(f,opts);

% Add circuit Toolbar
add_toolbar(f,ax_obj,opts)

% Add uitabs to show various results tables
add_tabgroup(f,ax_obj,opts_set,opts)

% Initialize axes with closed loop or exisiting sides (depending on call)
if exist('UserData','var')
    initial_layout(f,opts,UserData,'')
    reset_table_data(f,'load',{R_Table,B_Table})
else
    initial_layout(f,opts,'','')
end

drawnow
f.Pointer = 'arrow';
end

function opts = default_opts
%% Default configuration options

% options field format (4 fields):
%   opts.fieldname = {default, description, isEditable, Grouping}

% Groups : 'General Optics', 'Format', 'Settings tab', 'Symbols', 'Other', 'None'

% general optics

opts.LW         = {4.5, 'Linewidth',                                            true,   'Format'};
opts.node_MS    = {30,  'Node MarkerSize',                                      true,   'Format'};
opts.FS         = {14,  'Font Size',                                            true,   'General Optics'};
opts.FS_lab     = {17,  'Font Size for Element Labels',                         true,   'Format'};
opts.spacer     = {5,   'spacer between GUI elements',                          true,   'General Optics'};
opts.cspace     = {25,  'circuit spacer between el. elements / plot  corners',  true,   'Format'};
opts.aspace     = {100, 'Space between longer circuit axes and plot axis range',true,   'Format'};
opts.ax_l       = {625, 'Axis length',                                          true,   'Format'};
opts.W0         = {450, 'Initial rectangular circuit width',                    true,   'Format'};
opts.H0         = {350, 'Initial rectangular circuit height',                   true,   'Format'};
opts.btn_s      = {80,  'Square button size',                                   true,   'General Optics'};
opts.btn_w      = {80,  'rectangular button width',                             true,   'General Optics'};
opts.btn_w_l    = {130, 'button width, large',                                  true,   'General Optics'};
opts.btn_h      = {30,  'rectangular button height',                            true,   'General Optics'};
opts.btn_Th     = {3,   'Thickness for Button Icon Image',                      true,   'General Optics'};
opts.ax_clr     = {0.94*[1,1,1], 'Axes Background color'                        true,   'General Optics'};

% settings tab

opts.txt_h      = {20,  'Height of Various Text Boxes (Settings)',              true,   'Settings tab'};
opts.name_w     = {100, 'Variable name width',                                  true,   'Settings tab'};
opts.desc_w     = {340, 'Variable description width',                           true,   'Settings tab'};
opts.val_w      = {80,  'Variable value width',                                 true,   'Settings tab'};
opts.txt_h_l    = {35,  'Height of Options Subsections Banner'                  true,   'Settings tab'};

% toolbar 
opts.toolbar_h  = {60,   'Height of editing Toolbar',                           true,   'Toolbar'};
opts.titledbar  = {false,'Flag for including editing toolbar title',            true,   'Toolbar'};
opts.toolbarClr = {[.48,.65,.9],'BackGround Color for Toolbar',                 true,   'Toolbar'};

% edit tab  

opts.edit_sz    = {[200,200], 'Editing Element uifigure size',                  true,   'Edit tab'};

% other (?) 

opts.bck_clr    = {[220,236,250]/255, 'Background Color (RGB)',                 true,   'General Optics'}; % muted green rn
opts.config_sz  = {[700,750],'Save configuration subfigure size',               true,   'Other'};
opts.fn         = {'circuit_solver_directory.txt','file storing directory name',true,   'None'};

% Symbols

opts.R_l        = {60,  'Resistor symbol plot length',                          true,   'Symbols'};
opts.R_h        = {6,   'Resistor symbol plot height',                          true,   'Symbols'};
opts.R_tail     = {.2,  'Resistor symbol tail length ratio to length',          true,   'Symbols'};
opts.bat_l      = {60,  'Battery symbol plot length',                           true,   'Symbols'};
opts.Spl_l      = {.55, 'Split symbol length ratio',                            true,   'Symbols'};
opts.Spl_h      = {.3,  'Split symbol height ratio',                            true,   'Symbols'};

% table display

opts.R_tab_cols     = {{'Ohms','Amps','Volts'},'Resistor table columns',        false,  'None'};
opts.B_tab_cols     = {{'Volts','Amps','Watts'},'Battery table columns',        false,  'None'};
opts.table_height   = {550, 'Table Height',                                     true,   'General Optics'};

% circuit options
p_l = opts.R_l{1} + 2*opts.cspace{1};
p_h = opts.R_h{1} + 2/3*opts.cspace{1};
h_c_str = 'HighLightClr';
s_c_str = 'SelectedClr';
h_c = [128, 0, 0]/255;
s_c = [249,134,134]/255;

opts.parl_l     = {p_l, 'Default parallel side lengths',                        false,  'Format'}; % default child side length
opts.parl_h     = {p_h, 'Default parallel side heights',                        false,  'Format'}; 
opts.(h_c_str)  = {h_c, 'Highlight color for adding elements',                  true,   'Format'}; % Maroon (atm)
opts.(s_c_str)  = {s_c, 'Display color for chosen side',                        true,   'Format'}; % Muted Maroon (atm)
opts.ResizeTime = {.25, 'Show-Resize delay time for color higlights',           true,   'Format'};
opts.PlotDelay  = {.075, 'Circuit-plot delay time',                             true,   'Format'};

% prompts

opts.prompt_Split       = {'Enter Number of new current branches (int > 1)','User Prompt for split current',false,'None'}; 
opts.prompt_Resistor    = {'Enter Resistance, Ohms','User Prompt for Resistor strength',                    false,'None'};
opts.prompt_Battery     = {'Enter Battery strength, Volts','User Prompt for Battery strength',              false,'None'};
end

function opts = read_opts(opts_set)
%% Read values from opts_set cell matirx

opts = struct;
fn = fieldnames(opts_set);
for i = 1:length(fn)
    opts.(fn{i}) = opts_set.(fn{i}){1};
end
end

function f = create_figure(opts)
%% Create and initialize main uifigure

f = uifigure('Name','Steady State Circuit Solver V0.3'); 

% Show loading
f.Pointer = 'watch';
drawnow % this is INTERESTING and I need to investigate more. But it works

% figure width : 
Settings_w = opts.name_w + opts.desc_w + opts.val_w + 4*opts.spacer;

settings_extra = 10;
Settings_w = Settings_w + settings_extra; % ~~~ TEMPORARY -- MAKE OPTION
% add all figure elements' widths left to right
f.Position(3) = opts.ax_l +Settings_w + 6*opts.spacer; 

% figure height
tbh = opts.toolbar_h;
if opts.titledbar
    tbh = tbh + 22.5;
end
f.UserData.ToolBarHeight = tbh;

column_lenghts = [opts.ax_l + tbh, opts.table_height + 2 * opts.spacer];
f.Position(4)  = max(column_lenghts) + 2*opts.spacer;
centerfig(f)

f.Color = opts.bck_clr;  

% Draw element symbols and store into figure UserData
draw_symbols(f,opts)

% Add conditional escape key function
f.WindowKeyPressFcn = @(f,key)Escape_add_mode(f,opts,key);

% Set empty temp data (for element adding)
f.UserData.Temp             = [];

% Set empty changed options (filled in by user value change)
f.UserData.Changed_opts     = {};

% Set Highlight(ed) states to false (for side selection & hovering)
f.UserData.HighLight_obj    = [];
f.UserData.Selected_obj     = [];

% Store solved settings width for future creation
f.UserData.Settings_w       = Settings_w;

% Set Lock to false
f.UserData.Lock             = false;

% Set Element Add mode to Empty
f.UserData.element_add      = '';

% Set Default Mode for adding nodes
f.UserData.NodeAddMode      = 'automatic';

% Set Default Mode for show circuit resizing with color highlights
f.UserData.ShowResize       = true;
end

function add_toolbar(f,ax_obj,opts)
%% Add toolbar panel (not uitoolbar) for editing purposes

% add panel
toolbar_ax_offset_h = 5; % 
tb_pos = ax_obj.Position + [1,0,-2,0] * toolbar_ax_offset_h;
tb_pos(2) = opts.spacer;
tb_pos(4) = f.UserData.ToolBarHeight;

p = uipanel(f,'Position',tb_pos,'BackgroundColor',opts.toolbarClr);

if opts.titledbar
    p.Title = 'Control Bar';
end

% define button functionality and criteria

Txt     = {'',       '',        '',     'Lock','Save','Load','Solve','Undo','Clear'};
tags    = {'Battery','Resistor','Split','Lock','Save','Load','Solve','Undo','Clear'};
icon    = {[],[],[],'','save.jpg','download.png','checkmark.png','Undo.jpg','trash.png'};
fcn     = {@(btn,~) add_element(btn),...
           @(btn,~) add_element(btn),...
           @(btn,~) add_element(btn),...
           @(ch,~)  switch_lock_mode(f,ch,opts),...
           @(btn,~) Save_Circuit(f,btn,opts),...
           @(btn,~) Load_Circuit(f,btn,opts),...
           @(btn,~) Solve_Circuit(btn,f),...
           @(btn,~) Restore_Prev_Sides(f,btn,opts)...
           @(btn,~) initial_layout(f,opts,'','clear',btn)
           };

% *** Order Displayed ***
order = [1,2,3,4,8,9,6,5,7];

% Plot state buttons
btn_h = opts.toolbar_h - 2 * opts.spacer;
for i = 1:numel(Txt)

    % element position
    ipos = order(i);
    el_pos = [opts.spacer + (opts.spacer + btn_h)*(ipos-1),opts.spacer,btn_h,btn_h];

    btn = uibutton(p,'state','Text',Txt{i},'FontSize',opts.FS,'Position',...
        el_pos,'ValueChangedFcn',fcn{i},'Tag',tags{i});
    if ~isempty(icon{i}) 
        btn.Icon = icon{i};
    elseif i ~= 4
        btn.Icon = f.UserData.Symbols.btn_icons.(tags{i});    
    end
    btn.IconAlignment = 'top';
end
end

function add_element(btn)
%% Get ready to accept user-add circuit element

% Change pointer :
f = btn.Parent.Parent;
f.Pointer = 'custom';
pause(.1)
f.PointerShapeCData = f.UserData.Symbols.pointers.(btn.Tag); 
drawnow % This works! Nice ~~~ no it dont. nevermind.

% Turn on hover capabailty
iptPointerManager(f,'enable')

% Set figure mode to circuit element add mode
f.UserData.element_add = btn.Tag; 
end

function switch_lock_mode(f,ch,opts)
%% Enable/Disable lock mode to consecutively add elements with ease
f.UserData.Lock = ch.Value;

% revert back to normal mouse automatically
if ~f.UserData.Lock
    Escape_add_mode(f,opts)
end
end

function Restore_Prev_Sides(f,btn,opts)
%% Restore and display previous sides before last element add

% reset table data 
reset_table_data(f,'old')

% Reset old sides
f.UserData = f.UserData.old.UserData;

% redraw entire circuit
redraw_square(f,opts)

% reset button value
btn.Value = false;
end

function reset_table_data(f,option,Tables)
%% Reset table data after undo or clear button 

fn = {'R_Table','B_Table'};% fieldnames

for i = 1:2
    Table = findobj(f,'Tag',fn{i});
    switch option
        case 'old'
            % Restore provious data
            Old_Table_info  = f.UserData.old.(fn{i});
            Table.Data      = Old_Table_info.Data;
            Table.RowName   = Old_Table_info.RowName;
        case 'clear'
            % Reset startpoint data
            Table.Data      = table();
            Table.RowName   = {};
        case 'load'
            % set specific memory of data
            Table.Data      = Tables{i}.Data;
            Table.RowName   = Tables{i}.RowName;
    end
end
end

% function RowName = GetRowName(n)
%% Output {'A','B','C',...nth letter} list for table update
% This function has been deleted. Find in archived versions
% end

function Save_Circuit(f,btn,opts)
%% Create a new uifigure for saving configurations

directory   = read_directory;
tx_w        = 250;  % file name uitextarea
tx2_w       = 90;   % '.mat'
tx3_w       = 450;  % show directory
gray        = [.4 .4 .4]; % color

f2 = uifigure("Name",'Save Configuration',...
    'Position',[0,0,opts.config_sz]);
centerfig(f2)

% Add text to explain user options
l1pos = [opts.spacer, opts.config_sz(2)-opts.spacer-opts.txt_h, opts.config_sz(1)-2*opts.spacer, opts.txt_h];
uilabel(f2,'Position',l1pos,'Text',...
    'Save circuit as new configuration or overwrite existing configuration from list below:');

% Add text to show directory
l2pos = l1pos-[0,opts.spacer + opts.btn_h,0,0];
l2pos(3) = tx3_w;
uilabel(f2,'Position',l2pos,'Text',...
    ['Storage Location: ',directory],'FontColor',gray);
%btn_xpos = sum([opts.spacer,l2.Position([1,3])]);
%uibutton(f2,'Text','Change',...
%    'Position',[btn_xpos,l2pos(2),opts.btn_w,opts.btn_h],...
%    'ButtonPushedFcn',@(~,~)set_directory(opts,l2));

% text area & label for file name and extension (respectively)
tx = uitextarea(f2,'Position',[opts.spacer,opts.spacer,tx_w,opts.txt_h],...
    'Value',''); %,'Tag','filename');
tx2 = uilabel(f2,'Text','_config.mat','FontColor',gray,'Position',...
    [sum([tx.Position([1,3]),opts.spacer]),opts.spacer,tx2_w,opts.txt_h]);

% Create uitable to overwrite presaved configurations 
dir_names        = {dir(directory).name}';
Configurations   = dir_names(endsWith(dir_names,'_config.mat'));
table_pos        = [opts.spacer,2*opts.spacer + opts.btn_h,(opts.config_sz - [2*opts.spacer,5*opts.spacer + 3*opts.btn_h])];
t = uitable(f2,'Position',table_pos,'Data',table(Configurations));
t.CellSelectionCallback = @(Table,~) SelectFile(Table,tx);
% ^ use cell selection callback for this

% Apply (Save)
uibutton(f2,'Text','Save',...
    'Position',[sum([opts.spacer,tx2.Position([1,3])]),opts.spacer,opts.btn_w,opts.btn_h],...
    'ButtonPushedFcn', @ (~,~) Apply_Save(f,tx,directory,f2));

% Reset button value
btn.Value = false;
end

function SelectFile(Table,tx)
%% Fillin filename object for overwriting selected configuration file

% Grab name of selected file
fn = Table.Data.Configurations{1};
% remove extension
fn = fn (1:strfind(fn,'_config.mat')-1);
tx.Value = fn;
end

function Apply_Save(f,tx,directory,f2)
%% Save configuration .mat file (UserData, BTable, RTable)

RTable          = findobj(f,'Tag','R_Table');
RTableData      = RTable.Data;
RTableRowName   = RTable.RowName;
BTable          = findobj(f,'Tag','B_Table');
BTableData      = BTable.Data;
BTableRowName   = BTable.RowName;
UserData    = f.UserData;

filepath = fullfile(directory,[tx.Value{1},'_config.mat']);
save(filepath,'BTableData','RTableData','BTableRowName','RTableRowName','UserData')

delete(f2)
end

function Load_Circuit(f,btn,opts)
%% Load circuit configuration, easy uigetfile

% We are gonna do a prompt function for directory
directory = read_directory;

% Select loaded file from this direectory
[matfile,filepath] = uigetfile([directory,'/*_config.mat'],'Chose file to load configuration');
figure(f) % Bring my screen back!

% 'cancel' button, exit:
if matfile == 0
    return
end
load(fullfile(filepath,matfile),'UserData','RTableData','BTableData','RTableRowName','BTableRowName')
RTable.Data = RTableData; RTable.RowName = RTableRowName;
BTable.Data = BTableData; BTable.RowName = BTableRowName;
% ^ ~~~ This absolutely could be done better but I had some issues wiht
% this and this is current patch. Fix up by just saving and loading whole
% structs.

% Redraw circuit
f.UserData = UserData;
redraw_square(f,opts)

% Load table data
reset_table_data(f,'load',{RTable,BTable})

% Reset button
btn.Value = false;
end

function directory = read_directory
%% grab directory to load and save configurations. Prompt if not input yet

% ** changed to simply script directory! (prev. method in archived version)
directory = fileparts(mfilename("fullpath"));
% (also see and paste in 'set_directory' function in archived version)
end

function ax_obj = add_axes(f,opts)
%% Add the axes

size    = opts.ax_l * ones(1,2);
ypos    = f.UserData.ToolBarHeight + opts.spacer; 
ax_obj  = uiaxes(f,'Tag','Display',...
    'Position',[opts.spacer,ypos,size],...
    'Color',opts.ax_clr); 
hold(ax_obj,'on')
end

function add_tabgroup(f,ax_obj,opts_set,opts)
%% Add tabs to show different results tables

tab_height = 24.666;

% Conditionally resize figure height
vert_s = opts.table_height + tab_height + 4*opts.spacer;
if vert_s > f.Position(4)
    f.Position(4) = vert_s;
    centerfig(f)
end

% Positioning :

% right of axis object
position(1) = sum(ax_obj.Position([1,3])) + opts.spacer;
% spaced just under top of figure
position(2) = f.Position(4) - 3*opts.spacer - opts.table_height - tab_height;
% referring to options struct for size
position(3:4) = [f.UserData.Settings_w,opts.table_height + tab_height] + 2*opts.spacer;

% Create tabgroup
tabgroup = uitabgroup(f,'Position',position); % ~~~ Can NOT do Font Size for some odd reason

% --- guesses tab height
table_pos = [opts.spacer,opts.spacer,f.UserData.Settings_w,opts.table_height];

tab_titles  = {'Resistors','Batteries'};
fn          = {'R_tab_cols','B_tab_cols'}; 
tags        = {'R_Table','B_Table'};

for i = 1:2
    % Create tab
    tab = uitab(tabgroup,'Title',tab_titles{i});

    % Create table
    t = uitable(tab,'ColumnName',opts.(fn{i}),'FontSize',opts.FS,...
    'Tag',tags{i},'Data',table(),'RowName',{},'Position',table_pos,...
    'ColumnEditable',[true,false,false],...
    'CellEditCallback',@(t,event)table_val_edit(f,t,event));

    % Init. 'old' data
    f.UserData.old.(tags{i}).Data = t.Data;
    f.UserData.old.(tags{i}).RowName = t.RowName;
end

% Add settings tab 
add_settings_tab(f,tabgroup,opts_set,opts);
end

function table_val_edit(f,t,event)
%% Callback function for element uitable (update values)

% ~~~ Now here's my quiestion, I'm updating UserData when element edited,
% then updating the edit menu callback with new Element. What I should do
% there AND HERE is to instead just have to update UserData and have the
% edit element refer to the UserData.

% THe problem is you need element ind which changes all the time 

% Now we do use the element ID in tag to find the context menu 
% But that context menu needs to be reset with 'Element' value 

% OK it turns out we are already kind of doing that. A slong as we update
% userdata element value we are good 

Element.ID = t.RowName{event.Indices(1)}; 

% I need el_ind and Side_ind
[~,el_ind,Side_ind] = id_element(f,Element);

f.UserData.Sides(Side_ind).Elements{el_ind}.Value = event.NewData;
end

function add_settings_tab(f,tabgroup,opts_set,opts)
%% Display modifiable options in settings tab

tab = uitab(tabgroup,'Title','Settings');
p = uipanel(tab,'Title','Set Options','Scrollable','on','Position',...
    [opts.spacer,2*opts.spacer + opts.btn_h,f.UserData.Settings_w,opts.table_height - opts.btn_h - opts.spacer]);

% Create 'Apply Options' Button
b = uibutton(tab,'Text','Apply Options',...
    'Position',[opts.spacer,opts.spacer,opts.btn_w_l,opts.btn_h],...
    'FontSize',opts.FS,'Enable',false,...
    'ButtonPushedFcn',@(~,~)ReApply_Options(f,tab,opts_set));

% Create 'Set Default Options' Button
uibutton(tab,'Text','Restore Default', 'Position',...
    [f.UserData.Settings_w - opts.btn_w_l - opts.spacer,opts.spacer,...
    opts.btn_w_l,opts.btn_h],...
    'FontSize',opts.FS,...
    'ButtonPushedFcn',@(~,~) Restore_Default_Opts(f,p,b));

% Organize Options by grouping
Opts_Groups = Organize_Opts(opts_set);

% ** current height idea :
%   Start at high number. drop down per item written. At the end, subtract
%   them all by the last value s.t. the bottom aligns with ypos = 0
ypos = 5e3;

for j = 1:width(Opts_Groups)

    % Identify group
     banner      = Opts_Groups{1,j};
     if strcmp(banner,'None')
         continue
     end

    % Write Grouping banner
    ypos        = ypos - opts.txt_h_l - opts.spacer;
    banner_pos  = [opts.spacer,ypos,opts.desc_w,opts.txt_h_l];
    uilabel(p,'Text',banner,'FontSize',opts.FS_lab * 1.35,'Position',banner_pos,...
        'FontColor','b');

    % Write each individual option
    fn = fieldnames(Opts_Groups{2,j});
    for i = 1:numel(fn)
        % height
        ypos = ypos - opts.txt_h - opts.spacer;

        % variable name label
        pos1 = [opts.spacer,ypos,opts.name_w,opts.txt_h];
        uilabel(p,'Text',fn{i},'Position',pos1,'FontSize',opts.FS);

        % variable description
        pos2 = [2*opts.spacer + opts.name_w,ypos,opts.desc_w,opts.txt_h];
        uilabel(p,'Text',opts_set.(fn{i}){2},'Position',pos2,...
            'FontColor','k','FontSize',opts.FS,'FontAngle','italic');

        val = read_opts_val(opts_set,fn{i});

        pos3 = [3*opts.spacer+opts.name_w+opts.desc_w,ypos,opts.val_w,opts.txt_h];
        t = uitextarea(p,'Value',val,'Tag',fn{i},...
            'Position',pos3,'FontSize',opts.FS,...
            'ValueChangedFcn',@(~,~)enable_Apply(f,b,fn{i}));

        % Make editable (per instructed)
        if opts_set.(fn{i}){3}
            t.Editable = 'on';
        else
            t.Editable = 'off';
            t.FontColor = [.5 .5 .5];
        end
    end
end

% Remove blank space at bottom
ch = p.Children;
for i = 1:numel(ch)
    ch(i).Position(2) = ch(i).Position(2) - ypos + opts.spacer;
end
end

function Opts_Groups = Organize_Opts(opts_set)
%% Seperate Options by Grouping

% Initialize empty array of group data
Opts_Groups = repmat({''},2,100);
fn          = fieldnames(opts_set);
num_groups  = 0;
for i = 1:numel(fn)
    fni = fn{i};
    Grouping = opts_set.(fni){4};
    [existing,ind] = ismember(Grouping,Opts_Groups(1,:));
    if existing
        % transfer cell vector to struct (w/in cell matrix)
        Opts_Groups{2,ind}.(fni) = opts_set.(fni);
    else
        % set grouping name
        num_groups = num_groups + 1;
        Opts_Groups{1,num_groups} = Grouping;
        Opts_Groups{2,num_groups}.(fni) = opts_set.(fni);
    end
end
% Truncate
Opts_Groups = Opts_Groups(:,1:num_groups);
end

function val = read_opts_val(opts_set,fieldname)
%% Write in value from options set and place in text area

% Modifiable value
val = opts_set.(fieldname){1};

% convert to string
if ~iscell(val)
    val = num2str(val);
end
end

function enable_Apply(f,b,tag)
%% Enable Apply button after a change

if ~b.Enable
    b.Enable = true;
end

% store modified options for quicker applying of changes
if exist('tag','var')
    f.UserData.Changed_opts = [f.UserData.Changed_opts,{tag}];
end
end

function ReApply_Options(f,tab,opts_set)
%% Reapply user-changed options, recreating entire gui figure

% download uitextarea changed inputs
for tag = f.UserData.Changed_opts
    Tag = tag{1};

    % find textarea object
    t = findobj(tab,'Tag',Tag);

    % str --> number
    val = str2double(t.Value);
    
    % (conditionally keep str, if not number)
    if isnan(val)
        val = t.Value;
    end

    % Set user-changed option
    opts_set.(Tag){1} = val;
end

UserData        = f.UserData;
T               = findobj(f,'Tag','R_Table');
R_Table.Data    = T.Data;
R_Table.RowName = T.RowName;
T               = findobj(f,'Tag','B_Table');
B_Table.Data    = T.Data;
B_Table.RowName = T.RowName;

directory = read_directory; 
save(fullfile(directory,'CS_UserSettings.mat'),'opts_set')

delete(f)
Create_GUI(UserData,R_Table,B_Table)
end

function Restore_Default_Opts(f,panel_obj,btn_obj)
%% Reset Default opts values

opts_set = default_opts;
fn = fieldnames(opts_set);

for i = 1:numel(fn)
    if ~strcmp(opts_set.(fn{i}),'None')
        txt = findobj(panel_obj,'Tag',fn{i});
    % fill in val
        txt.Value = read_opts_val(opts_set,fn{i});
    end
end

% Enable Apply Options Button
enable_Apply(f,btn_obj)
end

function initial_layout(f,opts,UserData,option,btn)
%% Initialize a blank circuit

ax_obj = findobj(f,'Tag','Display');

% Set sides data
if isstruct(UserData)
    f.UserData = UserData;
else
    [Original_Sides,Original_Nodes] = Empty_Sides(opts);
    f.UserData.Sides = Original_Sides;
    f.UserData.Nodes = Original_Nodes;
end
f.UserData.Side_Count = numel(f.UserData.Sides);

if strcmp(option,'clear')
    % clear resistor and battery table if this is a clear call
    reset_table_data(f,option)
else
    % Remove tick labels (we aren't concerned with that)
    ax_obj.YTickLabel = [];
    ax_obj.XTickLabel = [];
end

% Set axis size  % ~~~ Im pretty sure this is overwritten by centering
% figure and 'aspace' is used instead
ax_obj.XLim = [0,opts.ax_l];
ax_obj.YLim = [0,opts.ax_l];

redraw_square(f,opts,0)

% reset button value
if strcmp(option,'clear')
    btn.Value = false;
end
end

function [Sides,Nodes] = Empty_Sides(opts)
%% Default empty layout for electrical circuit

Sides(4) = struct; 
for i = 1:4
    Sides(i).Elements       = {}; 
    Sides(i).isOriginal     = true;
    Sides(i).FollowedBy     = [];
end

% corners, x:
x = (opts.ax_l + [-1,1]*opts.W0)/2;
% corners, y:
y = (opts.ax_l + [-1,1]*opts.H0)/2;

% corners (CW from lower left)
corners = [x(1),y(1);...
           x(1),y(2);...
           x(2),y(2);...
           x(2),y(1)];

% Original Sides (CW from lower left)
% (Up)
Sides(1).Origin     = corners(1,:);
Sides(1).Length     = opts.H0;
Sides(1).Direction  = pi/2; % Radians!
Sides(1).Tag        = 'Side 1';
Sides(1).Nodes      = [1,2];

% (Right)
Sides(2).Origin     = corners(2,:);
Sides(2).Length     = opts.W0;
Sides(2).Direction  = 0;
Sides(2).Tag        = 'Side 2';
Sides(2).Nodes      = [2,3];

% (Down)
Sides(3).Origin     = corners(3,:);
Sides(3).Length     = opts.H0;
Sides(3).Direction  = -pi/2;
Sides(3).Tag        = 'Side 3';
Sides(3).Nodes      = [3,4];

% (Left)
Sides(4).Origin     = corners(4,:);
Sides(4).Length     = opts.W0;
Sides(4).Direction  = pi;
Sides(4).Tag        = 'Side 4';
Sides(4).Nodes      = [4,1];

% Original Nodes
Nodes(4) = struct;
for i = 1:4
    Nodes(i).Position   = corners(i,:);
    Nodes(i).In         = i - 1;
    if i == 1
        Nodes(i).In     = 4;
    end
    Nodes(i).Out        = i;
    Nodes(i).Show       = true; % These nodes (and most) will be shown
end
end

function redraw_square(f,opts,dont_recenter) %#ok<INUSD>
%% Redraw the entire circuit

ax_obj = findobj(f,'Tag','Display');

% clear all plots since we're redrawing side data
delete(ax_obj.Children)

% redraw all original sides
Original_Sides = find([f.UserData.Sides.isOriginal]);
for i = Original_Sides
    redraw_side(ax_obj,i,opts)
end

% redraw all nodes
for i = 1:length(f.UserData.Nodes)
    redraw_node(f,i,opts)
end
% recenter axes in case of a resizing in the previous step to revert from
if ~exist('dont_recenter','var')
    recenter_axes(f,ax_obj,opts)
end
end

function place_element(f,Line_ind,Side_ind,Node_ind,opts,pl_obj)
%% Place circuit element onto a wire

% check that an element has been selected, otherwise exit immediately
el_add = f.UserData.element_add;
if isempty(el_add)
    return
end

% Can't add elements to nodes
if ~contains(el_add,'Split') && Node_ind ~= 0
    disp("entered Here -- element on node")
    return
end

if Node_ind
    error('we did it')
    % ~~~ we're hitting it, now need to make plan
end

% Save old Sides for undo button
f.UserData.old.UserData = f.UserData;

% Temp values for double click
if isempty(f.UserData.Temp)
    f.UserData.Temp.Side_ind    = Side_ind;
    f.UserData.Temp.Line_ind    = Line_ind;
    f.UserData.Temp.Node_ind    = Node_ind;
    if contains(el_add,'Split')
        pl_obj.Color = opts.SelectedClr;
        f.UserData.Selected_obj = pl_obj;
        return
    end
end

if contains(el_add,'Split')
    f.UserData.Temp.Side_ind = [f.UserData.Temp.Side_ind,Side_ind];
    f.UserData.Temp.Line_ind = [f.UserData.Temp.Line_ind,Line_ind];
    f.UserData.Temp.Node_ind = [f.UserData.Temp.Node_ind,Node_ind];
end

create_element(f,el_add,opts);

% draw the element within a line and redisplay figure as necesary
if ~strcmp(el_add,'Split')
    ax_obj = findobj(f,'Tag','Display');
    redraw_side(ax_obj,Side_ind,opts)
end

% Reset UserData
f.UserData.Temp = [];

% Go back to normal mode (not adding an element)
if ~f.UserData.Lock
    Escape_add_mode(f,opts)
end
end

function create_element(f,el_add,opts)
%% Create element object

% Load inputs (abbreviate)
Line_ind = f.UserData.Temp.Line_ind;
Side_ind = f.UserData.Temp.Side_ind;
Node_ind = f.UserData.Temp.Node_ind;

if contains(el_add,'Split')
    if Side_ind(1) == Side_ind(2)
        % No nodes on same line!
        if max(Node_ind) > 0
            reject_input(el_add);
            return
        end
        % Child side branch
        create_child_side_branch(f,el_add,Side_ind(1),Line_ind,opts) 
    else
        % Node branch
        add_node_side(f,el_add,Side_ind,Line_ind,Node_ind,opts)
    end
else
    create_basic_element(f,el_add,Side_ind,Line_ind,opts)
end
end

function create_basic_element(f,el_add,Side_ind,Line_ind,opts)
%% create and insert resistor or battery element to parent side

% Prompt element value
Value = prompt_element_value(el_add,opts);

if isempty(Value)
    return
end

element.Value       = Value;
element.Type        = el_add;
element.x_plot      = f.UserData.Symbols.icon_plots.(el_add).x;
element.y_plot      = f.UserData.Symbols.icon_plots.(el_add).y;

% Add element to table
element.ID = add_el_to_table(f,element.Value,el_add,opts);

switch el_add
    case 'Battery'
        element.Length = opts.bat_l;
        element.Height = opts.bat_l;
    case 'Resistor'
        element.Length = opts.R_l;
        element.Height = opts.R_h;
end

% Find existing elements
El = f.UserData.Sides(Side_ind).Elements;

f.UserData.Sides(Side_ind).Elements = [El(1:Line_ind-1),{element},El(Line_ind:end)];
end

function create_child_side_branch(f,el_add,Side_ind,Line_ind,opts)
%% Add element of child sides (child branch)

element.Type = 'Child Side';

if contains(el_add,'Plus')
    % Prompt element value
    num_sides = prompt_element_value(el_add,opts);
else
    num_sides = 2;
end

% create new sides
new_side_inds       = add_new_child_sides(f,Side_ind,num_sides,opts);
element.Side_ind    = new_side_inds;
% define "main child side" to carry existing elements
main_child_ind      = new_side_inds(1);

% create new nodes -- NO position recorded because it's dynamic
node_inds = numel(f.UserData.Nodes) + (1:2);

% first node
f.UserData.Nodes(node_inds(1)).Show = false;
f.UserData.Nodes(node_inds(1)).In   = Side_ind;
f.UserData.Nodes(node_inds(1)).Out  = new_side_inds;

% second node
f.UserData.Nodes(node_inds(2)).Show = false;
f.UserData.Nodes(node_inds(2)).In   = new_side_inds;
f.UserData.Nodes(node_inds(2)).Out  = Side_ind;

% find existing elements 
El = f.UserData.Sides(Side_ind).Elements;

% Adding with no exisiting elements case
if Line_ind(1) == Line_ind(2)

    % Place new child side element within parent side elements
    f.UserData.Sides(Side_ind).Elements = ...
        [El(1:Line_ind-1),{element},El(Line_ind:end)];

    % default starting branch height for new branch
    branch_height = opts.parl_h;
else
    % rearrange elements within parents side to second twin side

    % Find elements 'within' split choices (from ButtonDwnFcn inputs)
    el_inds = sort(Line_ind);

    % Add elements to new side
    added_elements = f.UserData.Sides(Side_ind).Elements(el_inds(1):el_inds(2)-1);
    f.UserData.Sides(main_child_ind).Elements = added_elements;

    % Replace those elements from Parent side with the new child side
    % branch
    f.UserData.Sides(Side_ind).Elements = ...
        [El(1:el_inds(1)-1),{element},El(el_inds(2):end)];

    % Length Resizing (not necesssary, saves some re-draw time)
    length = length_from_elements(f,added_elements,opts);
    for i = new_side_inds
        f.UserData.Sides(i).Length = length;
    end

    % Find highest net height as new branch height
    branch_height = height_from_elements(f,added_elements,opts);
end

% Height-wise resizing
ax_obj = findobj(f,'Tag','Display');
set_height(f,ax_obj,main_child_ind,branch_height,opts);
end

function add_node_side(f,el_add,Side_ind,Line_ind,Node_ind,opts)
%% Add new side connecting exisiting or non-exisiting nodes in the circuit

if contains(el_add,'Plus') % ~~~ still not implemented 
    reject_input(el_add)
    return
end

for ind = Side_ind
    if  ind ~= 0 && ~f.UserData.Sides(ind).isOriginal
        Escape_add_mode(f,opts)
        errordlg('Can Not add Node Sides to Child Sides (as of now)')
        return
    end
end

ax_obj = findobj(f,'Tag','Display');

% Assess inputs
isLine = find(Node_ind == 0); 
isNode = find(Node_ind ~= 0);

side_node_inds = zeros(1,2);

% for new nodes
for i = isLine

    % Assign node location
    switch f.UserData.NodeAddMode % ~~~ still need to add button for this option and functionality
        case 'automatic'
            % center of line
            NodePos = f.UserData.Sides(Side_ind(i)).NodePos(Line_ind(i),:);
        case 'manual'
            % Position would come from event info in callback function
            % NodePos = ... ~~~ finish l8r (far from priority)
    end

    % Counting 
    new_node = numel(f.UserData.Nodes) + 1;
    Fol_Side = f.UserData.Side_Count + 1;
    f.UserData.Side_Count = f.UserData.Side_Count + 1;

    % Add new node to struct (to be reffered)
    f.UserData.Nodes(new_node).Position    = NodePos;
    f.UserData.Nodes(new_node).In          = Side_ind(i);
    f.UserData.Nodes(new_node).Out         = Fol_Side;
    f.UserData.Nodes(new_node).Show        = true;
    redraw_node(f,new_node,opts)
    side_node_inds(i) = new_node;

    % Shrink the original side & edit end node
    old_length = f.UserData.Sides(Side_ind(i)).Length;
    new_length = norm(NodePos - f.UserData.Sides(Side_ind(i)).Origin);
    
    % Reassign side end node (store previous for following side)
    old_InNode = f.UserData.Sides(Side_ind(i)).Nodes(2);
    f.UserData.Sides(Side_ind(i)).Length    = new_length;
    f.UserData.Sides(Side_ind(i)).Nodes(2)  = new_node;

    % Create new 'following' side
    f.UserData.Sides(Side_ind(i)).FollowedBy    = Fol_Side;
    f.UserData.Sides(Fol_Side).Origin           = NodePos;
    f.UserData.Sides(Fol_Side).Length           = old_length - new_length;
    f.UserData.Sides(Fol_Side).Direction        = f.UserData.Sides(Side_ind(i)).Direction;
    f.UserData.Sides(Fol_Side).isOriginal       = f.UserData.Sides(Side_ind(i)).isOriginal;
    f.UserData.Sides(Fol_Side).Tag              = ['Side ',num2str(Fol_Side)];

    % Assign "In" node for Side index for following node
    f.UserData.Sides(Fol_Side).Nodes            = [new_node,old_InNode];

    index = find(f.UserData.Nodes(old_InNode).In == Side_ind(i),1);
    f.UserData.Nodes(old_InNode).In(index) = Fol_Side; 

    % Transfer elements
    El = f.UserData.Sides(Side_ind(i)).Elements;
    if isempty(El)
        f.UserData.Sides(Fol_Side).Elements = {};
    else
        f.UserData.Sides(Side_ind(i)).Elements = El(1:Line_ind(i) - 1);
        f.UserData.Sides(Fol_Side).Elements = El(Line_ind(i):end);
    end

    % Draw Following Side upon creation. 
    redraw_side(ax_obj,Fol_Side,opts)
end

% for placement on exisiting node
for i = isNode
    side_node_inds(i) = Node_ind(i);
end

% Create new node-side
node_side_ind = f.UserData.Side_Count + 1;
f.UserData.Side_Count = f.UserData.Side_Count + 1;

% Assign node side properties
f.UserData.Sides(node_side_ind).Tag          = ['Side ',num2str(node_side_ind)];
f.UserData.Sides(node_side_ind).Elements     = {};
f.UserData.Sides(node_side_ind).Nodes        = side_node_inds;

% Plot calculations for new nodeside
dist_vec = f.UserData.Nodes(side_node_inds(2)).Position - f.UserData.Nodes(side_node_inds(1)).Position;

f.UserData.Sides(node_side_ind).Origin       = f.UserData.Nodes(side_node_inds(1)).Position;
f.UserData.Sides(node_side_ind).Direction    = atan2(dist_vec(2),dist_vec(1));
f.UserData.Sides(node_side_ind).Length       = norm(dist_vec);
f.UserData.Sides(node_side_ind).isOriginal   = true; % Node sides are original!

% Assign Side inds to nodes
f.UserData.Nodes(side_node_inds(1)).Out = [f.UserData.Nodes(side_node_inds(1)).Out,node_side_ind];
f.UserData.Nodes(side_node_inds(2)).In  = [f.UserData.Nodes(side_node_inds(2)).In,node_side_ind];

% Draw all of the involved sides
for i = [Side_ind(1),Side_ind(2),node_side_ind]
    redraw_side(ax_obj,i,opts)
end
end

function redraw_node(f,node_ind,opts)
%% Draw Node on Axis

if ~f.UserData.Nodes(node_ind).Show
    return
end

ax_obj = findobj(f,'Tag','Display');

tag = ['Node ',num2str(node_ind)];

% Delete previous Node if exists 
existing_plot = findobj(ax_obj,'Tag',tag);
delete(existing_plot)

% plot the node
pos = f.UserData.Nodes(node_ind).Position;
pl_obj = plot(ax_obj,pos(1),pos(2),'k.','MarkerSize',opts.node_MS,'Tag',tag);

% add functionality to add to node
pl_obj.ButtonDownFcn = @(~,~) place_element(f,0,0,node_ind,opts); 
end

function Value = prompt_element_value(el_add,opts)
%% Prompt element value and check for errors

fn = ['prompt_',el_add];

value = inputdlg(opts.(fn));

% load value input
if ~isempty(value)
    
    % non-integer splits -- reject
    if isempty(value{1})
        Value = reject_input(el_add);
        return
    else
        num = str2double(value);
    end

    if isnan(num)
        Value = reject_input(el_add);
        return
    elseif strcmp('Split',el_add) && num ~= round(num)
        Value = reject_input(el_add);
        return
    else
        Value = num;
    end
else
    % No input dialog -- reject
    Value = reject_input(el_add);
    return
end
end

function Value = reject_input(el_add)
%% Reject bad input for element value
warndlg([el_add,' not created'])
Value = [];
end

function all_new_inds = add_new_child_sides(f,Parent_Side_ind,num,opts)
%% Create new child side from parent side

% ouput Main_Side_ind is the side index which will carry exisiting elements
% input num is number of child sides within branch

% New child side indices
all_new_inds = f.UserData.Side_Count + (1:num);

% Update figure side count
f.UserData.Side_Count = f.UserData.Side_Count + num;

% Use Parent side for direction
Parent_Side = f.UserData.Sides(Parent_Side_ind);

% Side Properties
for i = all_new_inds
    f.UserData.Sides(i).Tag         = ['Side ',num2str(i)];
    f.UserData.Sides(i).Length      = opts.parl_l;
    f.UserData.Sides(i).Elements    = {};
    f.UserData.Sides(i).FollowedBy  = [];
    f.UserData.Sides(i).Direction   = Parent_Side.Direction;
    f.UserData.Sides(i).isOriginal  = 0;
    f.UserData.Sides(i).Parent_ind  = Parent_Side_ind;
    f.UserData.Sides(i).Group_ind   = all_new_inds;
    f.UserData.Sides(i).Nodes       = numel(f.UserData.Nodes) + (1:2);
end
end

function Length = length_from_elements(f,Elements,opts)
%% Determine length for side based on elements

Length = opts.cspace;

for i = 1:length(Elements)
    if strcmp(Elements{i}.Type,'Child Side')
        el_length = f.UserData.Sides(Elements{i}.Side_ind(1)).Length;
    else
        el_length = Elements{i}.Length;
    end
    Length = Length + el_length + opts.cspace;
end
end

function Height = height_from_elements(f,added_elements,opts)
%% Determine net height for side based on elements

% find child sides
child_sides = find(cellfun(@(c)strcmp(c.Type,'Child Side'),added_elements));
Height = opts.parl_h;

% Find largest child branch net height within elements
for i = child_sides
    side_ind = added_elements{i}.Side_ind;
    ind_height = f.UserData.Sides(side_ind(1)).branch_height * length(side_ind);
    if ind_height > Height
        Height = ind_height;
    end
end
end

function set_height(f,ax_obj,side_ind,branch_height,opts)
%% Assign relative child side heights 

twin_sides      = f.UserData.Sides(side_ind).Group_ind; 
Parent_ind      = f.UserData.Sides(side_ind).Parent_ind;
Parent_Side     = f.UserData.Sides(Parent_ind);
num             = numel(twin_sides);
N               = num-1;
side_heights    = (-N:2:N) * branch_height;
net_height      = num * branch_height;

for i = 1:num
    f.UserData.Sides(twin_sides(i)).branch_height   = branch_height;
    f.UserData.Sides(twin_sides(i)).Height          = side_heights(i);
end

if ~Parent_Side.isOriginal && net_height > Parent_Side.branch_height
    % recursive funciton call to set new heights, no plot yet
    set_height(f,ax_obj,Parent_ind,net_height,opts)
else
    % replot parent side with new side heights
    redraw_side(ax_obj,Parent_ind,opts)
    
end
end

function Escape_add_mode(f,opts,key)
%% Exit from the inserting element feature
% Can be called from escape key or successful placement of element

if exist('key','var')
    % If called by keypress, make sure its escape key
    if double(key.Character) ~= 27 % 'escape'
        return
    end
    % Check for exisiting add mode to escape from
    if isempty(f.UserData.element_add)
        return
    end
end

% Reset mouse pointer to normal arrow
f.UserData.element_add = '';
f.Pointer = 'arrow';

% Reset UserData
f.UserData.Temp = [];

% End HighLight Mode
if ~isempty(f.UserData.HighLight_obj)
    ax_obj = findobj(f,'Tag','Display');
    unhighlight_line(f,ax_obj,f.UserData.HighLight_obj,opts)
end

% End Selected Mode
if ~isempty(f.UserData.Selected_obj) && isvalid(f.UserData.Selected_obj)
    f.UserData.Selected_obj.Color = 'k';
    f.UserData.Selected_obj = [];
end

% Turn off the hovering mode
iptPointerManager(f,'disable')
end

function ID = add_el_to_table(f,Value,Type,opts)
%% Add Resistor to uitable to display results after solving

% Input check:
if ~startsWith(Type,{'R','B'})
    error('Unrecognized add type for element table add')
end

fn = [Type(1),'_tab_cols']; % fieldname
tag = [Type(1),'_Table']; % tag

% create new data
t = table(Value,nan,nan,'VariableNames',opts.(fn));

% find uitable
Table = findobj(f,'Tag',tag);

% store old table data
f.UserData.old.(tag).Data    = Table.Data; 
f.UserData.old.(tag).RowName = Table.RowName;

% insert new data
Table.Data = [Table.Data; t]; 

% Row Name - Lettered 
if isempty(Table.RowName)
    if strcmp(Type,'Resistor')
        ID = 'A';
    else
        ID = 'a';
    end
else
    ID = char(double(Table.RowName{end}) + 1); % 'A', 'B', 'C',...
end
Table.RowName = [Table.RowName;{ID}]; 
end

function redraw_side(ax_obj,Side_ind,opts)
%% Inject the plot of vertices into the current circuit display

% ~~~ this functions getting a little big and hard to read, try to function
% off some stuff

f = ax_obj.Parent; 

% Read side properties
Side = f.UserData.Sides(Side_ind);

% delete old plots
old_plots = findobj(ax_obj,'Tag',Side.Tag); 
delete(old_plots) 

% delete insertion hashmarks if highlighted mode on
hashmark = findobj(ax_obj,'Tag','Hashmark');
delete(hashmark)

% delete context menus from figure
old_cm = findobj(f,'Type','uicontextmenu');
if ~isempty(old_cm)
    rmv_ind = contains({old_cm.Tag},['Side ',num2str(Side_ind)]);
    delete(old_cm(rmv_ind))
end

El = Side.Elements; % abbreviate

% Check_Length function off ~~~
% If length is not appropriate, we will need to resize length-wise
Length = length_from_elements(f,El,opts);
if Side.Length < Length   
    % Two types of length-resizing : original and unoriginal
    if Side.isOriginal
        Length_resize(f,ax_obj,Side_ind,Length,opts) 
        recenter_axes(f,ax_obj,opts) % Nice
    else
        % Reset the size of this side and its twin sides
        for i = 1:length(Side.Group_ind)
            f.UserData.Sides(Side.Group_ind(i)).Length = Length; % I think this is fine still
        end
        % Go outside and redraw parent side 
        redraw_side(ax_obj,Side.Parent_ind,opts) 
    end
    return
end

% Update all child side lenghts
for i = 1:length(El)
    if strcmp(El{i}.Type,'Child Side')
        for ii = 1:length(El{i}.Side_ind)
            El{i}.Length = f.UserData.Sides(El{i}.Side_ind(ii)).Length;
        end
    end
end

% number of elements :
num_el = numel(El);

% Side Length check
spacer = (Side.Length - sum(cellfun(@(c)c.Length,El))) / (num_el+1);

plot_func = @ (item) plot_circuit(ax_obj,item,Side,opts);

% Plot legs for child side:
if ~Side.isOriginal
    Leg.Type = 'Leg';
    Leg.x_plot = [0,0];
    Leg.y_plot = [0,-Side.Height];
    leg_origins = [0,Side.Length];
    for i = 1:2
        Leg.Rel_Origin = leg_origins(i);
        plot_func(Leg);
    end
end

% Set all the lines and element placement 

x = 0;
NodePos = zeros(num_el + 1,3);
for i = 0:num_el
    if i ~=0
        if strcmp(El{i}.Type,'Child Side')
            % Recursive call to plot child sides

            for ii = El{i}.Side_ind

                y = f.UserData.Sides(ii).Height;

                % Set Side Origin 
                Origin = [x,y,0]*R3(Side.Direction) + [Side.Origin,0];
                f.UserData.Sides(ii).Origin = Origin([1,2]);

                % redraw child side (recursive call)
                redraw_side(ax_obj,ii,opts)
            end
        else
            % Plot element

            El{i}.Rel_Origin = x; % Element origin is relative
            pl_obj = plot_func(El{i});

            % Use 

            % Assign left-click funciton
            cm = uicontextmenu(f,...
                'Tag',['Side ',num2str(Side_ind),' Element ', El{i}.ID]);
            uimenu(cm,'Text','Delete Element','Tag','Delete Fcn',...
                'MenuSelectedFcn',@(~,~) delete_element(f,Side_ind,El{i},opts));
            uimenu(cm,'Text','Edit Element','Tag','Edit Fcn',...
                'MenuSelectedFcn',@(~,~) edit_element(f,Side_ind,El{i},opts));
            for ii = 1:numel(pl_obj)
                % plural for battery (has multiple plots)
                pl_obj(ii).ContextMenu = cm;
            end
        end

        % Advance x
        x = x + El{i}.Length;
    end

    % Set new line
    Line.x_plot     = [0,spacer];
    Line.y_plot     = [0,0];
    Line.Rel_Origin = x;
    Line.Type       = 'Line';

    % Plot Line
    pl_obj = plot_func(Line);

    % Assign left-click function
    Line_ind = i + 1;
    pl_obj.ButtonDownFcn = @(obj,~) place_element(f,Line_ind,Side_ind,0,opts,obj);
    
    % Assign mouse-hovering function (highlight)
    % so first we set the pb (pointer behavior)
    pb.enterFcn = @(~,~)highlight_line(f,pl_obj,Line_ind,Side_ind,opts);
    pb.traverseFcn = [];
    pb.exitFcn = @(~,~)unhighlight_line(f,ax_obj,pl_obj,opts); % Nice
    
    iptSetPointerBehavior(pl_obj,pb)

    % Store place to put new nodes
    NodePos(Line_ind,1) = x + spacer/2;

    % Advance x
    x = x + spacer;
end

% Store place to put new nodes in raw position
Z = zeros(num_el+1,1); o = ones(num_el + 1,2);
NodePos = NodePos*R3(Side.Direction) + [Side.Origin.*o,Z];
f.UserData.Sides(Side_ind).NodePos = NodePos(:,1:2);
end

function Length_resize(f,ax_obj,side_ind,Length,opts)
%% Trying nodeside compatible resize

% ~~~ Make Display optional!

% set resized length and redraw
dL = Length - f.UserData.Sides(side_ind).Length;
f.UserData.Sides(side_ind).Length = Length;
redraw_side(ax_obj,side_ind,opts)

% push node and redraw
node_ind = f.UserData.Sides(side_ind).Nodes(2);
push_Dir = f.UserData.Sides(side_ind).Direction;
push_vec = dL*[cos(push_Dir),sin(push_Dir)];
push_node(f,side_ind,node_ind,push_vec,ax_obj,opts)

% Return colors (~~~ not sure if I'm gonna keep this)
for i = ax_obj.Children'
    if ismember('Color',fieldnames(i))
        i.Color = 'k';
    end
end
end

function push_node(f,side_ind,node_ind,push_vec,ax_obj,opts)
%% Move node and corresponding sides

% This function is now declared working. Need to go through and redo /
% remove a lot of the commentary
% ~~~ ^ Declared working is a stretch. See saved file 'Spacing_Cols_Err' 

% used for approximate equals in directions and positions!
tolerance = 1e-3;

% Color functions (easier)
CS = @(ind,clr) Color(f,ax_obj,'Side',ind,clr);
CN = @(clr)     Color(f,ax_obj,'Node',node_ind,clr);

% Highlight Side bringing the push :
%CS(side_ind,[.8,.8,.1]);

dL = norm(push_vec); % ~~~ Add stopper for small dL case!!
push_unit = push_vec/dL;

% Move Node Pos and show
CN('r')
f.UserData.Nodes(node_ind).Position = f.UserData.Nodes(node_ind).Position + push_vec;
redraw_node(f,node_ind,opts)
CN('b')

% Go thorugh all In's and Out's and call push nodes as necesary, at some
% point
move_sides = [f.UserData.Nodes(node_ind).In,f.UserData.Nodes(node_ind).Out];
move_sides = move_sides(~ismember(move_sides,side_ind));

if isempty(move_sides)
    error('ay!')
end

for ind = move_sides

    in = f.UserData.Sides(ind).Nodes(2) == node_ind;

    pos1 = f.UserData.Sides(ind).Origin;
    pos2 = f.UserData.Nodes(f.UserData.Sides(ind).Nodes(1)).Position;
    if ~isequal(pos1,pos2) && in
        continue
    end

    CS(ind,'r')

    % Direction comparisons
    if in
        sideout_dir = f.UserData.Sides(ind).Direction + pi;
    else
        sideout_dir = f.UserData.Sides(ind).Direction;
    end
    sideout_unit = [cos(sideout_dir),sin(sideout_dir)];

    agreement = dot(push_unit,sideout_unit); % = cos(theta)

    % Assess push vs. pull
    % expand_length = (agreement > .001 && in) || (agreement < -.001 && ~in);
    if agreement < -tolerance
        f.UserData.Sides(ind).Length = f.UserData.Sides(ind).Length - dL/agreement; % ~~~ set to work just for straight lines
    end

    if in
        d = f.UserData.Sides(ind).Direction;
        f.UserData.Sides(ind).Origin = f.UserData.Nodes(node_ind).Position...
            - f.UserData.Sides(ind).Length *[cos(d),sin(d)];
    else
        f.UserData.Sides(ind).Origin = f.UserData.Nodes(node_ind).Position;
    end

    pause(opts.ResizeTime) 
    redraw_side(ax_obj,ind,opts)
    CS(ind,'b')
    if agreement ~= -1
        if in
            new_node_ind = f.UserData.Sides(ind).Nodes(1);
        else
            new_node_ind = f.UserData.Sides(ind).Nodes(2);
            % Find endpoint
            d = f.UserData.Sides(ind).Direction;
            endpoint = f.UserData.Sides(ind).Origin + f.UserData.Sides(ind).Length*[cos(d),sin(d)];
            new_node_pos = f.UserData.Nodes(new_node_ind).Position;
            if isempty(find(abs(endpoint - new_node_pos) > tolerance,1))
                continue
            end
        end
        CS(ind,'k')
        push_node(f,ind,new_node_ind,push_vec,ax_obj,opts)
    end
end
CS(side_ind,'k')
CN('k')
end

function Color(f,ax_obj,type,ind,clr)
%% Change color of given node or line object(s)

if ~f.UserData.ShowResize
    return
end

% change color of side or node
objs = findobj(ax_obj,'Tag',[type,' ',num2str(ind)]);
for i = objs'
    i.Color = clr;
end

% delay for dramatic effect
pause(opts.ResizeTime) 
end

% function Length_resize_original_original(f,ax_obj,side_ind,Length,opts)
% %% resize length wise for orignial sides
% find in Archived versions of function
% end

function recenter_axes(f,ax_obj,opts)
%% Recenter the axes region based on current side origins

% Use FIRST and THIRD side Origins
XRange = [f.UserData.Sides(1).Origin(1),f.UserData.Sides(3).Origin(1)];
YRange = [f.UserData.Sides(1).Origin(2),f.UserData.Sides(3).Origin(2)];

Length =  max([diff(XRange),diff(YRange)])/2 + opts.aspace;
Center = [sum(XRange)/2,sum(YRange)/2];

% set axis ranges
ax_obj.XLim = Center(1) + [-1,1]*Length;
ax_obj.YLim = Center(2) + [-1,1]*Length;
end

function delete_element(f,Side_ind,Element,opts)
%% Remove circuit element from display axis and element table

% grab index values
[Els,el_ind,Table,Row_ind] = id_element(f,Element,Side_ind); % ~~~ I want side_ind output. Might change entire output to struct

% remove element from side element list
f.UserData.Sides(Side_ind).Elements = Els([1:el_ind-1,el_ind+1:end]);
ax_obj = findobj(f,'Tag','Display');
redraw_side(ax_obj,Side_ind,opts)

% remove from table
Table.Data = Table.Data([1:Row_ind-1,Row_ind+1:end],:);
Table.RowName = Table.RowName([1:Row_ind-1,Row_ind+1:end]);
end

function edit_element(f,Side_ind,Element,opts)
%% Edit element properties
% create small uifigure to take in changes

% ~~~ add a line to display the element type (uneditable). I like that

% ~~~ ^ AND, based on type, use actual value name (Ohms,VOlts) instead of
% 'value'

%  ******************** delete above soon(after reading)
% grab index values
[Els,el_ind,Table,Row_ind] = id_element(f,Element,Side_ind);

% minimum figure width (display name and such)
min_fig_w = 240;

% banner options
banner_w = 150;
banner_h = 33;
FS       = 22;

% label and textarea widths
lbl_w   = 40;
txt_w   = 125;
txt_h   = 22;
lbl_va  = {'VerticalAlignment','bottom'}; % vertical calignment
% 

% net width
net_w = max([txt_w + lbl_w,2*opts.btn_w]) + 3 * opts.spacer;
if net_w < min_fig_w
    net_w = min_fig_w;
end
% net height
net_h       = 3 * txt_h + banner_h + opts.btn_h + 6 * opts.spacer;

% generate figure
f2 = uifigure('Name','Edit Element','Position',[0,0,net_w,net_h],...
    'Color',opts.bck_clr);
centerfig(f2)

% banner
ypos = net_h - opts.spacer - banner_h;
uilabel(f2,"Text",'Edit Element','FontSize',FS,...
    'Position',[opts.spacer,ypos,banner_w,banner_h],...
    'FontColor','b',lbl_va{:});

% type  (label, label)
ypos = net_h - 2*opts.spacer - txt_h - banner_h;
uilabel(f2,"Text",'Type','FontSize',opts.FS,...,
    'Position',[opts.spacer,ypos,lbl_w,txt_h],lbl_va{:});
uilabel(f2,"Text",Els{el_ind}.Type,'FontSize',opts.FS,...,
    'Position',[2*opts.spacer + lbl_w,ypos,txt_w,txt_h],lbl_va{:});

% ID    (label, uitextarea)
ypos = ypos - (opts.spacer + txt_h);
uilabel(f2,"Text",'Name','FontSize',opts.FS,...
    'Position',[opts.spacer,ypos,lbl_w,txt_h],lbl_va{:});
xpos = 2*opts.spacer + lbl_w;
ID_tx = uitextarea(f2,"Value",Els{el_ind}.ID,'FontSize',opts.FS,...
    'Position',[xpos,ypos,txt_w,txt_h],...
    'ValueChangedFcn',@(txt,~)user_val_check(f2,txt,'ID',Table));

% Value (label, uitextarea)
ypos = ypos - (opts.spacer + txt_h);
uilabel(f2,"Text",'Value','FontSize',opts.FS,...
    'Position',[opts.spacer,ypos,lbl_w,txt_h],lbl_va{:});
xpos = 2*opts.spacer + lbl_w;
Val_tx = uitextarea(f2,"Value",num2str(Els{el_ind}.Value),'FontSize',opts.FS,...
    'Position',[xpos,ypos,txt_w,txt_h],...
    'ValueChangedFcn',@(txt,~)user_val_check(f2,txt,'Value'));

% Apply (button) (initialize false)
ypos = ypos - (opts.spacer + opts.btn_h);
xpos = net_w - (opts.spacer + opts.btn_w);
uibutton(f2,'Text','Apply','FontSize',opts.FS,'Enable',false,'Tag','Apply',...
    'Position',[xpos,ypos,opts.btn_w,opts.btn_h],...
    'ButtonPushedFcn',@(~,~)apply_edit_element(f,f2,ID_tx,Val_tx,Side_ind,el_ind,Table,Row_ind,opts));

% Cancel (button)
uibutton(f2,'Text','Cancel','FontSize',opts.FS,...
    'Position',[opts.spacer,ypos,opts.btn_w,opts.btn_h],...
    'ButtonPushedFcn',@(~,~)close(f2));
end

function [Els,el_ind,Table,Row_ind] = id_element(f,Element,Side_ind)
%% Grab Reference variables to identify element (element side index, table row)

% ~~~ change to have optional side_ind input. If no side_input, search all
% sides for the element. As soon as found, return, no table info needed

el_find = @(ID,Els) find(cellfun(@(c)strcmp(c.ID,ID),Els),1);

% element ref id within side
if exist('Side_ind','var')
    % just look at input side
    Els = f.UserData.Sides(Side_ind).Elements;
    el_ind = el_find(Element.ID,Els);
else
    % if no input side, search all sides and exit early when found
    for i = 1:f.UserData.Side_Count
        Els = f.UserData.Sides(i).Elements;
        el_ind = el_find(Element.ID,Els);
        if ~isempty(el_ind)
            Table = i; % ~~~ This is not a great way to do this tbh
            return
        end
    end
end

% error case -- not found
if isempty(el_ind)
    error('Element not found')
end

% table reference variables
switch Element.Type
    case 'Battery'
        tag = 'B_Table';
    case 'Resistor'
        tag = 'R_Table';
end
Table   = findobj(f,'Tag',tag);
[~,Row_ind] = ismember(Element.ID,Table.RowName); 
end

function user_val_check(f2,txt,type,Table)
%% Assess new user entry for element ID from edit figure
val = txt.Value{1};

switch type
    case 'ID'
        % check if ID exists in table
        fail = ismember(val,Table.RowName);
        fail_str = sprintf('%s already exists in this diagram.',val);
    case 'Value'
        % check if is numeric, non-negative
        fail = isnan(str2double(val));
        fail_str = 'Element value requires numeric entry.';
end

if fail
    errordlg(fail_str)
end

% Set apply enable based on result
apply_btn = findobj(f2,'Tag','Apply');
apply_btn.Enable = ~fail;
end

function apply_edit_element(f,f2,ID_tx,Val_tx,Side_ind,el_ind,Table,Row_ind,opts)
%% Apply user edits to element (ID, Value) and close edit window

Val = str2double(Val_tx.Value);

% determine if name changed; redraw side to reflect
name_changed = ~isequal(f.UserData.Sides(Side_ind).Elements{el_ind}.ID,ID_tx.Value{1}); 

Element = f.UserData.Sides(Side_ind).Elements{el_ind};

% apply to element in 'Sides'
f.UserData.Sides(Side_ind).Elements{el_ind}.ID      = ID_tx.Value{1};
f.UserData.Sides(Side_ind).Elements{el_ind}.Value   = Val;
type = Element.Type;
% apply value to element table
switch type
    case 'Resistor'
        val_col = 'Ohms';
    case 'Battery'
        val_col = 'Volts';
end
Table.Data.(val_col)(Row_ind) = Val;

% apply ID to table
Table.RowName(Row_ind) = ID_tx.Value;

% reset the edit and delete functions with new Element Variable

cm = findobj(f,'Tag',['Side ',num2str(Side_ind),' Element ', Element.ID]); % ~~~ I feel like this should def be functioned off right
cm.Tag = ['Side ',num2str(Side_ind),' Element ',ID_tx.Value{1}];
% In this case, becuase youve already specified the side and element, you
% can simply use text for tagging specific menus on the context menu
delete_fcn  = findobj(cm,'Tag','Delete Fcn'); % ~~~ change back to using tag!! might want to edit text for display
edit_fcn    = findobj(cm,'Tag','Edit Fcn');

delete_fcn.MenuSelectedFcn  = @(~,~) delete_element(f,Side_ind,Element,opts);
edit_fcn.MenuSelectedFcn    = @(~,~) edit_element(f,Side_ind,Element,opts);

% close edit subfigure
close(f2)

% reflect new name
if name_changed
    ax_obj = findobj(f,'Tag','Display');
    redraw_side(ax_obj,Side_ind,opts)
end

end

function pl_obj = plot_circuit(ax_obj,item,Side,opts)
%% Plot element or line after applying origin offset and rotation
pause(opts.PlotDelay) % ~~~ set in options ??? later
% For battery, because matrix plot used, we need to vectorize and then
% reshape (see battery if statements)

if strcmp(item.Type,'Battery')
    Size = size(item.x_plot);
    item.x_plot = item.x_plot(:)';
    item.y_plot = item.y_plot(:)';
end

% Apply rotation and origin :
o = ones(numel(item.x_plot),1);
X = item.x_plot'; Y = item.y_plot'; Z = 0*o;
mat = [X,Y,Z] + [item.Rel_Origin*o,Z,Z];
mat = mat*R3(Side.Direction) + [Side.Origin.*o,Z];

x_plot = mat(:,1);
y_plot = mat(:,2);

% See comment above about regarding matrix plot and vectorizing
if strcmp(item.Type,'Battery')
    x_plot = reshape(x_plot,Size);
    y_plot = reshape(y_plot,Size);
end

% plot to the axis
pl_obj = plot(ax_obj,x_plot,y_plot,'k-','LineWidth',opts.LW,'Tag',Side.Tag);

% Add text box to label element 
if isfield(item,'ID')

    % ~~~ This needs to be optioned somewhere
    if strcmp(item.Type,'Battery')
        spacer = 5/8 * opts.bat_l;
    elseif strcmp(item.Type,'Resistor')
        spacer = 3 * opts.R_h; 
    end

    txt_pos = [(max(X)-min(X))/2,spacer,0];
    txt_pos = txt_pos + [item.Rel_Origin,0,0];
    txt_pos = txt_pos*R3(Side.Direction) + [Side.Origin,0];
    text(ax_obj,txt_pos(1),txt_pos(2),item.ID,'FontSize',opts.FS_lab,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','middle','Tag',Side.Tag);
end
end

function output = R3(theta)
%% Rotation (+ CCW) (the radians)
output = [cos(theta) sin(theta) 0;-sin(theta) cos(theta) 0; 0 0 1];
end

function highlight_line(f,pl_obj,Line_ind,Side_ind,opts)
%% Highlight Lines to Aid Element Placement

% Change line color -- maybe linewidth too? idk
pl_obj.Color = opts.HighLightClr; 

% Show Node placement area with hashmark
if contains(f.UserData.element_add,'Split')
    pos = f.UserData.Sides(Side_ind).NodePos(Line_ind,:);
    normal_dir = f.UserData.Sides(Side_ind).Direction + pi/2;
    hashmark_len = 17; % ~~~ add to options later!
    hashmark = pos + hashmark_len/2*[1;-1]*[cos(normal_dir),sin(normal_dir)];
    
    ax_obj = findobj(f,'Tag','Display');
    plot(ax_obj,hashmark(:,1),hashmark(:,2),'LineWidth',opts.LW+1,'Color','k','Tag','Hashmark')
end

% Set Data
f.UserData.HighLight_obj = pl_obj;

end

function unhighlight_line(f,ax_obj,pl_obj,opts)
%% Remove highlited lines after mouse leaves area during element add

if ~isempty(pl_obj)
    if ~isvalid(pl_obj)
        return
    end
    
    % Set Data
    f.UserData.HighLight_obj = [];
    hashmark = findobj(ax_obj,'Tag','Hashmark');
    delete(hashmark)
end

% return object color accordingly
if ~isempty(f.UserData.Selected_obj) && isequal(f.UserData.Selected_obj,pl_obj)
    pl_obj.Color = opts.SelectedClr;
else
    pl_obj.Color = 'k';
end
end

function draw_symbols(f,opts)
%% Draw and store the element symbols for button icons, mouse pointer symbols 

mat3d = @ (mat) mat.*ones(1,1,3);

% Button icon :

% Split
mat = draw_split(opts.btn_s,opts);
f.UserData.Symbols.btn_icons.Split      = mat3d(mat);

% Resistor
mat = draw_resistor(opts.btn_s,opts.btn_Th,opts); 
f.UserData.Symbols.btn_icons.Resistor   = mat3d(mat);

% Battery 
[mat,~] = draw_battery(opts.btn_s,opts);
f.UserData.Symbols.btn_icons.Battery    = mat3d(mat);

% Pointer Symbol :
% (1 --> black, 2 --> white, NaN --> background)

% Split
mat = draw_split(32,opts) + 1;
f.UserData.Symbols.pointers.Split       = mat;

% Resistor
mat = draw_resistor(32,2,opts) + 1;
f.UserData.Symbols.pointers.Resistor    = mat;

% Battery
mat = draw_battery(32,opts) + 1;
f.UserData.Symbols.pointers.Battery     = mat;

% lineplot :

% Resistor
f.UserData.Symbols.icon_plots.Resistor = draw_resistor_plot(opts);

% Battery 
[~,lineplot] = draw_battery(opts.bat_l,opts);
f.UserData.Symbols.icon_plots.Battery = lineplot;
end

function mat = draw_split(Width,opts)
%% Draw shape for current splitting

%initialize mat 
mat = ones(Width,Width);

% Square shape 
Height = Width;

% Corners
X = round(Width/2*(1 + [-1,1]*opts.Spl_l));
Y = round(Height/2*(1 + [-1,1]*opts.Spl_h));

% Thickness
layers      = round((opts.LW-1)/2); if layers == 0;error('');end
thickness   = (-layers:layers);
plot_aid    = @(int) round(int+thickness);

% horz. lines
for ii = 1:Width

    % Tails
    if ii < X(1) || ii > X(2)
        mat(plot_aid(Width/2),ii) = 0;
    else
        % Top/ Bottom
        for iii = 1:2
            mat(plot_aid(Y(iii)),ii) = 0;
        end
    end
end

% Vertical lines
for ii = min(Y):max(Y)
    x_plot = [plot_aid(X(1)),plot_aid(X(2))];
    mat(ii,x_plot) = 0;
end

% Plotline ~~~ what the hell is this ?
% plotline.x = [ [0;X(1)] , [X(2);Width] , [X(1);X(2)] , [X(1);X(2)] , [X(1);X(1)] , [X(2);X(2)] ];
% plotline.y = [ [0;0] ,    [0;0],         [Y(2);Y(2)] , [Y(1);Y(1)] , [Y(1);Y(2)] , [Y(1);Y(2)] ];
end

function [mat] = draw_resistor(Width,thickness,opts)
%% Draw shape of resistor based on varied size inputs

% Automatically SQUARE
Height = Width;

% Creat shape
y = resistor_y_of_x(Width,opts);

% Round to integers (index access)
y = round(y);

% Apply Thickness (only works for even opts.R_h numbers atm)
y = y +(-(thickness-1)-.5:(thickness-1)+.5)'; if mod(Height,2) ~= 0; error('');end

% Apply Y-Center off-set
y = y + (Height - 1)/2;  % (Start at index one, not zero)

% initialze 2D mat (all white)
mat = ones(Height,Width); %(one --> white)

% Fill in (draw) resistor black
for ii = 1:Width
    mat(y(:,ii),ii) = 0; %(zero --> black)
end
end

function y = resistor_y_of_x(Width,opts)
%% Producee y of x function to resemble resistor shape

dx_tail = opts.R_tail * Width;

dx_halfpeak = (Width * (1 - 2 *opts.R_tail))/10;

Height = opts.R_h * Width / opts.R_l;

Slope = Height / dx_halfpeak;

x0 = dx_tail+dx_halfpeak*[0,1:2:9,10];
y0 = -[0,Height,-Height,Height,-Height,Height,0];

x = 1:Width;
y = zeros(size(x));

for j = 1:numel(x)

    % Tails
    if abs(x(j)-Width/2) > (Width/2 - dx_tail)
        y(j) = 0;
    else
        % Peaks
        for jj = 1:length(x0) - 1
            if x(j) < x0(jj + 1)
                if mod(jj,2) == 0
                    dir = 1; % up
                else
                    dir = -1; % down
                end
                y(j) = y0(jj) + dir * Slope * (x(j) - x0(jj));
                break
            end
        end

    end
end
end

function lineplot = draw_resistor_plot(opts)
%% Draw plot icon for resistor

dx_lp = opts.R_tail * opts.R_l; % tail ends distance for lineplot (same ratio)

peak_w_lp = opts.R_l * (1-2*opts.R_tail) / 10; % hald peak dx for lineplot (same ratio)

% coords.
x       = [0, dx_lp, dx_lp + [1:2:9,10]*peak_w_lp, 10*peak_w_lp + 2*dx_lp];
y_pos   = opts.R_h;
y_neg   = -opts.R_h;
y       = [0,0,y_pos,y_neg,y_pos,y_neg,y_pos,0,0];

% Return struct here 
lineplot.x = x;
lineplot.y = y;
end

function [mat,lineplot] = draw_battery(Width,opts)
%% Draw battery shape 

% x-location of lines
x = linspace(1,Width,6);
x0 = round(x(2:5)); % for inidices

% Heights of lines (as ratio to area height)
height_ratios = [.75,.25,.65,.25];

% Apply thickness (opts.lW)
layers = round((opts.LW-1)/2);
x = x0 + (-layers:layers)';

yvec = @(ratio) round((1:ratio*Width) + (1-ratio)*Width/2);

mat = ones(Width,Width);

y0 = zeros(2,4);

for j = 1:width(x)  
    y_j = yvec(height_ratios(j));
    % Apply thickness
    for jj = 1:height(x)
        mat(y_j,x(jj,j)) = 0; 
    end
    y0(1,j) = max(y_j);
    y0(2,j) = min(y_j);
end

lineplot.x = [x0;x0];
lineplot.y = y0 - Width/2;
end

function Solve_Circuit(btn,f)
%% Solve the circuit and display the results to tables

% ~~~ add early exit case for no elements or no battery

% ~~~ I'm thinking about eliminating node sides on child sides !!

% *** Mat is :
% [v1,...,num_nodes,i1,...,num_currents,CONST]

% initializations
num_nodes   = numel(f.UserData.Nodes); % Will have more nodes based on child sides
num_sides   = numel(f.UserData.Sides); % This is our number of currents, hard stop
num_eqns    = num_nodes + num_sides;
eqn_mat     = zeros(num_eqns,num_nodes+num_sides+1);
R_count     = 0;
B_count     = 0;

% ** This function handle used for debugging and displaying equations
% conveiently to command window! nothing else
disp_eqns = @(mat)disp_eqn_mat(mat,num_nodes,num_sides); %#ok<NASGU>

%~~~num_currents = num_sides; % this will differentiate with child sides

% Create current splitting equations at each node
for i = 1:num_nodes
    % based on Node.In and Node.Out, create the equations
    % sum(Node.In) - sum(Node.Out) = 0;
    eqn_mat(i,num_nodes + f.UserData.Nodes(i).In) = 1;
    eqn_mat(i,num_nodes + f.UserData.Nodes(i).Out) = -1; % Way simpler than I thought lol
end

% ~~~ there is no perfect way to comment this all honestly. Its gonna be
% kind of hard to re-read and edit, just the nature of it. Tried my best
% with variable naming. Good luck if youre debugging this.

% Create voltage drop equations for each side
for i = 1:num_sides
    Els = f.UserData.Sides(i).Elements;

    % establish current index for this side. If child side exists, current
    % index will be switched to anew.
    current_ind = num_nodes + i;
    last_node   = f.UserData.Sides(i).Nodes(1);
    % loop through side elements, counting values and placing in eqn_mat
    for j = 1:numel(Els)
        switch Els{j}.Type
            case 'Resistor'
                R_count = R_count + Els{j}.Value;
                el_currents.Resistors.(Els{j}.ID) = current_ind;
            case 'Battery'
                B_count = B_count + Els{j}.Value;
                el_currents.Batteries.(Els{j}.ID) = current_ind;
            case 'Child Side'
                % place ends of child side branch in voltage eqn row
                nodes = f.UserData.Sides(Els{j}.Side_ind(1)).Nodes; 
                
                % Write equation up to child-branch
                num_eqns  = num_eqns+1;
                eqn_mat(num_eqns,[last_node,nodes(1),current_ind]) = [-1,1,R_count];  

                % reset R-value count and last node (now end of child
                % branch for next voltage equation
                last_node = nodes(2);
                R_count = 0;
        end
    end
    % finish equation row
    eqn_mat(current_ind,[last_node,f.UserData.Sides(i).Nodes(2),current_ind]) = [-1,1,R_count]; 

    % reset R-value count
    R_count = 0;

    eqn_mat(current_ind,end) = B_count;
    B_count = 0;
end

% Add ground equation (rel --> abs)
% Current is just node1 = GND subject to change / expansion
num_eqns = num_eqns + 1;
eqn_mat(num_eqns,1) = 1;

%Truncate mat based on number of currents
eqn_mat = eqn_mat(1:num_eqns,:);

% Solve matrix of equations 
results_mat = rref(eqn_mat);

% update tables with solved data ~~~ error case for Ohms or Volts never
% created (not existing in resulsts table at solve call)
tags = ["R_Table",  "B_Table"];
fn   = ["Resistors","Batteries"];
for i = 1:2

    % find uitable to be updated
    table = findobj(f,'Tag',tags(i));

    % fill in amps column with rref result
    for ii = 1:height(table.Data)
        table.Data.Amps(ii) = results_mat(el_currents.(fn(i)).(table.RowName{ii}),end);
    end

    % result column (volts, Watts) column
    if i == 1
        table.Data.Volts = table.Data.Ohms .* table.Data.Amps;
    else
        table.Data.Watts = table.Data.Volts .* table.Data.Amps;
    end
end
btn.Value = false;
end

function disp_eqn_mat(eqn_mat,num_nodes,num_sides)
%% label the equation mat rows and cols for debugging
fprintf('\n')

id  = {'n','i','B'}; % Node, Current, Constant
numPrintType = numel(id);

% varFormat = 'color';
varFormat = 'bold';

switch varFormat
    case 'color'
        % color string short handle
        clr = {'blue','red','black'};
        str = @(i,str) ['<font color="', clr{i}, '">', str, '</font>'];
    case 'bold'
        is_bold = [1,0,1];
        str = @(i,str) embolden_str(is_bold(i),str);
end

% column headers - nodes, currents and constant indices
 
len = [num_nodes,num_sides,1];
for i = 1:numPrintType
    if i == 3
        id_str = id{i};
    else
        id_str = [id{i},'%d'];
    end
    for ii = 1:len(i)
        fprintf(['\t',str(i,id_str)],ii)
    end
end

% print matrix along same tabs
fprintf('\n')
for i = 1:height(eqn_mat)
    for ii = 1:sum(len)
        fprintf('\t%d',eqn_mat(i,ii))
    end
    fprintf('\n')
end
fprintf('\n\n')
end

function str = embolden_str(is_bold,str)
%% Return String emboldened

if is_bold
    str = ['<strong>',str,'</strong>'];
end
end

function highlight_side(f,ind,clr) %#ok<DEFNU>
%% Highlight a given side of the circuit a given color, used for debugging

ax_obj = findobj(f,'Tag','Display');

sides = findobj(ax_obj,'Tag',['Side ',num2str(ind)]);
for i = 1:numel(sides)
    sides(i).Color = clr;
end
end