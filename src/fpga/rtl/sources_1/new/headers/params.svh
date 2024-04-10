package params;

  localparam int NumTransducers = 249;

  localparam int GainSTMSize = 1024;
  localparam int STMWrAddrWidth = $clog2(GainSTMSize * 256);
  localparam int STMRdAddrWidth = $clog2(GainSTMSize * 64);

  localparam bit [7:0] VersionNumMajor = 8'h90;
  localparam bit [7:0] VersionNumMinor = 8'h00;

  localparam bit [1:0] BramSelectController = 2'h0;
  localparam bit [1:0] BramSelectMod = 2'h1;
  localparam bit [1:0] BramSelectDutyTable = 2'h2;
  localparam bit [1:0] BramSelectSTM = 2'h3;

  localparam bit [5:0] BramCntSelMain = 6'h00;
  localparam bit [5:0] BramCntSelFilter = 6'h01;

  localparam bit STMModeFocus = 1'b0;
  localparam bit STMModeGain = 1'b1;

  localparam bit SilencerModeFixedCompletionSteps = 1'b0;
  localparam bit SilencerModeFixedUpdateRate = 1'b1;

  localparam bit [7:0] AddrCtlFlag = 8'h00;
  localparam bit [7:0] AddrFPGAState = 8'h01;
  localparam bit [7:0] AddrECATSyncTime_0 = 8'h11;
  localparam bit [7:0] AddrECATSyncTime_1 = AddrECATSyncTime_0 + 1;
  localparam bit [7:0] AddrECATSyncTime_2 = AddrECATSyncTime_0 + 2;
  localparam bit [7:0] AddrECATSyncTime_3 = AddrECATSyncTime_0 + 3;
  localparam bit [7:0] AddrModMemWrSegment = 8'h20;
  localparam bit [7:0] AddrModReqRdSegment = 8'h21;
  localparam bit [7:0] AddrModCycle0 = 8'h22;
  localparam bit [7:0] AddrModFreqDiv0_0 = 8'h23;
  localparam bit [7:0] AddrModFreqDiv0_1 = 8'h24;
  localparam bit [7:0] AddrModCycle1 = 8'h25;
  localparam bit [7:0] AddrModFreqDiv1_0 = 8'h26;
  localparam bit [7:0] AddrModFreqDiv1_1 = 8'h27;
  localparam bit [7:0] AddrModRep0_0 = 8'h28;
  localparam bit [7:0] AddrModRep0_1 = 8'h29;
  localparam bit [7:0] AddrModRep1_0 = 8'h2A;
  localparam bit [7:0] AddrModRep1_1 = 8'h2B;
  localparam bit [7:0] AddrVersionNumMajor = 8'h30;
  localparam bit [7:0] AddrVersionNumMinor = 8'h31;
  localparam bit [7:0] AddrSilencerMode = 8'h40;
  localparam bit [7:0] AddrSilencerUpdateRateIntensity = 8'h41;
  localparam bit [7:0] AddrSilencerUpdateRatePhase = 8'h42;
  localparam bit [7:0] AddrSilencerCompletionStepsIntensity = 8'h43;
  localparam bit [7:0] AddrSilencerCompletionStepsPhase = 8'h44;
  localparam bit [7:0] AddrSTMMemWrSegment = 8'h50;
  localparam bit [7:0] AddrSTMMemWrPage = 8'h51;
  localparam bit [7:0] AddrSTMReqRdSegment = 8'h52;
  localparam bit [7:0] AddrSTMCycle0 = 8'h54;
  localparam bit [7:0] AddrSTMFreqDiv0_0 = 8'h55;
  localparam bit [7:0] AddrSTMFreqDiv0_1 = 8'h56;
  localparam bit [7:0] AddrSTMCycle1 = 8'h57;
  localparam bit [7:0] AddrSTMFreqDiv1_0 = 8'h58;
  localparam bit [7:0] AddrSTMFreqDiv1_1 = 8'h59;
  localparam bit [7:0] AddrSTMRep0_0 = 8'h5A;
  localparam bit [7:0] AddrSTMRep0_1 = 8'h5B;
  localparam bit [7:0] AddrSTMRep1_0 = 8'h5C;
  localparam bit [7:0] AddrSTMRep1_1 = 8'h5D;
  localparam bit [7:0] AddrSTMMode0 = 8'h5E;
  localparam bit [7:0] AddrSTMMode1 = 8'h5F;
  localparam bit [7:0] AddrSTMSoundSpeed0_0 = 8'h60;
  localparam bit [7:0] AddrSTMSoundSpeed0_1 = 8'h61;
  localparam bit [7:0] AddrSTMSoundSpeed1_0 = 8'h62;
  localparam bit [7:0] AddrSTMSoundSpeed1_1 = 8'h63;
  localparam bit [7:0] AddrPulseWidthEncoderTableWrPage = 8'hE0;
  localparam bit [7:0] AddrPulseWidthEncoderFullWidthStart = 8'hE1;
  localparam bit [7:0] AddrDebugType0 = 8'hF0;
  localparam bit [7:0] AddrDebugValue0 = 8'hF1;
  localparam bit [7:0] AddrDebugType1 = 8'hF2;
  localparam bit [7:0] AddrDebugValue1 = 8'hF3;
  localparam bit [7:0] AddrDebugType2 = 8'hF4;
  localparam bit [7:0] AddrDebugValue2 = 8'hF5;
  localparam bit [7:0] AddrDebugType3 = 8'hF6;
  localparam bit [7:0] AddrDebugValue3 = 8'hF7;

  localparam int CtlFlagModSetBit = 0;
  localparam int CtlFlagSTMSetBit = 1;
  localparam int CtlFlagSilencerSetBit = 2;
  localparam int CtlFlagPulseWidthEncoderSetBit = 3;
  localparam int CtlFlagDebugSetBit = 4;
  localparam int CtlFlagSyncSetBit = 5;
  localparam int CtlFlagForceFanBit = 13;

  typedef enum logic [7:0] {
    DBG_NONE = 8'h00,
    DBG_BASE_SIG = 8'h01,
    DBG_THERMO = 8'h02,
    DBG_FORCE_FAN = 8'h03,
    DBG_SYNC = 8'h10,
    DBG_MOD_SEGMENT = 8'h20,
    DBG_MOD_IDX = 8'h21,
    DBG_STM_SEGMENT = 8'h50,
    DBG_STM_IDX = 8'h51,
    DBG_IS_STM_MODE = 8'h52,
    DBG_PWM_OUT = 8'hE0,
    DBG_DIRECT = 8'hF0
  } debug_type_t;

endpackage
