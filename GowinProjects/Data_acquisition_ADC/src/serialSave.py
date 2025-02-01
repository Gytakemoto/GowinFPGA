# ----------------------------- Needed libraries ----------------------------- #
# Activate the virtual environment: .venv\Scripts\activate
import serial
import time
import numpy as np
from colorama import init as colorama_init
from colorama import Fore, Style
import os
import time
from Check_file import check_samples_list
from pathlib import Path
import random

#Initialize Colorama
colorama_init()

#Flux control: control between while loops
wait_samples = False
wait_package = True
wait_check = False

#Variable initialization
#samples_after = 0
#samples_before = 0
new_message = 0
decodebytes = 0
last_time = 0

#Constants
SAMPLES_AFTER_MSG = "[A3]"
SAMPLES_BEFORE_MSG = "[A4]"
MAX_SAMPLES = 4194303
TIMEOUT = 2 #Seconds to wait between buffer readings

#Empty list for storing all samples
#samples_list = []

#Initialization of serial port. Define properly Baud Rate
PORT = 'COM12'
BAUD_RATE = 921600
serialCom = serial.Serial(PORT, BAUD_RATE)

#Increasing rx buffer size to prevent overflow
serialCom.set_buffer_size(rx_size = 8192)

# ------------------------------- Get filename ------------------------------- #
def get_name(logFilename, i):
    #timestamp = datetime.datetime.now().strftime("%a %d %b %Y %H-%M-y%S")
    return "csvFiles/" + str(logFilename) + "/samples_[" + str(i) + "].csv "


# -------------------- Auto-mode random samples generator -------------------- #
def get_random_samples(s,i):

    if(i == 4):
        return "max"
    elif(i == 5):
        if(s == "samples_after"):
            return str(0)
        elif(s == "samples_before"):
            return "max"
    else:
        samples_dict = {0 : str(random.randint(0, 1000)), 1 : str(random.randint(1001, 100000)), 2 : str(random.randint(100001,1000000)), 3 : str(random.randint(1000001,MAX_SAMPLES))}
        if s == "samples_after":
            return samples_dict.get(i)
        elif s == "samples_before":
            return samples_dict.get(3-i)    #Get complementary


# ---------------------------- InputHandler class ---------------------------- #

class InputHandler:  # this class handles user input sample_after and samples_list
    def __init__(self):
        self.samples_after = 0
        self.samples_list = []
        self.i = 0

    def gen_input(self, msg_id, method):
        if method == "manual":  
            message = input("Write to ESP32: ")
        elif method == "auto":
            answers_dict = {'[0]': "Y", '[1]': "A", '[A2]': "B", SAMPLES_AFTER_MSG: get_random_samples("samples_after", self.i), SAMPLES_BEFORE_MSG: get_random_samples("samples_before", self.i)}
            message = answers_dict.get(msg_id)
            print(Fore.BLUE,"[Auto - USER]",Style.RESET_ALL + str(message) + "\n")

        #if it's expected to be samples after:
        if(msg_id == SAMPLES_AFTER_MSG):
            try: 
                self.samples_after = int(message)
            except: 
                if(message == "max"): self.samples_after = MAX_SAMPLES
                else: self.samples_after = MAX_SAMPLES + 1 #Purposely out of range
            if self.samples_after <= MAX_SAMPLES:
                self.samples_list.append(self.samples_after)


        #if it's expected to be samples before:
        elif(msg_id == SAMPLES_BEFORE_MSG):
            try: 
                samples_before = int(message)
            except:
                if(message == "max"): 
                    samples_before = MAX_SAMPLES - self.samples_after
                else: samples_before = MAX_SAMPLES + 1 #Purposely out of range
            if samples_before <= MAX_SAMPLES - self.samples_after:
                self.samples_list.append(samples_before)

                if(self.i < 5):
                    self.i += 1
                else: self.i = 0
        return message

# ----------------------------------- Main ----------------------------------- #

