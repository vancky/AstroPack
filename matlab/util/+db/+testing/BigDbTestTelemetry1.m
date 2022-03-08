
function Result = BigDbTestTelemery1()
    % You need to have configuration file with database user and password:
    % config/local/Database.DbConnections.UnitTest.yml
    % 
    DatabaseName = 'perftest';
    TableName = 'telemetry1';   %'big_table2';
    Cols = 50;
    BatchSize = 9999;
    Pid = feature('getpid');
    
    MsgLogger.getSingleton().setLogLevel(LogLevel.Debug);
    
    Q = db.DbQuery(DatabaseName);
    pgver = Q.getDbVersion();
    io.msgLog(LogLevel.Test, 'Postgres version: %s', pgver);
    Q.TableName = TableName;
             
    %
    FileName = sprintf('BigDbTest_%d.csv', Pid);
    CsvFileName = fullfile(tools.os.getTempDir(), FileName);    
    
    [~, ClientFileName] = Q.getSharedFileName(CsvFileName);
    CsvFileName = ClientFileName;
    
    % Prepare data
    Data = struct;
    rcv_time = rand;
    tick = int32(rand*1000000);
    time = rand;
    for i=1:BatchSize
        Data(i).rcv_time = rcv_time;
        Data(i).param = sprintf('PRM%03d', mod(i, 999));
        Data(i).idx = mod(i, 200);
        Data(i).f_time = time;
        Data(i).f_tick = tick;
        Data(i).f_value = rand * 1000;
        Data(i).s_value = sprintf('this %d is my %d text bla bla %d', i, i, i);
    end
               
    BatchCounter = 1;
    RowCount = 0;
    while true
        
        % Update data with keys
        rcv_time = rand;
        tick = int32(rand*1000000);
        time = rand;
        for i=1:BatchSize
            Data(i).rcv_time = rcv_time;
            Data(i).param = sprintf('PRM%03d', mod(i, 999));
            Data(i).idx = mod(i, 200);
            Data(i).f_time = time;
            Data(i).f_tick = tick;
            Data(i).f_value = rand * 1000;
            Data(i).s_value = sprintf('this %d is my %d text bla bla %d', i, i, i);
        end
        
        % Write to CSV file
        Table = struct2table(Data);
        writetable(Table, CsvFileName);                     
            
        % Get number of rows in table
        if mod(BatchCounter, 10) == 1
            RowCount = Q.selectCount('Fast', true);
        else
            RowCount = RowCount + BatchSize;
        end

        % Insert from CSV file
        t1 = tic;
        Q.insert([], 'CsvFileName', CsvFileName);        
        io.msgLog(LogLevel.Test, '[%05d] RowCount=%d, insert %d x %d: %0.5f sec', BatchCounter, RowCount, BatchSize, Cols, toc(t1));
        
        BatchCounter = BatchCounter + 1;
    end
       
end

