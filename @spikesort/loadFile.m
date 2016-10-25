% this function loads files 

function [s] = loadFile(s,src,~)

if strcmp(get(src,'String'),'Load File')
    [s.file_name,s.path_name,filter_index] = uigetfile({'*.mat';'*.kontroller'});
    if ~s.file_name
        return
    end
elseif strcmp(get(src,'String'),'<')
    if isempty(s.file_name)
        return
    else
        % first save what we had before
        save(strcat(s.path_name,s.file_name),'spikes','-append')


        if filter_index == 1
            allfiles = dir(strcat(s.path_name,'*.mat'));
        else
            allfiles = dir(strcat(s.path_name,'*.kontroller'));
        end
        thisfile = find(strcmp(s.file_name,{allfiles.name}))-1;
        if thisfile < 1
            s.file_name = allfiles(end).name;
        else
            s.file_name = allfiles(thisfile).name;    
        end
        
    end
else
    if isempty(s.file_name)
        return
    else
        % first save what we had before
        save(strcat(s.path_name,s.file_name),'spikes','-append')
        
        if filter_index == 1
            allfiles = dir(strcat(s.path_name,'*.mat'));
        else
            allfiles = dir(strcat(s.path_name,'*.kontroller'));
        end
        thisfile = find(strcmp(s.file_name,{allfiles.name}))+1;
        if thisfile > length(allfiles)
            s.file_name = allfiles(1).name;
        else
            s.file_name = allfiles(thisfile).name;
        end
        
    end
end

% reset some pushbuttons and other things
set(s.handles.discard_control,'Value',0)
s.this_trial = 1;
s.this_paradigm = 1;
s.current_data = [];
    
