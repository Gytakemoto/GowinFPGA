import numpy as np
import matplotlib.pyplot as plt

def plot_samples(samples_list):
    # Carrega os dados como strings
    f = np.loadtxt(samples_list, dtype=str)

    # Extrai os dois primeiros valores como número de amostras
    samples_after = int(f[0])
    samples_before = int(f[1])
    expected_samples = samples_after + samples_before + 1

    # Resto são as amostras
    data = f[2:]  # Remove os dois primeiros valores

    processed_samples = []
    error = 0

    for i, val in enumerate(data):
        try:
            adc_val = int("0x" + val, 16) - int("0xF000", 16)
            voltage = -(adc_val - 2**11) * 10 / 2**12
            processed_samples.append(voltage)
            ##print(f"Sample {i}: {voltage:.4f} V")
            if val[0] != "F":
                error += 1
        except ValueError:
            print(f"Erro ao processar valor '{val}' na posição {i+2}")
            error += 1

    # Verificação de discrepância entre esperadas e processadas
    actual_samples = len(processed_samples)
    print(f"\nAmostras esperadas: {expected_samples}")
    print(f"Amostras processadas: {actual_samples}")
    if actual_samples != expected_samples:
        print("⚠️  Erro: número de amostras processadas diferente do esperado.")
    else:
        print("✅ Todas as amostras esperadas foram processadas corretamente.")

    print(f"Erros de formatação encontrados: {error}")

    # Plota os dados
    plt.plot(processed_samples)
    plt.ylabel("ADC Voltage [V]")
    plt.xlabel("Sample number")
    plt.title("Dados convertidos do ADC")
    plt.grid(True)
    plt.show()

##filename = "csvFiles/teste_3/samples_[1].csv"
##plot_samples(filename)
