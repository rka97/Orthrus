library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;


entity RAWHazardComponent is
    generic (
    N : natural := 16;
    M : natural := 16;
    L_BITS : natural := 3;
    buffer_unit : natural := 32
    );

    port (

    --MY PIPE NUMBER
    i_am_pipe : in std_logic;   -- 0 for pipe 1,
                                -- 1 for pipe 2

    -- my pipe
    ex_r_code : in std_logic_vector(L_BITS-1 downto 0);
    --other pipe
    ex_rt_code_otherpipe: in std_logic_vector(L_BITS-1 downto 0);
    ex_WBreg_otherpipe: in std_logic;
    ex_out_otherpipe: in std_logic_vector(N-1 downto 0);


    ---- IN from memory buffer.
    -- mypipe.
    mem_WBreg_mypipe  : in std_logic;
    mem_rt_code_mypipe:  in std_logic_vector(L_BITS-1 downto 0);
    mem_op_r_mypipe   : in std_logic;
    mem_AR_mypipe     : in std_logic_vector(N-1 downto 0);

   -- other pipe
    mem_WBreg_otherpipe  : in std_logic; 
    mem_rt_code_otherpipe:  in std_logic_vector(L_BITS-1 downto 0); 
    mem_op_r_otherpipe   : in std_logic; 
    mem_AR_otherpipe     : in std_logic_vector(N-1 downto 0);

    ----- IN from writeback buffer.
    wb_mdata    : in std_logic_vector(buffer_unit-1 downto 0);
    -- my pipe
    wb_WBreg_mypipe   : in std_logic;
    wb_rt_code_mypipe :in std_logic_vector(L_BITS-1 downto 0);
    wb_AR_mypipe      : in std_logic_vector(N-1 downto 0);
    wb_mem_op_mypipe  :in std_logic;

    -- Other pipe
    wb_WBreg_otherpipe   : in std_logic;
    wb_rt_code_otherpipe :in std_logic_vector(L_BITS-1 downto 0);
    wb_AR_otherpipe      : in std_logic_vector(N-1 downto 0);
    wb_mem_op_otherpipe  : in std_logic;

    ---- OUT to buffers.
    stall_DandE     : out std_logic;
    input_mem_cw_z: out std_logic;

    ---- OUT to ex unit 
    load_forwarded : out std_logic;
    ex_r: out std_logic_vector(N-1 downto 0)
    );
end RAWHazardComponent;

