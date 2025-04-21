import numpy as np
from colorama import init as colorama_init
from colorama import Fore, Style
import time

def check_samples_list(samples_list, logFile):
    f = np.loadtxt(samples_list, dtype = str)
    samples_before = 0
    samples_after = 0
    samples_before = 0
    samples_before_no = 0
    samples_after_no = 0
    start_time = time.time()


    for i, val in enumerate(f):
        #First index
        if(i == 0):
            samples_after = int(f[i])
        #Second index
        elif(i == 1):
            samples_before = int(f[i])
        #Remaining indices
        elif(i < f.shape[0]-1):
            sample_before = str(f[i-1])
            if (f[i] == "F000"):
                if(sample_before == "F000"):
                    samples_before_no += 1
                elif (sample_before == "FFFF"): samples_after_no += 1

            hex_sample = int("0x" + f[i], 16)
            if (hex_sample == int("0x" + sample_before, 16) + 1):
                samples_after_no += 1
        else:
            sample_before = str(f[i-1])
            hex_sample = int("0x" + f[i], 16)
            if (hex_sample == int("0x" + sample_before, 16) + 1):
                samples_after_no += 1
            elif(f[i] == "F000"):
                samples_before_no += 1

            status = "CORRECT"
            if(i - 2 == samples_after + samples_before):
                print("[STATUS] Samples quantity:", Fore.GREEN, "CORRECT [" + str(int(samples_before) + int(samples_after)) + "]", Style.RESET_ALL)
            else:
                print("[STATUS] Samples quantity:", Fore.RED, "INCORRECT [" + str(int(samples_after_no) + int(samples_before_no)) + "]. Expected: [" + str(int(samples_before) + int(samples_after)) + "]", Style.RESET_ALL)
                status = "SAMPLES"

            #Checking sample_before
            if(samples_before_no == samples_before):
                print("[STATUS] Samples before:", Fore.GREEN, "CORRECT [" + str(samples_before) + "]", Style.RESET_ALL)
            else: 
                print("[STATUS] Samples before:", Fore.RED, "INCORRECT [" + str(samples_before_no) + "]. Expected: [" + str(samples_before) + "]", Style.RESET_ALL)
                status = status + " SAMPLES_BEFORE"
            #Checking sample_after
            if(samples_after_no == samples_after):
                print("[STATUS] Samples after:", Fore.GREEN, "CORRECT [" + str(samples_after_no) + "]", Style.RESET_ALL)
            else:
                print("[STATUS] Samples after:", Fore.RED, "INCORRECT [" + str(samples_after_no) + "]. Expected: [" + str(samples_after) + "]", Style.RESET_ALL)
                status = status + " SAMPLES_AFTER"

            print(samples_before_no,samples_after_no, samples_before, samples_after)

            finish_time = time.time()
            runtime = round(finish_time - start_time, 3)
            print("[STATUS] Tempo decorrido: " + str(runtime))

            logArray = np.array([str(runtime), str(int(samples_before) + int(samples_after)), str(int(samples_after_no) + int(samples_before_no)), str(samples_after), str(samples_after_no), str(samples_before), str(samples_before_no), status])
            logArray = logArray.reshape(1, len(logArray))


            with open(logFile, 'a') as file:
                np.savetxt(file, logArray, delimiter=';', fmt='%s')

#filename = "csvFiles/samples [Fri 17 Jan 2025 13-35-y31].csv"
#logFile = "logFiles/Teste1.csv"
#check_samples_list(filename, logFile)