temp = load(strcat(s.path_name,s.file_name),'-mat');
try
    try
        delete(handles.load_waitbar)
    catch
    end
    s.handles.load_waitbar = waitbar(0.2, 'Loading data...');

    s.current_data.ControlParadigm = temp.ControlParadigm;
    s.current_data.data = temp.data;
    s.current_data.SamplingRate = temp.SamplingRate;
    s.OutputChannelNames = temp.OutputChannelNames;


    if isfield(temp,'spikes')
        s.current_data.spikes = temp.spikes;
    end
    clear temp



    waitbar(0.3,s.handles.load_waitbar,'Updating listboxes...')
    % update control signal listboxes with OutputChannelNames
    set(s.handles.valve_channel,'String',s.OutputChannelNames)

    % update stimulus listbox with all input channel names
    fl = fieldnames(s.current_data.data);

    % also add all the control signals
    try
        set(s.handles.stim_channel,'String',[fl(:); s.OutputChannelNames]);
    catch
        set(s.handles.stim_channel,'String',[fl(:) s.OutputChannelNames]);
    end

    % update response listbox with all the input channel names
    set(s.handles.resp_channel,'String',fl);

    % some sanity checks
    if length(s.current_data.data) > length(s.current_data.ControlParadigm)
        error('Something is wrong with this file: more data than control paradigms.')
    end

    % find out which paradigms have data 
    n = structureElementLength(s.current_data.data);  % vector with trials per paradigm

    % only show the paradigms with data
    temp = {s.current_data.ControlParadigm.Name};
    set(s.handles.paradigm_chooser,'String',temp(find(n)),'Value',1);


    % go to the first paradigm with data. 
    s.this_paradigm = find(n);
    s.this_paradigm = s.this_paradigm(1);


    n = n(s.this_paradigm);
    if n
        temp  ={};
        for i = 1:n
            temp{i} = strcat('Trial-',mat2str(i));
        end
        set(s.handles.trial_chooser,'String',temp);
        s.this_trial = 1;
        set(s.handles.trial_chooser,'String',temp);
    else
        set(s.handles.trial_chooser,'String','No data');
        s.this_trial = NaN;
    end

    waitbar(0.4,s.handles.load_waitbar,'Guessing control signals...')
    % automatically default to picking the digital signals as the control signals
    digital_channels = zeros(1,length(s.OutputChannelNames));
    for i = 1:length(s.current_data.ControlParadigm)
        for j = 1:width(s.current_data.ControlParadigm(i).Outputs)
            uv = (unique(s.current_data.ControlParadigm(i).Outputs(j,:)));
            if length(uv) == 2 && sum(uv) == 1
                digital_channels(j) = 1;
            end
           
        end
    end
    digital_channels = find(digital_channels);
    set(s.handles.valve_channel,'Value',digital_channels);


    waitbar(0.5,s.handles.load_waitbar,'Guessing stimulus and response...')
    temp = find(strcmp('PID', fl));
    if ~isempty(temp)
        set(s.handles.stim_channel,'Value',temp);
    end
    temp = find(strcmp('voltage', fl));
    if ~isempty(temp)
        set(s.handles.resp_channel,'Value',temp);

    end

    set(s.handles.main_fig,'Name',strcat(s.version_name,'--',s.file_name))

    % enable all controls
    waitbar(.7,s.handles.load_waitbar,'Enabling UI...')
    set(s.handles.sine_control,'Enable','on');
    set(s.handles.autosort_control,'Enable','on');
    set(s.handles.redo_control,'Enable','on');
    set(s.handles.findmode,'Enable','on');
    set(s.handles.filtermode,'Enable','on');
    set(s.handles.cluster_control,'Enable','on');
    set(s.handles.prev_trial,'Enable','on');
    set(s.handles.next_trial,'Enable','on');
    set(s.handles.prev_paradigm,'Enable','on');
    set(s.handles.next_paradigm,'Enable','on');
    set(s.handles.trial_chooser,'Enable','on');
    set(s.handles.paradigm_chooser,'Enable','on');
    set(s.handles.discard_control,'Enable','on');
    set(s.handles.metadata_text_control,'Enable','on')

    % check for amplitudes 
    waitbar(.7,s.handles.load_waitbar,'Checking to see amplitude data exists...')
    % check if we have spike_amplitude data
    spikes = s.current_data.spikes;
    if length(spikes)
        for i = 1:length(spikes)
            for j = 1:width(spikes(i).A)
                haz_data = 0;
                if length(spikes(i).A(j,:)) > 2 
                    if isfield(spikes,'discard')
                        if length(spikes(i).discard) < j
                            haz_data = 1;
                        else
                            if ~spikes(i).discard(j)
                                haz_data = 1;
                            end
                        end
                    else
                        haz_data = 1;
                    end
                end
                if haz_data
                    recompute = 0;
                    if isfield(spikes,'amplitudes_A')
                        if width(spikes(i).amplitudes_A) < j
                            recompute = 1;
                            spikes(i).amplitudes_A = [];
                            spikes(i).amplitudes_B = [];
                        elseif length(spikes(i).amplitudes_A(j,:)) < length(spikes(i).A(j,:))
                            spikes(i).amplitudes_A = [];
                            spikes(i).amplitudes_B = [];
                            recompute = 1;
                            
                        end
                    end
                    if recompute
                        A = spikes(i).A(j,:);
                    
                        spikes(i).amplitudes_A(j,:) = sparse(1,length(A));
                        spikes(i).amplitudes_B(j,:) = sparse(1,length(A));
                        V = data(i).voltage(j,:);
                        spikes(i).amplitudes_A(j,find(A))  =  ssdm_1DAmplitudes(V,pref.deltat,find(A),pref.invert_V);
                        B = spikes(i).B(j,:);
                        spikes(i).amplitudes_B(j,find(B))  =  ssdm_1DAmplitudes(V,pref.deltat,find(B),pref.invert_V);
                    end
                end

            end
        end
    end

    % check to see if metadata exists
    try
        set(s.handles.metadata_text_control,'String',metadata.spikesort_comment)
    catch
        set(s.handles.metadata_text_control,'String','')
    end

    % check to see if this file is tagged. 
    if isunix
        clear es
        es{1} = 'tag -l ';
        es{2} = strcat(s.path_name,s.file_name);
        [~,temp] = unix(strjoin(es));
        set(s.handles.tag_control,'String',temp(strfind(temp,'.mat')+5:end-1));
    end

    % clean up
    close(s.handles.load_waitbar)

    s.plotStim;
    s.plotResp(@s.loadFile);
catch err
    if strcmp(get(src,'String'),'>')
        s.loadFile(src)
    elseif strcmp(get(src,'String'),'<')
        s.loadFile(src)
    else
        warning('Something went wrong with loading the file. The error was:')
        disp(err)
        disp('The error was here:')
        for ei = 1:length(err.stack)
            disp(err.stack(ei))
        end
    end

end