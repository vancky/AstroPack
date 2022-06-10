function Result = pointingModel(Files, Args)
    %
    % Example: R = pipeline.last.pointingModel([],'StartDate',[08 06 2022 17 54 00],'EndDate',[08 06 2022 18 06 00]);
    
    arguments
        Files                             = 'LAST*sci*.fits';
        Args.StartDate                    = [];
        Args.EndDate                      = [];
        Args.astrometryCroppedArgs cell   = {};
        %Args.backgroundArgs cell          = {};
        %Args.findMeasureSourcesArgs cell  = {};
    end
    
    if isempty(Files)
        Files = 'LAST*sci*.fits';
    end
    
    List = ImagePath.selectByDate(Files, Args.StartDate, Args.EndDate);
    
    Nlist = numel(List);
    for Ilist=1:1:Nlist
        Ilist
        AI = AstroImage(List{Ilist});
        Keys = AI.getStructKey({'RA','DEC','HA','M_JRA','M_JDEC','M_JHA','JD','LST'});
        try
            [R, CAI, S] = imProc.astrometry.astrometryCropped(List{Ilist}, 'RA',Keys.RA, 'Dec',Keys.DEC, 'CropSize',[],Args.astrometryCroppedArgs{:});
        catch
            fprintf('Failed on image %d\n',Ilist);
            
            S.CenterRA = NaN;
            S.CenterDec = NaN;
            S.Scale = NaN;
            S.Rotation = NaN;
            S.Ngood = 0;
            S.AssymRMS = NaN;
        end
        if Ilist==1
            Head   = {'RA','Dec','HA','M_JRA','M_JDEC','M_JHA','JD','LST','CenterRA','CenterDec','Scale','Rotation','Ngood','AssymRMS'};
            Nhead  = numel(Head);
            Table  = zeros(Nlist,Nhead);
        end
        Table(Ilist,:) = [Keys.RA, Keys.DEC, Keys.HA, Keys.M_JRA, Keys.M_JDEC, Keys.M_JHA, Keys.JD, Keys.LST, ...
                          S.CenterRA, S.CenterDec, S.Scale, S.Rotation, S.Ngood, S.AssymRMS];
        
    end
    
    Result = array2table(Table);
    Result.Properties.VariableNames = Head;
    
end