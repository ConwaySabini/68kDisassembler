*-----------------------------------------------------------
* Title      :  DASM
* Written by :  Team BSR (Fatima Farah, Ethan Sabini, Zhijun Huang, and Deepali Juneja
* Date       :  5/3/2021
* Description:  Final Project for CSS 422. This is a disassembler. It translates machine language
                ; into assembly language. The inverse operation to that of an assembler. 
*-----------------------------------------------------------

    ORG    $1000    
 
;beginning of DASM program    
dasm_main:
    
        JMP     begin_io    *begin io operations

;beginning of IO
begin_io:

        LEA     prompt, A1      ;loads the prompt message and displays it to the user.
        MOVE.B  #14, D0     
        TRAP    #15
        BRA     get_start
  
;gets the starting address     
get_start: 
        ;Displays the starting
        LEA     start_addr, A1         
        MOVE.B  #13, D0
        TRAP    #15
        
        ;Stores the user input for the first address into the variable start_hex
        LEA     start_hex, A1            
        MOVE.B  #2, D0               
        TRAP    #15
        
        CMPI.B  #8,D1
        BNE     errorLength

        JSR     toStart_Hex
        JSR     checkStartAddrEven  

        MOVE.L  D5, A3
        BRA     get_end
 
;gets the ending address       
get_end:
        LEA     end_addr, A1
        MOVE.B  #13, D0
        TRAP    #15
        
        LEA     end_hex, A1            
        MOVE.B  #2, D0               
        TRAP    #15
        
        CMPI.B  #8,D1
        BNE     errorLength
        
        JSR     toStart_Hex
        
        JSR     checkStartAddr 
        JSR     checkEndAddrEven  
        
        MOVE.L  D5, A4
        JMP     ioDone

errorLength:
        LEA     ErrorMsg1, A1
        MOVE.B  #13, D0
        TRAP    #15
        BRA     dasm_main

;changes the the starting address input from ASCII to hex
toStart_Hex:
        MOVE.L      D1, D3                  
        MOVEA.L     A1,A2                   
        CLR.L       D5

;loops through the start_hex digit by digit and checks whether it's a number, hex uppercase, or 
;an invalid input
hex_loop:  
        CLR         D4                      
        SUBI.L      #1, D3                   
        MOVE.B      (A2)+, D4                 
        CMP.B       #$2F, D4
        BLE         inputError              
        CMP.B       #$39, D4                 
        BLE         hex_number           
        CMP.B       #$40, D4
        BLE         inputError
        CMP.B       #$46, D4
        BLE         hex_uppercase  
        CMP.B       #$47, D4
        BGE         inputError     

;if a digit is a number, it changs it to it's hex equivalent    
hex_number:
    SUBI.B          #$30, D4                   
    JMP             hex_formatting                

;if a digit is an uppercase from A-F, it prepares for it's change
hex_uppercase:
    SUBI.B          #$37, D4                     
    JMP             hex_formatting                   
  
 
;chnages the ascii digit by first adding value to D5 that changes it to hex.  
hex_formatting:
    ADD.B           D4, D5                       
    CMP.B           #0, D3      ;checks if we're done by comparing to the digit count in D3                     
    BEQ             hex_done                   
    ASL.L           #4, D5      ;shifts D5 to prepare for next digit to be processed                     
    JMP             hex_loop                   
 
;converting the address to hex is done, now save the address from D5 to A1   
hex_done:  
    MOVE.L  D5, (A1)                                                       
    RTS                                         
 
;displays the invalid input error and starts IO over again   
inputError:
    MOVE.B  #14, D0
    LEA     invalidChar, A1
    TRAP    #15
    JMP     begin_io

;checks that the start address in less then the ending address    
checkStartAddr:
        CLR.L    D2
        CLR.L    D3
        MOVE.L   start_hex, D2
        MOVE.L   end_hex, D3
        CMP.L    D3, D2        *compare starting and end addresses for error
        BGT      smallEndError *branch when start is greater than end
        RTS

*displays error that end address is less than start
smallEndError:
        LEA     startError, A1
        MOVE.B  #13, D0               
        TRAP    #15
        JMP     get_start
        
        
;checks that the start address is even. If not, displays error and asks again for address
checkStartAddrEven:
        ROR.L   #1,D2
        BCS     inputStartOddError
        ROL.L   #1,D2 
        ROR.L   #1,D3
        BCS     inputStartOddError
        ROL.L   #1,D3 
        RTS
        
        
*displays message that user has entered odd address
inputStartOddError:
        LEA     StartOddError, A1
        MOVE.B  #13, D0               
        TRAP    #15
        JMP     get_start
        

;checks that the end address is even. If not, displays error and asks again for address
checkEndAddrEven:
        ROR.L   #1,D2
        BCS     inputEndOddError
        ROL.L   #1,D2 
        ROR.L   #1,D3
        BCS     inputEndOddError
        ROL.L   #1,D3 
        RTS
        
*displays message that user has entered odd address
inputEndOddError:
        LEA     EndOddError, A1
        MOVE.B  #13, D0               
        TRAP    #15
        JMP     get_end




;finishes off IO and branches to the Opcodes section    
ioDone:
    ADD.L       #$02, A4
    *clear registers
    BRA         first


*---------------------------------END-IO------------------------------*


*---------------------------------Opcodes Start------------------------------*

* initialize variables
first:
    MOVE.L   #0, numLines
    MOVE.L   #$02, counter 
    BRA      start

* start of every opcode to decide when done
start:
    CMP.L    A3, A4          *compare start A3 and end A4
    BLE      done
    CMP.L    A3,A4 
    BNE      start_opcodes
   
*iterate to the next word to decode
iterate:
    ADD.L   counter, A3
    ADD.L   #1, numLines
    BRA     start
    
start_opcodes:                   *starting routine for opcodes
    LEA     string, A5   *single line of message
    MOVE.L  #$2, counter *counter for address
    MOVE.W  #0, numBytes *counter for bytes
    MOVE.L  #0, hexCounter
    MOVE.L  #0, D2
    
    *clear all registers 
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D5
    CLR.L   (A0)
    CLR.L   (A1)
    CLR.L   (A2)
    CLR.L   (A5)
    CLR.L   (A6)
    MOVE.L  A3, D3
    MOVE.B  #'$', (A5)+
    ADD.W   #1, numBytes *counter for bytes to output
    JSR     printHex
    JSR     tab

opcodes:
    *determine opcode

    MOVE.W  (A3),D5 * move word to dissassemble D5
    MOVE.W  D5, D6  * D6 copy of word
    
    *--------------------Compare and branch for opcodes------------------------*

    MOVE.L  D5, D6
    CMP.W   #%0100111001110001, D6
    BEQ     nop_op
    
    MOVE.L  D5, D6
    CMP.W   #%0100111001110101, D6
    BEQ     rts_op

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6
    CMP.W   #%0000001000000000, D6
    BEQ     i_op                 *immediate

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6
    CMP.W   #%0000011000000000, D6
    BEQ     i_op                 *immediate

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6
    CMP.W   #%0000010000000000, D6
    BEQ     i_op                 *immediate
    
    MOVE.L  D5, D6
    AND.W   #%1111101110000000, D6
    CMP.W   #%0100100010000000, D6
    BEQ     movem_op

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6
    CMP.W   #%0100011000000000, D6
    BEQ     not_op

    MOVE.L  D5, D6
    AND.W   #%1111000111000000, D6
    CMP.W   #%0100000111000000, D6
    BEQ     lea_op

    MOVE.L  D5, D6
    AND.W   #%1111111111000000, D6  
    CMP.W   #%1110001111000000, D6 *lsl memory shift
    BEQ     lsl_mem

    MOVE.L  D5, D6
    AND.W   #%1111111111000000, D6  
    CMP.W   #%1110001011000000, D6 *lsr memory shift
    BEQ     lsr_mem

    MOVE.L  D5, D6
    AND.W   #%1111000100011000, D6 
    CMP.W   #%1110000100001000, D6 *lsl register shift
    BEQ     lsl_reg

    MOVE.L  D5, D6
    AND.W   #%1111000100011000, D6 
    CMP.W   #%1110000000001000, D6 *lsr register shift
    BEQ     lsr_reg
    
    MOVE.L  D5, D6
    AND.W   #%1111111111000000, D6  
    CMP.W   #%1110000111000000, D6 *lsl memory shift
    BEQ     asl_mem

    MOVE.L  D5, D6
    AND.W   #%1111111111000000, D6  
    CMP.W   #%1110000011000000, D6 *lsl memory shift
    BEQ     asr_mem

    MOVE.L  D5, D6
    AND.W   #%1111000100011000, D6 
    CMP.W   #%1110000100000000, D6 *lsl register shift
    BEQ     asl_reg

    MOVE.L  D5, D6
    AND.W   #%1111000100011000, D6 
    CMP.W   #%1110000000000000, D6 *lsr register shift
    BEQ     asr_reg

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6 
    CMP.W   #%0110000000000000, D6 *bra
    BEQ     bra_op

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6 
    CMP.W   #%0110110100000000, D6 *blt
    BEQ     blt_op

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6 
    CMP.W   #%0110011100000000, D6 *beq
    BEQ     beq_op

    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6 
    CMP.W   #%0110110000000000, D6 *bge
    BEQ     bge_op
    
    MOVE.L  D5, D6
    AND.W   #%1111111111000000, D6 
    CMP.W   #%0100111010000000, D6 *jsr
    BEQ     jsr_op

    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%1101000000000000, D6
    BEQ     add_op
    
    MOVE.L  D5, D6
    AND.W   #%1111111100000000, D6
    CMP.W   #%0000011000000000, D6
    BEQ     add_op

    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%1001000000000000, D6
    BEQ     sub_op
    
    MOVE.L  D5, D6
    AND.W   #%1111000111000000, D6
    CMP.W   #%1100000111000000, D6
    BEQ     muls_op

    MOVE.L  D5, D6
    AND.W   #%1111000111000000, D6
    CMP.W   #%1000000011000000, D6
    BEQ     divu_op

    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%1100000000000000, D6
    BEQ     and_op

    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%0001000000000000, D6
    BEQ     move_op
    
    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%0011000000000000, D6
    BEQ     move_op
    
    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%0010000000000000, D6
    BEQ     move_op

    MOVE.L  D5, D6
    AND.W   #%1111000000000000, D6
    CMP.W   #%0111000000000000, D6
    BEQ     movei_op
   
    BRA     print_data
    

*---------------------------------- Opcodes, A5 used for output -------------------------

*immediate opcodes
i_op:
    MOVE.W  D5, D6
    LSR.L   #6, D6 *save mode
    MOVE.W  D5, D4 *save size
    LSR.L   #3, D4
    AND.B   #%00000111, D4
    CMP.B   #%00000111, D4
    BEQ     word_count

    AND.B   #%00000011, D6
    CMP.B   #%00000000, D6
    BEQ     i_word
    CMP.B   #%00000001, D6
    BEQ     i_word
    CMP.B   #%00000010, D6
    BEQ     i_long

*immediate word
i_word:
    MOVE.W  D5, D4
    LSR.L   #3, D4
    AND.B   #%00000111, D4
    CMP.B   #%00000111, D4
    BEQ     i_three_words

    *print spacing
    JSR     tab
    JSR     tab
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'d', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    ADD.W   #7, numBytes

    *print data
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    JSR     print_data_immediate
    SUB.W   #$02, A3
    BRA     print_output

*print data longword
i_long:
    *append output
    JSR     tab
    JSR     tab
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'d', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    ADD.W   #7, numBytes

    *print data
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+

    JSR     print_data_immediate
    JSR     print_data_immediate
    SUB.W   #$02, A3       *fix counter
    BRA     print_output

*get word count
word_count:
    MOVE.W  D5, D4
    AND.B   #%00000111, D4
    CMP.B   #%00000000, D4
    BEQ     i_word
    CMP.B   #%00000001, D4
    BEQ     i_four_words

*immediate 3 words
i_three_words:
    MOVE.W  D5, D4
    AND.B   #%11111111, D4
    CMP.B   #%10111000, D4
    BEQ     i_four_words
    *append output
    JSR     tab
    JSR     tab

    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'d', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    ADD.W   #8, numBytes

    *print data
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    JSR     print_data_immediate
    SUB.W   #$02, A3            *fix counter
    BRA     print_output

*immediate 4 words
i_four_words:
    *append output
    JSR     tab
    JSR     tab

    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'d', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    ADD.W   #10, numBytes

    *print data
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    JSR     print_data_immediate
    MOVE.B  #' ', (A5)+
    MOVE.B  #'$', (A5)+
    JSR     print_data_immediate
    SUB.W   #$02, A3
    BRA     print_output


*bra
bra_op:
    *append output
    MOVE.B  #'B', (A5)+
    MOVE.B  #'R', (A5)+
    MOVE.B  #'A', (A5)+
    ADD.W   #3, numBytes
    *get size
    MOVE.L  D5, D6
    AND.B   #%11111111, D6
    CMP.B   #%00000000, D6
    BEQ     bra_word
    BNE     bra_byte

*bge
bge_op:
    *append output
    MOVE.B  #'B', (A5)+
    MOVE.B  #'G', (A5)+
    MOVE.B  #'E', (A5)+
    ADD.W   #3, numBytes
    *get size
    MOVE.L  D5, D6
    AND.B   #%11111111, D6
    CMP.B   #%00000000, D6
    BEQ     bra_word
    BNE     bra_byte

*blt
blt_op:
    *append output
    MOVE.B  #'B', (A5)+
    MOVE.B  #'L', (A5)+
    MOVE.B  #'T', (A5)+
    ADD.W   #3, numBytes
    *get size
    MOVE.L  D5, D6
    AND.B   #%11111111, D6
    CMP.B   #%00000000, D6
    BEQ     bra_word
    BNE     bra_byte

*beq
beq_op:
    *append output
    MOVE.B  #'B', (A5)+
    MOVE.B  #'E', (A5)+
    MOVE.B  #'Q', (A5)+
    ADD.W   #3, numBytes
    *get size
    MOVE.L  D5, D6
    AND.B   #%11111111, D6
    CMP.B   #%00000000, D6
    BEQ     bra_word
    BNE     bra_byte

*bra.s
bra_byte:
    CLR.L   D6
    ADD.B   D5, D6         *D6 holds displacement
    *append output
    MOVE.B  #'.', (A5)+
    MOVE.B  #'S', (A5)+
    MOVE.B  #' ', (A5)+
    JSR     tab
    ADD.W   #3, numBytes

    MOVE.L  #0, addr_size  *prepare ea
    MOVE.W  A3, D4         *get address
    ADD.B   #$02, D4       *increment counter

    BTST.L  #$07, D6       *check if backwards jump
    BNE     bra_byte_negative

    ADD.W   D6, D4          *add displacement
    MOVE.W  D4, D3          *prepare addressing
    MOVE.W  #8, D1          *prepare addressing
    MOVE.B  #'$', (A5)+
    ADD.W   #9, numBytes

    JSR     print_address_long  *print location
    BRA     print_output

*backwards branch
bra_byte_negative:
    *flip sign and subtract
    NOT.B     D6
    ADD.B   #1, D6
    SUB.B   D6, D4

    MOVE.W  D4, D3         *prepare addressing
    MOVE.W  #8, D1          *prepare addressing
    MOVE.B  #'$', (A5)+
    ADD.W   #9, numBytes

    JSR     print_address_long   *print location
    BRA     print_output

*bra w
bra_word:
    CLR.L   D6
    MOVE.W  (A3)+, D5
    MOVE.W  (A3), D5
    ADD.W   D5, D6        *D6 holds displacement
    *append output
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    JSR     tab

    ADD.W   #3, numBytes
    MOVE.L  #0, addr_size
    MOVE.W  A3, D4         *get address

    BTST.L  #$0F, D6        *check if backwards jump
    BNE     bra_word_negative

    ADD.W   D6, D4          *add displacement
    MOVE.W  D4, D3          *prepare addressing
    MOVE.W  #8, D1          *prepare addressing  
    MOVE.B  #'$', (A5)+
    ADD.W   #9, numBytes

    JSR     print_address_long *print location
    BRA     print_output

*backwards branch
bra_word_negative:
    *flip sign and subtract
    NOT.W   D6        
    ADD.W   #1, D6
    SUB.W   D6, D4

    MOVE.W  D4, D3      *prepare addressing  
    MOVE.W  #8, D1      *prepare addressing  
    MOVE.B  #'$', (A5)+
    ADD.W   #9, numBytes

    JSR     print_address_long *print location
    BRA     print_output


*lea
lea_op:
    *append output
    MOVE.B  #'L', (A5)+
    MOVE.B  #'E', (A5)+
    MOVE.B  #'A', (A5)+
    JSR     tab
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #8, numBytes

    *output address
    JSR     address_main
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    *output address register
    JSR     output_an
    bra     print_output

*register shift
asr_reg:
    *append output
    MOVE.B   #'A', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #3, numBytes
    JSR      shiftRight    *direction
    JSR      shift_size    *size
    MOVE.B   #' ', (A5)+

    JSR      regMode       *register shift
    JSR      output_ead  *output data register
    BRA      print_output

*register shift
asl_reg:
    *append output
    MOVE.B   #'A', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #3, numBytes
    JSR      shiftLeft
    JSR      shift_size    *size
    MOVE.B   #' ', (A5)+

    JSR      regMode       *register shift
    JSR      output_ead  *output data register
    BRA      print_output

*memory shift
asr_mem:
    *append output
    MOVE.B   #'A', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #4, numBytes
    JSR      shiftRight
    MOVE.B   #'W', (A5)+
    MOVE.B   #' ', (A5)+

    MOVE.B   #1, addr_size *addressing mode
    JSR      tab
    JSR      address_main  *output memory address
    BRA      print_output

*memory shift
asl_mem:
    *append output
    MOVE.B   #'A', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #4, numBytes
    JSR      shiftLeft
    MOVE.B   #'W', (A5)+
    MOVE.B   #' ', (A5)+

    MOVE.B   #1, addr_size *addressing mode
    JSR      tab
    JSR      address_main  *output memory address
    BRA      print_output

*register shift
lsl_reg:
    *append output
    MOVE.B   #'L', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #3, numBytes
    JSR      shiftLeft
    JSR      shift_size       *get size
    MOVE.B   #' ', (A5)+ 

    JSR      regMode          *register shift
    JSR      output_ead *output data register
    BRA      print_output

*memory shift
lsl_mem:
    *append output
    MOVE.B   #'L', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #4, numBytes
    JSR      shiftLeft
    MOVE.B   #'W', (A5)+
    MOVE.B   #' ', (A5)+

    MOVE.B   #1, addr_size *addressing mode
    JSR      tab
    JSR      address_main  *ea mode
    BRA      print_output

*register shift
lsr_reg:
    *append output
    MOVE.B   #'L', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #3, numBytes
    JSR      shiftRight
    JSR      shift_size
    MOVE.B   #' ', (A5)+

    JSR      regMode          *register shift
    JSR      output_ead *output data register
    BRA      print_output

*memory shift
lsr_mem:
    *append output
    MOVE.B   #'L', (A5)+
    MOVE.B   #'S', (A5)+

    ADD.W    #4, numBytes
    JSR      shiftRight
    MOVE.B   #'W', (A5)+
    MOVE.B   #' ', (A5)+

    MOVE.B   #1, addr_size *addressing mode
    JSR      tab
    JSR      address_main  *print memory address
    BRA      print_output

shiftRight:
    MOVE.B  #'R', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W    #2, numBytes
    RTS

shiftLeft:
    MOVE.B  #'L', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W    #2, numBytes
    RTS

*determine how much to shift register
regMode:
    MOVE.W  D5, D6
    AND.B   #%00100000, D6
    CMP.B   #%00100000, D6
    BEQ     shiftReg       *shift amount in data register
    BNE     shiftImmediate *shift immediate amount 

*determine how much to shift register
shiftImmediate:
    MOVE.W  D5, D6
    LSR.W   #8, D6
    LSR.W   #1, D6
    AND.B   #%00000111, D6
    CMP.B   #%00000000, D6
    BEQ     shiftDefault
    BNE     shiftAmount

*shift by default 8
shiftDefault:
    MOVE.W  #8, D6

*convert the hex to ascii
shiftAmount:
    ADD.B   #$30, D6
    ADD.W   #4, numBytes
    *append output
    MOVE.B  #'#', (A5)+
    MOVE.B  D6, (A5)+
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    RTS

*print data register
shiftReg:
    JSR     output_dn     *output data register
    MOVE.B  #',', (A5)+
    ADD.W   #1, numBytes
    RTS

shift_size:
    *get size
    MOVE.W  D5, D6
    *get bits
    LSR.L   #6, D6
    AND.B   #%00000011,D6
    *compare
    CMP.B   #%00000000,D6
    BEQ     byte_op
    CMP.B   #%00000010,D6
    BEQ     long_op
    CMP.B   #%00000001,D6
    BEQ     word_op
    BRA     print_data

*nop
nop_op:
    *append output
    MOVE.B  #'N', (A5)+
    MOVE.B  #'O', (A5)+
    MOVE.B  #'P', (A5)+
    ADD.W   #3, numBytes
   
    JMP      print_output

*rts
rts_op:
    *append output
    MOVE.B  #'R', (A5)+
    MOVE.B  #'T', (A5)+
    MOVE.B  #'S', (A5)+
    ADD.W   #3, numBytes
    
    JMP     print_output

*move compact form
movei_op:
    *append output
    MOVE.B  #'M', (A5)+
    MOVE.B  #'O', (A5)+
    MOVE.B  #'V', (A5)+
    MOVE.B  #'E', (A5)+
    MOVE.B  #'.', (A5)+
    MOVE.B  #'L', (A5)+
    ADD.W   #12, numBytes
    JSR     tab
    MOVE.B  #'#', (A5)+
    MOVE.B  #'$', (A5)+

    *print immediate data
    MOVE.W  D5, D6
    LSR.W   #4, D6
    AND.W   #%0000000000001111, D6
    JSR     print_number
    MOVE.B  D6, (A5)+

    *print immediate data
    MOVE.B  D5, D6
    AND.B   #%00001111, D6
    JSR     print_number
    MOVE.B  D6, (A5)+

    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+  

    *print data register  
    JSR     output_dn  
    BRA     print_output

*move
move_op:
    *append output
    MOVE.B  #'M', (A5)+
    MOVE.B  #'O', (A5)+
    MOVE.B  #'V', (A5)+
    MOVE.B  #'E', (A5)+
    MOVE.W  D5, D6
    ROR.W   #6, D6
    BRA     move_data

move_data:
    ADD.W   #5, numBytes
    MOVE.B  #'.', (A5)+
    BRA     move_size

move_size:
    *get word to decode
    MOVE.W  D5, D6
    *get bits for size
    ROL.W   #4, D6
    AND.B   #%00001111,D6
    *compare and branch
    CMP.B   #%00000001,D6
    BEQ     move_byte
    CMP.B   #%00000010,D6
    BEQ     move_long
    CMP.B   #%00000011,D6
    BEQ     move_word
    BRA     print_data

*byte helper
move_byte:
    MOVE.B  #'B', (A5)+
    MOVE.B  #0, addr_size  
    ADD.W   #1, numBytes
    JSR     tab
    BRA     output_ea_op *do addressing and print source

*word helper
move_word:
    MOVE.B  #'W', (A5)+
    MOVE.B  #1, addr_size
    ADD.W   #1, numBytes
    JSR     tab
    BRA     output_ea_op *do addressing and print source

*long helper
move_long:
    MOVE.B  #'L', (A5)+
    MOVE.B  #2, addr_size
    ADD.W   #1, numBytes
    JSR     tab
    BRA     output_ea_op *do addressing and print source



*add 
add_op:
    *append output
    MOVE.B  #'A', (A5)+
    MOVE.B  #'D', (A5)+
    MOVE.B  #'D', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W   #4, numBytes

    *get size
    JSR     getBits8_10
    MOVE.L  D7, D6
    AND.B   #%011,D6
    *compare and branch
    CMP.B   #%000,D6
    BEQ     add_byte
    MOVE.L  D7, D6
    AND.B   #%011,D6
    CMP.B   #%001,D6
    JSR     add_word
    MOVE.L  D7, D6
    AND.B   #%011,D6
    CMP.B   #%010,D6
    JSR     add_long

add_byte:
    JSR     byte_op
    MOVE.L  #0, addr_size
    JSR     add_sub_and_done *addressing

add_word:
    JSR     word_op
    MOVE.L  #1, addr_size
    JSR     add_sub_and_done *addressing

add_long:
    JSR     long_op
    MOVE.L  #2, addr_size
    JSR     add_sub_and_done *addressing

*determine addressing
add_sub_and_done:
    MOVE.B  #' ', (A5)+
    ADD.W   #1, numBytes
    MOVE.L  D5, D7
    *get mode
    AND.W   #%0000000111000000, D7
    LSR.W   #6, D7
    AND.B   #%100,D7        *get opmode
    CMP.B   #%100,D7
    BEQ     add_ea_last  *Dn + <ea> _> <ea>
    BNE     add_ea_first *<ea> + Dn _> Dn

add_ea_first:
    JSR     address_main *ea first
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes
    JSR     output_dn   *print data register
    JMP     print_output
    
add_ea_last:
    JSR     output_dn   *print data register
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes
    JSR     address_main *ea last
    JMP     print_output

*sub
sub_op:
    *append output
    MOVE.B  #'S', (A5)+
    MOVE.B  #'U', (A5)+
    MOVE.B  #'B', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W   #4, numBytes
    MOVE.L  D5, D6
    *get size
    JSR     getBits8_10
    MOVE.L  D7, D6
    AND.B   #%011,D6
    CMP.B   #%000,D6
    BEQ     add_byte
    MOVE.L  D7, D6
    AND.B   #%011,D6
    CMP.B   #%001,D6
    JSR     add_word
    MOVE.L  D7, D6
    AND.B   #%011,D6
    CMP.B   #%010,D6
    JSR     add_long

    *determine addressing
    MOVE.L  D5, D6
    ROL.W   #8, D6
    AND.B   #%00000001, D6
    CMP.B   #%00000000, D6
    BEQ     add_ea_first  *<ea> + Dn _> Dn
    BNE     add_ea_last   *Dn + <ea> _> <ea>

*muls
muls_op:
    *append output
    MOVE.B  #'M', (A5)+
    MOVE.B  #'U', (A5)+
    MOVE.B  #'L', (A5)+
    MOVE.B  #'S', (A5)+
    MOVE.B  #'.', (A5)+
    MOVE.B  #'W', (A5)+
    JSR     tab

    ADD.W   #8, numBytes
    JSR     getBits11_13
    CMP.B   #1, D7
    *handle longword case
    BEQ     muls_i_long
    MOVE.B  #1, addr_size

    *do addressing
    JSR     address_main
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    *print data register
    JSR     output_dn
    JMP     print_output

*handle longword cases
muls_i_long:
    MOVE.B  #2, addr_size
    *do addressing
    JSR     address_main
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    *print data register
    JSR     output_dn
    JMP     print_output

divu_op:
    *append output
    MOVE.B  #'D', (A5)+
    MOVE.B  #'I', (A5)+
    MOVE.B  #'V', (A5)+
    MOVE.B  #'U', (A5)+
    MOVE.B  #'.', (A5)+
    MOVE.B  #'W', (A5)+
    ADD.W   #8, numBytes

    JSR     getBits11_13
    CMP.B   #1, D7
    BEQ     muls_i_long
    MOVE.B  #1, addr_size
    
    *do addressing
    JSR     tab
    JSR     address_main
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    *print data register
    JSR     output_dn
    JMP     print_output

and_op:
    *append output
    MOVE.B  #'A', (A5)+
    MOVE.B  #'N', (A5)+
    MOVE.B  #'D', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W   #5, numBytes
    MOVE.L  D5, D6
    *get size
    AND.W   #%0000000011000000, D6
    CMP.W   #%0000000000000000, D6
    BEQ     and_byte
    AND.W   #%0000000111000000, D6
    CMP.W   #%0000000001000000, D6
    BEQ     and_word
    AND.W   #%0000000111000000, D6
    CMP.W   #%0000000010000000, D6
    BEQ     and_long
    BRA     print_data

and_byte:
    JSR     byte_op
    MOVE.B  #' ', (A5)+
    MOVE.B  #0, addr_size
    *get bits
    JSR     getBits8_10
    AND.B   #%00000100, D7
    CMP.B   #%00000100, D7
    BEQ     add_ea_last   *Dn + <ea> _> <ea>
    BNE     add_ea_first  *<ea> + Dn _> Dn
    
and_word:
    JSR     word_op
    MOVE.B  #' ', (A5)+
    MOVE.B  #1, addr_size
    JSR     getBits8_10
    AND.B   #%00000100, D7
    CMP.B   #%00000100, D7
    BEQ     add_ea_last   *Dn + <ea> _> <ea>
    BNE     add_ea_first  *<ea> + Dn _> Dn

and_long:
    JSR     long_op
    MOVE.B  #' ', (A5)+
    MOVE.B  #2, addr_size
    JSR     getBits8_10
    AND.B   #%00000100, D7
    CMP.B   #%00000100, D7
    BEQ     add_ea_last   *Dn + <ea> _> <ea>
    BNE     add_ea_first  *<ea> + Dn _> Dn

*not
not_op:
    *append output
    MOVE.B  #'N', (A5)+
    MOVE.B  #'O', (A5)+
    MOVE.B  #'T', (A5)+
    MOVE.B  #'.', (A5)+
    ADD.W   #5, numBytes
    MOVE.L  D5, D6
    *get size
    AND.W   #%0000000011000000, D6
    CMP.W   #%0000000000000000, D6
    BEQ     not_byte
    AND.W   #%0000000011000000, D6
    CMP.W   #%0000000001000000, D6
    BEQ     not_word
    AND.W   #%0000000011000000, D6
    CMP.W   #%0010000010000000, D6
    BEQ     not_long
    

not_byte:
    JSR     byte_op
    MOVE.B  #' ', (A5)+
    JSR     address_main *addressing
    JMP     print_output

not_word:
    JSR     word_op
    MOVE.B  #' ', (A5)+
    JSR     address_main *addressing
    JMP     print_output

not_long:
    JSR     long_op
    MOVE.B  #' ', (A5)+
    JSR     address_main *addressing
    JMP     print_output

*jsr
jsr_op:
    *append output
    MOVE.B  #'J', (A5)+
    MOVE.B  #'S', (A5)+
    MOVE.B  #'R', (A5)+
    ADD.W   #6, numBytes
    JSR     tab
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    JSR     address_main *do addressing and RTS when done
    JMP     print_output

*movem
movem_op:
    *append output
    MOVE.B  #'M', (A5)+
    MOVE.B  #'O', (A5)+
    MOVE.B  #'V', (A5)+
    MOVE.B  #'E', (A5)+
    MOVE.B  #'M', (A5)+
    MOVE.B  #'.', (A5)+

    ADD.W   #7, numBytes
    MOVE.L  D5, D6
    *compare and branch
    AND.B   #%01000000, D6
    CMP.B   #%01000000, D6
    BEQ     movem_word

    CMP.B   #%00000000, D6
    BEQ     movem_long

    JSR     movem_done
    JMP     print_output

movem_word:
    MOVE.B  #'W', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #3, numBytes
    BRA     movem_done

movem_long:
    MOVE.B  #'L', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #3, numBytes
    BRA     movem_done

movem_done:
    MOVE.W  D5, D7
    LSR.L     #8, D7
    LSR.L     #2, D7
    AND.B   #%00000001, D7
    CMP.B   #%00000000, D7
    BEQ     addr_list_to_mem  *MOVEM < list > , < ea > 
    BNE     addr_mem_to_list *MOVEM < ea > , < list > 

addr_list_to_mem:
    *increment to word mask
    MOVE.W  (A3)+, D1
    MOVE.W  (A3), D2
    *determine if pre or post
    JSR     getBits11_13
    CMP.B   #4, D7
    BEQ     addr_list_to_mem_pre *if predecrement mode 
    *else
    JSR     reg_list_post

    JSR     address_main *addressing
    BRA     print_output

addr_list_to_mem_pre:
    JSR     reg_list_pre *reg list
    JSR     address_main *addressing
    BRA     print_output

addr_mem_to_list:
    *determine if absolute address
    MOVE.W  D5, D6
    AND.B   #%00111000, D6
    CMP.B   #%00111000, D6
    BEQ     addr_mem_absolute

    JSR     address_main *addressing
    *increment address to mask
    MOVE.W  (A3)+, D2
    MOVE.W  (A3), D2

    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes

    *determine if pre or post
    JSR     getBits11_13
    CMP.B   #4, D7
    BEQ     addr_mem_to_list_pre
    *else
    JSR     reg_list_post

    BRA     print_output

addr_mem_to_list_pre:
    JSR     reg_list_pre *reg list
    BRA     print_output

addr_mem_absolute:
    *check if absolute word or long
    MOVE.W  D5, D6
    AND.B   #%00000001, D6
    CMP.B   #%00000001, D6
    BEQ     addr_mem_absolute_long

    *increment address to address
    MOVE.W  (A3)+, D2
    MOVE.W  (A3)+, D2
    MOVE.W  (A3), D3
    MOVE.B  #4, D1        *counter for 4 nibbles or 16 bits
    MOVE.B  #'$', (A5)+
    JSR     print_address_word
    *subtract to get bit mask for registers
    SUB.L   #$02, A3
    *move word address
    MOVE.L  (A3), D2
    *swap for bit mask
    SWAP    D2
    *append output
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #7, numBytes

    *determine if pre or post
    JSR     getBits11_13
    CMP.B   #4, D7
    BEQ     addr_mem_to_list_pre
    *else
    JSR     reg_list_post
    *increment for next word to decode
    MOVE.W  (A3)+, D1 
    BRA     print_output

addr_mem_absolute_long:
    *increment address to address
    MOVE.W  A3, D1
    MOVE.W  (A3)+, D2
    MOVE.W  (A3)+, D2
    MOVE.L  (A3), D3
    MOVE.B  #8, D1        *counter for 4 nibbles or 16 bits
    MOVE.B  #'$', (A5)+
    JSR     print_address_long
    *subtract to get bit mask for registers
    SUB.L   #$04, A3
    *move long address
    MOVE.L  (A3), D2

    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #11, numBytes

    *determine if pre or post
    JSR     getBits11_13
    CMP.B   #4, D7
    BEQ     addr_mem_to_list_pre
    *else
    JSR     reg_list_post
    *increment for next word to decode
    MOVE.W  (A3)+, D1
    MOVE.W  (A3)+, D1

    BRA     print_output




*---------------------------------- Addressing -------------------------

*output address then operand
output_ea_op:
    JSR     address_main *addressing
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes
    BRA     output_operand *addressing

*output data register with last 3 bits
output_ead:
    MOVE.L  D5,D6
    MOVE.B  #'D', (A5)+
    ADD.W   #2, numBytes
    *get bits
    AND.B   #%00000111, D6
    ADD.B   #48, D6   *convert to ascii
    MOVE.B  D6, (A5)+ *append output
    RTS

*output operand and decide what kind
output_operand:
    *get bits
    MOVE.W  D5,D6
    LSR.L   #6, D6
    *compare and branch
    AND.B   #%00000111, D6
    CMP.B   #%00000000, D6
    BEQ     output_dn_noRet
    CMP.B   #%00000001, D6
    BEQ     output_an_noRet
    CMP.B   #%00000100, D6
    BEQ     output_pre
    CMP.B   #%00000011, D6
    BEQ     output_post
    CMP.B   #%00000010, D6
    BEQ     output_indirect
    CMP.B   #%00000111, D6
    BEQ     output_address
    BRA     print_data        *if no match

*output some address
output_address:
    *get bits
    JSR     getBits5_7
    *compare and branch for word or long
    CMP.B   #0, D7
    BEQ     output_absolute_word
    CMP.B   #1, D7
    BEQ     output_absolute_long
    
output_absolute_word:
    JSR     AbsoluteWord
    BRA     print_output

output_absolute_long:
    JSR     AbsoluteLong
    BRA     print_output

*helper methods
output_dn_noRet:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.W   #48, D7     *convert to ascii

    MOVE.B  #'D', (A5)+
    MOVE.B  D7, (A5)+   *append number

    ADD.W   #2, numBytes  
    BRA     print_output
    
*helper methods
output_an_noRet:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.W   #$30, D7    *convert to ascii

    MOVE.B  #'A', (A5)+
    MOVE.B  D7, (A5)+   *append number

    ADD.W   #2, numBytes
    BRA     print_output

*helper methods
output_dn:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.B   #$30, D7    *convert to ascii

    MOVE.B  #'D', (A5)+
    MOVE.B  D7, (A5)+  *append number
    ADD.W   #2, numBytes

    RTS

output_an:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.B   #$30, D7

    MOVE.B  #'A', (A5)+
    MOVE.B  D7, (A5)+   *append number
    ADD.W   #2, numBytes

    RTS

output_pre:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.B   #$30, D7     *convert to ascii

    MOVE.B  #'-', (A5)+
    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+
    MOVE.B  D7, (A5)+    *append number
    MOVE.B  #')', (A5)+

    ADD.W   #5, numBytes
    BRA     print_output

output_post:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.B   #$30, D7    *convert to ascii

    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+
    MOVE.B  D7, (A5)+   *append number
    MOVE.B  #')', (A5)+
    MOVE.B  #'+', (A5)+

    ADD.W   #5, numBytes
    BRA     print_output

output_indirect:
    MOVE.L  D5,D6
    JSR     getBits5_7
    ADD.B   #$30, D7    *convert to ascii

    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+
    MOVE.B  D7, (A5)+   *append number
    MOVE.B  #')', (A5)+

    ADD.W   #4, numBytes
    BRA     print_output


*----------------------- Movem default--------------------*
*outputs registers that are marked in register list, as a list (ex:D2 D0_/D5/A1_A4/A6)
*check every bit in the word mask bit by bit and output 
*the register if the corresponding bit is set
reg_list_post:
    BTST.L    #$0F, D2
    BNE       post_a7
    BRA       post_a7No

post_a7:
    JSR       output_a7

post_a7No:
    BTST.L    #$0E, D2
    BNE       post_a6
    BRA       post_a6No

post_a6:
    JSR       output_a6

post_a6No:
    BTST.L    #$0D, D2
    BNE       post_a5
    BRA       post_a5No

post_a5:
    JSR       output_a5

post_a5No:
    BTST.L    #$0C, D2
    BNE       post_a4
    BRA       post_a4No

post_a4:
    JSR       output_a4

post_a4No:
    BTST.L    #$0B, D2
    BNE       post_a3
    BRA       post_a3No

post_a3:
    JSR       output_a3

post_a3No:
    BTST.L    #$0A, D2
    BNE       post_a2
    BRA       post_a2No

post_a2:
    JSR       output_a2

post_a2No:
    BTST.L    #$09, D2
    BNE       post_a1
    BRA       post_a1No

post_a1:
    JSR       output_a0

post_a1No:
    BTST.L    #$08, D2
    BNE       post_a0
    BRA       post_a0No

post_a0:
    JSR       output_a1

post_a0No:
    BTST.L    #$07, D2
    BNE       post_d7
    BRA       post_d7No

post_d7:
    JSR       output_d7

post_d7No:
    BTST.L    #$06, D2
    BNE       post_d6
    BRA       post_d6No

post_d6:
    JSR       output_d6

post_d6No:
    BTST.L    #$05, D2
    BNE       post_d5
    BRA       post_d5No

post_d5:
    JSR       output_d5

post_d5No:
    BTST.L    #$04, D2
    BNE       post_d4
    BRA       post_d4No

post_d4:
    JSR       output_d4

post_d4No:
    BTST.L    #$03, D2
    BNE       post_d3
    BRA       post_d3No

post_d3:
    JSR       output_d3

post_d3No:
    BTST.L    #$02, D2
    BNE       post_d2
    BRA       post_d2No

post_d2:
    JSR       output_d2

post_d2No:
    BTST.L    #$01, D2
    BNE       post_d1
    BRA       post_d1No

post_d1:
    JSR       output_d1

post_d1No:
    BTST.L    #$00, D2
    BNE       post_d0
    BRA       post_d0No

post_d0:
    JSR       output_d0

post_d0No:
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes
    RTS





*----------------------- Movem pre: -(A)--------------------*
*outputs registers that are marked in register list, as a list (ex:D2 D0_/D5/A1_A4/A6)
*check every bit in the word mask bit by bit and output 
*the register if the corresponding bit is set
reg_list_pre:
    BTST.L    #$0F, D2
    BNE       pre_d0
    BRA       pre_d0No

pre_d0:
    JSR       output_d0

pre_d0No:
    BTST.L    #$0E, D2
    BNE       pre_d1
    BRA       pre_d1No

pre_d1:
    JSR       output_d1

pre_d1No:
    BTST.L    #$0D, D2
    BNE       pre_d2
    BRA       pre_d2No

pre_d2:
    JSR       output_d2

pre_d2No:
    BTST.L    #$0C, D2
    BNE       pre_d3
    BRA       pre_d3No

pre_d3:
    JSR       output_d3

pre_d3No:
    BTST.L    #$0B, D2
    BNE       pre_d4
    BRA       pre_d4No

pre_d4:
    JSR       output_d4

pre_d4No:
    BTST.L    #$0A, D2
    BNE       pre_d5
    BRA       pre_d5No

pre_d5:
    JSR       output_d5

pre_d5No:
    BTST.L    #$09, D2
    BNE       pre_d6
    BRA       pre_d6No

pre_d6:
    JSR       output_d6

pre_d6No:
    BTST.L    #$08, D2
    BNE       pre_d7
    BRA       pre_d7No

pre_d7:
    JSR       output_d7

pre_d7No:
    MOVE.B  #'/', (A5)+
    ADD.W   #1, numBytes

    BTST.L    #$07, D2
    BNE       pre_a0
    BRA       pre_a0No

pre_a0:
    JSR       output_a0

pre_a0No:
    BTST.L    #$06, D2
    BNE       pre_a1
    BRA       pre_a1No

pre_a1:
    JSR       output_a1

pre_a1No:
    BTST.L    #$05, D2
    BNE       pre_a2
    BRA       pre_a2No

pre_a2:
    JSR       output_a2

pre_a2No:
    BTST.L    #$04, D2
    BNE       pre_a3
    BRA       pre_a3No

pre_a3:
    JSR       output_a3

pre_a3No:
    BTST.L    #$03, D2
    BNE       pre_a4
    BRA       pre_a4No

pre_a4:
    JSR       output_a4

pre_a4No:
    BTST.L    #$02, D2
    BNE       pre_a5
    BRA       pre_a5No

pre_a5:
    JSR       output_a5

pre_a5No:
    BTST.L    #$01, D2
    BNE       pre_a6
    BRA       pre_a6No

pre_a6:
    JSR       output_a6

pre_a6No:
    BTST.L    #$00, D2
    BNE       pre_a7
    BRA       pre_a7No

pre_a7:
    JSR       output_a7

pre_a7No:
    MOVE.B  #',', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #2, numBytes
    RTS





*-----------------------Movem Helpers--------------------*

output_a0:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'0', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a1:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'1', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a2:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'2', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a3:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'3', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a4:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'4', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a5:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'5', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a6:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'6', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_a7:
    MOVE.B  #'A', (A5)+
    MOVE.B  #'7', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d0:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'0', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d1:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'1', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d2:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'2', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d3:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'3', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d4:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'4', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d5:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'5', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d6:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'6', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS

output_d7:
    MOVE.B  #'D', (A5)+
    MOVE.B  #'7', (A5)+
    MOVE.B  #'/', (A5)+
    ADD.W   #3, numBytes
    RTS






*all opcode functions call main or specific mode
address_main:
    MOVE.L  D5, D7
    AND.B   #%11111111, D7
    MOVE.B  D5, D2
    *save register in D2
    AND.B   #%00000111, D2
    *save mode in D7
    AND.B   #%00111000, D7
    LSR.B   #3, D7
    *compare and branch 
    CMP.B   #%00000000,D7
    BEQ     DirectData 
    CMP.B   #%00000001,D7
    BEQ     DirectAddress
    CMP.B   #%00000010,D7
    BEQ     IndirectAddress
    CMP.B   #%00000011,D7
    BEQ     PostIncrement
    CMP.B   #%00000100,D7
    BEQ     PreDecrement
    CMP.B   #%00000111,D7
    BEQ     check_register
    RTS

*check for immediate or absolute
check_register:
    CMP.B   #%00000000,D2
    BEQ     AbsoluteWord 
    CMP.B   #%00000001,D2
    BEQ     AbsoluteLong
    CMP.B   #%00000100,D2
    BEQ     Immediate

*---------------------------------- Addressing Modes -------------------------

DirectData:
    ADD.W   #2, numBytes
    MOVE.L  #$02, counter
    MOVE.B  D2, D6        *prepare number to print

    MOVE.B  #'D', (A5)+
    JSR     print_number
    MOVE.B  D6, (A5)+     *append number
    RTS


DirectAddress:
    ADD.W   #2, numBytes
    MOVE.L  #$02, counter
    MOVE.B  D2, D6       *prepare number to print

    MOVE.B  #'A', (A5)+
    JSR     print_number  
    MOVE.B  D6, (A5)+   *append number

    RTS

Immediate:
    MOVE.B  #'#', (A5)+
    MOVE.B  #'$', (A5)+
    JSR     ImmediateSize
    RTS
    
ImmediateSize:
    ADD.W   #2, numBytes
    MOVE.B  addr_size, D7
    *compare and branch
    CMP.B   #%00000000, D7
    BEQ     ImmediateByte
    CMP.B   #%00000001, D7
    BEQ     ImmediateWord
    CMP.B   #%00000010, D7
    BEQ     ImmediateLong
    BRA     print_data

ImmediateByte:
    MOVE.L  #$02, counter
    ADD.W   #4, numBytes
    
    MOVE.W  (A3)+, D3    *prepare immediate to print
    MOVE.W  (A3), D3
    MOVE.B  #4, D1       *counter for 4 nibbles or 16 bits
    
    JSR     print_address_word
    RTS

ImmediateWord:
    MOVE.L  #$02, counter
    ADD.W   #4, numBytes

    MOVE.W  (A3)+, D3    *prepare immediate to print
    MOVE.W  (A3), D3
    MOVE.B  #4, D1       *counter for 4 nibbles or 16 bits
    
    JSR     print_address_word
    RTS

ImmediateLong:
    MOVE.L  #$02, counter
    ADD.W   #8, numBytes

    MOVE.W  (A3)+, D3    *prepare immediate to print
    MOVE.L  (A3), D3
    MOVE.B  #8, D1       *counter for 8 nibbles or 32 bits
    
    JSR     print_address_long

    MOVE.W  (A3)+, D3
    RTS

IndirectAddress:
    ADD.W   #4, numBytes
    MOVE.L  #$02, counter
    
    MOVE.B  D2, D6         *prepare number to print

    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+

    JSR     print_number

    MOVE.B  D6, (A5)+    *append number
    MOVE.B  #')', (A5)+
    
    RTS

PostIncrement:
    ADD.W   #5, numBytes
    MOVE.L  #$02, counter

    MOVE.B  D2, D6         *prepare number to print

    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+

    JSR     print_number

    MOVE.B  D6, (A5)+    *append number
    MOVE.B  #')', (A5)+
    MOVE.B  #'+', (A5)+
    RTS

PreDecrement:
    ADD.W   #5, numBytes
    MOVE.L  #$02, counter

    MOVE.B  D2, D6        *prepare number to print

    MOVE.B  #'-', (A5)+
    MOVE.B  #'(', (A5)+
    MOVE.B  #'A', (A5)+

    JSR     print_number

    MOVE.B  D6, (A5)+    *append number
    MOVE.B  #')', (A5)+
    RTS

AbsoluteWord:
    MOVE.L  #$02, counter
    MOVE.B  #'$', (A5)+
    ADD.W   #5, numBytes

    MOVE.W  (A3)+, D3     *prepare address to print
    MOVE.W  (A3), D3    
    MOVE.B  #4, D1        *counter for 4 nibbles or 16 bits

    JSR     print_address_word
    RTS


AbsoluteLong:
    MOVE.L  #$04, counter
    MOVE.B  #'$', (A5)+
    ADD.W   #9, numBytes

    MOVE.W  (A3)+, D3   *prepare address to print
    MOVE.L  (A3), D3
    MOVE.B  #8, D1      *counter for 4 nibbles or 16 bits

    JSR     print_address_long
    RTS

print_address_word:
    *get bits to print
    ROL.W   #4,D3
    MOVE.B  D3, D6
    AND.B   #$0F,D6

    JSR     print_number  *checks for letter
    MOVE.B  D6, (A5)+
    SUB.B   #1, D1        *subtract from counter
    CMP.B   #0, D1

    BNE     print_address_word
    RTS 

print_address_long:
    *get bits to print
    ROL.L   #4,D3
    MOVE.B  D3, D6
    AND.B   #$0F,D6

    JSR     print_number  *checks for letter
    MOVE.B  D6, (A5)+
    SUB.B   #1, D1        *subtract from counter
    CMP.B   #0, D1

    BNE     print_address_long
    RTS

print_number:
    *check if letter
    CMP.B   #$A, D6
    BGE     print_letter
    ADD.B   #$30, D6    *convert to ascii
    RTS

print_letter:
    ADD.B   #$37, D6    *convert to ascii
    RTS


*___________________________Helper Methods_____________________
byte_op:
    MOVE.B  #'B', (A5)+
    MOVE.L  #0, addr_size
    ADD.W   #1, numBytes
    JSR     tab
    RTS

*use word
word_op:
    MOVE.B  #'W', (A5)+
    MOVE.L  #1, addr_size
    ADD.W   #1, numBytes
    JSR     tab
    RTS

long_op:
    MOVE.B  #'L', (A5)+
    MOVE.L  #2, addr_size
    ADD.W   #1, numBytes
    JSR     tab
    RTS
    
*get bits from D5 and save a byte in D7
getBits5_7:
    MOVE.W  D5, D7
    LSR.W   #$08, D7
    LSR.W   #$01, D7
    AND.B   #%00000111, D7
    RTS

*get bits from D5 and save a byte in D7
getBits8_10:
    MOVE.L  D5, D7
    LSR.W   #$06, D7
    AND.B   #%00000111, D7
    RTS

*get bits from D5 and save a byte in D7
getBits11_13:
    MOVE.L  D5, D7
    LSR.W   #$03, D7
    AND.B   #%00000111, D7
    RTS

*get bits from D5 and save a byte in D7
getBits14_16:
    MOVE.W  D5, D7
    AND.B   #%00000111, D7
    RTS    
    
* print ascii to hex for a longword
printHex:
    MOVE.L  D3, D7
    CMP.B   #8, D2        *compare counter to finish
    BEQ     convertDone
    ROL.L   #4,D3         *get next bits
    AND.B   #%00001111, D3
    ADD.B   #1,D2         *add to counter
    CMP.B   #9,D3         *compare if letter or number
    BGT     letterToAscii
    BLE     numToAscii
convertDone:
    RTS

* convert a letter to ascii
letterToAscii:
    ADD.L   #55, D3
    MOVE.B  D3, (A5)+
    ADD.W   #1,numBytes
    *get bits
    ROL.L   #4,D7
    MOVE.L  D7,D3
    *print more
    BRA     printHex

* convert number to ascii
numToAscii:
    ADD.L   #48, D3
    MOVE.B  D3, (A5)+
    ADD.W   #1,numBytes
    *get bits
    ROL.L   #4,D7
    MOVE.L  D7,D3
    *print more
    BRA     printHex

* add a tab to the output
tab: 
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    MOVE.B  #' ', (A5)+
    ADD.W   #4, numBytes
    RTS

* if no match with opcode print address followed by "d" then the hex data 
print_data:
    MOVE.B  #'d', (A5)+
    MOVE.B  #' ', (A5)+
    JSR     tab
    JSR     tab
    MOVE.B  #'$', (A5)+
    ADD.W   #3, numBytes
    *prepare address
    MOVE.L  D5, D6
    MOVE.L  #4, D2        *counter for hex
    MOVE.L  D5, D3
    SWAP    D3

    JSR     printHex
    BRA     print_output

*print immediate data
print_data_immediate:
    *prepare address to print
    MOVE.L  D5, D6
    MOVE.L  #4, D2
    MOVE.L  D5, D3
    SWAP    D3
    JSR     printHex
    *increment address to data
    ADD.W   #$02, A3
    MOVE.W  (A3), D5
    RTS

*print a single line of output and go back for next opcode
print_output:
    MOVE.B  #0, D0
    LEA     string, A1
    MOVE.W  numBytes, D1
    TRAP    #15
    BRA     iterate    

*finish
done:
    LEA     doneMessage,A1
    MOVE.B  #13,D0
    TRAP    #15



    SIMHALT             ; halt simulator

*messages to display to user

CR:         EQU   $0D  *ascii carraige return
LF:         EQU   $0A  *ascii line feed

prompt:      DC.B     'Welcome to our Disassembler Program, brought to you by Group BSR!', CR, LF
             DC.B     'This is a dissassembler which read from a portion in memory and converts', CR, LF
             DC.B     'the machine code into assembly level code.', CR, LF
             DC.B     'Note: Addresses entered must be (1) in hexadecimal, (2) should be even,', CR, LF
             DC.B     'and (3) should be 4 or 8 digits ONLY.', CR, LF, 0         
start_addr:  DC.B     'Enter a starting address between $00000000 and $FFFFFFFF to start', CR, LF
             DC.B     'reading from: $', CR, LF, 0          
end_addr:    DC.B     'Enter an ending address between $00000000 and $FFFFFFFF to start', CR, LF
             DC.B     'reading from: $', CR, LF, 0   
ErrorMsg1:   DC.B     'Error: You must enter an address that is 8 digits.', CR, LF, 0   
ErrorMsg2:   DC.B     'Error: You must enter an even hexadecimal address.', CR, LF, 0
RangeError:  DC.B     'Error: You must enter an address that is after 0 and less than $FFFFFFFF.', CR, LF, 0   
StartOddError:  DC.B     'Error: Start address must end with an even number.', CR, LF, 0
EndOddError:    DC.B     'Error: End address must end with an even number.', CR, LF, 0
StartError:  DC.B     'Error: Starting address must be before the ending address.', CR, LF, 0
invalidChar: DC.B     'Error: Address entered was not valid please enter another one.', CR, LF
             DC.B     'Note: (1) Address entered must be in capital letters, and ', CR, LF
             DC.B     '(2) letters must be from A-F only.', CR, LF, 0
empty_line:  DC.B     '',CR,LF,0
doneMessage: DC.B     'The Disassembler is done',CR,LF,0
file_name:   DC.B     'output.txt',0

*variables
start_hex:   DS.L  1
end_hex:     DS.L  1
addr_size:   DS.L  1  *size value for addressing modes
addrCounter: DS.L  1  *counter for printing
counter:     DS.L  1  *counter to add to address
endSearch:   DS.L  1  *end of memory read
endPrint:    DS.L  1  *end of printing output
numLines:    DS.L  1  *used for number of output lines
numBytes:    DS.L  1  *total number of bytes of output
hexCounter:  DS.L  1  *used as a counter for printing


*locations in memory to store values
string:    EQU  $4000  *used for single line of output
                 
                 
    *END    dasm_main        ; last line of source
    
    END dasm_main
    

    SIMHALT
*~Font name~Courier New~
*~Font size~16~

















































*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
