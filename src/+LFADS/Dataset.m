classdef Dataset < handle & matlab.mixin.CustomDisplay & matlab.mixin.Copyable
    % A single-day collection of raw data to be processed by LFADS

    methods
        % These methods you should customize in order to access the data and
        % metadata for this dataset.
        
        function data = loadData(ds)
            % Load and return this Dataset's data. The default
            % implementation calls Matlab's load on `.path`
            
            data = load(ds.path);
%             flds = fieldnames(in);
%             if numel(flds) == 1
%                 fld = flds{1};
%             else
%                 fld = 'data';
%             end
%             data = in.(fld);
        end

        function loadInfo(ds, reload)
            % Load this Dataset's metadata if not already loaded
            % Override this method directly if you wish to manually load
            % metadata without calling `loadData` first. If you need to
            % load the data in order to determine the metadata, then
            % override loadInfoFromData` below and extract the metadata.
    
            if nargin < 2, reload = false; end
            if ds.infoLoaded && ~reload, return; end
            data = ds.loadData();
            ds.loadInfoFromData(data);
            ds.infoLoaded = true;
        end

        function loadInfoFromData(data) %#ok<MANU>
            % This method should load any metadata about the dataset from
            % the loaded data. You should provide an implementation for
            % this method yourself, or override loadInfo directly
            error('Subclasses should provide their own implementation of this method unless loadInfo() is overridden directly');
        end
    end

    properties
        % Information about the dataset's name and location

        name char = '';
        % Unique, semi-permanent identifier for the dataset. This will be used for paths and filenames and
        % variables within the LFADS model, so it's best to pick a scheme and stick to it.

        comment char = '';
        % Textual comment for convenience

        relPath char = '';
        % Path to the Matlab data file that will be loaded when loadData is called, relative to the path of the
        % :ref:`LFADS_DatasetCollection` to which this Dataset belongs. If you override loadData, this can be left blank.

        collection
        % :ref:`LFADS_DatasetCollection` to which this Dataset belongs
    end

    properties
        % Useful metadata about this dataset to be loaded by loadInfoFromData. These are not used explicitly
        % and can be left blank.

        infoLoaded logical = false;
        % Has loadInfo already been called and the info fields populated?

        subject char = ''
        % Dataset subject or participant name

        saveTags
        % Data grouping identifiers

        datenum double = NaN;
        % Matlab datenum identifying the collection time of this dataset

        nChannels = NaN;
        % Number of spike channels recorded in this dataset

        nTrials = NaN;
        % Number of behavioral trials recorded in this dataset
    end

    properties(Dependent)
        path
        % Full path to data which will be loaded by load data, a concatenation of the DatasetCollection path and relPath

        datestr
        % a string version of datenum YYYY-MM-DD
        
        datestrNoHyphen
        % a string version of datenum YYYYMMDD
        
        indexInCollection
        % my index in the collection
    end
    
    properties(Hidden, SetAccess=protected)
        addedToCollection = false;
    end

    methods
        function ds = Dataset(collection, relPath)
            % ds = Dataset(collection, relPath)
            % Parameters
            % ------------
            % collection : :ref:`LFADS_DatasetCollection`
            %   DatasetCollection to which this Dataset belongs
            %
            % relPath : string
            %   Relative path to data from `collection.path`

            [~, ds.name] = fileparts(relPath);
            ds.name = strrep(ds.name, ',', '_');
            ds.relPath = relPath;
            if ~ds.addedToCollection
                collection.addDataset(ds);
                ds.addedToCollection = true;
            end
        end

        function p = get.path(ds)
            if isempty(ds.collection)
                p = ds.relPath;
            else
                p = fullfile(ds.collection.path, ds.relPath);
            end
        end

        function reloadInfo(ds)
            % Load or reload this Dataset's metadata even if already loaded
            ds.infoLoaded = false;
            ds.loadInfo();
        end

        function ds = get.datestr(ds)
            if isempty(ds.datenum) || isnan(ds.datenum)
                ds = '';
            else
                ds = datestr(ds.datenum, 'yyyy-mm-dd'); %#ok<CPROP>
            end
        end
        
        function ds = get.datestrNoHyphen(ds)
            if isempty(ds.datenum) || isnan(ds.datenum)
                ds = '';
            else
                ds = datestr(ds.datenum, 'yyyymmdd'); %#ok<CPROP>
            end
        end
        
        function index = get.indexInCollection(ds)
            index = find(ds == ds.collection.datasets);
        end
        
        function name = getSingleRunName(ds)
           % generate a consise name for a run with only this dataset
           name = sprintf('single_%s', ds.name); 
        end
    end
    
    methods(Hidden)
        function h = getFirstLineHeader(ds)
            className = class(ds);
            h = sprintf('%s "%s"', className, ds.name);
        end
    end

    methods (Access = protected)
       function header = getHeader(ds)
          if ~isscalar(ds)
             header = getHeader@matlab.mixin.CustomDisplay(ds);
          else
             header = sprintf('%s\n', ds.getFirstLineHeader());
          end
       end
    end

end