architecture Behavioral of RAWHazardComponent is 
begin

    process( mem_WBreg_otherpipe,mem_op_r_otherpipe,mem_rt_code_otherpipe,
    ex_r_code,mem_WBreg_mypipe,mem_op_r_mypipe,
    mem_rt_code_mypipe,wb_WBreg_otherpipe,wb_rt_code_otherpipe,wb_rt_code_mypipe,wb_mem_op_mypipe
    ,wb_mem_op_otherpipe,ex_WBreg_otherpipe,ex_rt_code_otherpipe,ex_out_otherpipe,i_am_pipe,mem_AR_otherpipe,
    mem_AR_mypipe,wb_AR_otherpipe,
    wb_AR_mypipe, wb_mdata,wb_WBreg_mypipe)
    begin
        if i_am_pipe = '1' then
            if ex_r_code = ex_rt_code_otherpipe and ex_WBreg_otherpipe = '1' then    
                ex_r <= ex_out_otherpipe;
                load_forwarded <= '1';
                input_mem_cw_z <= '0';
                stall_DandE <= '0';
            elsif ex_r_code = mem_rt_code_mypipe and mem_WBreg_mypipe = '1' then
                if mem_op_r_mypipe = '1' then
                    input_mem_cw_z <= '1';
                    load_forwarded <= '0';
                    stall_DandE <= '1';
                else
                    ex_r <= mem_AR_mypipe(N-1 downto 0);
                    load_forwarded <= '1';
                    input_mem_cw_z <= '0';
                    stall_DandE <= '0';
                end if;
            elsif ex_r_code = mem_rt_code_otherpipe and mem_WBreg_otherpipe = '1' then
                if mem_op_r_otherpipe = '1' then
                    input_mem_cw_z <= '1';
                    load_forwarded <= '0';
                    stall_DandE <= '1';
                else
                    ex_r <= mem_AR_otherpipe(N-1 downto 0);
                    load_forwarded <= '1';
                    input_mem_cw_z <= '0';
                    stall_DandE <= '0';
                end if;
            elsif ex_r_code = wb_rt_code_mypipe and wb_WBreg_mypipe = '1' then
                load_forwarded <= '1';
                --not stalling
                input_mem_cw_z<='0';
                stall_DandE<='0';
                if wb_mem_op_mypipe = '1' then
                    ex_r <= wb_mdata(N-1 downto 0);
                else
                    ex_r <= wb_AR_mypipe(N-1 downto 0);
                end if;
            elsif ex_r_code = wb_rt_code_otherpipe and wb_WBreg_otherpipe = '1' then
                load_forwarded <= '1';
                --not stalling
                input_mem_cw_z<='0';
                stall_DandE<='0';
                if wb_mem_op_otherpipe = '1' then
                    ex_r <= wb_mdata(N-1 downto 0);
                else
                    ex_r <= wb_AR_otherpipe(N-1 downto 0);
                end if;
            else
                ex_r <= (others => '0');
                load_forwarded <= '0';
                input_mem_cw_z<='0';
                stall_DandE<='0';
            end if;
        else 
            if ex_r_code = mem_rt_code_otherpipe and mem_WBreg_otherpipe = '1' then
                if mem_op_r_otherpipe = '1' then
                    input_mem_cw_z <= '1';
                    load_forwarded <= '0';
                    stall_DandE <= '1';
                else
                    ex_r <= mem_AR_otherpipe(N-1 downto 0);
                    load_forwarded <= '1';
                    input_mem_cw_z <= '0';
                    stall_DandE <= '0';
                end if;
            elsif ex_r_code = mem_rt_code_mypipe and mem_WBreg_mypipe = '1' then
                if mem_op_r_mypipe = '1' then
                    input_mem_cw_z <= '1';
                    load_forwarded <= '0';
                    stall_DandE <= '1';
                else
                    ex_r <= mem_AR_mypipe(N-1 downto 0);
                    load_forwarded <= '1';
                    input_mem_cw_z <= '0';
                    stall_DandE <= '0';
                end if;
            elsif ex_r_code = wb_rt_code_otherpipe and wb_WBreg_otherpipe = '1' then
                load_forwarded <= '1';
                --not stalling
                input_mem_cw_z<='0';
                stall_DandE<='0';
                if wb_mem_op_otherpipe = '1' then
                    ex_r <= wb_mdata(N-1 downto 0);
                else
                    ex_r <= wb_AR_otherpipe(N-1 downto 0);
                end if;
            elsif ex_r_code = wb_rt_code_mypipe and wb_WBreg_mypipe = '1' then
                load_forwarded <= '1';
                --not stalling
                input_mem_cw_z<='0';
                stall_DandE<='0';
                if wb_mem_op_mypipe = '1' then
                    ex_r <= wb_mdata(N-1 downto 0);
                else
                    ex_r <= wb_AR_mypipe(N-1 downto 0);
                end if;
            else
                ex_r <= (others => '0');
                load_forwarded <= '0';
                input_mem_cw_z<='0';
                stall_DandE<='0';
            end if;
        end if;

        -- if ex_r_code = ex_rt_code_otherpipe and ex_WBreg_otherpipe='1' and i_am_pipe='1' then 
        --     ex_r <= ex_out_otherpipe;
        --     load_forwarded <= '1';
        --     --no stalling
        --     input_mem_cw_z<='0';
        --     stall_DandE<='0'; 
        -- --If there exists a dependency between execution stage and mem + mem operation 
        -- elsif ex_r_code=mem_rt_code_otherpipe  and mem_WBreg_otherpipe='1' and mem_op_r_otherpipe='1' then 
        --     input_mem_cw_z<='1';                            --input zeroes                                             
        --     load_forwarded <= '0';                          --no data forwarded yet
        --     stall_DandE<='1';                                   --stall!
        -- --if there exists a dependency between ex and mem 
        -- elsif ex_r_code=mem_rt_code_otherpipe and mem_WBreg_otherpipe = '1'   then
        --     ex_r <= mem_AR_otherpipe(N-1 downto 0);
        --     load_forwarded <= '1';   
        --     --no stalling                                                   
        --     input_mem_cw_z<='0';
        --     stall_DandE<='0';
        -- --Same as above but my pipe
        -- elsif ex_r_code=mem_rt_code_mypipe and mem_WBreg_mypipe = '1' and mem_op_r_mypipe='1' then 
        --     input_mem_cw_z<='1';
        --     load_forwarded <= '0';
        --     stall_DandE<='1';
        -- elsif ex_r_code=mem_rt_code_mypipe and mem_WBreg_mypipe ='1' then
        --     ex_r <= mem_AR_mypipe(N-1 downto 0);
        --     load_forwarded <= '1';
        --     --no stalling
        --     input_mem_cw_z<='0';
        --     stall_DandE<='0';
        -- --if there exists a depenedency between ex and wb 
        -- elsif ex_r_code=wb_rt_code_otherpipe and wb_WBreg_otherpipe = '1'then
        --     -- if it was a memory operation restult, read from Mdata
        --     if wb_mem_op_otherpipe = '1' then
        --         ex_r <= wb_mdata(N-1 downto 0);
        --     else --read from Alu res reg
        --         ex_r <= wb_AR_otherpipe(N-1 downto 0); 
        --     end if;
        --     load_forwarded <= '1';
        --     --not stalling
        --     input_mem_cw_z<='0';
        --     stall_DandE<='0';
        -- --Same but for mypipe
        -- elsif ex_r_code=wb_rt_code_mypipe and wb_WBreg_mypipe = '1'then
        --         if wb_mem_op_mypipe = '1' then
        --             ex_r <= wb_mdata(N-1 downto 0);
        --         else --read from Alu res reg
        --             ex_r <= wb_AR_mypipe(N-1 downto 0); 
        --         end if;
        --         load_forwarded <= '1';
        --         --not stalling
        --         input_mem_cw_z<='0';
        --         stall_DandE<='0';
        -- else
        --     load_forwarded <= '0';
        --     input_mem_cw_z<='0';
        --     stall_DandE<='0';
        -- end if; 
    end process; 

    end Behavioral;