# 68kDisassembler
The program begins with simple IO subroutines that prompt the user to enter an address that is 8 digits in hex and the program will convert this to ascii to hex. Then the opcode detection begins which will mask the bits and compare the mask to the opcode bit values to branch to the correct opcode subroutines.

Opcode methods begin with immediate values that will print data for immediate opcodes in hex. Next is the branches which all call the same branch subroutine helpers. Every opcode is handled according to its function, if there needs to be addressing then it will either call address main, or its own custom addressing function such as movem. Output is pushed byte by byte to the 5th address register and the number of bytes to print will be incremented each time a character is added to the register. When the addressing is done it returns and the opcode will then branch to print and after this it will branch back to the start to increment the memory and find the next word to decode if there are any left. Addressing functions also include ways to output addresses that are of a higher bit count. These will shift different bits to output addresses with the output_operand method. There are two methods for each addressing mode in each bit place so 2 for each mode. 

Movem is completely custom addressing with a bit mask that will print the corresponding registers that are marked. The bit mask can be reversed depending on the mode of the opcode.

Program Flow:
![image](https://user-images.githubusercontent.com/53063791/153731505-14c909b8-2e99-4579-8247-c11009f22ee7.png)

IO Flow:
![image](https://user-images.githubusercontent.com/53063791/153731511-56574c44-10f3-45cc-923e-02c37bfbb835.png)


