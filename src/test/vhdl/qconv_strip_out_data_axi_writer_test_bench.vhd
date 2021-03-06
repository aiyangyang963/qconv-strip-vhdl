-----------------------------------------------------------------------------------
--!     @file    qconv_strip_out_data_axi_writer_test_bench.vhd
--!     @brief   Test Bench for Quantized Convolution (strip) In Data AXI Reader Module
--!     @version 0.1.0
--!     @date    2019/4/2
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2018-2019 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_OUT_DATA_AXI_WRITER_TEST_BENCH is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        AXI_ADDR_WIDTH  : integer := 32;
        AXI_DATA_WIDTH  : integer := 64;
        AXI_XFER_SIZE   : integer := 12;
        I_DATA_WIDTH    : integer := 64;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_OUT_DATA_AXI_WRITER_TEST_BENCH;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.UTIL.all;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
use     DUMMY_PLUG.CORE.REPORT_STATUS_VECTOR;
use     DUMMY_PLUG.CORE.MARGE_REPORT_STATUS;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SLAVE_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_MASTER_PLAYER;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_REGISTER_INTERFACE;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
architecture MODEL of QCONV_STRIP_OUT_DATA_AXI_WRITER_TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant  PERIOD            :  time    := 10 ns;
    constant  DELAY             :  time    :=  1 ns;
    constant  SYNC_WIDTH        :  integer :=  2;
    constant  GPO_WIDTH         :  integer :=  8;
    constant  GPI_WIDTH         :  integer :=  GPO_WIDTH;
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    constant  QCONV_PARAM       :  QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal    CLK               :  std_logic;
    signal    RESET             :  std_logic;
    signal    ARESETn           :  std_logic;
    constant  CLEAR             :  std_logic := '0';
    ------------------------------------------------------------------------------
    -- CSR I/F 
    ------------------------------------------------------------------------------
    constant  C_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => 32,
                                     ARADDR      => 32,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => 32,
                                     RDATA       => 32,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    C_ARADDR          :  std_logic_vector(C_WIDTH.ARADDR -1 downto 0);
    signal    C_ARLEN           :  std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal    C_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    C_ARBURST         :  AXI4_ABURST_TYPE;
    signal    C_ARLOCK          :  std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal    C_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    C_ARPROT          :  AXI4_APROT_TYPE;
    signal    C_ARQOS           :  AXI4_AQOS_TYPE;
    signal    C_ARREGION        :  AXI4_AREGION_TYPE;
    signal    C_ARUSER          :  std_logic_vector(C_WIDTH.ARUSER -1 downto 0);
    signal    C_ARID            :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_ARVALID         :  std_logic;
    signal    C_ARREADY         :  std_logic;
    signal    C_RVALID          :  std_logic;
    signal    C_RLAST           :  std_logic;
    signal    C_RDATA           :  std_logic_vector(C_WIDTH.RDATA  -1 downto 0);
    signal    C_RRESP           :  AXI4_RESP_TYPE;
    signal    C_RUSER           :  std_logic_vector(C_WIDTH.RUSER  -1 downto 0);
    signal    C_RID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_RREADY          :  std_logic;
    signal    C_AWADDR          :  std_logic_vector(C_WIDTH.AWADDR -1 downto 0);
    signal    C_AWLEN           :  std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal    C_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    C_AWBURST         :  AXI4_ABURST_TYPE;
    signal    C_AWLOCK          :  std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal    C_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    C_AWPROT          :  AXI4_APROT_TYPE;
    signal    C_AWQOS           :  AXI4_AQOS_TYPE;
    signal    C_AWREGION        :  AXI4_AREGION_TYPE;
    signal    C_AWUSER          :  std_logic_vector(C_WIDTH.AWUSER -1 downto 0);
    signal    C_AWID            :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_AWVALID         :  std_logic;
    signal    C_AWREADY         :  std_logic;
    signal    C_WLAST           :  std_logic;
    signal    C_WDATA           :  std_logic_vector(C_WIDTH.WDATA  -1 downto 0);
    signal    C_WSTRB           :  std_logic_vector(C_WIDTH.WDATA/8-1 downto 0);
    signal    C_WUSER           :  std_logic_vector(C_WIDTH.WUSER  -1 downto 0);
    signal    C_WID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_WVALID          :  std_logic;
    signal    C_WREADY          :  std_logic;
    signal    C_BRESP           :  AXI4_RESP_TYPE;
    signal    C_BUSER           :  std_logic_vector(C_WIDTH.BUSER  -1 downto 0);
    signal    C_BID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_BVALID          :  std_logic;
    signal    C_BREADY          :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  REQ_ADDR_WIDTH    :  integer := 32;
    signal    REQ_ADDR          :  std_logic_vector(REQ_ADDR_WIDTH -1 downto 0);
    signal    REQ_OUT_C         :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    REQ_OUT_W         :  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
    signal    REQ_OUT_H         :  std_logic_vector(QCONV_PARAM.OUT_H_BITS-1 downto 0);
    signal    REQ_C_POS         :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    REQ_C_SIZE        :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    REQ_X_POS         :  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
    signal    REQ_X_SIZE        :  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
    signal    REQ_USE_TH        :  std_logic;
    signal    REQ_VALID         :  std_logic;
    signal    REQ_READY         :  std_logic;
    signal    RES_VALID         :  std_logic;
    signal    RES_ERROR         :  std_logic;
    signal    RES_NONE          :  std_logic;
    signal    RES_READY         :  std_logic;
    signal    IRQ               :  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
    constant  AXI_ID            :  integer := 0;
    constant  AXI_PROT          :  integer := 0;
    constant  AXI_QOS           :  integer := 0;
    constant  AXI_REGION        :  integer := 1;
    constant  AXI_CACHE         :  integer := 15;
    constant  AXI_REQ_QUEUE     :  integer := 2;
    constant  O_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => AXI_ADDR_WIDTH,
                                     ARADDR      => AXI_ADDR_WIDTH,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => AXI_DATA_WIDTH,
                                     RDATA       => AXI_DATA_WIDTH,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    O_AWID            :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_AWADDR          :  std_logic_vector(O_WIDTH.AWADDR -1 downto 0);
    signal    O_AWLEN           :  std_logic_vector(7 downto 0);
    signal    O_AWSIZE          :  std_logic_vector(2 downto 0);
    signal    O_AWBURST         :  std_logic_vector(1 downto 0);
    signal    O_AWLOCK          :  std_logic_vector(0 downto 0);
    signal    O_AWCACHE         :  std_logic_vector(3 downto 0);
    signal    O_AWPROT          :  std_logic_vector(2 downto 0);
    signal    O_AWQOS           :  std_logic_vector(3 downto 0);
    signal    O_AWREGION        :  std_logic_vector(3 downto 0);
    signal    O_AWUSER          :  std_logic_vector(O_WIDTH.AWUSER -1 downto 0);
    signal    O_AWVALID         :  std_logic;
    signal    O_AWREADY         :  std_logic;
    signal    O_WID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_WDATA           :  std_logic_vector(O_WIDTH.WDATA  -1 downto 0);
    signal    O_WSTRB           :  std_logic_vector(O_WIDTH.WDATA/8-1 downto 0);
    signal    O_WUSER           :  std_logic_vector(O_WIDTH.WUSER  -1 downto 0);
    signal    O_WLAST           :  std_logic;
    signal    O_WVALID          :  std_logic;
    signal    O_WREADY          :  std_logic;
    signal    O_BID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_BRESP           :  std_logic_vector(1 downto 0);
    signal    O_BUSER           :  std_logic_vector(O_WIDTH.BUSER  -1 downto 0);
    signal    O_BVALID          :  std_logic;
    signal    O_BREADY          :  std_logic;
    signal    O_ARADDR          :  std_logic_vector(O_WIDTH.ARADDR -1 downto 0);
    signal    O_ARLEN           :  std_logic_vector(O_WIDTH.ALEN   -1 downto 0);
    signal    O_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    O_ARBURST         :  AXI4_ABURST_TYPE;
    signal    O_ARLOCK          :  std_logic_vector(O_WIDTH.ALOCK  -1 downto 0);
    signal    O_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    O_ARPROT          :  AXI4_APROT_TYPE;
    signal    O_ARQOS           :  AXI4_AQOS_TYPE;
    signal    O_ARREGION        :  AXI4_AREGION_TYPE;
    signal    O_ARUSER          :  std_logic_vector(O_WIDTH.ARUSER -1 downto 0);
    signal    O_ARID            :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_ARVALID         :  std_logic;
    signal    O_ARREADY         :  std_logic;
    signal    O_RVALID          :  std_logic;
    signal    O_RLAST           :  std_logic;
    signal    O_RDATA           :  std_logic_vector(O_WIDTH.RDATA  -1 downto 0);
    signal    O_RRESP           :  AXI4_RESP_TYPE;
    signal    O_RUSER           :  std_logic_vector(O_WIDTH.RUSER  -1 downto 0);
    signal    O_RID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_RREADY          :  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  I_WIDTH           :  AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                      ID         => 4,
                                      USER       => 4,
                                      DEST       => 4,
                                      DATA       => I_DATA_WIDTH
                                   );
    signal    I_DATA            :  std_logic_vector(I_WIDTH.DATA   -1 downto 0);
    signal    I_STRB            :  std_logic_vector(I_WIDTH.DATA/8 -1 downto 0);
    signal    I_KEEP            :  std_logic_vector(I_WIDTH.DATA/8 -1 downto 0);
    signal    I_DEST            :  std_logic_vector(I_WIDTH.DEST   -1 downto 0);
    signal    I_USER            :  std_logic_vector(I_WIDTH.USER   -1 downto 0);
    signal    I_ID              :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_LAST            :  std_logic;
    signal    I_VALID           :  std_logic;
    signal    I_READY           :  std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal    SYNC              :  SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal    C_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    C_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    I_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    I_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    O_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    O_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal    N_REPORT          :  REPORT_STATUS_TYPE;
    signal    C_REPORT          :  REPORT_STATUS_TYPE;
    signal    I_REPORT          :  REPORT_STATUS_TYPE;
    signal    O_REPORT          :  REPORT_STATUS_TYPE;
    signal    N_FINISH          :  std_logic;
    signal    C_FINISH          :  std_logic;
    signal    I_FINISH          :  std_logic;
    signal    O_FINISH          :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: entity QCONV.QCONV_STRIP_OUT_DATA_AXI_WRITER -- 
        generic map (                                -- 
            QCONV_PARAM         => QCONV_PARAM     , --
            AXI_ADDR_WIDTH      => O_WIDTH.AWADDR  , -- 
            AXI_DATA_WIDTH      => O_WIDTH.WDATA   , -- 
            AXI_ID_WIDTH        => O_WIDTH.ID      , -- 
            AXI_USER_WIDTH      => O_WIDTH.AWUSER  , -- 
            AXI_XFER_SIZE       => AXI_XFER_SIZE   , --   
            AXI_ID              => AXI_ID          , --   
            AXI_PROT            => AXI_PROT        , --   
            AXI_QOS             => AXI_QOS         , --   
            AXI_REGION          => AXI_REGION      , --   
            AXI_CACHE           => AXI_CACHE       , --   
            AXI_REQ_QUEUE       => AXI_REQ_QUEUE   , --
            I_DATA_WIDTH        => I_DATA_WIDTH    , --
            REQ_ADDR_WIDTH      => REQ_ADDR_WIDTH    --   
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock / Reset Signals.
        ---------------------------------------------------------------------------
            CLK                 => CLK             , -- In  :
            RST                 => RESET           , -- In  :
            CLR                 => CLEAR           , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            AXI_AWID            => O_AWID          , -- Out :
            AXI_AWADDR          => O_AWADDR        , -- Out :
            AXI_AWLEN           => O_AWLEN         , -- Out :
            AXI_AWSIZE          => O_AWSIZE        , -- Out :
            AXI_AWBURST         => O_AWBURST       , -- Out :
            AXI_AWLOCK          => O_AWLOCK        , -- Out :
            AXI_AWCACHE         => O_AWCACHE       , -- Out :
            AXI_AWPROT          => O_AWPROT        , -- Out :
            AXI_AWQOS           => O_AWQOS         , -- Out :
            AXI_AWREGION        => O_AWREGION      , -- Out :
            AXI_AWUSER          => O_AWUSER        , -- Out :
            AXI_AWVALID         => O_AWVALID       , -- Out :
            AXI_AWREADY         => O_AWREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            AXI_WID             => O_WID           , -- Out :
            AXI_WDATA           => O_WDATA         , -- Out :
            AXI_WSTRB           => O_WSTRB         , -- Out :
            AXI_WLAST           => O_WLAST         , -- Out :
            AXI_WVALID          => O_WVALID        , -- Out :
            AXI_WREADY          => O_WREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            AXI_BID             => O_BID           , -- In  :
            AXI_BRESP           => O_BRESP         , -- In  :
            AXI_BVALID          => O_BVALID        , -- In  :
            AXI_BREADY          => O_BREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Stream Slave Interface.
        ---------------------------------------------------------------------------
            I_DATA              => I_DATA          , -- In  :
            I_STRB              => I_STRB          , -- In  :
            I_LAST              => I_LAST          , -- In  :
            I_VALID             => I_VALID         , -- In  :
            I_READY             => I_READY         , -- Out :
        -------------------------------------------------------------------------------
        -- Request / Response Interface.
        -------------------------------------------------------------------------------
            REQ_VALID           => REQ_VALID       , -- In  :
            REQ_ADDR            => REQ_ADDR        , -- In  :
            REQ_OUT_C           => REQ_OUT_C       , -- In  :
            REQ_OUT_W           => REQ_OUT_W       , -- In  :
            REQ_OUT_H           => REQ_OUT_H       , -- In  :
            REQ_C_POS           => REQ_C_POS       , -- In  :
            REQ_C_SIZE          => REQ_C_SIZE      , -- In  :
            REQ_X_POS           => REQ_X_POS       , -- In  :
            REQ_X_SIZE          => REQ_X_SIZE      , -- In  :
            REQ_USE_TH          => REQ_USE_TH      , -- In  :
            REQ_READY           => REQ_READY       , -- Out :
            RES_VALID           => RES_VALID       , -- Out :
            RES_NONE            => RES_NONE        , -- Out :
            RES_ERROR           => RES_ERROR       , -- Out :
            RES_READY           => RES_READY         -- In  :
    );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL                                       -- 
        generic map(                                 -- 
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "MARCHAL"       , -- 
            SYNC_PLUG_NUM       => 1               , -- 
            SYNC_WIDTH          => SYNC_WIDTH      , --
            FINISH_ABORT        => FALSE             -- 
        )                                            -- 
        port map(                                    -- 
            CLK                 => CLK             , -- In  :
            RESET               => RESET           , -- In  :
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
            REPORT_STATUS       => N_REPORT        , -- Out :
            FINISH              => N_FINISH          -- Out :
        );                                           -- 
    ------------------------------------------------------------------------------
    -- AXI4_MASTER_PLAYER
    ------------------------------------------------------------------------------
    C: AXI4_MASTER_PLAYER                            -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "CSR"           , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => TRUE            , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => C_WIDTH         , -- 
            SYNC_PLUG_NUM       => 2               , -- 
            SYNC_WIDTH          => SYNC_WIDTH      , -- 
            GPI_WIDTH           => GPI_WIDTH       , -- 
            GPO_WIDTH           => GPO_WIDTH       , -- 
            FINISH_ABORT        => FALSE             -- 
        )                                            -- 
        port map(                                    -- 
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR              => C_ARADDR        , -- I/O : 
            ARLEN               => C_ARLEN         , -- I/O : 
            ARSIZE              => C_ARSIZE        , -- I/O : 
            ARBURST             => C_ARBURST       , -- I/O : 
            ARLOCK              => C_ARLOCK        , -- I/O : 
            ARCACHE             => C_ARCACHE       , -- I/O : 
            ARPROT              => C_ARPROT        , -- I/O : 
            ARQOS               => C_ARQOS         , -- I/O : 
            ARREGION            => C_ARREGION      , -- I/O : 
            ARUSER              => C_ARUSER        , -- I/O : 
            ARID                => C_ARID          , -- I/O : 
            ARVALID             => C_ARVALID       , -- I/O : 
            ARREADY             => C_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => C_RLAST         , -- In  :    
            RDATA               => C_RDATA         , -- In  :    
            RRESP               => C_RRESP         , -- In  :    
            RUSER               => C_RUSER         , -- In  :    
            RID                 => C_RID           , -- In  :    
            RVALID              => C_RVALID        , -- In  :    
            RREADY              => C_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR              => C_AWADDR        , -- I/O : 
            AWLEN               => C_AWLEN         , -- I/O : 
            AWSIZE              => C_AWSIZE        , -- I/O : 
            AWBURST             => C_AWBURST       , -- I/O : 
            AWLOCK              => C_AWLOCK        , -- I/O : 
            AWCACHE             => C_AWCACHE       , -- I/O : 
            AWPROT              => C_AWPROT        , -- I/O : 
            AWQOS               => C_AWQOS         , -- I/O : 
            AWREGION            => C_AWREGION      , -- I/O : 
            AWUSER              => C_AWUSER        , -- I/O : 
            AWID                => C_AWID          , -- I/O : 
            AWVALID             => C_AWVALID       , -- I/O : 
            AWREADY             => C_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST               => C_WLAST         , -- I/O : 
            WDATA               => C_WDATA         , -- I/O : 
            WSTRB               => C_WSTRB         , -- I/O : 
            WUSER               => C_WUSER         , -- I/O : 
            WID                 => C_WID           , -- I/O : 
            WVALID              => C_WVALID        , -- I/O : 
            WREADY              => C_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => C_BRESP         , -- In  :    
            BUSER               => C_BUSER         , -- In  :    
            BID                 => C_BID           , -- In  :    
            BVALID              => C_BVALID        , -- In  :    
            BREADY              => C_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => C_GPI           , -- In  :
            GPO                 => C_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => C_REPORT        , -- Out :
            FINISH              => C_FINISH          -- Out :
        );                                           -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    REGS: block
        constant  REGS_ADDR_WIDTH       :  integer := 7;
        constant  REGS_DATA_WIDTH       :  integer := 32;
        signal    regs_req              :  std_logic;
        signal    regs_write            :  std_logic;
        signal    regs_ack              :  std_logic;
        signal    regs_err              :  std_logic;
        signal    regs_addr             :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
        signal    regs_ben              :  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
        signal    regs_wdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        signal    regs_rdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        signal    t_addr                :  std_logic_vector(REQ_ADDR_WIDTH       -1 downto 0);
        signal    i_c                   :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        signal    i_w                   :  std_logic_vector(QCONV_PARAM.IN_W_BITS-1 downto 0);
        signal    i_h                   :  std_logic_vector(QCONV_PARAM.IN_H_BITS-1 downto 0);
    begin 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        AXI4: AXI4_REGISTER_INTERFACE                --
            generic map (                            -- 
                AXI4_ADDR_WIDTH => C_WIDTH.ARADDR  , --
                AXI4_DATA_WIDTH => C_WIDTH.RDATA   , --
                AXI4_ID_WIDTH   => C_WIDTH.ID      , --
                REGS_ADDR_WIDTH => REGS_ADDR_WIDTH , --
                REGS_DATA_WIDTH => REGS_DATA_WIDTH   --
            )                                        -- 
            port map (                               -- 
            -----------------------------------------------------------------------
            -- Clock and Reset Signals.
            -----------------------------------------------------------------------
                CLK             => CLK             , -- In  :
                RST             => RESET           , -- In  :
                CLR             => CLEAR           , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Read Address Channel Signals.
            -----------------------------------------------------------------------
                ARID            => C_ARID          , -- In  :
                ARADDR          => C_ARADDR        , -- In  :
                ARLEN           => C_ARLEN         , -- In  :
                ARSIZE          => C_ARSIZE        , -- In  :
                ARBURST         => C_ARBURST       , -- In  :
                ARVALID         => C_ARVALID       , -- In  :
                ARREADY         => C_ARREADY       , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Read Data Channel Signals.
            -----------------------------------------------------------------------
                RID             => C_RID           , -- Out :
                RDATA           => C_RDATA         , -- Out :
                RRESP           => C_RRESP         , -- Out :
                RLAST           => C_RLAST         , -- Out :
                RVALID          => C_RVALID        , -- Out :
                RREADY          => C_RREADY        , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Write Address Channel Signals.
            -----------------------------------------------------------------------
                AWID            => C_AWID          , -- In  :
                AWADDR          => C_AWADDR        , -- In  :
                AWLEN           => C_AWLEN         , -- In  :
                AWSIZE          => C_AWSIZE        , -- In  :
                AWBURST         => C_AWBURST       , -- In  :
                AWVALID         => C_AWVALID       , -- In  :
                AWREADY         => C_AWREADY       , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Data Channel Signals.
            -----------------------------------------------------------------------
                WDATA           => C_WDATA         , -- In  :
                WSTRB           => C_WSTRB         , -- In  :
                WLAST           => C_WLAST         , -- In  :
                WVALID          => C_WVALID        , -- In  :
                WREADY          => C_WREADY        , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Response Channel Signals.
            -----------------------------------------------------------------------
                BID             => C_BID           , -- Out :
                BRESP           => C_BRESP         , -- Out :
                BVALID          => C_BVALID        , -- Out :
                BREADY          => C_BREADY        , -- In  :
            -----------------------------------------------------------------------
            -- Register Interface.
            -----------------------------------------------------------------------
                REGS_REQ        => regs_req        , -- Out :
                REGS_WRITE      => regs_write      , -- Out :
                REGS_ACK        => regs_ack        , -- In  :
                REGS_ERR        => regs_err        , -- In  :
                REGS_ADDR       => regs_addr       , -- Out :
                REGS_BEN        => regs_ben        , -- Out :
                REGS_WDATA      => regs_wdata      , -- Out :
                REGS_RDATA      => regs_rdata        -- In  :
            );                                       -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        REGS: entity QCONV.QCONV_STRIP_REGISTERS     -- 
            generic map (                            -- 
                QCONV_PARAM     => QCONV_PARAM     , --
                DATA_ADDR_WIDTH => REQ_ADDR_WIDTH  , -- 
                REGS_ADDR_WIDTH => REGS_ADDR_WIDTH , --
                REGS_DATA_WIDTH => REGS_DATA_WIDTH   --
            )                                        -- 
            port map (                               -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK             , -- In  :
                RST             => RESET           , -- In  :
                CLR             => CLEAR           , -- In  :
            -----------------------------------------------------------------------
            -- Register Access Interface
            -----------------------------------------------------------------------
                REGS_REQ        => regs_req        , -- In  :
                REGS_WRITE      => regs_write      , -- In  :
                REGS_ADDR       => regs_addr       , -- In  :
                REGS_BEN        => regs_ben        , -- In  :
                REGS_WDATA      => regs_wdata      , -- In  :
                REGS_RDATA      => regs_rdata      , -- Out :
                REGS_ACK        => regs_ack        , -- Out :
                REGS_ERR        => regs_err        , -- Out :
            -----------------------------------------------------------------------
            -- Quantized Convolution (strip) Registers
            -----------------------------------------------------------------------
                I_DATA_ADDR     => open            , -- Out :
                O_DATA_ADDR     => REQ_ADDR        , -- Out :
                K_DATA_ADDR     => open            , -- Out :
                T_DATA_ADDR     => t_addr          , -- Out :
                I_WIDTH         => i_w             , -- Out :
                I_HEIGHT        => i_h             , -- Out :
                I_CHANNELS      => i_c             , -- Out :
                O_WIDTH         => REQ_OUT_W       , -- Out :
                O_HEIGHT        => REQ_OUT_H       , -- Out :
                O_CHANNELS      => REQ_OUT_C       , -- Out :
                K_WIDTH         => open            , -- Out :
                K_HEIGHT        => open            , -- Out :
                PAD_SIZE        => open            , -- Out :
                USE_TH          => REQ_USE_TH      , -- Out :
            -----------------------------------------------------------------------
            -- Quantized Convolution (strip) Request/Response Interface
            -----------------------------------------------------------------------
                REQ_VALID       => REQ_VALID       , -- Out :
                REQ_READY       => REQ_READY       , -- In  :
                RES_VALID       => RES_VALID       , -- In  :
                RES_READY       => RES_READY       , -- Out :
                RES_STATUS      => RES_ERROR       , -- In  :
                REQ_RESET       => open            , -- Out :
                REQ_STOP        => open            , -- Out :
                REQ_PAUSE       => open            , -- Out :
            -----------------------------------------------------------------------
            -- Interrupt Request 
            -----------------------------------------------------------------------
                IRQ             => IRQ               -- Out :
            );
        REQ_X_POS  <= std_logic_vector(resize(unsigned(t_addr), QCONV_PARAM.OUT_W_BITS));
        REQ_X_SIZE <= std_logic_vector(resize(unsigned(i_w   ), QCONV_PARAM.OUT_W_BITS));
        REQ_C_POS  <= std_logic_vector(resize(unsigned(i_h   ), QCONV_PARAM.OUT_C_BITS));
        REQ_C_SIZE <= std_logic_vector(resize(unsigned(i_c   ), QCONV_PARAM.OUT_C_BITS));
    end block;                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "O"             , -- 
            READ_ENABLE         => FALSE           , -- 
            WRITE_ENABLE        => TRUE            , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => O_WIDTH         , -- 
            SYNC_PLUG_NUM       => 3               , -- 
            SYNC_WIDTH          => SYNC_WIDTH      , -- 
            GPI_WIDTH           => GPI_WIDTH       , -- 
            GPO_WIDTH           => GPO_WIDTH       , -- 
            FINISH_ABORT        => FALSE             -- 
        )                                            -- 
        port map(                                    -- 
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR              => O_ARADDR        , -- In  :    
            ARLEN               => O_ARLEN         , -- In  :    
            ARSIZE              => O_ARSIZE        , -- In  :    
            ARBURST             => O_ARBURST       , -- In  :    
            ARLOCK              => O_ARLOCK        , -- In  :    
            ARCACHE             => O_ARCACHE       , -- In  :    
            ARPROT              => O_ARPROT        , -- In  :    
            ARQOS               => O_ARQOS         , -- In  :    
            ARREGION            => O_ARREGION      , -- In  :    
            ARUSER              => O_ARUSER        , -- In  :    
            ARID                => O_ARID          , -- In  :    
            ARVALID             => O_ARVALID       , -- In  :    
            ARREADY             => O_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => O_RLAST         , -- I/O : 
            RDATA               => O_RDATA         , -- I/O : 
            RRESP               => O_RRESP         , -- I/O : 
            RUSER               => O_RUSER         , -- I/O : 
            RID                 => O_RID           , -- I/O : 
            RVALID              => O_RVALID        , -- I/O : 
            RREADY              => O_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR              => O_AWADDR        , -- In  :    
            AWLEN               => O_AWLEN         , -- In  :    
            AWSIZE              => O_AWSIZE        , -- In  :    
            AWBURST             => O_AWBURST       , -- In  :    
            AWLOCK              => O_AWLOCK        , -- In  :    
            AWCACHE             => O_AWCACHE       , -- In  :    
            AWPROT              => O_AWPROT        , -- In  :    
            AWQOS               => O_AWQOS         , -- In  :    
            AWREGION            => O_AWREGION      , -- In  :    
            AWUSER              => O_AWUSER        , -- In  :    
            AWID                => O_AWID          , -- In  :    
            AWVALID             => O_AWVALID       , -- In  :    
            AWREADY             => O_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST               => O_WLAST         , -- In  :    
            WDATA               => O_WDATA         , -- In  :    
            WSTRB               => O_WSTRB         , -- In  :    
            WUSER               => O_WUSER         , -- In  :    
            WID                 => O_WID           , -- In  :    
            WVALID              => O_WVALID        , -- In  :    
            WREADY              => O_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => O_BRESP         , -- I/O : 
            BUSER               => O_BUSER         , -- I/O : 
            BID                 => O_BID           , -- I/O : 
            BVALID              => O_BVALID        , -- I/O : 
            BREADY              => O_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => O_GPI           , -- In  :
            GPO                 => O_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => O_REPORT        , -- Out :
            FINISH              => O_FINISH          -- Out :
       );                                            -- 
    O_ARADDR   <= (others => '0');
    O_ARLEN    <= (others => '0');
    O_ARSIZE   <= (others => '0');
    O_ARBURST  <= (others => '0');
    O_ARLOCK   <= (others => '0');
    O_ARCACHE  <= (others => '0');
    O_ARPROT   <= (others => '0');
    O_ARQOS    <= (others => '0');
    O_ARREGION <= (others => '0');
    O_ARUSER   <= (others => '0');
    O_ARID     <= (others => '0');
    O_ARVALID  <= '0';
    O_RREADY   <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I: AXI4_STREAM_MASTER_PLAYER                 -- 
        generic map (                            -- 
            SCENARIO_FILE   => SCENARIO_FILE   , --
            NAME            => "I"             , --
            OUTPUT_DELAY    => DELAY           , --
            SYNC_PLUG_NUM   => 4               , --
            WIDTH           => I_WIDTH         , --
            SYNC_WIDTH      => SYNC_WIDTH      , --
            GPI_WIDTH       => GPI_WIDTH       , --
            GPO_WIDTH       => GPO_WIDTH       , --
            FINISH_ABORT    => FALSE             --
        )                                        -- 
        port map(                                -- 
            ACLK            => CLK             , -- In  :
            ARESETn         => ARESETn         , -- In  :
            TDATA           => I_DATA          , -- Out :
            TSTRB           => I_STRB          , -- Out :
            TKEEP           => I_KEEP          , -- Out :
            TUSER           => I_USER          , -- Out :
            TDEST           => I_DEST          , -- Out :
            TID             => I_ID            , -- Out :
            TLAST           => I_LAST          , -- Out :
            TVALID          => I_VALID         , -- Out :
            TREADY          => I_READY         , -- In  :
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
            GPI             => I_GPI           , -- In  :
            GPO             => I_GPO           , -- Out :
            REPORT_STATUS   => I_REPORT        , -- Out :
            FINISH          => I_FINISH          -- Out :
        );                                       --
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        loop
            CLK <= '0'; wait for PERIOD / 2;
            CLK <= '1'; wait for PERIOD / 2;
            exit when(N_FINISH = '1');
        end loop;
        CLK <= '0';
        wait;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    C_GPI(0)  <= IRQ;
    C_GPI(C_GPI'high downto 1) <= (C_GPI'high downto 1 => '0');
    I_GPI     <= (others => '0');
    O_GPI     <= (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ARESETn  <= '1' when (RESET = '0') else '0';

    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (C_FINISH'event and C_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ CSR ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,C_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,C_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,C_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ IN ]");                                        WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,I_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,I_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,I_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ OUT ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,O_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,O_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,O_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert (C_REPORT.error_count    = 0 and
                I_REPORT.error_count    = 0 and
                O_REPORT.error_count    = 0)
            report "Simulation complete(error)."    severity FAILURE;
        assert (C_REPORT.mismatch_count = 0 and
                I_REPORT.mismatch_count = 0 and
                O_REPORT.mismatch_count = 0)
            report "Simulation complete(mismatch)." severity FAILURE;
        if (FINISH_ABORT) then
            assert FALSE report "Simulation complete(success)."  severity FAILURE;
        else
            assert FALSE report "Simulation complete(success)."  severity NOTE;
        end if;
        wait;
    end process;
end MODEL;
