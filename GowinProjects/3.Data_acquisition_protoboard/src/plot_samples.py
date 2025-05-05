import numpy as np
import matplotlib.pyplot as plt

def plot_samples(samples_list):
    # Load the samples from the file
    f = np.loadtxt(samples_list, dtype = str)
    samples_before = 0
    samples_after = 0
    samples_before = 0
    samples_before_no = 0
    samples_after_no = 0
    error = 0

    for i, val in enumerate(f):
        #First index
        if(i == 0):
            samples_after = int(f[i])
        #Second index
        elif(i == 1):
            samples_before = int(f[i])
            samples = np.zeros(samples_after + samples_before + 1, dtype = int)
        #Remaining indices
        elif(i < f.shape[0]-1):
            samples[i-2] = int("0x" + f[i], 16) - int("0x" + "F000", 16)
            if(f[i][0] != "F"): error = error + 1
        else:
            samples[i-2] = int("0x" + f[i], 16) - int("0x" + "F000", 16)
            if(f[i][0] != "F"): error = error + 1
            
    converted_samples = -(samples - 2**11) * 10 / 2**12
    print(f'Foram encontrados %d erros \n', error)

    plt.plot(converted_samples)
    ##plt.axhline(2048, color='r', linestyle='--', label='2048 (Midpoint)')  # horizontal line for raw data
    plt.ylabel("ADC Voltage [V]")
    plt.xlabel("Samples number")
    plt.title("Frequency: 1MHz")
    plt.show()

#filename = "csvFiles/imagens_osciloscópio/samples_[3].csv"
#logFile = "logFiles/Teste1.csv"
#plot_samples(filename)