#Ask for log outputs local
logPath = ""
while logPath == "":
    logFile = input("Select log's file name (i.e test_1): ")
    logPath = Path("logFiles/" + logFile + ".csv")
    if logPath.is_file():
        print("Given name already exists! Choose another name")
        logPath = ""

header = np.array(["RunTime", "Expected samples", "Samples", "Expected Samples After", "Samples After", "Expected Samples Before", "Samples Before", "STATUS"])
header = header.reshape(1, len(header))

with open(logPath, 'a') as file:
    np.savetxt(file, header, delimiter=';', fmt='%s')

method = ""
while method != "manual" and method != "auto":
    method = input("Select method between 'manual' and 'auto': ")
    if method != "manual" and method != "auto":
        print("Invalid input. Please try again.")

samples_no = 0
name = get_name(logFile, samples_no)

# Initialize InputHandler
handler = InputHandler()

#Main Loop
while True:
    #wait package -> collect message package and send it to ESP32
    while wait_package:
        ser_msg = new_message   #Updates message
        s_bytes = serialCom.readline()

        try:
            decodebytes = s_bytes.decode('utf-8').strip()
        except:
            decodebytes = " "
            print(Fore.BLUE,"[USER]",Style.RESET_ALL + "ESP32 is processing, please wait...")
            time.sleep(.5)

        split_decodebytes = decodebytes.split() 
        if(len(split_decodebytes) > 0):                     #Avoid empty strings
            #Collect current message
            if(split_decodebytes[0] == "[Auto]"):           
                new_message = ' '.join(split_decodebytes[1:len(split_decodebytes)])
            elif(split_decodebytes[0] == "[User]"):
                new_message = ' '.join(split_decodebytes[2:len(split_decodebytes)])

        #Does not display the same message twice
        if(ser_msg != new_message):
            print(Fore.YELLOW,"[ESP32]",Style.RESET_ALL,new_message)
            #If string contains [User], awaits for input. Otherwise, just displays
            if(split_decodebytes[0] == "[User]"):

                #message = manual_input(split_decodebytes, samples_list, samples_after)
                message = handler.gen_input(split_decodebytes[1], method)
                message = message  + '\n'
                serialCom.write(message.encode('utf-8'))

        #End of package
        if(decodebytes == "[Auto] Message sent successfully!") : 
            wait_samples = True
            wait_package = False
            last_time = 0

    hex_mes = ""

    while wait_samples:
        #Read all available bytes in serial POR
        s_bytes = serialCom.read(serialCom.inWaiting())

        #If a timeout applies, end transmission
        #!It must comply with ESP32 .ino timeout. See the source code!
        if (time.time() - last_time) > TIMEOUT and last_time != 0:

            print(Fore.GREEN, "[FPGA] Transmission ended", Style.RESET_ALL)

            samples_no += 1  #Increase samples_no for next file name
            name = get_name(logFile, samples_no)
            
            if not os.path.exists("csvFiles/" + str(logFile)):
                os.makedirs("csvFiles/" + str(logFile))

            np.savetxt(name, [data for data in handler.samples_list], delimiter=';', fmt='%s')
            print(".csv generated successfully!")

            #Resetting
            handler.samples_list = []
            wait_samples = False
            wait_check = True

        if s_bytes:
            last_time = time.time()
            #For each byte, convert to HEX and append to samples_list
            for byte in s_bytes:
                hex_mes += f"{byte:02X}"  #Converts to HEX format

                #If two bytes were read, append to samples_list
                if len(hex_mes) == 4:
                    #print(Fore.GREEN, "[FPGA]", Style.RESET_ALL + hex_mes.upper())
                    handler.samples_list.append(hex_mes.upper())
                    hex_mes = ""

    while wait_check:
        check_samples_list(name,str(logPath))
        wait_check = False
        wait_package = True


#Automatizar escolha de samples_after e samples_before
#Printar ok ok ok se tudo tiver certo
#Salvar logs relevantes em um arquivo e dar um append
#hummm