classdef TVStitchedMosaicInfo
    %TVSTITCHEDDATASETINFO Provides metadata on a particular, stitched TV
    %experiment
    
    properties(SetAccess=protected)
        baseDirectory
        experimentName
        sampleName
        stitchedImagePaths
        metaData
    end
    properties(Dependent, SetAccess=protected)
        downscaledStacks
        downscaledStackList
    end
    
    methods
        function obj=TVStitchedMosaicInfo(baseDirectory)
            
            %% Error checking
            if nargin<1
                error('No path specified')
            elseif ~exist(baseDirectory, 'dir')
                error('Specified path does not exist')
            end

            %% Get file parts
            [~, obj.experimentName]=fileparts(baseDirectory);
            obj.baseDirectory=baseDirectory;

            %% Get metadata
            obj=getMosaicMetaData(obj);
            obj.sampleName=obj.metaData.SampleID;
            
            obj=getStitchedImagePaths(obj);
            %% Get available downscaled stacks
        end

        function ds=get.downscaledStacks(obj)
            masivDir=getMasivDirPath(obj);
            pathToDSObjsFile=fullfile(masivDir, [obj.sampleName '_MaSIVInfo.mat']);
            if ~exist(pathToDSObjsFile, 'file')
                ds=[];
                fprintf('\n\n\t=====>  Directory %s contains no down-scaled image stacks  <=====\n',obj.baseDirectory)
                fprintf('\n\n\t\tINSTRUCTIONS')
                fprintf('\n\n\tYou will need to generate down-scaled image stacks in order to proceed.')
                fprintf('\n\tClick "New", then the channel you want to build, then the section range.')
                fprintf('\n\tSee documention on the web for more information.\n\n\n')
            else
                a=load(pathToDSObjsFile);
                ds=a.stacks;
                for ii=1:numel(ds)
                    ds(ii).updateFilePathMetaData(obj)
                end
            end
        end

        function dsl=get.downscaledStackList(obj)
            ds=obj.downscaledStacks;
            if ~isempty(ds)
                dsl=ds.list;
            else
                dsl=[];
            end
            dsl=dsl(:);
        end

        function obj=changeImagePaths(obj, strToReplace, newStr)
                % Allows batch editing of the image paths. This can be
                % needed if the base directory is changed
                
                s=fieldnames(obj.stitchedImagePaths);
                for ii=1:numel(s)
                    obj.stitchedImagePaths.(s{ii})=strrep(obj.stitchedImagePaths.(s{ii}), strToReplace, newStr);
                end
            
        end
    end
    
end

function obj=getMosaicMetaData(obj)
    %Get meta-data from TissueVision Mosaic file
    delimiterInTextFile='\r\n';

    %% Get matching files
    metaDataFileName=dir(fullfile(obj.baseDirectory,'Mosaic*.txt'));
    if isempty(metaDataFileName)
        error('Mosaic metadata file not found')
    elseif numel(metaDataFileName)>1
        error('Multiple metadata files found. There should only be one matching ''Mosaic*.txt''')
    end

    metaDataFullPath=fullfile(obj.baseDirectory, metaDataFileName.name);

    %% Open
    fh=fopen(metaDataFullPath);
    
    %% Read
    txtFileContents=textscan(fh, '%s', 'Delimiter', delimiterInTextFile);
    txtFileContents=txtFileContents{1};
    
    %% Parse
    info=struct;
    for ii=1:length(txtFileContents)
        spl=strsplit(txtFileContents{ii}, ':');
    
        if numel(spl)<2
            error('Invalid name/value pair: %s', txtFileContents{ii})
        elseif numel(spl)>2
            spl{2}=strjoin(spl(2:end), ':');
            spl=spl(1:2);
        end
        nm=strrep(spl{1}, ' ', '');
        val=spl{2};
        valNum=str2double(val);
        if ~isempty(valNum)&&~isnan(valNum)
            val=valNum;
        end
    
        info.(nm)=val;
    end

    fclose(fh); 

    %% Assign
    if isempty(info)||~isstruct(info)
        error('Invalid metadata file')
    else
        obj.metaData=info;
    end
end %function obj=getMosaicMetaData(obj)



function obj=getStitchedImagePaths(obj)
    %Get paths to stitched (full-resolution) images from text files
    delimiterInTextFile='\r\n';
    searchPattern=[obj.sampleName, '_ImageList_'];
    baseDir=getMasivDirPath(obj);
    listFilePaths=dir(fullfile(baseDir, [searchPattern '*.txt']));
    
    if isempty(listFilePaths)
        fprintf('\n\n\t*****\n\tCan not find text files listing the relative paths to the full resolution images.\n\tYou need to create these text files. Please see the documentation on the web.\n\tQUITING.\n\t*****\n\n\n')
        error('No %s*.txt files found.\n',searchPattern)
    end

    obj.stitchedImagePaths=struct;

    for ii=1:numel(listFilePaths)
        
        fh=fopen(fullfile(baseDir, listFilePaths(ii).name));
            channelFilePaths=textscan(fh, '%s', 'Delimiter', delimiterInTextFile);
        fclose(fh);
        checkForAbsolutePaths(channelFilePaths{:})
        channelName=strrep(strrep(listFilePaths(ii).name, searchPattern, ''), '.txt', '');
        obj.stitchedImagePaths.(channelName)=channelFilePaths{:};
    end
end %function obj=getStitchedImagePaths(obj)

function checkForAbsolutePaths(strList)
    for ii = 1:numel(strList)
        s=strList{ii};
        if s(1)=='/' || ~isempty(regexp(s, '[A-Z]:/', 'ONCE'))
            error('File List appears to be absolute. ImageList files must contain relative paths, to prevent data loss')
        end
    end
end