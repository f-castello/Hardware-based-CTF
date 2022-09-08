from pynq import DefaultIP
from pynq import Overlay
from pynq import Device
from pynq import Bitstream
from pynq import MMIO
import logging
import sys
import numpy as np
import math
import json
import string
import binascii

# Convert string in HEX form in array of int in binary form when format = 'HEX
# Convert string of BIN digit in array of 0/1 int ( binary but of type int)

def convert(data,format):
    LUT = {'0' : [0,0,0,0],
         '1' : [0,0,0,1],
         '2' : [0,0,1,0],
         '3' : [0,0,1,1],
         '4' : [0,1,0,0],
         '5' : [0,1,0,1],
         '6' : [0,1,1,0],
         '7' : [0,1,1,1],
         '8' : [1,0,0,0],
         '9' : [1,0,0,1],
         'A' : [1,0,1,0],
         'B' : [1,0,1,1],
         'C' : [1,1,0,0],
         'D' : [1,1,0,1],
         'E' : [1,1,1,0],
         'F' : [1,1,1,1]}
    dataBin = []
    if(format == 'HEX'):   
        for i in data:
            dataBin.append(LUT[i])
        dataBin = np.asarray(dataBin).reshape(-1)
    elif(format == 'BIN'): 
        for i in data:
            dataBin.append(int(i))
    return dataBin  
# convert blocks of 8 HEX string(32 bit) in array of integer 
def convertBlock(data,format):
    dataBin = []
    if(format == 'HEX'):
        for i in range(0,64,8):    
            dataBin.append(int(data[i:i+8], 16))
    elif(format == 'BIN'): 
        for i in range(0,256,32):    
            dataBin.append(int(data[i:i+32], 2))
    return dataBin
# convert the string of bit in a string of hex
def toHex(msg):
    msg = np.asarray(list(msg)).reshape(int(len(msg)/4),4)
    return ''.join(tohex(x) for x in msg)
#convert a hex character in 4 binary character
def tohex(msg):
    return str(hex(int(msg[0])*8 + int(msg[1])*4 + int(msg[2])*2 + int(msg[3])*1))[2:].upper()

# Class managing interfacing with PL of PYNQ
class CipherDriver(DefaultIP):


    def __init__(self, description):
        super().__init__(description=description)
# Bind the class, hthat inherit DefaultIP, to the IP
    bindto = ['xilinx.com:user:myip:1.0'] 
    
    def ciphe(self, message,messageFormat, ALFSR,seedFormat):
    # Convert the chiper text and the LFSR in an array of 0/1 integer for the message and on array of integer that rapresent 32 bit 
        messageBin = convert(message.upper(),messageFormat) 
        alfsrBin = convertBlock(ALFSR.upper(),seedFormat)

        ciphertext = []
        lfsr_out = []
        alfsr_out = []
        edge_out = []
        net_out = []
        fa_out = []

        logging.warning("Inside chipe")
        logging.warning(message)
        logging.warning(ALFSR)
        logging.warning(messageBin)
        logging.warning(alfsrBin)


    # Initialize control signal
        self.write(0x24,0) # SEQ_EN = 0
        self.write(0x28,0) # CLOCK = 0
        self.write(0x2C,0) # RESET = 0
        self.write(0x30,0) # LOAD_0 = 0 
        self.write(0x34,0) # LOAD_A = 0
    # Reset the design
        self.write(0x24,1) # SEQ_EN = 1
        self.write(0x2C,1) # RESET = 1
        self.write(0x28,1) # CLOCK = 1
        self.write(0x28,0) # CLOCK = 0
        
        self.write(0x28,1) # CLOCK = 1
        self.write(0x28,0) # CLOCK = 0
        self.write(0x28,1) # CLOCK = 1
        self.write(0x28,0) # CLOCK = 0
        self.write(0x2C,0) # RESET = 0 
  
        self.write(0x28,1) # CLOCK = 1
        self.write(0x28,0) # CLOCK = 0

    #load ALFSR parallel with first bit of plaintext
        self.write(0x34,1) # LOAD_A = 1 
        for i in range(0,32,4):    # TODO  check order for ALFSR
            temp = alfsrBin[int(i/4)]
            logging.warning(f"Writing in {i} {temp} ")
            self.write(i , temp) # convert the ALFSR to binary( integer base )
    #load message 
        self.write(0x30,1) #LOAD_0 = 1 
        x = 0 
        y = 1
        for i in messageBin: # write the vector LSB first 
            logging.warning(f"Writing in 0x28 value {i} of message. {y} iteration ")
            self.write(0x20,int(i)) #SERIAL_IN = i
            y = y+1
        # When the ACK is = 1 (4294967295 because we write 1 for 32 bit) we start to read the output port
            if(self.read(0x50) == 4294967295 and x < len(messageBin)):
                ciphertext.append(0 if self.read(0x4C) == 0 else 1)
                lfsr_out.append(0 if self.read(0x38) == 0 else 1) 
                alfsr_out.append(0 if self.read(0x3C) == 0 else 1)
                edge_out.append(0 if self.read(0x44) == 0 else 1) 
                net_out.append(0 if self.read(0x48) == 0 else 1) 
                fa_out.append(0 if self.read(0x40) == 0 else 1)
                x = x+1
                logging.warning(f"Reading {x} value")
            self.write(0x28,1) #CLOCK = 1
            self.write(0x28,0) #CLOCK = 0

            self.write(0x34,0) #LOAD_A = 0
        self.write(0x30,0) #LOAD_0 = 0
    #wait till output ready at output port
        logging.warning(f"Finished loading. Reading {x} bits output")
    # Continue to read output till the lenght of the message
        while(x < len(messageBin)): 
            if(self.read(0x50) == 4294967295 ):
                logging.warning(f"edge {self.read(0x44)}")
                ciphertext.append(0 if self.read(0x4C) == 0 else 1)
                lfsr_out.append(0 if self.read(0x38) == 0 else 1) 
                alfsr_out.append(0 if self.read(0x3C) == 0 else 1)
                edge_out.append(0 if self.read(0x44) == 0 else 1) 
                net_out.append(0 if self.read(0x48) == 0 else 1) 
                fa_out.append(0 if self.read(0x40) == 0 else 1)
                x = x + 1
                logging.warning(f"Reading {x} value")
            
            self.write(0x28,0) #CLOCK = 0
            self.write(0x28,1) #CLOCK = 1
            self.write(0x28,0) #CLOCK = 0

        logging.warning("Reading completed")
        
        value = {               'output_CP' : ''.join(str(x) for x in ciphertext),
                                'output_LFSR' : ''.join(str(x) for x in lfsr_out),
                                'output_ALFSR' : ''.join(str(x) for x in alfsr_out),
                                'output_EDGE' : ''.join(str(x) for x in edge_out),
                                'output_NET' : ''.join(str(x) for x in net_out),
                                'output_FA' : ''.join(str(x) for x in fa_out)
                        }
    # Convert the message in HEX if the plain text was HEX
        if(messageFormat == 'HEX'):
            value["output_CP"] = toHex(value["output_CP"])
            value["output_LFSR"] = toHex(value["output_LFSR"])
            value["output_ALFSR"] = toHex(value["output_ALFSR"])
            value["output_EDGE"] = toHex(value["output_EDGE"])
            value["output_NET"] = toHex(value["output_NET"])
            value["output_FA"] = toHex(value["output_FA"])

        logging.warning("Process ended. Returning value to user")
        return value
 



        

                              
        
       