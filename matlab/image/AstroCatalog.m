% AstroCatalog handle class
% Package: @AstroCatalog
% Description: 
% Tested : Matlab R2018a
% Author : Eran O. Ofek (Mar 2021)
% Dependencies: @convert, @celestial
% Example : 
% Reliable: 2
%--------------------------------------------------------------------------

classdef AstroCatalog < handle %ImageComponent
    % Component should contain:
    % UserData
    % Config
    
    properties (SetAccess = public)
        Catalog                                                = [];
        ColCell cell                                           = {};
        ColUnits cell                                          = {};
        SortByCol                                              = [];
        IsSorted(1,1) logical                                  = false;
    end
    
    methods % Constructor
       
        function Obj = AstroCatalog
            %
            
        end

    end
 
%     methods % subsref
%         function varargout = subsref(Obj,S)
%             % FOR SMALL TABLES THIS SLOWS DOWN PERFORMNCES BY FACTOR OF 4!
%             % tic; for I=1:1:1000, aa=AC.Catalog; end; toc

%             if numel(S)>1 && strcmp(S(end-1).subs,'CatCol')
%                 % identified a CatColumn requesy
%                 if strcmp(S(end).type,'.')
%                     ColInd = colname2ind(Obj, S(end).subs);
%                     varargout{1} = Obj.Catalog(:,ColInd);
%                     if istable(varargout{1})
%                         varargout{1} = table2array(varargout{1});
%                     end
%                 end
%             else
%                 if nargout==0
%                     Nargout = 1;
%                 else
%                     Nargout = nargout;
%                 end
%                 [varargout{1:Nargout}] = builtin('subsref',Obj,S);
%             end
%             
%         end
%     end

 
    methods % Setters/Getters
        function set.Catalog(Obj, Data)
            % setter for catalog - set also column names and units if table
            % and available
            
            if istable(Data)
                Obj.Catalog = Data;
                
            elseif isnumeric(Data)
                Obj.Catalog = Data;
            elseif iscell(Data)
                Obj.Catalog = cell2table(Data);
            else
                error('Catalog must be numeric, cell, or table');
            end
            Obj.IsSorted = false;
        end
        
        function Result = get.Catalog(Obj)
            % getter for Image - get image from ImageData property
            Result = Obj.Catalog;
        end        
        
        function set.ColCell(Obj, CellColName)
            % setter for ColCell - input is either a cell or a string array
            % if the catalog is in table format it will also set its
            % Properties.VariableNames (but only if the size is consistent)
            Obj.ColCell = CellColName;
            if istable(Obj.Catalog)
                % set the column names also in the table
                if numel(CellColName)==size(Obj.Catalog,2)
                    Obj.Catalog.Properties.VariableNames = CellColName;
                end
            end
        end
        
        function CellColName = get.ColCell(Obj)
            % getter for ColCell
           
            CellColName = Obj.ColCell;
            if isempty(CellColName) && ~isempty(Obj.Catalog) && istable(Obj.Catalog)
                % get ColCell from table properties
                CellColName = Obj.Catalog.Properties.VariableNames;
            end
        end
            
        function set.ColUnits(Obj, CellColUnits)
            % setter for ColUnits - input is either a cell or a string array
            % if the catalog is in table format it will also set its
            % Properties.VariableUnits (but only if the size is consistent)
            Obj.ColUnits = CellColUnits;
            if istable(Obj.Catalog)
                % set the column names also in the table
                if numel(CellColUnits)==size(Obj.Catalog,2)
                    Obj.Catalog.Properties.VariableUnits = CellColUnits;
                end
            end
        end
        
        function CellColUnits = get.ColUnits(Obj)
            % getter for ColUnits
           
            CellColUnits = Obj.ColCell;
            if isempty(CellColUnits) && ~isempty(Obj.Catalog) && istable(Obj.Catalog)
                % get ColUnits from table properties
                CellColUnits = Obj.Catalog.Properties.VariableUnits;
            end
        end
       
        function set.SortByCol(Obj,Val)
            % Setter for SortByCol, also set IsSorted to false
            
            Obj.SortByCol = Val;
            Obj.IsSorted  = false;
        end
        
    end
    
    methods (Static)  % static methods
       function VarNames = default_colcell(Ncol)
            % create a default ColCell with N columns
            % Package: @AstroCatalog (Static)
            % Input  : - Number of columns
            % Example: AstroCatalog.default_colcell(5)
            
            VarNames = cell(1,Ncol);
            for Icol=1:1:Ncol
                VarNames{Icol} = sprintf('Var%d',Icol);
            end
       end
        
       function Ans = compare_colcell(ColCell1,ColCell2)
            % Compare two ColCell's
            % Package: @AstroCatalog (Static)
            % Description: Given two cell array of strings compare their
            %              content. Return a vector of logical of length
            %              equal to the longer ColCell.
            % Input  : - First ColCell
            %          - Second ColCell
            % Output : - a vector of logical of length
            %            equal to the longer ColCell. True if two elements
            %            are identical.
            % Example: AstroCatalog.compare_colcell({'a','b'},{'a','b'})
            
            N1 = numel(ColCell1);
            N2 = numel(ColCell2);
            
            MaxN = max(N1,N2);
            MinN = min(N1,N2);
            Ans  = false(1,MaxN);
            Ans(1:MinN) = ~tools.cell.isempty_cell(regexp(ColCell1(1:MinN),ColCell2(1:MinN),'match'));
            
       end
        
       function NewArray = insert_column(OldArray,NewData,ColInd)
            % Insert a single column into a matrix, table, or a cell array
            % Package: @AstroCatalog (Static)
            % Description: Insert a single column into a matrix, table,
            %              or a cell array.
            % Input  : - A matrix, cell array, or a table.
            %          - A multiple column array, table, or cell array, in
            %            which the number of rows is equal to the number of
            %            rows in the first input argument.
            %            The type must be equalt to the type of the first
            %            input.
            %          - A column index in which to insert the new column.
            %            This is the index of the new column after
            %            insertion. For example, 1 will insert the new
            %            column as the first column.
            % Output : - The new array.
            % Example: AstroCatalog.insert_column({'a','b','c'},{'d','e'},2)
            %          AstroCatalog.insert_column(ones(5,3),zeros(5,2),2)
            %          TT=array2table(zeros(5,2));
            %          TT.Properties.VariableNames={'a','b'};
            %          AstroCatalog.insert_column(array2table(ones(5,3)),TT,2)
            
            [Nrow,Ncol]   = size(OldArray);
            [NrowI,NcolI] = size(NewData);
            
            if ~strcmp(class(OldArray),class(NewData))
                error('First two input arguments must be of the same class');
            end
            
            if  (Nrow~=NrowI)
                error('Number of rows in column to insert must equal to the number of rows in array');
            end
            if ColInd>(Ncol+1) || ColInd<1
                error('Column index in which to insert the column must be between 1 and number of columns +1');
            end
            
            NewArray = [OldArray(:,1:(ColInd-1)), NewData, OldArray(:,ColInd:end)];
        end
    end
    
    
    methods % get general info
        function [Nrow,Ncol] = sizeCatalog(Obj)
            % Return the number o rows and columns in all elements in an AstroCatalog object
            % Example: [Nrow,Ncol] = sizeCatalog(Obj)
            
            Nrow = zeros(size(Obj));
            Ncol = zeros(size(Obj));
            Nobj = numel(Obj);
            for Iobj=1:1:Nobj
                [Nrow(Iobj), Ncol(Iobj)] = size(Obj(Iobj).Catalog);
            end
                
        end
        
        function Result = isemptyCatalog(Obj)
            % Return true if Catalog data in AstroCatalog object is empty, otherwise false.
            % example: Result = isemptyCatalog(Obj)
            
            Result = true(size(Obj));
            Nobj   = numel(Obj);
            for Iobj=1:1:Nobj
                Result(Iobj) = isempty(Obj(Iobj).Catalog);
            end
            
        end
        
        function Result = isColumn(Obj,ColName)
            % Return true if a name is an existing column name in an AstroCatalog object
            % Example: Result = isColumn(Obj,'RA')
            
            arguments
                Obj
                ColName char
            end
            
            Result = false(size(Obj));
            Nobj   = numel(Obj);
            for Iobj=1:1:Nobj
                Result(Iobj) = any(strcmp(ColName, Obj(Iobj).ColCell));
            end
            
        end
            
        function ColInd = colname2ind(Obj, ColName, FillValue)
            % Convert column names to column indices
            % Input  : - A single element AstroCatalog object.
            %          - A column name, a cell array of column names or an
            %            array of column indices.
            %            If empty, then return all columns.
            %            Default is empty.
            %          - If the colun name is char or cell, and it doesn't
            %            exist, this is the fill value for the column
            %            index. If empty, will fail. Default is NaN.
            % Output : - A vector of column indices corresponding to the column names.
            % Author : Eran Ofek (Mar 2021)
            % Example: colname2ind(AC, {'Var1','aa'})
            %          colname2ind(AC, [1 2])
            
            arguments
                Obj(1,1)
                ColName        = [];
                FillValue      = NaN;
            end
           
            if isempty(ColName)
                ColInd = (1:1:numel(Obj.ColCell));
            else
                if isnumeric(ColName)
                    % assumes columns are already column index
                    ColInd = ColName;
                elseif ischar(ColName)
                    ColInd = find(strcmp(Obj.ColCell, ColName));
                    Tmp = find(strcmp(Obj.ColCell, ColName));
                    if isempty(Tmp)
                        if isempty(FillValue)
                            error('Column %s not found',ColName);
                        else
                            ColInd = FillValue;
                        end
                    else
                        ColInd = Tmp;
                    end

                elseif iscell(ColName) || isstring(ColName)
                    Ncol   = numel(ColName);
                    ColInd = nan(1,Ncol);
                    for Icol=1:1:Ncol
                        Tmp = find(strcmp(Obj.ColCell, ColName{Icol}));
                        if isempty(Tmp)
                            if isempty(FillValue)
                                error('Column %s not found',ColName{Icol});
                            else
                                ColInd(Icol) = FillValue;
                            end
                        else
                            ColInd(Icol) = Tmp;
                        end
                    end
                end
            end
        end
        
        function ColName = colind2name(Obj, ColInd)
            % Return column names corresponding to column indices
            % Input  : - A single element AstroCatlog object
            %          - A vector of column indices.
            % Output : - A cell array of column names corresponding to the
            %            column indices.
            % Example: colind2name(AC,[2 1])
           
            ColName = Obj.ColCell(ColInd);
        end
        
        function St = col2struct(Obj)
            % return structure array with column names in field and index in values.
            % Example: col2struct(A)
            
            Nobj = numel(Obj);
            Iobj = 1;
            St   = tools.struct.struct_def(Obj(Iobj).ColCell,size(Obj));
            for Iobj=1:1:Nobj
                St(Iobj) = cell2struct(num2cell(1:1:numel(Obj(Iobj).ColCell)), Obj(Iobj).ColCell,2);
            end
            
        end
        
        function Result = isColIdentical(Obj, ColCell)
            % Check if ColCell in an AstroCatalog object is identical to another ColCell
            % Package: @AstroCatalog
            % Descriptio: For each element in a AstroCatalog object check if the
            %             ColCell property is equal to a reference ColCell.
            % Input  : - An AstroCatalog object.
            %          - A cell array of column names (i.e., a reference
            %            ColCell).
            % Output : - A vector lf logical indicating if ColCell's are
            %            identical
            % Example:  Ans=isColIdentical(C,C(4).ColCell)
            
            Nobj   = numel(Obj);
            Result = false(size(Obj));
            for Iobj=1:1:Nobj
                Result(Iobj) = all(AstroCatalog.compare_colcell(Obj(Iobj).ColCell, ColCell));
            end
        end
        
    end
    
    methods  % columns get/edit
        function Result = getCol(Obj, Columns, OutputIsTable, UpdateAstroCatalog)
            % Get a catalog columns by index or names
            % Input  : - A single element AstroCatalog object.
            %          - A vector of column indices, or a column name, or a
            %            cell array of column names.
            %          - If true will convert the output to table,
            %            otherwise will attempt to convert to a matrix.
            %            Default is false.
            %          - If true than in addition to returning the sub
            %            catalog, will store this sub catalog in the
            %            Astrocatalog object.
            %            Default is false.
            % Output : - A matrix or a table containing the selected
            %            columns.
            % Author : Eran Ofek (Mar 2021)
            % Example: AC.getCol({'Var1','Var3'},true)
            %          AC.getCol([1 2])
            %          AC.getCol({'Var1','Var3'},true,true)
            
            arguments
                Obj(1,1)
                Columns
                OutputIsTable(1,1) logical         = false;
                UpdateAstroCatalog(1,1) logical    = false;
            end
                
            
            ColInd = colname2ind(Obj, Columns, []);
            if istable(Obj.Catalog)
                if OutputIsTable
                    Result = Obj.Catalog(:,ColInd);
                else
                    Result = table2array(Obj.Catalog(:,ColInd));
                end
            else
                if OutputIsTable
                    Result = array2table(Obj.Catalog(:,ColInd));
                    Result.Properties.VariableNames = Obj.ColCell;
                    Result.Properties.VariableUnits = Obj.UnitCell;
                else
                    Result = Obj.Catalog(:,ColInd);
                end
            end
            
            if UpdateAstroCatalog
                Obj.Catalog = Result;
            end
            
        end
        
        function Obj = insertCol(Obj, Data, Pos)
            %
           
            
        end
        
        function Obj = replaceCol(Obj, Data, ColNames)
            %
            
        end
        
        function Obj = deleteCol(Obj, Columns)
            %
            
        end
       
        function Obj = merge(Obj)
            %
            
        end
        
    end
    
    methods  % sort and flip
        
        function Obj = sortrows(Obj,SortByColumn)
            % Sort AstroCatalog objects by some column names/indices
            % Input  : - An AstroCatalog object (multiple elements is possible).
            %          - A column/s names or indices by which to sort the
            %            catalogs. If empty, will attempt to use the
            %            SortByCol property. Default is empty.
            % Output : - An object in which the catalogs are sorted.
            % Author : Eran Ofek (Mar 2021)
            % Example: AC=AstroCatalog; AC.Catalog = rand(100,3); AC=sortrows(AC,2);
            
            arguments
                Obj
                SortByColumn       = [];
            end
           
            SortByColumn           = colname2ind(Obj,SortByColumn);
            
            Nobj = numel(Obj);
            for Iobj=1:1:Nobj
                if ~Obj(Iobj).IsSorted
                    if isempty(SortByColumn)
                        SortByColumn = Obj(Iobj).SortByCol;
                    end
                    Obj(Iobj).Catalog   = sortrows(Obj(Iobj).Catalog, SortByColumn);
                    Obj(Iobj).SortByCol = SortByColumn;
                    Obj(Iobj).IsSorted  = true;
                end
            end
        end
                
        function Obj = flipud(Obj)
            % flip up-down all catalogs in AstroCatalog object (set IsSorted to false)
            % Example: flipud(Obj)
            
            Nobj = numel();
            for Iobj=1:1:Nobj
                Obj(Iobj).Catalog = flipud(Obj(Iobj).Catalog);
            end
            
        end
        
    end
    
    methods % applay functions and overloads
            
        function Result = fun_unary(Obj, Operator, OperatorArgs, Columns, UpdateObj)
            % Apply an unary function to columns of a catalog
            % Input  : - An AstroCatalog object.
            %          - Unary operator handle (e.g., @sin).
            %          - A cell array of additional arguments to pass to
            %            the operator. Default is {}.
            %          - List of columns names or indices on which to apply
            %            the operator. If empty, apply to all columns.
            %            Default is empty.
            %          - A logical indicating if to update the object (in
            %            addition to returning the output).
            %            Default is false.
            % Output : - The result (matrix or table).
            % Author : Eran Ofek (Mar 2021)
            % Example: AC=AstroCatalog; AC.Catalog = rand(100,3); AC.ColCell={'a','n','s'}; AC.fun_unary(@sin)
           
            arguments
                Obj
                Operator function_handle
                OperatorArgs cell           = {};
                Columns                     = [];
                UpdateObj(1,1) logical      = false;
            end
            
            
            Nobj = numel(Obj);
            for Iobj=1:1:Nobj
                %
                ColInd = colname2ind(Obj(Iobj), Columns);  % If columns empty - return all columns
                if istable(Obj(Iobj).Catalog)
                    Ncol  = numel(ColInd);
                    Nrows = size(Obj(Iobj).Catalog,1); 
                    Result = nan(Nrows,Ncol);
                    for Icol=1:1:Ncol
                        ColName = Obj(Iobj).ColCell(ColInd(Icol));
                        Result(:,Icol)  = Operator(Obj(Iobj).Catalog.(ColName), OperatorArgs{:});
                        if UpdateObj
                            Obj(Iobj).Catalog.(ColName) = Result(:,Icol);
                        end
                    end
                else
                    Result = Operator(Obj(Iobj).Catalog(:,ColInd), OperatorArgs{:});
                    if UpdateObj
                        Obj(Iobj).Catalog(:,ColInd) = Result;
                    end
                end
            end
            
            
        end
        
    end
    

    methods % Unit-Test
        function Result = unitTest()
            Astro = AstroImage;
            Result = true;
        end
    end
    

end

            
