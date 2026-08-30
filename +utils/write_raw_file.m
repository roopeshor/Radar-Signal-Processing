function write_raw_file(Header, filepath)
% write_raw_file  Write a RadarData array into a binary ST-Radar .raw file.
%
%   write_raw_file(Header, filepath)
%
%   Input:
%     Header   - RadarData array (1 × beam_count).
%     filepath - string. Path to the .raw binary radar data file.
%
%   See also read_raw_file, RadarData

arguments
    Header RadarData
    filepath (1,1) string
end

fPtr = fopen(filepath, 'wb');
if fPtr == -1
    error('Cannot open file for writing: %s', filepath);
end

beam_count = length(Header);

for beam_No = 1:beam_count
    nInCoh = Header(beam_No).m_sNumOfInCohIntegrations;
    if nInCoh <= 0
        nInCoh = 1;
    end

    for InCohIntegration = 1:nInCoh
        % Create 1024-byte zero-initialized array for the header
        hdrBytes = zeros(1, 1024, 'uint8');

        % Populate header fields by reversing read_raw_file typecasts
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sMagicNumber, 'int16', 1, 2);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sNumOfRangeBins, 'int16', 3, 4);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fBaudLength_us, 'single', 5, 8);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sNFFT, 'int16', 9, 10);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sNumOfCohIntegrations, 'int16', 11, 12);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sNumOfInCohIntegrations, 'int16', 13, 14);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sCodeFlag, 'int16', 15, 16);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fIntrPulsePeriod_us, 'single', 17, 20);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fPulseWidth_us, 'single', 21, 24);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sNumOfObservWindows, 'int16', 25, 26);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sStationID, 'int16', 27, 28);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sReserved1, 'int16', 29, 30);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sReserved2, 'int16', 31, 32);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sReserved3, 'int16', 33, 34);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sYear, 'int16', 35, 36);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sMonth, 'int16', 37, 38);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sDay, 'int16', 39, 40);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sHour, 'int16', 41, 42);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sMin, 'int16', 43, 44);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sSec, 'int16', 45, 46);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sReserved4, 'int16', 47, 48);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fLatitude, 'single', 49, 52);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fLongitude, 'single', 53, 56);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fAltitude, 'single', 57, 60);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fTotalPowerRadiated, 'single', 61, 64);

        pow_cluster = Header(beam_No).m_fRadiatedPower_ClusterWise;
        if isempty(pow_cluster), pow_cluster = zeros(13,1); end
        hdrBytes = assign_bytes(hdrBytes, pow_cluster, 'single', 65, 116);

        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_sOperationMode, 'int16', 117, 118);
        hdrBytes = assign_bytes(hdrBytes, beam_No, 'int16', 119, 120); % m_sCurrentBeamCnt
        hdrBytes = assign_bytes(hdrBytes, beam_count, 'int16', 121, 122); % m_sTotalNumberofBeams
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_usCodeLength, 'int16', 123, 124);

        cmt = Header(beam_No).m_cComment;
        if isempty(cmt), cmt = char(zeros(16,1)); end
        if length(cmt) < 16, cmt(end+1:16) = 0; else, cmt = cmt(1:16); end
        hdrBytes = assign_bytes(hdrBytes, cmt, 'int8', 125, 140);

        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fTRP_RF_Delay_us, 'single', 141, 144);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fMGC_Gain_dB, 'single', 145, 148);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_usWindowType, 'int16', 149, 150);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_usReserved, 'int16', 151, 152);

        rem = Header(beam_No).m_cArrRemarks;
        if isempty(rem), rem = char(zeros(512,1)); end
        if length(rem) < 512, rem(end+1:512) = 0; else, rem = rem(1:512); end
        hdrBytes = assign_bytes(hdrBytes, rem, 'int8', 153, 664);

        coda = Header(beam_No).m_ulCodeA;
        if isempty(coda), coda = zeros(2,1); end
        hdrBytes = assign_bytes(hdrBytes, coda, 'uint32', 665, 672);

        codb = Header(beam_No).m_ulCodeB;
        if isempty(codb), codb = zeros(2,1); end
        hdrBytes = assign_bytes(hdrBytes, codb, 'uint32', 673, 680);

        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_ucExperimentDataEnable, 'int8', 681, 681);

        cres = Header(beam_No).m_cReserved;
        if isempty(cres), cres = zeros(3,1); end
        hdrBytes = assign_bytes(hdrBytes, cres, 'int8', 682, 684);

        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fAzimuth, 'single', 685, 688);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fOffZenith, 'single', 689, 692);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow1StartHeight, 'single', 693, 696);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow1EndHeight, 'single', 697, 700);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow2StartHeight, 'single', 701, 704);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow2EndHeight, 'single', 705, 708);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow3StartHeight, 'single', 709, 712);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow3EndHeight, 'single', 713, 716);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow4StartHeight, 'single', 717, 720);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow4EndHeight, 'single', 721, 724);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow5StartHeight, 'single', 725, 728);
        hdrBytes = assign_bytes(hdrBytes, Header(beam_No).m_fWindow5EndHeight, 'single', 729, 732);

        % Write the 1024 byte header
        fwrite(fPtr, hdrBytes, 'uint8');

        % Now write the IQ data
        nRangeBins = Header(beam_No).m_sNumOfRangeBins;
        nNFFT = Header(beam_No).m_sNFFT;

        % BeamData is (RangeBins x NFFT x InCohIntegrations)
        % For the current incoherent integration, get the block:
        if ~isempty(Header(beam_No).BeamData)
            block = Header(beam_No).BeamData(:, :, InCohIntegration);

            % Flatten block correctly. read_raw_file uses:
            % rawData = fread(fPtr, [2, dataBlockSize], 'int32');
            % in_data = complex(rawData(1, :), rawData(2, :));
            % reshape(in_data, [nRangeBins, nNFFT]);

            % So data was written as [real; imag] for each element of the flattened block.
            flat_block = block(:).'; % 1 x (nRangeBins * nNFFT)
            out_data = zeros(2, length(flat_block));
            out_data(1, :) = real(flat_block);
            out_data(2, :) = imag(flat_block);

            fwrite(fPtr, out_data, 'int32');
        else
            % If no BeamData, just write zeros
            fwrite(fPtr, zeros(2, nRangeBins * nNFFT), 'int32');
        end
    end
end
fclose(fPtr);
end

function bytes = assign_bytes(bytes, data, type, start_idx, end_idx)
    raw_bytes = typecast(cast(data, type), 'uint8');
    bytes(start_idx:end_idx) = raw_bytes;
end
