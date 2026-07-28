function Header = Read_data(filepath)
    FileName = filepath;
    fPtr = fopen(FileName, 'rb');
    if fPtr == -1
        error('Cannot open file: %s', filepath);
    end

    DEFAULT_MAGIC_NUMBER = 369;
    
    % Seek to offset 120 (byte 121) to read m_sTotalNumberofBeams (int16)
    fseek(fPtr, 120, 'bof');
    beam_count = double(fread(fPtr, 1, 'int16'));
    fseek(fPtr, 0, 'bof');

    if isempty(beam_count) || beam_count <= 0
        fclose(fPtr);
        Header = struct([]);
        return;
    end

    % Preallocate Header struct array
    Header(beam_count) = struct( ...
        'm_sMagicNumber', [], ...
        'm_sNumOfRangeBins', [], ...
        'm_fBaudLength_us', [], ...
        'm_sNFFT', [], ...
        'm_sNumOfCohIntegrations', [], ...
        'm_sNumOfInCohIntegrations', [], ...
        'm_sCodeFlag', [], ...
        'm_fIntrPulsePeriod_us', [], ...
        'm_fPulseWidth_us', [], ...
        'm_sNumOfObservWindows', [], ...
        'm_sStationID', [], ...
        'm_sReserved1', [], ...
        'm_sReserved2', [], ...
        'm_sReserved3', [], ...
        'm_sYear', [], ...
        'm_sMonth', [], ...
        'm_sDay', [], ...
        'm_sHour', [], ...
        'm_sMin', [], ...
        'm_sSec', [], ...
        'm_sReserved4', [], ...
        'm_fLatitude', [], ...
        'm_fLongitude', [], ...
        'm_fAltitude', [], ...
        'm_fTotalPowerRadiated', [], ...
        'm_fRadiatedPower_ClusterWise', [], ...
        'm_sOperationMode', [], ...
        'm_sCurrentBeamCnt', [], ...
        'm_sTotalNumberofBeams', [], ...
        'm_usCodeLength', [], ...
        'm_cComment', [], ...
        'm_fTRP_RF_Delay_us', [], ...
        'm_fMGC_Gain_dB', [], ...
        'm_usWindowType', [], ...
        'm_usReserved', [], ...
        'm_cArrRemarks', [], ...
        'm_ulCodeA', [], ...
        'm_ulCodeB', [], ...
        'm_ucExperimentDataEnable', [], ...
        'm_cReserved', [], ...
        'm_fAzimuth', [], ...
        'm_fOffZenith', [], ...
        'm_fWindow1StartHeight', [], ...
        'm_fWindow1EndHeight', [], ...
        'm_fWindow2StartHeight', [], ...
        'm_fWindow2EndHeight', [], ...
        'm_fWindow3StartHeight', [], ...
        'm_fWindow3EndHeight', [], ...
        'm_fWindow4StartHeight', [], ...
        'm_fWindow4EndHeight', [], ...
        'm_fWindow5StartHeight', [], ...
        'm_fWindow5EndHeight', [], ...
        'BeamData', [] ...
    );

    for beam_No = 1:beam_count
        hdrBytes = fread(fPtr, 1024, 'uint8=>uint8');
        if length(hdrBytes) < 1024
            break;
        end

        magicNum = double(typecast(hdrBytes(1:2), 'int16'));
        Header(beam_No).m_sMagicNumber = magicNum;

        if magicNum ~= DEFAULT_MAGIC_NUMBER
            WarnDlgHandle = warndlg('Wrong File Selected','ST Radar Warning','modal');
            waitfor(WarnDlgHandle);
            fclose(fPtr);
            if exist('handles', 'var') && isfield(handles, 'FilePath')
                set(handles.FilePath, 'String', '');
            end
            return;
        end

        Header(beam_No).m_sNumOfRangeBins            = double(typecast(hdrBytes(3:4), 'int16'));
        Header(beam_No).m_fBaudLength_us             = double(typecast(hdrBytes(5:8), 'single'));
        Header(beam_No).m_sNFFT                      = double(typecast(hdrBytes(9:10), 'int16'));
        Header(beam_No).m_sNumOfCohIntegrations      = double(typecast(hdrBytes(11:12), 'int16'));
        Header(beam_No).m_sNumOfInCohIntegrations    = double(typecast(hdrBytes(13:14), 'int16'));
        Header(beam_No).m_sCodeFlag                  = double(typecast(hdrBytes(15:16), 'int16'));
        Header(beam_No).m_fIntrPulsePeriod_us        = double(typecast(hdrBytes(17:20), 'single'));
        Header(beam_No).m_fPulseWidth_us             = double(typecast(hdrBytes(21:24), 'single'));
        Header(beam_No).m_sNumOfObservWindows        = double(typecast(hdrBytes(25:26), 'int16'));
        Header(beam_No).m_sStationID                 = double(typecast(hdrBytes(27:28), 'int16'));
        Header(beam_No).m_sReserved1                 = double(typecast(hdrBytes(29:30), 'int16'));
        Header(beam_No).m_sReserved2                 = double(typecast(hdrBytes(31:32), 'int16'));
        Header(beam_No).m_sReserved3                 = double(typecast(hdrBytes(33:34), 'int16'));
        Header(beam_No).m_sYear                      = double(typecast(hdrBytes(35:36), 'int16'));
        Header(beam_No).m_sMonth                     = double(typecast(hdrBytes(37:38), 'int16'));
        Header(beam_No).m_sDay                       = double(typecast(hdrBytes(39:40), 'int16'));
        Header(beam_No).m_sHour                      = double(typecast(hdrBytes(41:42), 'int16'));
        Header(beam_No).m_sMin                       = double(typecast(hdrBytes(43:44), 'int16'));
        Header(beam_No).m_sSec                       = double(typecast(hdrBytes(45:46), 'int16'));
        Header(beam_No).m_sReserved4                 = double(typecast(hdrBytes(47:48), 'int16'));
        Header(beam_No).m_fLatitude                  = double(typecast(hdrBytes(49:52), 'single'));
        Header(beam_No).m_fLongitude                 = double(typecast(hdrBytes(53:56), 'single'));
        Header(beam_No).m_fAltitude                  = double(typecast(hdrBytes(57:60), 'single'));
        Header(beam_No).m_fTotalPowerRadiated        = double(typecast(hdrBytes(61:64), 'single'));
        Header(beam_No).m_fRadiatedPower_ClusterWise = double(reshape(typecast(hdrBytes(65:116), 'single'), 13, 1));
        Header(beam_No).m_sOperationMode             = double(typecast(hdrBytes(117:118), 'int16'));
        Header(beam_No).m_sCurrentBeamCnt            = double(typecast(hdrBytes(119:120), 'int16'));
        Header(beam_No).m_sTotalNumberofBeams        = double(typecast(hdrBytes(121:122), 'int16'));
        Header(beam_No).m_usCodeLength               = double(typecast(hdrBytes(123:124), 'int16'));
        Header(beam_No).m_cComment                   = double(reshape(typecast(hdrBytes(125:140), 'int8'), 16, 1));
        Header(beam_No).m_fTRP_RF_Delay_us           = double(typecast(hdrBytes(141:144), 'single'));
        Header(beam_No).m_fMGC_Gain_dB               = double(typecast(hdrBytes(145:148), 'single'));
        Header(beam_No).m_usWindowType               = double(typecast(hdrBytes(149:150), 'int16'));
        Header(beam_No).m_usReserved                 = double(typecast(hdrBytes(151:152), 'int16'));
        Header(beam_No).m_cArrRemarks                = double(reshape(typecast(hdrBytes(153:664), 'int8'), 512, 1));
        Header(beam_No).m_ulCodeA                    = double(reshape(typecast(hdrBytes(665:672), 'uint32'), 2, 1));
        Header(beam_No).m_ulCodeB                    = double(reshape(typecast(hdrBytes(673:680), 'uint32'), 2, 1));
        Header(beam_No).m_ucExperimentDataEnable     = double(typecast(hdrBytes(681), 'int8'));
        Header(beam_No).m_cReserved                  = double(reshape(typecast(hdrBytes(682:684), 'int8'), 3, 1));
        Header(beam_No).m_fAzimuth                   = double(typecast(hdrBytes(685:688), 'single'));
        Header(beam_No).m_fOffZenith                 = double(typecast(hdrBytes(689:692), 'single'));
        Header(beam_No).m_fWindow1StartHeight        = double(typecast(hdrBytes(693:696), 'single'));
        Header(beam_No).m_fWindow1EndHeight          = double(typecast(hdrBytes(697:700), 'single'));
        Header(beam_No).m_fWindow2StartHeight        = double(typecast(hdrBytes(701:704), 'single'));
        Header(beam_No).m_fWindow2EndHeight          = double(typecast(hdrBytes(705:708), 'single'));
        Header(beam_No).m_fWindow3StartHeight        = double(typecast(hdrBytes(709:712), 'single'));
        Header(beam_No).m_fWindow3EndHeight          = double(typecast(hdrBytes(713:716), 'single'));
        Header(beam_No).m_fWindow4StartHeight        = double(typecast(hdrBytes(717:720), 'single'));
        Header(beam_No).m_fWindow4EndHeight          = double(typecast(hdrBytes(721:724), 'single'));
        Header(beam_No).m_fWindow5StartHeight        = double(typecast(hdrBytes(725:728), 'single'));
        Header(beam_No).m_fWindow5EndHeight          = double(typecast(hdrBytes(729:732), 'single'));

        % In DMA Data processing NSA = 0 (non experiment condition)
        if Header(beam_No).m_sNumOfInCohIntegrations <= 0
            Header(beam_No).m_sNumOfInCohIntegrations = 1;
        end

        nRangeBins = Header(beam_No).m_sNumOfRangeBins;
        nNFFT = Header(beam_No).m_sNFFT;
        nInCoh = Header(beam_No).m_sNumOfInCohIntegrations;
        dataBlockSize = nRangeBins * nNFFT;

        Header(beam_No).BeamData = zeros(nRangeBins, nNFFT, nInCoh);

        for InCohIntegration = 1:nInCoh
            if InCohIntegration ~= 1
                [~, headerDataCount] = fread(fPtr, 1024, 'int8');
                if headerDataCount ~= 1024
                    errordlg(sprintf('Error in file Read \nExpected Header Data Count %d \nRead Data Count %d ', 1024, headerDataCount));
                end
            end

            dataSize = ftell(fPtr);
            rawData = fread(fPtr, [2, dataBlockSize], 'int32');
            
            if (ftell(fPtr) - dataSize) ~= (2 * dataBlockSize * 4)
                errordlg(sprintf('Error in file Read \nExpected Data Count %d \nRead Data Count %d ', 2 * dataBlockSize, size(rawData, 2)));
            end

            in_data = complex(rawData(1, :), -rawData(2, :));
            Header(beam_No).BeamData(:, :, InCohIntegration) = reshape(in_data, [nRangeBins, nNFFT]);
        end
    end
    fclose(fPtr);
end
